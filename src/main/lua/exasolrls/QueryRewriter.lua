local QueryRenderer = require("exasolvs.QueryRenderer")
local protection_reader = require("exasolrls.TableProtectionReader")
local log = require("remotelog")
local exaerror = require("exaerror")

--- This class rewrites the query, adding RLS protection if necessary.
-- @classmod QueryRewriter
local QueryRewriter = {}

local function validate(query)
    if not query then
        exaerror.error("E-RLSL-QRW-1", "Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        exaerror.error("E-RLSL-QRW-2", "Unable to rewrite push-down query of type {{query_type}}"
            .. ". Only 'select' is supported.", {query_type =  push_down_type})
    end
end

local function _numeric(value)
    return {type = "literal_exactnumeric", value = value}
end

local function _or(...)
    return {type = "predicate_or", expressions = {...}}
end

local function _and(...)
    return {type = "predicate_and", expressions = {...}}
end

local function _bit_and(...)
    return {type = "function_scalar", name = "BIT_AND", arguments = {...}}
end

local function _bit_check(value, position)
    return {type = "function_scalar", name = "BIT_CHECK", arguments = {value, _numeric(position)}}
end

local function _column(table_id, column_id, index)
    return {type = "column", tableName = table_id, name = column_id, columnNr = index} -- index is optional
end

local function _table(schema_id, table_id)
    return {type = "table", schema = schema_id, name = table_id}
end

local function _equal(left, right)
    return {type = "predicate_equal", left = left, right = right}
end

local function _not_equal(left, right)
    return {type = "predicate_notequal", left = left, right = right}
end

local function _current_user()
    return {type = "function_scalar", name = "CURRENT_USER"}
end

local function _exists(sub_query)
    return {type = "predicate_exists", query = sub_query}
end

local function _user_owns_row(table_id)
    return _equal(_column(table_id, "EXA_ROW_TENANT"), _current_user())
end

local function _user_has_row_group(source_schema_id, table_id)
    return _exists(
        {
            type = "select",
            selectList = {
                _numeric(1)
            },
            from = _table(source_schema_id, "EXA_GROUP_MEMBERS"),
            filter = _and(
                _equal(_column("EXA_GROUP_MEMBERS", "EXA_GROUP"), _column(table_id, "EXA_ROW_GROUP")),
                _equal(_column("EXA_GROUP_MEMBERS", "EXA_USER_NAME"), _current_user())
            )
        }
    )
end

local function _row_has_public_role(table_id)
    return _bit_check(_column(table_id, "EXA_ROW_ROLES"), 63)
end

local function _user_has_row_role(source_schema_id, table_id)
    return _exists(
        {
            type = "select",
            selectList = {
                _numeric(1)
            },
            from = _table(source_schema_id, "EXA_RLS_USERS"),
            filter = _and(
                _equal(
                    _column("EXA_RLS_USERS", "EXA_USER_NAME"),
                    _current_user()
                ),
                _not_equal(
                    _bit_and(_column(table_id, "EXA_ROW_ROLES"), _column("EXA_RLS_USERS", "EXA_ROLE_MASK")),
                    _numeric(0)
                )
            )
        }
    )
end

local function describe_protection_scheme(protection)
    local scheme = {}
    if(protection.tenant_protected) then
        table.insert(scheme, "tenant")
    end
    if(protection.group_protected) then
        table.insert(scheme, "group")
    end
    if(protection.role_protected) then
        table.insert(scheme, "role")
    end
    return table.concat(scheme, " + ")
end

local function raise_protection_scheme_error(source_schema_id, table_id, protection)
    exaerror.create("E-LRLS-QRW-3",
        "Unsupported combination of protection methods on the same table {{schema}}.{{table}}: {{combination}}",
        {schema = source_schema_id, table = table_id, combination = describe_protection_scheme(protection)})
        :add_mitigations("Allowed protection variants are: tenant, group, role, tenant + group, tenant + role")
        :raise()
end

local function construct_protection_filter(source_schema_id, table_id, protection)
    if protection.tenant_protected  then
        if protection.group_protected then
            log.debug('Table "%s"."%s" is tenant-protected and group-protected. Adding filter for user or a group.',
                source_schema_id, table_id)
            return _or(_user_owns_row(table_id),
                _user_has_row_group(source_schema_id, table_id))
        elseif protection.role_protected then
            log.debug('Table "%s"."%s" is tenant-protected and role-protected. Adding filter for user or role.',
                source_schema_id, table_id)
            return _or(_user_owns_row(table_id), _row_has_public_role(table_id),
                _user_has_row_role(source_schema_id, table_id))
        else
            log.debug('Table "%s"."%s" is tenant-protected. Adding tenant as row filter.', source_schema_id, table_id)
            return _user_owns_row(table_id)
        end
    elseif protection.group_protected then
        log.debug('Table "%s"."%s" is group-protected. Joining groups as row filter.', source_schema_id, table_id)
        return _user_has_row_group(source_schema_id, table_id)
    elseif protection.role_protected then
        log.debug('Table "%s"."%s" is role-protected. Adding role mask as row filter.', source_schema_id, table_id)
        return _or(_row_has_public_role(table_id), _user_has_row_role(source_schema_id, table_id))
    else
        raise_protection_scheme_error(source_schema_id, table_id, protection)
    end
end

local function is_select_star(select_list)
    return select_list == nil
end

local function is_empty_select_list(select_list)
    return next(select_list) == nil
end

local function replace_empty_select_list_with_constant_expression(query)
    log.debug('Empty select list pushed down. Replacing with constant expression to get correct number of rows.')
    query.selectList = {{type = "literal_bool", value = "true"}}
end

local function replace_star_with_payload_columns(query, involved_tables)
    local select_list = {}
    local index = 1
    for _, involved_table in ipairs(involved_tables) do
        for _, column in ipairs(involved_table.columns) do
            select_list[index] = _column(involved_table.name, column.name, index)
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

local function rewrite_filter(query, source_schema_id, table_id, protection)
    local original_filter = query.filter
    local protection_filter = construct_protection_filter(source_schema_id, table_id, protection)
    if original_filter then
        query.filter = {type = "predicate_and", expressions = {protection_filter, original_filter}}
    else
        query.filter = protection_filter
    end
end

local function rewrite_with_protection(query, source_schema_id, table_id, protection, involved_tables)
    expand_protected_select_list(query, involved_tables)
    rewrite_filter(query, source_schema_id, table_id, protection)
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

local function validate_protection_scheme(source_schema_id, table_id, protection)
    if protection.group_protected and protection.role_protected then
        raise_protection_scheme_error(source_schema_id, table_id, protection)
    end
end

local function extend_query_with_source_schema(query, source_schema_id)
    query.from.schema = source_schema_id
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
function QueryRewriter.rewrite(original_query, source_schema_id, adapter_cache, involved_tables)
    validate(original_query)
    local query = original_query
    local table_id = query.from.name
    local protection = protection_reader.read(adapter_cache, table_id)
    if protection.protected then
        validate_protection_scheme(source_schema_id, table_id, protection)
        rewrite_with_protection(query, source_schema_id, table_id, protection, involved_tables)
    else
        rewrite_without_protection(query)
        log.debug('Table "%s" is not protected. No filters added.', table_id)
    end
    extend_query_with_source_schema(query, source_schema_id)
    local renderer = QueryRenderer:new(query)
    return renderer:render()
end

return QueryRewriter