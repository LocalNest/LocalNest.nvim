-- lua/localnest/fim.lua
local api     = vim.api
local config  = require("localnest.config")
local http    = require("localnest.http")

local M       = {}

local ns_fim  = api.nvim_create_namespace("localnest_fim")

M.state       = M.state or {}

local function clear_state()
    if M.state.bufnr and api.nvim_buf_is_valid(M.state.bufnr) then
        api.nvim_buf_clear_namespace(M.state.bufnr, ns_fim, 0, -1)
    end
    M.state = {}
end

local function show_ghost(bufnr, lnum, col, text)
    api.nvim_buf_clear_namespace(bufnr, ns_fim, 0, -1)

    local opts = {
        virt_text = { { text, "Comment" } },
        virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
    }

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
    local bufnr        = api.nvim_get_current_buf()
    local pos          = api.nvim_win_get_cursor(0)
    local lnum         = pos[1] - 1 -- 0-based
    local col          = pos[2] -- 0-based byte index

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
        local first_line = suggestion:match("([^\n\r]*)")
        if not first_line or first_line == "" then
            clear_state()
            return
        end

        show_ghost(bufnr, lnum, col, first_line)
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

    local line   = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
    local before = line:sub(1, col)
    local after  = line:sub(col + 1)

    api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, { before .. text .. after })

    api.nvim_win_set_cursor(0, { lnum + 1, col + #text })

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
        prompt       = "",
        input_prefix = prefix or "",
        input_suffix = suffix or "",
        n_predict    = config.get("fim.max_tokens") or config.get("chat.max_tokens") or 64,
        temperature  = config.get("fim.temperature") or config.get("chat.temperature") or 0.2,
        model        = config.get("models.fim"),
    }

    http.post(url, body, function(err, response)
        vim.schedule(function()
            if err then
                vim.notify("FIM error: " .. err, vim.log.levels.ERROR)
                callback(nil)
                return
            end

            if type(response) ~= "table" then
                vim.notify("FIM error: invalid response", vim.log.levels.WARN)
                callback(nil)
                return
            end

            local text = response.content or response.completion or response.text

            if not text or text == "" then
                vim.notify("FIM error: empty response", vim.log.levels.WARN)
                callback(nil)
                return
            end

            callback(text)
        end)
    end)
end

return M
