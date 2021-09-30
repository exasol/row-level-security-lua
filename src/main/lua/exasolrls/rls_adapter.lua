local metadata_reader = require("exasolrls.metadata_reader")
local query_rewriter = require("exasolrls.query_rewriter")
local text = require("text")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local props = require("exasolrls.adapter_properties")

local M = {
    VERSION = "1.0.0",
    NAME = "Row-level Security adapter (LUA)",
}

local function get_adapter_properties(request)
    return props.create(request.schemaMetadataInfo.properties):validate()
end

local function handle_schema_scanning_request(request)
    local properties = get_adapter_properties(request)
    return metadata_reader.read(properties:get_schema_name(), properties:get_table_filter())
end


---
-- Create a virtual schema.
--
-- @param _ Exasol metadata (not used)
--
-- @param request virtual schema request
--
-- @return response containing the metadata for the virtual schema like table and column structure
--
function M.create_virtual_schema(_, request)
    return {type = "createVirtualSchema", schemaMetadata = handle_schema_scanning_request(request)}
end

---
-- Drop the virtual schema
--
-- @param _ Exasol metadata (not used)
--
-- @param request virtual schema request (not used)
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
-- @param _ Exasol metadata (not used)
--
-- @param request virtual schema request
--
-- @return response containing the metadata for the virtual schema like table and column structure
--
function M.refresh(_, request)
    return {type = "refresh", schemaMetadata = handle_schema_scanning_request(request)}
end

---
-- Alter the schema properties
--
function M.set_properties()
    -- Not implemented yet:
    -- https://github.com/exasol/row-level-security-lua/issues/89
    return {type ="setProperties"}
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
-- @param _ Exasol metadata (not used)
--
-- @param request virtual schema request
--
-- @return response containing the list of reported capabilities
--
function M.get_capabilities(_, request)
    local excluded_capabilities_property_value = (((request or {}).schemaMetadataInfo or {}).properties or {})
        .EXCLUDED_CAPABILITIES
    if excluded_capabilities_property_value == nil then
        return {type = "getCapabilities", capabilities = adapter_capabilities}
    else
        local excluded_capabilities = text.split(excluded_capabilities_property_value)
        return {
            type = "getCapabilities",
            capabilities = subtract_capabilities(adapter_capabilities, excluded_capabilities)
        }
    end
end

---
-- Rewrite a pushed down query.
--
-- @param _ Exasol metadata (not used)
--
-- @param request virtual schema request
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
