local AbstractVirtualSchemaAdapter = require("exasolvs.AbstractVirtualSchemaAdapter")
local AdapterProperties = require("exasolrls.AdapterProperties")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local QueryRewriter = require("exasolrls.QueryRewriter")

-- Derive from AbstractVirtualSchemaAdapter
local RlsAdapter = AbstractVirtualSchemaAdapter:new()
local VERSION <const> = "1.1.0"

--- Create an <code>RlsAdapter</code>
--
-- @param metadata_reader metadata reader
--
function RlsAdapter.create(metadata_reader)
    return RlsAdapter:new({metadata_reader = metadata_reader})
end

--- Create an <code>RlsAdapter</code>.
--
-- @param object to initialize the adapter with
--
-- @return RlsAdapter
--
function RlsAdapter:new(object)
    object = object or {}
    self.__index = self
    setmetatable(object, self)
    return object
end

--- Get the version number of the Virtual Schema adapter.
--
-- @return Virtual Schema adapter version
--
function RlsAdapter:get_version()
    return VERSION
end

--- Get the name of the Virtual Schema adapter.
--
-- @return Virtual Schema adapter name
--
function RlsAdapter:get_name()
    return "Row-level Security adapter (LUA)"
end

function RlsAdapter:_get_adapter_properties(request)
    local properties = AdapterProperties:new(request.schemaMetadataInfo.properties)
    properties:validate()
    return properties
end

function RlsAdapter:_handle_schema_scanning_request(request)
    local properties = self:_get_adapter_properties(request)
    local schema_name = properties:get_schema_name()
    local table_filter = properties:get_table_filter()
    return self.metadata_reader:read(schema_name, table_filter)
end

--- Create a virtual schema.
--
-- @param request virtual schema request
--
-- @return response containing the metadata for the virtual schema like table and column structure
--
function RlsAdapter:create_virtual_schema(request)
    local metadata = self:_handle_schema_scanning_request(request)
    return {type = "createVirtualSchema", schemaMetadata = metadata}
end

--- Refresh the metadata of the Virtual Schema.
-- <p>
-- Re-reads the structure and data types of the schema protected by RLS.
-- </p>
-- @param request virtual schema request
-- @return response containing the metadata for the virtual schema like table and column structure
function RlsAdapter:refresh(request)
    return {type = "refresh", schemaMetadata = self:_handle_schema_scanning_request(request)}
end

--- Alter the schema properties.
-- @param request virtual schema request
-- @return response containing the metadata for the virtual schema like table and column structure
function RlsAdapter:set_properties(request)
    return {type = "setProperties", schemaMetadata = self:_handle_schema_scanning_request(request)}
end

--- Rewrite a pushed down query.
-- @param request virtual schema request
-- @return response containing the list of reported capabilities
function RlsAdapter:push_down(request)
    local properties = request.schemaMetadataInfo.properties
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local rewritten_query = QueryRewriter.rewrite(request.pushdownRequest, properties.SCHEMA_NAME,
            adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

function RlsAdapter:_define_capabilities()
    return adapter_capabilities
end

return RlsAdapter