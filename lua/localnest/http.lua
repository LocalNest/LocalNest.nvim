-- nvim/lua/localnest/http.lua

local M = {}

function M.post(url, body, callback, opts)
    opts                   = opts or {}
    local timeout          = opts.timeout or 30000

    local uv               = vim.loop
    local req              = uv.new_tcp()

    -- Parse URL
    local host, port, path = url:match("http://([^:/?]+):?(%d*)(/.*)")
    port                   = tonumber(port) or 80
    path                   = path or "/"

    local body_str         = vim.fn.json_encode(body)
    local http_request     = string.format(
        "POST %s HTTP/1.1\r\nHost: %s:%d\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s",
        path, host, port, #body_str, body_str
    )

    local response_data    = ""
    local timer            = uv.new_timer()

    -- Safe callback: always back on main loop
    local function safe_callback(err, res)
        vim.schedule(function()
            callback(err, res)
        end)
    end

    local function cleanup()
        timer:close()
        if req and not req:is_closing() then
            req:shutdown()
            req:close()
        end
    end

    local function parse_response()
        -- If headers are present, strip them once
        local header_end = response_data:find("\r\n\r\n")
        local body_part = header_end and response_data:sub(header_end + 4) or response_data

        -- DEBUG: 
        -- vim.fn.writefile({ body_part }, "/tmp/localnest_http_body.json")

        -- Use vim.json.decode, not vim.fn.json_decode
        local ok, decoded = pcall(vim.json.decode, body_part)
        if ok and type(decoded) == "table" then
            return decoded
        end

        return nil
    end

    local function on_error(err)
        cleanup()
        safe_callback(err, nil)
    end

    local function on_read(err, data)
        if err then
            on_error(err)
            return
        end

        if data then
            response_data = response_data .. data
        else
            -- EOF
            timer:stop()
            cleanup()
            local parsed = parse_response()
            if parsed then
                safe_callback(nil, parsed)
            else
                safe_callback("Failed to parse response", nil)
            end
        end
    end

    local function on_connect(err)
        if err then
            on_error(err)
            return
        end

        req:write(http_request, function(werr)
            if werr then
                on_error(werr)
                return
            end
            req:read_start(on_read)
        end)
    end

    -- Timeout
    timer:start(timeout, 0, function()
        on_error("Request timeout")
    end)

    -- Resolve DNS and connect
    uv.getaddrinfo(host, port, { family = "inet" }, function(err, res)
        if err then
            on_error(err)
            return
        end

        if not res or #res == 0 then
            on_error("DNS resolution failed")
            return
        end

        local addr = res[1]
        req:connect(addr.addr, addr.port, on_connect)
    end)
end

return M
