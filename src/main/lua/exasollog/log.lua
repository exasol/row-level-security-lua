local levels = {NONE = 1, FATAL = 2, ERROR = 3, WARN = 4, INFO = 5, CONFIG = 6, DEBUG = 7, TRACE = 8}

---
-- This module implements a remote log client with the ability to fall back to console logging in case no connection
-- to a remote log receiver is established.
-- <p>
-- You can optionally use a high resolution timer for performance monitoring. Since Lua's <code>os.date()</code>
-- function only has a resolution of seconds, that timer uses <code>socket.gettime()</code>. Note that the values
-- you are getting are not the milliseconds of a second, but the milliseconds counted from when the module was first
-- loaded &mdash; which is typically at the very beginning of the software using this module.
-- </p><p>
-- Use the <code>init()</code> method to set some global parameters for this module.
-- </p>
--
local M = {
    level = levels.INFO,
    socket_client = nil,
    connection_timeout = 0.1, -- seconds
    log_client_name = nil,
    timestamp_pattern = "%Y-%m-%d %H:%M:%S",
    start_nanos = 0,
    use_high_resolution_time = true,
}

local socket = require("socket")

---
-- Initialize the log module
-- <p>
-- This method allows you to set parameters that apply to all subsequent calls to logging methods. While it is possible
-- to change these settings at runtime, the recommended way is to do this once only, before you use the log for the
-- first time.
-- </p>
-- <p>
-- You can use a high resolution timer. Note that these are <p>not</p> the sub-second units of the timestamp! Lua
-- timestamps only offer second resolution. Rather you get a time difference in milliseconds counted from the first time
-- the log is opened.
--
-- @param timestamp_pattern layout of timestamps displayed in the logs
--
-- @param use_high_resolution_time switch high resolution time display on or off
--
-- @return module loader
--
function M.init(timestamp_pattern, use_high_resolution_time)
    M.timestamp_pattern = timestamp_pattern
    if use_high_resolution_time ~= nil then
        M.use_high_resolution_time = use_high_resolution_time
    end
    return M
end

---
-- Set the log client name.
-- <p>
-- This is the name presented when the log is first opened. We recommend using the name of the application or script
-- that uses the log and a version number.
-- </p>
--
function M.set_client_name(log_client_name)
    M.log_client_name = log_client_name
end

local function start_high_resolution_timer()
    if M.use_high_resolution_time then
        M.start_nanos = socket.gettime()
    end
end

local function get_level_name(level)
    for k, v in pairs(levels) do
        if v == level then
            return k
        end
    end
    error("E-LOG-1: Unable to determine log level name for level number " .. level .. ".")
end

---
-- Open a connection to a remote log receiver.
-- <p>
-- This method allows connecting the log to an external process listening on a TCP port. The process can be on a remote
-- host. If the connection cannot be established, the logger falls back to console logging.
-- </p>
--
-- @param host remote host on which the logging process runs
--
-- @param port TCP port on which the logging process listens
--
function M.connect(host, port)
    local tcp_socket = socket.tcp()
    tcp_socket:settimeout(M.connection_timeout)
    local ok, err = tcp_socket:connect(host, port)
    local log_client_prefix = M.log_client_name and (M.log_client_name .. ": ") or ""
    if ok then
        M.socket_client = tcp_socket
        M.info("%sConnected to log receiver listening on %s:%d with log level %s. Timezone is UTC%s.", log_client_prefix, host, port,
            get_level_name(M.level), os.date("%z"))
    else
        print(log_client_prefix .. "W-LOG-2: Unable to open socket connection to " .. host .. ":" .. port
            .. "for sending log messages. Falling back to console logging with log level " .. get_level_name(M.level)
            .. ". Timezone is UTC" .. os.date("%z") .. ". Caused by: " .. err)
    end
end

---
-- Close the connection to the remote log receiver.
--
function M.disconnect()
    if(M.socket_client) then
        M.socket_client:close()
    end
end

---
-- Set the log level.
--
-- @param level_name name of the log level, one of: FATAL, ERROR, WARN, INFO, CONFIG, DEBUG, TRACE
--
function M.set_level(level_name)
    local level = levels[level_name]
    if level == nil then
        M.warning('W-LOG-1: Attempt to set illegal log level "' .. level_name
            .. ' Pick one of: NONE, FATAL, ERROR, WARN, INFO, CONFIG, DEBUG, TRACE. Falling back to level INFO.')
        M.level = levels.INFO
    else
        M.level = level
    end
end

---
-- Write to a socket, print or discard the message.
-- <p>
-- If a socket connection is established, this method writes to that socket. Otherwise if the global print function
-- exists (e.g. in a unit test) falls back to logging via <code>print()</code>.
-- </p><p>
-- Exasol removed print() in it's Lua implementation, so there is no fallback on a real Exasol instance. You either use
-- remote logging or messages are discarded immediately.
-- </p>
--
-- @param level log level
--
-- @param message log message; otherwise used as format string if any variadic parameters follow
--
-- @param ... parameters to be inserted into formatted message (optional)
--
local function write(level, message, ...)
    if not M.socket_client and print then
        return
    else
        local entry
        local formatted_message = (select('#', ...) > 0) and string.format(message, ...) or message
        if M.use_high_resolution_time then
            local current_millis = string.format("%07.3f", (socket.gettime() - M.start_nanos) * 1000)
            entry = {
                os.date(M.timestamp_pattern),
                " (", current_millis, "ms) [", level , "]",
                string.rep(" ", 7 - string.len(level)), formatted_message
            }
        else
            entry = {
                os.date(M.timestamp_pattern),
                " [", level , "]",
                string.rep(" ", 7 - string.len(level)), formatted_message
            }
        end
        if M.socket_client then
            entry[#entry + 1] = "\n"
            M.socket_client:send(table.concat(entry))
        else
            if(print) then
                print(table.concat(entry))
            end
        end
    end
end

function M.fatal(...)
    if M.level >= levels.FATAL then
        write("FATAL", ...)
    end
end

function M.error(...)
    if M.level >= levels.ERROR then
        write("ERROR", ...)
    end
end

function M.warn(...)
    if M.level >= levels.WARN then
        write("WARN", ...)
    end
end

function M.info(...)
    if M.level >= levels.INFO then
        write("INFO", ...)
    end
end

function M.config(...)
    if M.level >= levels.CONFIG then
        write("CONFIG", ...)
    end
end

function M.debug(...)
    if M.level >= levels.DEBUG then
        write("DEBUG", ...)
    end
end

function M.trace(...)
    if M.level >= levels.FATAL then
        write("TRACE", ...)
    end
end

start_high_resolution_timer()
return M
