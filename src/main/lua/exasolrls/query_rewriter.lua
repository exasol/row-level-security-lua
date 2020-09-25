local renderer = require("exasolvs.query_renderer")
local protection_reader = require("exasolrls.table_protection_reader")
local user = require("exasolrls.user_information")
local log = require("remotelog")

local M  = {}

local function validate(query)
    if not query then
        error("E-RLS-QRW-1: Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        error('E-RLS-QRW-2: Unable to rewrite push-down request of type "' .. push_down_type
                .. '". Only SELECT is supported.')
    end
end

local function construct_tenant_protection_filter(table_id)
    return {
        type = "predicate_equal",
        left = {type = "column", tableName = table_id, name = "EXA_ROW_TENANT"},
        right = {type = "function_scalar", name = "CURRENT_USER"}
    }
end

local function construct_group_protection_filter(source_schema_id, table_id)
    local groups = user.get_groups(source_schema_id)
    local group_literals = {}
    for i = 1, #groups do
        group_literals[i] = {type = "literal_string", value = groups[i]}
    end
    return {
        type = "predicate_in_constlist",
        expression = {type = "column", tableName = table_id, name = "EXA_ROW_GROUP"},
        arguments = group_literals
    }
end

local function construct_role_protection_filter(source_schema_id, table_id)
    local role_mask = user.get_role_mask(source_schema_id)
    return {
        type = "predicate_notequal",
        left = {
            type = "function_scalar",
            name = "BIT_AND",
            arguments = {
                {type = "column", tableName = table_id, name = "EXA_ROW_ROLES"},
                {type = "literal_exactnumeric", value = role_mask}
            }
         },
         right = {type = "literal_exactnumeric", value = 0}
    }
end

local function construct_or(...)
    return {
        type = "predicate_or",
        expressions = {...}
    }
end

local function construct_protection_filter(source_schema_id, table_id, protection)
    if protection.tenant_protected  then
        if protection.group_protected then
            log.debug('Table "%s"."%s" is tenant-protected and group-protected. Adding filter for user or a group.',
                source_schema_id, table_id)
            return construct_or(construct_tenant_protection_filter(table_id),
                construct_group_protection_filter(source_schema_id, table_id))
        elseif protection.role_protected then
            log.debug('Table "%s"."%s" is tenant-protected and role-protected. Adding filter for user or role.',
                source_schema_id, table_id)
            return construct_or(construct_tenant_protection_filter(table_id),
                construct_role_protection_filter(source_schema_id, table_id))
        else
            log.debug('Table "%s"."%s" is tenant-protected. Adding tenant as row filter.', source_schema_id, table_id)
            return construct_tenant_protection_filter(table_id)
        end
    elseif protection.group_protected then
        log.debug('Table "%s"."%s" is group-protected. Adding group as row filter.', source_schema_id, table_id)
        return construct_group_protection_filter(source_schema_id, table_id)
    elseif protection.role_protected then
        log.debug('Table "%s"."%s" is role-protected. Adding role mask as row filter.', source_schema_id, table_id)
        return construct_role_protection_filter(source_schema_id, table_id)
    else
        error("E-RLS-QRW-3: Illegal protection scheme used. Allowed schemes are: tenant, group, tenant + group")
    end
end

local function rewrite_with_protection(query, source_schema_id, table_id, protection)
    local protection_filter = construct_protection_filter(source_schema_id, table_id, protection)
    local original_filter = query.filter
    if original_filter then
        query.filter = {type = "predicate_and", expressions = {protection_filter, original_filter}}
    else
        query.filter = protection_filter
    end
end

---
-- Rewrite the original query with RLS restrictions.
--
-- @param original_query structure containing the original push-down query
--
-- @param source_schema_id source schema RLS is put on top of
--
-- @param adapter_cache cache taken from the adapter notes
--
-- @return string containing the rewritten query
--
function M.rewrite(original_query, source_schema_id, adapter_cache)
    validate(original_query)
    local query = original_query
    local table_id = query.from.name
    query.from.schema = source_schema_id
    local protection = protection_reader.read(adapter_cache, table_id)
    if protection.protected then
        rewrite_with_protection(query, source_schema_id, table_id, protection)
    else
        log.debug('Table "%s" is not protected. No filters added.', table_id)
    end
    return renderer.new(query).render()
end

return M