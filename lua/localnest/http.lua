-- nvim/lua/localnest/http.lua

local M = {}

--- POST request with optional streaming using curl CLI
--- @param url string
--- @param body table
--- @param callback function(err, response) Called once for non-stream, or for each chunk/event if stream=true
--- @param opts table|nil
function M.post(url, body, callback, opts)
    opts = opts or {}
    local timeout = opts.timeout or 30000
    local stream = body.stream or false

    local buffer = ""
    local full_response = ""

    local job_id = vim.fn.jobstart({
        "curl", "-sN",
        "-X", "POST",
        url,
        "-H", "Content-Type: application/json",
        "-d", "@-",
        "--max-time", tostring(timeout / 1000)
    }, {
        on_stdout = function(_, data)
            if not data then
                vim.notify("HTTP Warning: No data received", vim.log.levels.WARN)
                return
            end
            if not stream then
                full_response = full_response .. table.concat(data, "\n")
                return
            end

            -- Streaming logic
            for i, chunk in ipairs(data) do
                buffer = buffer .. chunk
                if i < #data then
                    -- We hit a newline
                    local line = vim.trim(buffer)
                    if line ~= "" then
                        local json_str = line:match("^data: (.*)$") or line
                        if json_str == "[DONE]" then
                            vim.schedule(function() callback(nil, nil) end)
                        else
                            local ok, decoded = pcall(vim.json.decode, json_str)
                            if ok then
                                vim.schedule(function() callback(nil, decoded) end)
                            end
                        end
                    end
                    buffer = ""
                end
            end
        end,
        on_exit = function(_, exit_code)
            if not stream then
                if full_response ~= "" then
                    local ok, decoded = pcall(vim.json.decode, full_response)
                    if ok then
                        vim.schedule(function() callback(nil, decoded) end)
                    else
                        vim.notify("Error Decoding Non Stream Result: " .. full_response, vim.log.levels.WARN)
                        vim.schedule(function() callback("Failed to decode JSON: " .. full_response, nil) end)
                    end
                else
                    vim.notify("Error, Empty full_response", vim.log.levels.WARN)
                    vim.schedule(function() callback("Empty response received", nil) end)
                end
            else
                -- Signal end of stream
                vim.schedule(function() callback(nil, nil) end)
            end
        end
    })

    if job_id > 0 then
        vim.fn.chansend(job_id, vim.json.encode(body))
        vim.fn.chanclose(job_id, "stdin")
    else
        callback("Failed to start curl", nil)
    end
end

return M
