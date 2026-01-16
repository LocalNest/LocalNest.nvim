-- nvim/lua/localnest/chat.lua
-- Chat/question mode module

local M = {}

local config  = require("localnest.config")
local http    = require("localnest.http")
local prompts = require("localnest.prompts")

-- Small helper: show text in a floating window
local function open_floating_window(title, text)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(text, "\n", { plain = true })
  table.insert(lines, 1, title)
  table.insert(lines, 2, string.rep("─", math.max(10, #title)))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width  = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.5)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })
end

-- Get visual selection from current visual range
local function get_visual_selection()
  local mode = vim.fn.mode()
  if not mode:lower():find("v") then
    return nil
  end

  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  if srow == erow then
    return vim.fn.getline(srow):sub(scol, ecol)
  else
    local lines = vim.fn.getline(srow, erow)
    lines[1] = lines[1]:sub(scol)
    lines[#lines] = lines[#lines]:sub(1, ecol)
    return table.concat(lines, "\n")
  end
end

-- Get whole buffer content
local function get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Get file language from filetype
local function get_language()
  local ft = vim.bo.filetype
  if ft == "" then
    return "text"
  end
  return ft
end

-- Call llama-server and get response (decoded table with .content)
local function llama_complete(question, system_prompt, callback)
  local url = string.format(
    "http://%s:%d/completion",
    config.get("llama_server.host"),
    config.get("llama_server.port")
  )

  local body = {
    prompt      = system_prompt .. "\n\n" .. question,
    n_predict   = config.get("chat.max_tokens"),
    temperature = config.get("chat.temperature"),
    model       = config.get("models.chat"),
    stream      = false,
  }

  http.post(url, body, function(err, response)
    vim.schedule(function()
      if err then
        vim.notify("Chat error: " .. err, vim.log.levels.ERROR)
        callback(nil)
        return
      end

      if type(response) ~= "table" or not response.content or response.content == "" then
        vim.notify("Chat error: empty or invalid response", vim.log.levels.WARN)
        callback(nil)
        return
      end

      callback(response.content)
    end)
  end)
end

-- Visual mode: ask on selection
function M.ask_on_selection()
  local selection = get_visual_selection()
  if not selection or selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  -- Ask the user for a question about the selected code
  vim.ui.input({ prompt = "LocalNest question: " }, function(question)
    if not question or question == "" then
      vim.notify("No question provided", vim.log.levels.WARN)
      return
    end

    local system_prompt = config.get("chat.system_prompt")

    vim.notify("Asking LocalNest AI...", vim.log.levels.INFO)

    -- Build the actual prompt from selection + user question
    local full_prompt = string.format(
      "You are a helpful coding assistant.\n\nCode:\n```%s\n```\n\nQuestion: %s\n\nAnswer:",
      selection,
      question
    )

    llama_complete(full_prompt, system_prompt, function(response)
      if not response then
        return
      end

      -- Use your existing UI (floating window or cmp)
      -- floating window version:
      local title = "LocalNest AI Response"
      local buf = vim.api.nvim_create_buf(false, true)
      local lines = vim.split(response, "\n", { plain = true })
      table.insert(lines, 1, title)
      table.insert(lines, 2, string.rep("─", math.max(10, #title)))
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

      local width  = math.floor(vim.o.columns * 0.7)
      local height = math.floor(vim.o.lines * 0.5)
      local row    = math.floor((vim.o.lines - height) / 2)
      local col    = math.floor((vim.o.columns - width) / 2)

      vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
      })
    end)
  end)
end


-- Visual/normal mode: ask with whole file context
function M.ask_on_file()
  local file_content = get_buffer_content()
  local language = get_language()

  local question = "What is the purpose and functionality of this file?"
  local prompt = prompts.file_context_template
    :gsub("{language}", language)
    :gsub("{file_content}", file_content)
    :gsub("{question}", question)

  local system_prompt = config.get("chat.system_prompt")

  vim.notify("Analyzing file with LocalNest AI...", vim.log.levels.INFO)

  llama_complete(prompt, system_prompt, function(response)
    if not response then
      return
    end

    open_floating_window("LocalNest AI File Analysis", response)
  end)
end

-- Insert mode: ask via @this block
function M.ask_inline()
  local line = vim.fn.getline(".")
  local _, _, question = line:find("@this%s*{%s*(.-)%s*}")

  if not question or question == "" then
    vim.notify("No @this block found on this line", vim.log.levels.WARN)
    return
  end

  local system_prompt = config.get("chat.system_prompt")

  vim.notify("Asking LocalNest AI...", vim.log.levels.INFO)

  llama_complete(question, system_prompt, function(response)
    if not response then
      return
    end

    open_floating_window("LocalNest AI Response", response)
  end)
end


function M.complete(question, system_prompt, callback)
  return llama_complete(question, system_prompt, callback)
end

return M
