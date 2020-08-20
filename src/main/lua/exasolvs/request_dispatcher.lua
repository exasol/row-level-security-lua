local log = require("exasollog.log")
local cjson = require("cjson")
local adapter = require("exasolrls.adapter", "adapter")

local function handle_request(request)
    local handlers = {
        pushdown =  adapter.push_down,
        createVirtualSchema = adapter.create_virtual_schema,
        dropVirtualSchema = adapter.drop_virtual_schema,
        refresh = adapter.refresh,
        getCapabilities = adapter.get_capabilities,
        setProperties = adapter.set_properties
    }
    log.info('Received "%s" request.', request.type)
    local handler = handlers[request.type]
    if(handler ~= nil) then
        local response = cjson.encode(handler(nil, request))
        log.debug("Response:\n" .. response)
        return response
    else
        error('F-RQD-1: Unknown Virtual Schema request type "%s" received.', request.type)
    end
end

local function log_error(message)
    local error_type = string.sub(message, 1, 2)
    if(error_type == "F-") then
        log.fatal(message)
    else
        log.error(message)
    end
end

---
-- RLS adapter entry point.
-- <p>
-- This global function receives the request from the Exasol core database.
-- </p>
--
function adapter_call(request_as_json)
    log.set_client_name(adapter.NAME .. " " .. adapter.VERSION)
    local request = cjson.decode(request_as_json)
    local properties = (request.schemaMetadataInfo or {}).properties or {}
    local log_level = properties.LOG_LEVEL
    if(log_level) then
        log.set_level(string.upper(log_level))
    end
    local debug_address = properties.DEBUG_ADDRESS
    if(debug_address) then
        local colon_position = string.find(debug_address,":", 1, true)
        local host = string.sub(debug_address, 1, colon_position - 1)
        local port = string.sub(debug_address, colon_position + 1)
        log.connect(host, port)
    end
    log.debug("Raw request:\n%s", request_as_json)
    local ok, result = pcall(function () return handle_request(request) end)
    if(ok) then
        log.disconnect()
        return result
    else
        log_error(result)
        log.disconnect()
        error(result)
    end
end
