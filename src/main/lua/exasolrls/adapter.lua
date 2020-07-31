metadata_reader=require("exasolrls.metadata_reader")

local M = {}

---
-- Create a virtual schema.
-- 
-- @param exa_metadata Exasol metadata
-- 
-- @param request      virtual schema request
-- 
-- @return response containing the metadata for the virtual schema like table and column structure
-- 
function M.create_virtual_schema(exa_metadata, request)
    local properties = request.schemaMetadataInfo.properties
    return {type = "createVirtualSchema", schemaMetadata = metadata_reader.read(properties.SCHEMA)}
end

---
-- Drop the virtual schema
--
-- @param exa_metadata Exasol metadata
-- 
-- @param request      virtual schema request
-- 
-- @return response confirming the request (otherwise empty)
-- 
function M.drop_virtual_schema(exa_metadata, request)
    return {type = "dropVirtualSchema"}
end

function M.refresh(exa_metadata, request)
end

function M.set_properties(exa_metadata, request)
end

function M.get_capabilities(exa_metadata, request)
    return {type = "getCapabilities",
            capabilities = {"SELECTLIST_PROJECTION", "AGGREGATE_SINGLE_GROUP", "AGGREGATE_GROUP_BY_COLUMN",
                        "AGGREGATE_GROUP_BY_TUPLE", "AGGREGATE_HAVING", "ORDER_BY_COLUMN", "LIMIT",
                        "LIMIT_WITH_OFFSET"}}
end

function M.push_down(exa_metadata, request)
end

return M