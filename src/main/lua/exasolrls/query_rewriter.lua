local renderer = require("exasolvs.query_renderer")
local protection = require("exasolrls.table_protection_status")
local log = require("exasollog.log")

local M  = {}

local function validate(query)
    if(query == nil) then
        error("E-RLS-QRW-1: Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        error('E-RLS-QRW-2: Unable to rewrite push-down request of type "' .. push_down_type
                .. '". Only SELECT is supported.')
    end
end

---
-- Rewrite the original query with RLS restrictions.
-- 
-- @param original_query structure containing the original push-down query
-- 
-- @param sourceSchema source schema RLS is put on top of
-- 
-- @param adapter_cache cache taken from the adapter notes
-- 
-- @return string containing the rewritten query
-- 
function M.rewrite(original_query, source_schema, adapter_cache)
    validate(original_query)
    local query = original_query
    local table = query.from.name
    query.from.schema = source_schema
    if(protection.is_table_protected(source_schema, table, adapter_cache)) then
        log.debug('Table "' .. table .. "' is RLS-protected. Adding row filters.")
        local protection_filter = {
            type = "predicate_equal",
            left = {type = "column", tableName = table, name = "EXA_ROW_TENANT"},
            right = {type = "function_scalar", name = "CURRENT_USER"}
        }
        local original_filter = query.filter
        if(original_filter) then
            query.filter =  {type = "predicate_and", expressions = {protection_filter, original_filter}}
        else
            query.filter = protection_filter
        end
    else
        log.debug('Table "' .. table .. "' is not protected. No filters added.")
    end
    return renderer.new(query).render()
end

return M