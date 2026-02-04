-- nvim/lua/localnest/chat.lua
-- Chat/question mode module with floating window and streaming support

local M = {}

local config  = require("localnest.config")
local http    = require("localnest.http")
local prompts = require("localnest.prompts")
local context = require("localnest.context")
local tools   = require("localnest.tools")

M.state = {
    bufnr = nil,
    winid = nil,
    history = {},
}

local function open_floating_window(title)
    local width  = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row    = math.floor((vim.o.lines - height) / 2)
    local col    = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "LocalNest Chat " .. os.time())
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })

    vim.api.nvim_set_option_value("wrap", true, { win = win })
    vim.api.nvim_set_option_value("linebreak", true, { win = win })
    vim.api.nvim_set_option_value("breakindent", true, { win = win })

    M.state.bufnr = buf
    M.state.winid = win
    return buf, win
end

local function append_to_chat(text)
    if not M.state.bufnr or not vim.api.nvim_buf_is_valid(M.state.bufnr) then
        return
    end
    
    local buf = M.state.bufnr
    local lines = vim.split(text, "\n", { plain = true })
    
    local last_line_idx = vim.api.nvim_buf_line_count(buf)
    local last_line = vim.api.nvim_buf_get_lines(buf, last_line_idx - 1, last_line_idx, false)[1] or ""
    
    if last_line == "" and last_line_idx == 1 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    else
        lines[1] = last_line .. lines[1]
        vim.api.nvim_buf_set_lines(buf, last_line_idx - 1, last_line_idx, false, lines)
    end
    
    -- Scroll to bottom and force redraw
    if M.state.winid and vim.api.nvim_win_is_valid(M.state.winid) then
        local new_last_line = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_win_set_cursor(M.state.winid, { new_last_line, 0 })
        vim.cmd("redraw")
    end
end

local loading_timer = nil
local loading_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local char_idx = 1

local function stop_loading()
    if loading_timer then
        loading_timer:stop()
        loading_timer:close()
        loading_timer = nil
    end
end

local function start_loading()
    stop_loading()
    local buf = M.state.bufnr
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

    append_to_chat("**LocalNest AI**: ")
    local line_count = vim.api.nvim_buf_line_count(buf)
    
    loading_timer = vim.loop.new_timer()
    loading_timer:start(0, 100, vim.schedule_wrap(function()
        if not vim.api.nvim_buf_is_valid(buf) then
            stop_loading()
            return
        end
        local char = loading_chars[char_idx]
        char_idx = (char_idx % #loading_chars) + 1
        vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, { "**LocalNest AI**: " .. char })
        vim.cmd("redraw")
    end))
end

-- Call llama-server with streaming using the /completion endpoint
local function llama_complete_stream(prompt, callback)
    local url = string.format(
        "http://%s:%d/completion",
        config.get("llama_server.host"),
        config.get("llama_server.port")
    )

    local body = {
        prompt = prompt,
        n_predict = config.get("chat.max_tokens"),
        temperature = config.get("chat.temperature"),
        model = config.get("models.chat"),
        stream = true,
    }

    local first_chunk = true
    local full_response = ""
    
    http.post(url, body, function(err, chunk)
        if err then
            stop_loading()
            append_to_chat("\n[Error: " .. err .. "]")
            return
        end

        if not chunk then
            -- Stream finished
            stop_loading()
            if callback then callback(full_response) end
            return
        end

        if first_chunk then
            stop_loading()
            -- Clear the loading line and start fresh with the label
            local buf = M.state.bufnr
            local line_count = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, { "**LocalNest AI**: " })
            first_chunk = false
        end

        local content = chunk.content
        if content then
            full_response = full_response .. content
            append_to_chat(content)
        end
    end)
end

function M.ask(question)
    open_floating_window("LocalNest AI")
    start_loading()
    
    local system_prompt = config.get("chat.system_prompt")
    local full_prompt = string.format("%s\n\n### User:\n%s\n\n### Assistant:\n", system_prompt, question)
    
    llama_complete_stream(full_prompt)
end

function M.ask_on_selection()
    local mode = vim.fn.mode()
    local selection
    if mode:lower():find("v") then
        local _, srow, scol = unpack(vim.fn.getpos("v"))
        local _, erow, ecol = unpack(vim.fn.getpos("."))
        if srow > erow or (srow == erow and scol > ecol) then
            srow, erow = erow, srow
            scol, ecol = ecol, scol
        end
        local lines = vim.fn.getline(srow, erow)
        if #lines > 0 then
            lines[1] = lines[1]:sub(scol)
            lines[#lines] = lines[#lines]:sub(1, ecol)
            selection = table.concat(lines, "\n")
        end
    end

    if not selection or selection == "" then
        vim.notify("No text selected", vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = "LocalNest question: " }, function(input)
        if not input or input == "" then return end
        
        local question = string.format("Code:\n```%s\n%s\n```\n\nQuestion: %s", vim.bo.filetype, selection, input)
        M.ask(question)
    end)
end

function M.ask_on_file()
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local question = string.format("Analyze this %s file:\n\n```%s\n%s\n```", vim.bo.filetype, vim.bo.filetype, content)
    M.ask(question)
end

function M.ask_inline()
    local line = vim.fn.getline(".")
    local _, _, question = line:find("@this%s*{%s*(.-)%s*}")

    if not question or question == "" then
        vim.notify("No @this block found on this line", vim.log.levels.WARN)
        return
    end

    M.ask(question)
end

function M.slash(command)
    local content = ""
    -- Logic for getting content (selection or full file)
    local mode = vim.fn.mode()
    if mode:lower():find("v") then
        local _, srow, scol = unpack(vim.fn.getpos("v"))
        local _, erow, ecol = unpack(vim.fn.getpos("."))
        if srow > erow or (srow == erow and scol > ecol) then
            srow, erow = erow, srow
            scol, ecol = ecol, scol
        end
        local lines = vim.fn.getline(srow, erow)
        if #lines > 0 then
            lines[1] = lines[1]:sub(scol)
            lines[#lines] = lines[#lines]:sub(1, ecol)
            content = table.concat(lines, "\n")
        end
    else
        content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    end

    local ft = vim.bo.filetype
    local ctx = context.gather()
    
    local prompt
    if command == "explain" then
        prompt = string.format(prompts.explain_template, ft, content)
    elseif command == "fix" then
        prompt = string.format(prompts.fix_template, ft, content, ctx)
    elseif command == "refactor" then
        prompt = string.format(prompts.refactor_template, ft, content)
    elseif command == "test" then
        prompt = string.format(prompts.unit_test_template, ft, content)
    else
        vim.notify("Unknown slash command: " .. command, vim.log.levels.ERROR)
        return
    end
    
    M.ask(prompt)
end

return M
