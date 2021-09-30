local log = require("remotelog")
local text = require("text")

_G.M = {
    DEFAULT_SRID = 0,
}

local function translate_parameterless_type(column_id, column_type)
    return {name = column_id, dataType = {type = column_type}}
end

local function translate_decimal_type(column_id, column_type)
    local precision, scale = string.match(column_type, "DECIMAL%((%d+),(%d+)%)")
    return {name = column_id, dataType = {type = "DECIMAL", precision = tonumber(precision), scale = tonumber(scale)}}
end

local function translate_char_type(column_id, column_type)
    local type, size, character_set = string.match(column_type, "(%a+)%((%d+)%) (%w+)")
    return {name = column_id, dataType = {type = type, size = tonumber(size), characterSet = character_set}}
end

-- Note that while users can optionally specify hash sizes in BITS, this is just a convenience method. Exasol
-- internally always stores hash size in bytes.
local function translate_hash_type(column_id, column_type)
    local size = string.match(column_type, "HASHTYPE%((%d+) BYTE%)")
    return {name = column_id, dataType = {type = "HASHTYPE", bytesize = tonumber(size)}}
end

local function translate_timestamp_type(column_id, local_time)
    if local_time then
        return {name = column_id, dataType = {type = "TIMESTAMP", withLocalTimeZone = true}}
    else
        return {name = column_id, dataType = {type = "TIMESTAMP"}}
    end
end

local function translate_geometry_type(column_id, column_type)
    local srid = string.match(column_type, "GEOMETRY%((%d+)%)")
    if(srid == nil) then
        srid = _G.M.DEFAULT_SRID
    else
        srid = tonumber(srid)
    end
    return {name = column_id, dataType = {type = "GEOMETRY", srid = srid}}
end

local function translate_interval_year_to_month_type(column_id, column_type)
    local precision =  string.match(column_type, "INTERVAL YEAR%((%d+)%) TO MONTH")
    return
    {
        name = column_id,
        dataType = {type = "INTERVAL", fromTo = "YEAR TO MONTH", precision = tonumber(precision)}
    }
end

local function translate_interval_day_to_second(column_id, column_type)
    local precision, fraction =  string.match(column_type, "INTERVAL DAY%((%d+)%) TO SECOND%((%d+)%)")
    return
    {
        name = column_id,
        dataType =
        {
            type = "INTERVAL",
            fromTo = "DAY TO SECONDS",
            precision = tonumber(precision),
            fraction = tonumber(fraction)
        }
    }
end

local function translate_column_metadata(column)
    local column_id = column.COLUMN_NAME
    local column_type = column.COLUMN_TYPE
    if (column_type == "BOOLEAN") or (column_type == "DATE") or text.starts_with(column_type, "DOUBLE") then
        return translate_parameterless_type(column_id, column_type)
    elseif text.starts_with(column_type, "DECIMAL") then
        return translate_decimal_type(column_id, column_type)
    elseif text.starts_with(column_type, "CHAR") or text.starts_with(column_type, "VARCHAR") then
        return translate_char_type(column_id, column_type)
    elseif text.starts_with(column_type, "HASHTYPE") then
        return translate_hash_type(column_id, column_type)
    elseif column_type == "TIMESTAMP" then
        return translate_timestamp_type(column_id, false)
    elseif column_type == "TIMESTAMP WITH LOCAL TIME ZONE" then
        return translate_timestamp_type(column_id, true)
    elseif text.starts_with(column_type, "GEOMETRY") then
        return translate_geometry_type(column_id, column_type)
    elseif text.starts_with(column_type, "INTERVAL YEAR") then
        return translate_interval_year_to_month_type(column_id, column_type)
    elseif text.starts_with(column_type, "INTERVAL DAY") then
        return translate_interval_day_to_second(column_id, column_type)
    else
        error('E-LVS-MDR-4: Column "' .. column_id .. '" has unsupported type "' .. column_type .. ".");
    end
end

local function translate_columns_metadata(schema_id, table_id)
    local sql = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"'
        .. ' WHERE "COLUMN_SCHEMA" = \'' .. schema_id .. '\' AND "COLUMN_TABLE" = \'' .. table_id .. "'"
    local ok, result = _G.exa.pquery_no_preprocessing(sql)
    local translated_columns = {}
    local tenant_protected, role_protected, group_protected
    if ok then
        for i = 1, #result do
            local column = result[i]
            local column_id = column.COLUMN_NAME
            if(column_id == "EXA_ROW_TENANT") then
                tenant_protected = true
            elseif(column_id == "EXA_ROW_ROLES") then
                role_protected = true
            elseif(column_id == "EXA_ROW_GROUP") then
                group_protected = true
            else
                table.insert(translated_columns, translate_column_metadata(column))
            end
        end
        return translated_columns, tenant_protected, role_protected, group_protected
    else
        error("E-MDR-3: Unable to read column metadata from source table " .. table_id .. ".  Caused by: "
            .. result.error_message)
    end
end

local function is_rls_metadata_table(table_id)
    return (table_id == "EXA_RLS_USERS") or (table_id == "EXA_ROLE_MAPPING") or (table_id == "EXA_GROUP_MEMBERS")
end

local function is_included_table(table_id, include_tables_lookup)
    return include_tables_lookup[table_id]
end

local function create_lookup(include_tables)
    local lookup = {}
    if include_tables == nil then
        setmetatable(lookup, {__index = function (_, _) return true end})
    else
        log.debug("Setting filter for metadata scan to the following tables: " .. table.concat(include_tables, ", "))
        for _, table_id in ipairs(include_tables) do
            lookup[table_id] = true
        end
    end
    return lookup
end

local function translate_table_scan_results(schema_id, result, include_tables)
    local tables = {}
    local table_protection = {}
    local include_tables_lookup = create_lookup(include_tables)
    for i = 1, #result do
        local table_id = result[i].TABLE_NAME
        if is_included_table(table_id, include_tables_lookup) and not is_rls_metadata_table(table_id)
        then
            local columns, tenant_protected, role_protected, group_protected =
                translate_columns_metadata(schema_id, table_id)
            table.insert(tables, {name = table_id, columns = columns})
            local protection = (tenant_protected and "t" or "-") .. (role_protected and "r" or "-")
                    .. (group_protected and "g" or "-")
            log.debug('Found table "' .. table_id .. '" (' .. #columns .. ' columns). Protection: ' .. protection)
            table.insert(table_protection, table_id .. ":" .. protection)
        end
    end
    return tables, table_protection
end

local function translate_table_metadata(schema_id, include_tables)
    local sql = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE "TABLE_SCHEMA" = \''
        .. schema_id .. "'"
    local ok, result = _G.exa.pquery_no_preprocessing(sql)
    if ok then
        return translate_table_scan_results(schema_id, result, include_tables)
    else
        error("E-MDR-2: Unable to read table metadata from source schema. Caused by: " .. result.error_message)
    end
end

---
-- Read the database metadata of the given schema (i.e. the internal structure of that schema)
-- <p>
-- The scan can optionally be limited to a set of user-defined tables. If the list of tables to include in the scan
-- is omitted, then all tables in the source schema are scanned and reported.
-- </p>
--
-- @param schema schema to be scanned
-- 
-- @param include_tables list of tables to be included in the scan (optional, defaults to all tables in the schema)
--
-- @return schema metadata
--
function M.read(schema_id, include_tables)
    local tables, table_protection = translate_table_metadata(schema_id, include_tables)
    return {tables = tables, adapterNotes = table.concat(table_protection, ",")}
end

return _G.M
