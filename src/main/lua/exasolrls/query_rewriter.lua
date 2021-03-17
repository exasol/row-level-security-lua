local renderer = require("exasolvs.query_renderer")
local protection_reader = require("exasolrls.table_protection_reader")
local user = require("exasolrls.user_information")
local log = require("remotelog")

local M  = { PUBLIC_ROLE_BIT_INDEX = 63 }

local function validate(query)
    if not query then
        error("E-LRLS-QRW-1: Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        error('E-LRLS-QRW-2: Unable to rewrite push-down request of type "' .. push_down_type
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

local function construct_single_group_protection_filter(table_id, group)
    return {
        type = "predicate_equal",
        left = {type = "column", tableName = table_id, name = "EXA_ROW_GROUP"},
        right = {type = "literal_string", value = group}
    }
end

local function construct_multi_group_protection_filter(table_id, groups)
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

local function construct_group_protection_filter(source_schema_id, table_id)
    local groups = user.get_groups(source_schema_id)
    if #groups == 1 then
        return construct_single_group_protection_filter(table_id, groups[1])
    else
        return construct_multi_group_protection_filter(table_id, groups)
    end
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
                {
                    type = "function_scalar",
                    name = "BIT_SET",
                    arguments = {
                        {type = "literal_exactnumeric", value = role_mask},
                        {type = "literal_exactnumeric", value = M.PUBLIC_ROLE_BIT_INDEX}
                    }
                }
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
        error("E-LRLS-QRW-3: Illegal protection scheme used. Allowed schemes are: tenant, group, tenant + group")
    end
end

local function is_select_star (select_list)
    return select_list == nil
end

local function is_empty_select_list(select_list)
    return next(select_list) == nil
end

local function replace_empty_select_list_with_constant_expression(query)
    log.debug('Empty select list pushed down. Replacing with constant expression to get correct number of rows.')
    query.selectList = {{type = "literal_bool", value = "true"}}
end

local function define_column(table_name, column_name, index)
    return {
        type = "column",
        name = column_name,
        columnNr = index,
        tableName = table_name
    }
end

local function replace_star_with_payload_columns(query, involved_tables)
    local select_list = {}
    local index = 1
    for _, involved_table in ipairs(involved_tables) do
        for _, column in ipairs(involved_table.columns) do
            select_list[index] = define_column(involved_table.name, column.name, index)
            index = index + 1
        end
    end
    query.selectList = select_list
end

local function expand_protected_select_list(query, involved_tables)
    if is_select_star(query.selectList) then
        log.debug('Expanding missing select list in push-down request to list of all payload columns.')
        replace_star_with_payload_columns(query, involved_tables)
    elseif is_empty_select_list(query.selectList) then
        replace_empty_select_list_with_constant_expression(query)
    end
end

local function rewrite_with_protection(query, source_schema_id, table_id, protection, involved_tables)
    expand_protected_select_list(query, involved_tables)
    local protection_filter = construct_protection_filter(source_schema_id, table_id, protection)
    local original_filter = query.filter
    if original_filter then
        query.filter = {type = "predicate_and", expressions = {protection_filter, original_filter}}
    else
        query.filter = protection_filter
    end
end

local function expand_select_list_without_protection(query)
    if is_select_star(query.selectList) then
        log.debug('Missing select list interpreted as: SELECT *')
    elseif is_empty_select_list(query.selectList) then
        replace_empty_select_list_with_constant_expression(query)
    end
end

local function rewrite_without_protection(query)
    expand_select_list_without_protection(query)
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
-- @param involved_tables list of tables that appear in the query
--
-- @return string containing the rewritten query
--
function M.rewrite(original_query, source_schema_id, adapter_cache, involved_tables)
    validate(original_query)
    local query = original_query
    local table_id = query.from.name
    query.from.schema = source_schema_id
    local protection = protection_reader.read(adapter_cache, table_id)
    if protection.protected then
        rewrite_with_protection(query, source_schema_id, table_id, protection, involved_tables)
    else
        rewrite_without_protection(query)
        log.debug('Table "%s" is not protected. No filters added.', table_id)
    end
    return renderer.new(query).render()
end

return M
