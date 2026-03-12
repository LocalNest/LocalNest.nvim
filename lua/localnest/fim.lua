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

    -- Restore cmp ghost text if we disabled it
    if M._cmp_ghost_text ~= nil then
        local has_cmp, cmp = pcall(require, "cmp")
        if has_cmp then
            cmp.setup({ experimental = { ghost_text = M._cmp_ghost_text } })
        end
        M._cmp_ghost_text = nil
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

    local hl_group = "LocalNestFimGhost"
    local first_line = lines[1]
    local other_lines = {}
    for i = 2, #lines do
        table.insert(other_lines, { { lines[i], hl_group } })
    end

    local opts = {
        virt_text = { { first_line, hl_group } },
        virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
        priority = 200, -- High priority to override other virtual text
    }

    if #other_lines > 0 then
        opts.virt_lines = other_lines
    end

    -- Conflict Resolution: Temporarily disable cmp ghost text if it exists
    local has_cmp, cmp = pcall(require, "cmp")
    if has_cmp and cmp.get_config().experimental.ghost_text then
        M._cmp_ghost_text = cmp.get_config().experimental.ghost_text
        cmp.setup({ experimental = { ghost_text = false } })
    end

    -- Ensure column is within bounds (in case buffer changed during async call)
    local line_content = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    if not line_content or col > #line_content then
        col = line_content and #line_content or 0
    end

    local ok, id = pcall(api.nvim_buf_set_extmark, bufnr, ns_fim, lnum, col, opts)
    if not ok then return end

    M.state = {
        bufnr = bufnr,
        lnum = lnum,
        col = col,
        text = text,
        mark_id = id,
    }
end

function M.trigger_auto()
    if not M.enabled then return end

    local bufnr = api.nvim_get_current_buf()
    local pos = api.nvim_win_get_cursor(0)
    local lnum = pos[1] - 1
    local col = pos[2]

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local current_line = lines[lnum + 1] or ""
    
    -- Prefix: strictly lines before + current line up to cursor
    local before_lines = {}
    for i = 1, lnum do table.insert(before_lines, lines[i]) end
    table.insert(before_lines, current_line:sub(1, col))
    local prefix = table.concat(before_lines, "\n")

    -- Suffix: current line after cursor + subsequent lines
    local after_lines = { current_line:sub(col + 1) }
    for i = lnum + 2, #lines do table.insert(after_lines, lines[i]) end
    local suffix = table.concat(after_lines, "\n")

    -- Auto mode: Tight tokens, strictly forward
    local opts = {
        max_tokens = 16,
    }

    M.complete(prefix, suffix, function(suggestion)
        if not suggestion or suggestion == "" then
            clear_state()
            return
        end
        
        -- Strip prefix/whitespace to ensure no cursor jumping
        suggestion = suggestion:gsub("^%s+", "")
        vim.schedule(function()
            show_ghost(bufnr, lnum, col, suggestion)
        end)
    end, opts)
end

function M.trigger_manual()
    if not M.enabled then return end

    local bufnr = api.nvim_get_current_buf()
    local pos = api.nvim_win_get_cursor(0)
    local lnum = pos[1] - 1
    local col = pos[2]

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local prefix = table.concat(vim.list_slice(lines, 1, lnum), "\n") .. "\n" .. lines[lnum+1]:sub(1, col)
    local suffix = lines[lnum+1]:sub(col + 1) .. "\n" .. table.concat(vim.list_slice(lines, lnum + 2), "\n")

    M.complete(prefix, suffix, function(suggestion)
        if not suggestion or suggestion == "" then
            clear_state()
            return
        end
        vim.schedule(function()
            show_ghost(bufnr, lnum, col, suggestion)
        end)
    end, { max_tokens = config.get("fim.max_tokens") or 128 })
end

function M.trigger()
    -- Compatibility wrapper or default to manual
    M.trigger_manual()
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

function M.complete(prefix, suffix, callback, opts)
    opts = opts or {}
    local url = string.format(
        "http://%s:%d/infill",
        config.get("llama_server.host"),
        config.get("llama_server.port")
    )

    local body = {
        prompt         = "",
        input_prefix   = prefix or "",
        input_suffix   = suffix or "",
        n_predict      = opts.max_tokens or config.get("fim.max_tokens") or 64,
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

        if type(text) ~= "string" or text == "" then
            -- Silent failure for auto-complete to avoid spamming
            if type(text) ~= "string" and not opts.max_tokens then
                vim.notify("FIM error: empty or invalid content", vim.log.levels.WARN)
            end
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
                    M.trigger_auto()
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
