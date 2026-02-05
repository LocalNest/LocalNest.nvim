-- nvim/lua/localnest/prompts.lua
-- System prompts and template builders

local M = {}

M.chat_system = [[You are a helpful coding assistant created by LocalNest. You help with:
- Code generation and completion
- Debugging and problem solving
- Code refactoring and optimization
- Explaining code and concepts

When asked about code, be precise, concise, and provide clear examples. Always explain your reasoning.
Use markdown for code blocks with appropriate language tags.
If it's helpful, you can call tools using the following format:
<tool_call>
{"name": "tool_name", "arguments": {"arg1": "val1"}}
</tool_call>]]

M.explain_template = [[Explain the following code in detail, focusing on logic and potential edge cases:

```%s
%s
```]]

M.fix_template = [[I'm having an issue with this code. Please identify any bugs and provide a fixed version:

```%s
%s
```

Context:
%s]]

M.refactor_template = [[Refactor the following code to improve readability, efficiency, or maintainability. Explain your changes:

```%s
%s
```]]

M.unit_test_template = [[Generate comprehensive unit tests for the following code:

```%s
%s
```]]

M.file_context_template = [[
Here is the full file context:

```{language}
{file_content}
```

Question: {question}]]

--- Build a chat prompt with system and messages
function M.build_chat_prompt(system_prompt, messages)
  return {
    system = system_prompt,
    messages = messages,
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
