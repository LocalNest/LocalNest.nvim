-- nvim/lua/localnest/context.lua

local M = {}

--- Get LSP diagnostics for current buffer
--- @param bufnr number|nil
--- @return string
function M.get_diagnostics(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local diags = vim.diagnostic.get(bufnr)
    if #diags == 0 then return "" end

    local lines = { "LSP Diagnostics:" }
    for _, d in ipairs(diags) do
        local severity = vim.diagnostic.severity[d.severity] or "UNKNOWN"
        table.insert(lines, string.format("- [%s] Line %d: %s", severity, d.lnum + 1, d.message))
    end
    return table.concat(lines, "\n")
end

--- Get git diff for current buffer/project
--- @return string
function M.get_git_diff()
    local has_plenary, Job = pcall(require, "plenary.job")
    if not has_plenary then return "" end

    local diff = ""
    local job = Job:new({
        command = "git",
        args = { "diff", "--unified=1" },
        on_exit = function(j, return_val)
            if return_val == 0 then
                diff = table.concat(j:result(), "\n")
            end
        end,
    })
    job:sync()
    
    if diff ~= "" then
        return "Git Diff:\n" .. diff
    end
    return ""
end

--- Get symbols in current buffer via Treesitter
--- @return string
function M.get_symbols()
    local has_ts, _ = pcall(require, "nvim-treesitter")
    if not has_ts then return "" end

    -- Very basic symbol list for now
    local query_file = vim.treesitter.query.get(vim.bo.filetype, "locals")
    if not query_file then return "" end

    -- This can be complex, let's keep it simple for now and just return filetype
    return "Filetype: " .. vim.bo.filetype
end

--- Gather full context
--- @return string
function M.gather()
    local parts = {}
    
    local diags = M.get_diagnostics()
    if diags ~= "" then table.insert(parts, diags) end
    
    local diff = M.get_git_diff()
    if diff ~= "" then table.insert(parts, diff) end
    
    return table.concat(parts, "\n\n")
end

return M
