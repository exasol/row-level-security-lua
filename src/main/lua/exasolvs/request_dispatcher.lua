cjson = require("cjson")
adapter = require("exasolrls.adapter", "adapter")

function adapter_call(request)
    local request = cjson.decode(request)
    local handlers = { pushdown = adapter.push_down,
            createVirtualSchema = adapter.create_virtual_schema,
            dropVirtualSchema = adapter.drop_virtual_schema,
            refresh = adapter.refresh,
            getCapabilities = adapter.get_capabilities,
            setProperties = adapter.set_properties}
    local handler = handlers[request.type]
    if(handler ~= nil) then
        return cjson.encode(handler(nil, request))
    else
        error("F-RQD-1: Unknown Virtual Schema request type received: " .. request.type)
    end
end