local M = {}

local config = require("localnest.config")
local fim = require("localnest.fim")
local chat = require("localnest.chat")

--- Main setup function
--- @param user_config table|nil User configuration overrides
function M.setup(user_config)
  -- Merge user config
  config.setup(user_config or {})

  -- Setup highlight groups
  vim.api.nvim_set_hl(0, "LocalNestFimGhost", { fg = "#5c6370", italic = true, default = true })

  -- Setup auto-triggering
  fim.setup_autocmds()

  -- Register commands
  vim.api.nvim_create_user_command("LocalNestFimManual", function()
    fim.trigger_manual()
  end, {})

  vim.api.nvim_create_user_command("LocalNestChatClear", function()
    chat.clear_history()
  end, {})

  vim.notify("LocalNest AI plugin loaded", vim.log.levels.INFO)
end

-- Export modules for direct use from user config
M.fim = fim
M.chat = chat
M.config = config

return M
