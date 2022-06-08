local log = require("remotelog")
local text = require("text")
local exaerror = require("exaerror")

local DEFAULT_SRID <const> = 0

--- This class reads schema, table and column metadata from the source.
-- @type MetadataReader
local MetadataReader = {}
MetadataReader.__index = MetadataReader

--- Create a new `MetadataReader`.
-- @param exasol_context handle to local database functions and status
-- @return metadata reader
function MetadataReader:new(exasol_context)
    assert(exasol_context ~= nil,
            "The metadata reader requires an Exasol context handle in order to read metadata from the database")
    local instance = setmetatable({}, self)
    instance:_init(exasol_context)
    return instance
end

function MetadataReader:_init(exasol_context)
    self._exasol_context = exasol_context
end

function MetadataReader:_translate_parameterless_type(column_id, column_type)
    return {name = column_id, dataType = {type = column_type}}
end

function MetadataReader:_translate_decimal_type(column_id, column_type)
    local precision, scale = string.match(column_type, "DECIMAL%((%d+),(%d+)%)")
    return {name = column_id,
            dataType = {type = "DECIMAL", precision = tonumber(precision), scale = tonumber(scale)}}
end

function MetadataReader:_translate_char_type(column_id, column_type)
    local type, size, character_set = string.match(column_type, "(%a+)%((%d+)%) (%w+)")
    return {name = column_id, dataType = {type = type, size = tonumber(size), characterSet = character_set}}
end

-- Note that while users can optionally specify hash sizes in BITS, this is just a convenience method. Exasol
-- internally always stores hash size in bytes.
function MetadataReader:_translate_hash_type(column_id, column_type)
    local size = string.match(column_type, "HASHTYPE%((%d+) BYTE%)")
    return {name = column_id, dataType = {type = "HASHTYPE", bytesize = tonumber(size)}}
end

function MetadataReader:_translate_timestamp_type(column_id, local_time)
    if local_time then
        return {name = column_id, dataType = {type = "TIMESTAMP", withLocalTimeZone = true}}
    else
        return {name = column_id, dataType = {type = "TIMESTAMP"}}
    end
end

function MetadataReader:_translate_geometry_type(column_id, column_type)
    local srid = string.match(column_type, "GEOMETRY%((%d+)%)")
    if (srid == nil) then
        srid = DEFAULT_SRID
    else
        srid = tonumber(srid)
    end
    return {name = column_id, dataType = {type = "GEOMETRY", srid = srid}}
end

function MetadataReader:_translate_interval_year_to_month_type(column_id, column_type)
    local precision = string.match(column_type, "INTERVAL YEAR%((%d+)%) TO MONTH")
    return
    {
        name = column_id,
        dataType = {type = "INTERVAL", fromTo = "YEAR TO MONTH", precision = tonumber(precision)}
    }
end

function MetadataReader:_translate_interval_day_to_second(column_id, column_type)
    local precision, fraction = string.match(column_type, "INTERVAL DAY%((%d+)%) TO SECOND%((%d+)%)")
    return
    {
        name = column_id,
        dataType = {
            type = "INTERVAL",
            fromTo = "DAY TO SECONDS",
            precision = tonumber(precision),
            fraction = tonumber(fraction)
        }
    }
end

function MetadataReader:_translate_column_metadata(table_id, column)
    local column_id = column.COLUMN_NAME
    local column_type = column.COLUMN_TYPE
    if (column_type == "BOOLEAN") or (column_type == "DATE") or text.starts_with(column_type, "DOUBLE") then
        return self:_translate_parameterless_type(column_id, column_type)
    elseif text.starts_with(column_type, "DECIMAL") then
        return self:_translate_decimal_type(column_id, column_type)
    elseif text.starts_with(column_type, "CHAR") or text.starts_with(column_type, "VARCHAR") then
        return self:_translate_char_type(column_id, column_type)
    elseif text.starts_with(column_type, "HASHTYPE") then
        return self:_translate_hash_type(column_id, column_type)
    elseif column_type == "TIMESTAMP" then
        return self:_translate_timestamp_type(column_id, false)
    elseif column_type == "TIMESTAMP WITH LOCAL TIME ZONE" then
        return self:_translate_timestamp_type(column_id, true)
    elseif text.starts_with(column_type, "GEOMETRY") then
        return self:_translate_geometry_type(column_id, column_type)
    elseif text.starts_with(column_type, "INTERVAL YEAR") then
        return self:_translate_interval_year_to_month_type(column_id, column_type)
    elseif text.starts_with(column_type, "INTERVAL DAY") then
        return self:_translate_interval_day_to_second(column_id, column_type)
    else
        exaerror.create("E-RLSL-MDR-4", "Column {{table}}.{{column}} has unsupported type {{type}}.",
                {table = table_id, column = column_id, type = column_type})
                :add_ticket_mitigation()
                :raise()
    end
end

function MetadataReader:_translate_columns_metadata(schema_id, table_id)
    local sql = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"'
            .. ' WHERE "COLUMN_SCHEMA" = :s AND "COLUMN_TABLE" = :t'
    local ok, result = self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id, t = table_id})
    local translated_columns = {}
    local tenant_protected, role_protected, group_protected
    if ok then
        for i = 1, #result do
            local column = result[i]
            local column_id = column.COLUMN_NAME
            if (column_id == "EXA_ROW_TENANT") then
                tenant_protected = true
            elseif (column_id == "EXA_ROW_ROLES") then
                role_protected = true
            elseif (column_id == "EXA_ROW_GROUP") then
                group_protected = true
            else
                table.insert(translated_columns, self:_translate_column_metadata(table_id, column))
            end
        end
        return translated_columns, tenant_protected, role_protected, group_protected
    else
        exaerror.error("E-RLSL-MDR-3",
                "Unable to read column metadata from source table {{schema}}.{{table}}. Caused by: {{cause}}",
                {schema = schema_id, table = table_id, cause = result.error_message})
    end
end

function MetadataReader:_is_rls_metadata_table(table_id)
    return (table_id == "EXA_RLS_USERS") or (table_id == "EXA_ROLE_MAPPING") or (table_id == "EXA_GROUP_MEMBERS")
end

function MetadataReader:_is_included_table(table_id, include_tables_lookup)
    return include_tables_lookup[table_id]
end

function MetadataReader:_create_lookup(include_tables)
    local lookup = {}
    if include_tables == nil then
        setmetatable(lookup, {__index = function(_, _)
            return true
        end})
    else
        log.debug("Setting filter for metadata scan to the following tables: "
                .. table.concat(include_tables, ", "))
        for _, table_id in ipairs(include_tables) do
            lookup[table_id] = true
        end
    end
    return lookup
end

function MetadataReader:_translate_table_scan_results(schema_id, result, include_tables)
    local tables = {}
    local table_protection = {}
    local include_tables_lookup = self:_create_lookup(include_tables)
    for i = 1, #result do
        local table_id = result[i].TABLE_NAME
        if self:_is_included_table(table_id, include_tables_lookup) and not self:_is_rls_metadata_table(table_id)
        then
            local columns, tenant_protected, role_protected, group_protected =
                    self:_translate_columns_metadata(schema_id, table_id)
            table.insert(tables, {name = table_id, columns = columns})
            local protection = (tenant_protected and "t" or "-") .. (role_protected and "r" or "-")
                    .. (group_protected and "g" or "-")
            log.debug("Found table '%s' (%d columns). Protection: %s", table_id, #columns, protection)
            table.insert(table_protection, table_id .. ":" .. protection)
        end
    end
    return tables, table_protection
end

function MetadataReader:_translate_table_metadata(schema_id, include_tables)
    local sql = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE "TABLE_SCHEMA" = :s'
    local ok, result = self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id})
    if ok then
        return self:_translate_table_scan_results(schema_id, result, include_tables)
    else
        exaerror.error("E-RLSL-MDR-2",
                "Unable to read table metadata from source schema {{schema}}. Caused by: {{cause}}",
                {schema = schema_id, cause = result.error_message})
    end
end

--- Read the database metadata of the given schema (i.e. the internal structure of that schema)
-- <p>
-- The scan can optionally be limited to a set of user-defined tables. If the list of tables to include in the scan
-- is omitted, then all tables in the source schema are scanned and reported.
-- </p>
-- @param schema schema to be scanned
-- @param include_tables list of tables to be included in the scan (optional, defaults to all tables in the schema)
-- @return schema metadata
function MetadataReader:read(schema_id, include_tables)
    local tables, table_protection = self:_translate_table_metadata(schema_id, include_tables)
    return {tables = tables, adapterNotes = table.concat(table_protection, ",")}
end

return MetadataReader