local metadata_reader = require("exasolrls.metadata_reader")
local query_rewriter = require("exasolrls.query_rewriter")

local M = {VERSION = "0.4.0", NAME = "Row-level Security adapter (LUA)"}

local function validate(properties)
    local schema_id = properties.SCHEMA_NAME
    if not schema_id or (schema_id == "") then
        error('F-LRLS-ADA-1: Missing mandatory property "SCHEMA_NAME". '
        .. 'Please define the name of the source schema with this property.');
    end
end

---
-- Create a virtual schema.
--
-- @param exa_metadata Exasol metadata (not used)
--
-- @param request      virtual schema request
--
-- @return response containing the metadata for the virtual schema like table and column structure
--
function M.create_virtual_schema(_, request)
    local properties = request.schemaMetadataInfo.properties
    validate(properties)
    local schema_metadata = metadata_reader.read(properties.SCHEMA_NAME)
    return {type = "createVirtualSchema", schemaMetadata = schema_metadata}
end

---
-- Drop the virtual schema
--
-- @param exa_metadata Exasol metadata (not used)
--
-- @param request      virtual schema request (not used)
--
-- @return response confirming the request (otherwise empty)
--
function M.drop_virtual_schema()
    return {type = "dropVirtualSchema"}
end

function M.refresh()
end

function M.set_properties()
end

function M.get_capabilities()
    return {type = "getCapabilities",
        capabilities = {"SELECTLIST_PROJECTION", "AGGREGATE_SINGLE_GROUP", "AGGREGATE_GROUP_BY_COLUMN",
            "AGGREGATE_GROUP_BY_TUPLE", "AGGREGATE_HAVING", "ORDER_BY_COLUMN", "LIMIT",
            "LIMIT_WITH_OFFSET"}}
end

function M.push_down(_, request)
    local properties = request.schemaMetadataInfo.properties
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local rewritten_query =
        query_rewriter.rewrite(request.pushdownRequest, properties.SCHEMA_NAME, adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

return M
