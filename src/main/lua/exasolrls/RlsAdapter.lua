local AbstractVirtualSchemaAdapter = require("exasolvs.AbstractVirtualSchemaAdapter")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local QueryRewriter = require("exasolrls.QueryRewriter")

-- Derive from AbstractVirtualSchemaAdapter
local RlsAdapter = {}
RlsAdapter.__index = RlsAdapter
setmetatable(RlsAdapter, {__index = AbstractVirtualSchemaAdapter})
local VERSION <const> = "1.2.0"

--- Create an `RlsAdapter`.
-- @param metadata_reader metadata reader
-- @return RlsAdapter
function RlsAdapter:new(metadata_reader)
    local instance = setmetatable({}, self)
    instance:_init(metadata_reader)
    return instance
end

function RlsAdapter:_init(metadata_reader)
    AbstractVirtualSchemaAdapter._init(self)
    self._metadata_reader = metadata_reader
end

--- Get the version number of the Virtual Schema adapter.
-- @return Virtual Schema adapter version
function RlsAdapter:get_version()
    return VERSION
end

--- Get the name of the Virtual Schema adapter.
-- @return Virtual Schema adapter name
function RlsAdapter:get_name()
    return "Row-level Security adapter (Lua)"
end

--- Create a virtual schema.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function RlsAdapter:create_virtual_schema(request, properties)
    properties:validate()
    local metadata = self:_handle_schema_scanning_request(request, properties)
    return {type = "createVirtualSchema", schemaMetadata = metadata}
end

function RlsAdapter:_handle_schema_scanning_request(request, properties)
    local schema_name = properties:get_schema_name()
    local table_filter = properties:get_table_filter()
    return self._metadata_reader:read(schema_name, table_filter)
end

--- Refresh the metadata of the Virtual Schema.
-- <p>
-- Re-reads the structure and data types of the schema protected by RLS.
-- </p>
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function RlsAdapter:refresh(request, properties)
    properties:validate()
    return {type = "refresh", schemaMetadata = self:_handle_schema_scanning_request(request, properties)}
end

--- Alter the schema properties.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function RlsAdapter:set_properties(request, properties)
    properties:validate()
    return {type = "setProperties", schemaMetadata = self:_handle_schema_scanning_request(request, properties)}
end

--- Rewrite a pushed down query.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the list of reported capabilities
function RlsAdapter:push_down(request, properties)
    properties:validate()
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local rewritten_query = QueryRewriter.rewrite(request.pushdownRequest, properties:get_schema_name(),
            adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

function RlsAdapter:_define_capabilities()
    return adapter_capabilities
end

return RlsAdapter