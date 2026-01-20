local M = {}

local config = require("localnest.config")
local fim = require("localnest.fim")
local chat = require("localnest.chat")

--- Main setup function
--- @param user_config table|nil User configuration overrides
function M.setup(user_config)
  -- Merge user config
  config.setup(user_config or {})

  vim.notify("LocalNest AI plugin loaded", vim.log.levels.INFO)
end

-- Export modules for direct use from user config
M.fim = fim
M.chat = chat
M.config = config

return M
