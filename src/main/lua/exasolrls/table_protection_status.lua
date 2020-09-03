local log = require("exasollog.log")

local M = {}

local function determine_table_protection_from_cache(table_id, protection_cache)
    local protection = string.match(protection_cache, table_id .. ":([-rtg]+)")
    if not protection then
        error("F-RLS-TPS-2: Unable to find table \"" .. table_id
            .. "\" in protection status cache. Please check the table name and refresh the Virtual Schema.")
    end
    return protection ~= "---"
end

local function determine_table_protection_from_metadata(schema_id, table_id)
    local fully_qualified_table_id = '"' .. schema_id .. '"."'.. table_id .. '"'
    log.debug("Reading protection status of table %s.", fully_qualified_table_id)
    local ok, result = exa.pquery('DESCRIBE ' .. fully_qualified_table_id)
    if ok then
        for i = 1, #result do
            local column_name = result[i].COLUMN_NAME
            if column_name == "EXA_ROW_TENANT" then
                return true
            end
        end
        return false
    else
        error('F-RLS-TPS-1: Unable to determine protection status of table "' .. table
            .. "'. Metadata could not be read. Caused by: " + result.error_msg)
    end
end

---
-- Check whether a table is protected by RLS or not.
--
-- @param schema_id name of the schema the table belongs to
-- 
-- @param table_id name of the table for which to check the protection status
-- 
-- @param adapter_cache if present, used as cached source for determining the protection status of tables
--
-- @return <code>true</code> if the table is protected.
--
function M.is_table_protected(schema_id, table_id, adapter_cache)
    if not adapter_cache then
        return determine_table_protection_from_metadata(schema_id, table_id)
    else
        return determine_table_protection_from_cache(table_id, adapter_cache)
    end
end


return M