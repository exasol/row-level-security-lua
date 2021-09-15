local metadata_reader = require("exasolrls.metadata_reader")
local query_rewriter = require("exasolrls.query_rewriter")
local text = require("text")

local M = {
    VERSION = "0.5.0",
    NAME = "Row-level Security adapter (LUA)",
    CAPABILITIES = {"SELECTLIST_PROJECTION", "AGGREGATE_SINGLE_GROUP", "AGGREGATE_GROUP_BY_COLUMN",
        "AGGREGATE_GROUP_BY_TUPLE", "AGGREGATE_HAVING", "ORDER_BY_COLUMN", "LIMIT", "LIMIT_WITH_OFFSET"}
}

local function is_schema_name_property_present(properties)
    local schema_id = properties.SCHEMA_NAME
    return schema_id and (schema_id ~= "")
end

local function validate(properties)
    if not is_schema_name_property_present(properties) then
        error('F-LRLS-ADA-1: Missing mandatory property "SCHEMA_NAME". Please define the name of the source schema.');
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
    local properties = request.schemaMetadataInfo.properties or {}
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

---
-- Refresh the metadata of the Virtual Schema.
-- <p>
-- Re-reads the structure and data types of the schema protected by RLS.
-- </p>
--
-- @param exa_metadata Exasol metadata (not used)
--
-- @param request      virtual schema request
--
-- @return response containing the metadata for the virtual schema like table and column structure
--
function M.refresh(_, request)
    local properties = request.schemaMetadataInfo.properties or {}
    validate(properties)
    local schema_metadata = metadata_reader.read(properties.SCHEMA_NAME)
    return {type = "refresh", schemaMetadata = schema_metadata}
end

function M.set_properties()
end

local function subtract_capabilities(original_capabilities, excluded_capabilities)
    local filtered_capabilities = {}
    for _, capability in ipairs(original_capabilities) do
        local is_excluded = false
        for _, excluded_capability in ipairs(excluded_capabilities) do
            if excluded_capability == capability then
                is_excluded = true
            end
        end
        if not is_excluded then
            table.insert(filtered_capabilities, capability)
        end
    end
    return filtered_capabilities
end

---
-- Report the capabilities of the Virtual Schema adapter
--
--
-- @param exa_metadata Exasol metadata (not used)
--
-- @param request      virtual schema request
--
-- @return response containing the list of reported capabilities
--
function M.get_capabilities(_, request)
    local excluded_capabilities_property_value = (((request or {}).schemaMetadataInfo or {}).properties or {})
        .EXCLUDED_CAPABILITIES
    if excluded_capabilities_property_value == nil then
        return {type = "getCapabilities", capabilities = M.CAPABILITIES}
    else
        local excluded_capabilities = text.split(excluded_capabilities_property_value)
        return {type = "getCapabilities", capabilities = subtract_capabilities(M.CAPABILITIES, excluded_capabilities)}
    end
end

---
-- Rewrite a pushed down query.
--
-- @param exa_metadata Exasol metadata (not used)
--
-- @param request      virtual schema request
--
-- @return response containing the list of reported capabilities
--
function M.push_down(_, request)
    local properties = request.schemaMetadataInfo.properties
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local rewritten_query =
        query_rewriter.rewrite(request.pushdownRequest, properties.SCHEMA_NAME, adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

return M
