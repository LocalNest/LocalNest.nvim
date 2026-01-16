local M = {}

local config = require("localnest.config")
local fim = require("localnest.fim")
local chat = require("localnest.chat")
local cmp_source = require("localnest.cmp_source")

--- Main setup function
--- @param user_config table|nil User configuration overrides
function M.setup(user_config)
  -- Merge user config
  config.setup(user_config or {})

  -- Setup cmp source (nvim-cmp integration)
  pcall(function()
    cmp_source.setup()
  end)

  vim.notify("LocalNest AI plugin loaded", vim.log.levels.INFO)
end

-- Export modules for direct use from user config
M.fim = fim
M.chat = chat
M.config = config
M.cmp_source = cmp_source

return M
