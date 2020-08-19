local M = {
    client = nil,
    timestamp_pattern = "%Y-%m-%d %H:%M:%S",
    start_nanos = 0,
    use_high_resolution_time = true
}

local socket = require("socket")

function M.init(timestamp_pattern, use_high_resolution_time)
    M.timestamp_pattern = timestamp_pattern
    if (use_high_resolution_time ~= nil) then
        M.use_high_resolution_time = use_high_resolution_time
    end
    return M
end

function M.open(host, port)
    if(M.use_high_resolution_time) then
        M.start_nanos = socket.gettime()
    end
    host = host or "127.0.0.1"
    port = port or 3000
    local client, err = socket.connect(host, port)
    if(not client) then
        print("Unable to open log socket to " .. host .. ":" .. port .. ". Falling back to console logging.")
    else
        M.client = client
        M.debug("Connected to log receiver listening on " .. host .. ":" .. port .. ".")
    end
end

local function write(level, message)
    local entry
    if(M.use_high_resolution_time) then
        local current_millis = string.format("%3.3f", (socket.gettime() - M.start_nanos) * 1000)
        entry = {
            os.date(M.timestamp_pattern),
            " (", current_millis, "ms) [", level , "]",
            string.rep(" ", 7 - string.len(level)), message
        }
    else
        entry = {
            os.date(M.timestamp_pattern),
            " [", level , "]",
            string.rep(" ", 7 - string.len(level)), message
        }
    end
    if(M.client) then
        entry[#entry + 1] = "\n"
        M.client:send(table.concat(entry))
    else
        print(table.concat(entry))
    end
end

function M.fatal(message)
    write("FATAL", message)
end

function M.error(message)
    write("ERROR", message)
end

function M.warn(message)
    write("WARN", message)
end

function M.info(message)
    write("INFO", message)
end

function M.config(message)
    write("CONFIG", message)
end

function M.debug(message)
    write("DEBUG", message)
end

function M.trace(message)
    write("TRACE", message)
end

function M.close()
    M.client.close()
end

return M
