-- nvim/lua/localnest/cmp_source.lua
-- nvim-cmp integration for LocalNest responses

local M = {}

local source = {}
source.namespace = "localnest"
source.items = {}

function source.new()
  -- Use source as the metatable so all instances share source.items
  return setmetatable({}, { __index = source })
end

function source:complete(_, callback)
  callback({
    items = self.items or {},
    isIncomplete = false,
  })
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

function source:get_trigger_characters()
  return {} -- No auto-trigger; chat module calls cmp.complete() explicitly
end

function source:get_debug_name()
  return "localnest"
end

--- Register the source with nvim-cmp
function M.setup()
  local cmp = require("cmp")
  cmp.register_source(source.namespace, source.new())
end

--- Set items to show in cmp popup
--- @param items table Array of completion items
function M.set_items(items)
  source.items = items or {}
end

--- Clear items
function M.clear_items()
  source.items = {}
end

return M
