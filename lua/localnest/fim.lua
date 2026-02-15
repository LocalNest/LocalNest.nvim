-- lua/localnest/fim.lua
local api    = vim.api
local config = require("localnest.config")
local http   = require("localnest.http")

local M      = {}

local ns_fim = api.nvim_create_namespace("localnest_fim")

M.state      = M.state or {}
M.enabled    = config.get("fim.enabled") or true

function M.toggle()
    M.enabled = not M.enabled
    local status = M.enabled and "enabled" or "disabled"
    vim.notify("LocalNest FIM " .. status, vim.log.levels.INFO)
    
    if not M.enabled then
        M.dismiss()
    end
end

local function clear_state()
    if M.state.bufnr and api.nvim_buf_is_valid(M.state.bufnr) then
        api.nvim_buf_clear_namespace(M.state.bufnr, ns_fim, 0, -1)
    end
    M.state = {}
end

local function show_ghost(bufnr, lnum, col, text)
    api.nvim_buf_clear_namespace(bufnr, ns_fim, 0, -1)

    if not text or text == "" then return end

    -- Split text into lines
    local lines = {}
    for line in text:gmatch("([^\n\r]*)") do
        table.insert(lines, line)
    end
    -- Remove trailing empty line if it exists
    if #lines > 1 and lines[#lines] == "" then
        table.remove(lines)
    end

    if #lines == 0 then return end

    local first_line = lines[1]
    local other_lines = {}
    for i = 2, #lines do
        table.insert(other_lines, { { lines[i], "Comment" } })
    end

    local opts = {
        virt_text = { { first_line, "Comment" } },
        virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
    }

    if #other_lines > 0 then
        opts.virt_lines = other_lines
    end

    local id = api.nvim_buf_set_extmark(bufnr, ns_fim, lnum, col, opts)

    M.state = {
        bufnr = bufnr,
        lnum = lnum,
        col = col,
        text = text,
        mark_id = id,
    }
end

function M.trigger()
    if not M.enabled then return end

    local bufnr        = api.nvim_get_current_buf()
    local pos          = api.nvim_win_get_cursor(0)
    local lnum         = pos[1] - 1 -- 0-based
    local col          = pos[2]     -- 0-based byte index

    -- Get all lines
    local lines        = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local total        = #lines
    local current_line = lines[lnum + 1] or ""

    local before_lines = {}

    -- lines strictly before current line
    if lnum > 0 then
        for i = 1, lnum do
            table.insert(before_lines, lines[i])
        end
    end

    -- current line up to cursor column
    local before_current = current_line:sub(1, col)
    table.insert(before_lines, before_current)

    local prefix = table.concat(before_lines, "\n")

    local after_lines = {}

    -- current line after cursor
    local after_current = current_line:sub(col + 1)
    table.insert(after_lines, after_current)

    -- all lines after current line
    if lnum + 2 <= total then
        for i = lnum + 2, total do
            table.insert(after_lines, lines[i])
        end
    end

    local suffix = table.concat(after_lines, "\n")

    M.complete(prefix, suffix, function(suggestion)
        if not suggestion or suggestion == "" then
            clear_state()
            return
        end

        suggestion = suggestion:gsub("^%s+", "")
        show_ghost(bufnr, lnum, col, suggestion)
    end)
end

function M.accept()
    if not (M.state.bufnr and api.nvim_buf_is_valid(M.state.bufnr)) then
        return
    end

    local bufnr = M.state.bufnr
    local lnum  = M.state.lnum
    local col   = M.state.col
    local text  = M.state.text or ""

    api.nvim_buf_clear_namespace(bufnr, ns_fim, 0, -1)

    -- Split text into lines for multi-line insertion
    local lines = {}
    for line in text:gmatch("([^\n\r]*)") do
        table.insert(lines, line)
    end

    local current_line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
    local before = current_line:sub(1, col)
    local after  = current_line:sub(col + 1)

    if #lines == 1 then
        api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, { before .. lines[1] .. after })
        api.nvim_win_set_cursor(0, { lnum + 1, col + #lines[1] })
    else
        local new_lines = {}
        new_lines[1] = before .. lines[1]
        for i = 2, #lines - 1 do
            table.insert(new_lines, lines[i])
        end
        table.insert(new_lines, lines[#lines] .. after)

        api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, new_lines)
        api.nvim_win_set_cursor(0, { lnum + #lines, #lines[#lines] })
    end

    clear_state()
end

function M.dismiss()
    clear_state()
end

function M.complete(prefix, suffix, callback)
    local url = string.format(
        "http://%s:%d/infill",
        config.get("llama_server.host"),
        config.get("llama_server.port")
    )

    local body = {
        prompt         = "",
        input_prefix   = prefix or "",
        input_suffix   = suffix or "",
        n_predict      = config.get("fim.max_tokens") or 64,
        temperature    = config.get("fim.temperature") or 0.0,
        top_p          = config.get("fim.top_p") or 0.9,
        top_k          = config.get("fim.top_k") or 40,
        repeat_penalty = config.get("fim.repeat_penalty") or 1.1,
        stop           = config.get("fim.stop_sequences") or { "```" },
        model          = config.get("models.fim"),
    }

    http.post(url, body, function(err, response)
        if err then
            vim.notify("FIM error: " .. tostring(err), vim.log.levels.ERROR)
            callback(nil)
            return
        end

        if type(response) ~= "table" then
            vim.notify("FIM error: invalid response type: " .. type(response), vim.log.levels.WARN)
            callback(nil)
            return
        end

        local text = response.content

        if not text or text == "" then
            vim.notify("FIM error: empty or missing content", vim.log.levels.WARN)
            callback(nil)
            return
        end
        callback(text)
    end)
end

local timer = vim.loop.new_timer()

function M.setup_autocmds()
    local group = api.nvim_create_augroup("LocalNestFIM", { clear = true })
    api.nvim_create_autocmd("TextChangedI", {
        group = group,
        pattern = "*",
        callback = function()
            if not config.get("fim.auto_trigger") or not M.enabled then return end
            
            timer:stop()
            timer:start(500, 0, vim.schedule_wrap(function()
                local mode = api.nvim_get_mode().mode
                if mode == "i" then
                    M.trigger()
                end
            end))
        end
    })

    -- Dismiss on insert leave
    api.nvim_create_autocmd("InsertLeave", {
        group = group,
        pattern = "*",
        callback = function()
            M.dismiss()
        end
    })
end

return M
