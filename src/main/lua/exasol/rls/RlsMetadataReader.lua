--- This class reads schema, table and column metadata from the source.
-- @classmod RlsMetadataReader
local RlsMetadataReader = {}
RlsMetadataReader.__index = RlsMetadataReader
local AbstractMetadataReader = require("exasol.evscl.AbstractMetadataReader")
setmetatable(RlsMetadataReader, {__index = AbstractMetadataReader})

local log = require("remotelog")
local ExaError = require("ExaError")

--- Create a new `MetadataReader`.
-- @param exasol_context handle to local database functions and status
-- @return metadata reader
function RlsMetadataReader:new(exasol_context)
    assert(exasol_context ~= nil,
            "The metadata reader requires an Exasol context handle in order to read metadata from the database")
    local instance = setmetatable({}, self)
    instance:_init(exasol_context)
    return instance
end

function RlsMetadataReader:_init(exasol_context)
    AbstractMetadataReader._init(self, exasol_context);
end

--- Get the metadata reader type
-- @return always 'LOCAL'
function AbstractMetadataReader:_get_type()
    return "LOCAL"
end

-- Override
function RlsMetadataReader:_execute_column_metadata_query(schema_id, table_id)
    local sql = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"'
            .. ' WHERE "COLUMN_SCHEMA" = :s AND "COLUMN_TABLE" = :t ORDER BY "COLUMN_ORDINAL_POSITION"'
    return self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id, t = table_id})
end

-- Override
function RlsMetadataReader:_execute_table_metadata_query(schema_id)
    local sql = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" '
        .. 'WHERE "TABLE_SCHEMA" = :s AND TABLE_NAME NOT LIKE \'EXA_%\''
    return self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id})
end

-- Override
function RlsMetadataReader:_translate_columns_metadata(schema_id, table_id)
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
        ExaError.error("E-RLSL-MDR-3",
                "Unable to read column metadata from source table {{schema}}.{{table}}. Caused by: {{cause}}",
                {schema = schema_id, table = table_id, cause = result.error_message})
    end
end

-- Override
function RlsMetadataReader:_translate_table_scan_results(schema_id, result, include_tables)
    local tables = {}
    local table_protection = {}
    local include_tables_lookup = self:_create_lookup(include_tables)
    for i = 1, #result do
        local table_id = result[i].TABLE_NAME
        if self:_is_included_table(table_id, include_tables_lookup)
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

--- Read the database metadata of the given schema (i.e. the internal structure of that schema)
-- <p>
-- The scan can optionally be limited to a set of user-defined tables. If the list of tables to include in the scan
-- is omitted, then all tables in the source schema are scanned and reported.
-- </p>
-- @param schema schema to be scanned
-- @param include_tables list of tables to be included in the scan (optional, defaults to all tables in the schema)
-- @return schema metadata
-- Override
function RlsMetadataReader:read(schema_id, include_tables)
    local tables, table_protection = self:_translate_table_metadata(schema_id, include_tables)
    return {tables = tables, adapterNotes = table.concat(table_protection, ",")}
end

return RlsMetadataReader