--- Main entry point of the Lua Virtual Schema adapter.
-- It is responsible for creating and wiring up the main adapter objects.

local RlsAdapter = require("exasolrls.RlsAdapter")
local RlsAdapterProperties = require("exasolrls.RlsAdapterProperties")
local MetadataReader = require("exasolrls.MetadataReader")
local RequestDispatcher = require("exasolvs.RequestDispatcher")

--- Handle a Virtual Schema request.
-- @param request_as_json JSON-encoded adapter request
-- @return JSON-encoded adapter response
function adapter_call(request_as_json)
    local exasol_context = _G.exa
    local metadata_reader = MetadataReader:new(exasol_context)
    local adapter = RlsAdapter:new(metadata_reader)
    local dispatcher = RequestDispatcher:new(adapter, RlsAdapterProperties)
    return dispatcher:adapter_call(request_as_json)
end
