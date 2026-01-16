-- nvim/lua/localnest/tools.lua
-- Tool calling integration with LocalNest n8n

local M = {}

local config = require("localnest.config")
local http = require("localnest.http")

--- Call a tool via LocalNest n8n endpoint
--- @param name string Tool name
--- @param arguments table Tool arguments
--- @param callback function(err, result) Callback
function M.call(name, arguments, callback)
  if not config.get("tools.enabled") then
    callback("Tools are disabled", nil)
    return
  end

  local url = config.get("tools.n8n_endpoint")
  local body = {
    tool = name,
    args = arguments,
  }

  http.post(url, body, function(err, response)
    if err then
      callback(err, nil)
      return
    end

    callback(nil, response)
  end)
end

--- Parse tool calls from model response
--- Format: <tool_call>\n{"name": "...", "arguments": {...}}\n</tool_call>
--- @param text string Response text
--- @return table Array of { name, arguments } tables
function M.parse_tool_calls(text)
  local tools = {}

  for tool_json in text:gmatch("<tool_call>%s*({.-})%s*</tool_call>") do
    local ok, tool = pcall(vim.fn.json_decode, tool_json)
    if ok and tool.name then
      table.insert(tools, tool)
    end
  end

  return tools
end

--- Execute tool calls and collect results
--- @param tool_calls table Array of { name, arguments }
--- @param callback function(err, results) Callback with results
function M.execute_tool_calls(tool_calls, callback)
  if #tool_calls == 0 then
    callback(nil, {})
    return
  end

  local results = {}
  local completed = 0

  for i, tool_call in ipairs(tool_calls) do
    M.call(tool_call.name, tool_call.arguments, function(err, result)
      completed = completed + 1
      if err then
        results[i] = { error = err }
      else
        results[i] = result
      end

      if completed == #tool_calls then
        callback(nil, results)
      end
    end)
  end
end

return M
