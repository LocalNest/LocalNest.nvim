-- nvim/lua/localnest/prompts.lua
-- System prompts and template builders

local M = {}

M.chat_system = [[You are a helpful coding assistant created by LocalNest. You help with:
- Code generation and completion
- Debugging and problem solving
- Code refactoring and optimization
- Explaining code and concepts

When asked about code, be precise, concise, and provide clear examples. Always explain your reasoning.]]

M.fim_system = [[You are a code completion assistant. Complete the code fragment provided, continuing the context naturally and correctly. Only return the completion itself without any explanations or additional text.]]

M.file_context_template = [[
Here is the full file context:

```{language}
{file_content}
```

Question: {question}]]

M.selection_template = [[Question: {selection}]]

M.inline_template = [[Question: {question}]]

--- Build a chat prompt with system and messages
function M.build_chat_prompt(system_prompt, question)
  return {
    system = system_prompt,
    messages = {
      {
        role = "user",
        content = question,
      },
    },
  }
end

--- Build a FIM prompt with prefix/suffix
function M.build_fim_prompt(prefix, suffix)
  -- Qwen2.5 FIM tokens
  local fim_prefix = "<|fim_prefix|>"
  local fim_middle = "<|fim_middle|>"
  local fim_suffix = "<|fim_suffix|>"

  return fim_prefix .. prefix .. fim_middle .. fim_suffix .. suffix
end

return M
