-- lua/localnest/fim.lua
local api    = vim.api
local config = require("localnest.config")
local prompts = require("localnest.prompts")
local chat   = require("localnest.chat")  -- <— use existing wrapper

local M = {}

local ns_fim = api.nvim_create_namespace("localnest_fim")

M.state = M.state or {}

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
  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local lnum = pos[1] - 1
  local col  = pos[2]

  local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
  local language = vim.bo[bufnr].filetype

  local system_prompt = config.get("fim.system_prompt") or config.get("chat.system_prompt") or ""
  local tmpl = prompts.fim_template or prompts.inline_template or "{language}\n{line}"

  local user_prompt = tmpl
    :gsub("{language}", language)
    :gsub("{line}", line)

  chat.complete(user_prompt, system_prompt, function(suggestion)
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

  local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
  local before = line:sub(1, col)
  local after  = line:sub(col + 1)

  api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, { before .. text .. after })

  api.nvim_win_set_cursor(0, { lnum + 1, col + #text })

  clear_state()
end

function M.dismiss()
  clear_state()
end

return M
