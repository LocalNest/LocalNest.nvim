-- nvim/lua/localnest/config.lua
-- Configuration management for LocalNest plugin

local M = {}

local defaults = {
  llama_server = {
    host = "localnest",
    port = 8888,
    timeout = 30000,  -- ms
  },

  models = {
    fim = "qwen2.5-coder-7b.ollama.gguf",
    chat = "qwen2.5-coder-7b.ollama.gguf",
  },

  fim = {
    enabled = true,
    trigger = "<C-x>",  -- Manual trigger
    auto_trigger = false,  -- Auto on certain chars
    max_tokens = 64,
    temperature = 0.3,
    stop_sequences = { "\n\n", "```" },
    -- Constraints
    only_in_code = true,  -- FIM only in code blocks
    code_filetypes = { "lua", "rust", "python", "go", "typescript", "javascript", "cpp", "c" },
    min_prefix_len = 3,
    reject_short_results = true,
  },

  chat = {
    enabled = true,
    trigger_mode = {
      visual = "<leader>lq",  -- Visual: question on selection
      visual_file = "<leader>lf",  -- Visual: whole file context
      insert = "<leader>li",  -- Insert: opens @this input
    },
    max_tokens = 512,
    temperature = 0.7,
    system_prompt = "You are a helpful coding assistant. Help with code generation, debugging, refactoring, and explanation. Be precise and concise.",
    show_tool_calls = true,
  },

  tools = {
    enabled = true,
    n8n_endpoint = "http://localhost:5678/webhook/localnest",
  },
}

M.config = {}

--- Merge user config with defaults
local function merge_tables(base, user)
  local result = vim.deepcopy(base)
  if user then
    for k, v in pairs(user) do
      if type(v) == "table" and type(result[k]) == "table" then
        result[k] = merge_tables(result[k], v)
      else
        result[k] = v
      end
    end
  end
  return result
end

--- Setup function called by user
function M.setup(user_config)
  M.config = merge_tables(defaults, user_config or {})
end

--- Get config value
function M.get(key)
  local parts = vim.split(key, ".", { plain = true })
  local result = M.config
  for _, part in ipairs(parts) do
    if result == nil then
      return nil
    end
    result = result[part]
  end
  return result
end

-- Initialize with defaults
M.setup({})

return M
