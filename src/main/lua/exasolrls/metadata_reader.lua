local log = require("remotelog")
local cjson require("cjson")

M = {}

local function open_schema(schema_id)
    local ok, result = exa.pquery('OPEN SCHEMA "' .. schema_id .. '"')
    if not ok  then
        error("E-MDR-1: Unable to open source schema " .. schema_id .. " for reading metadata. Caused by: "
            .. result.error_message)
    end
end

local function read_columns(table_id)
    local ok, result = exa.pquery('DESCRIBE "' .. table_id .. '"')
    local columns = {}
    local tenant_protected, role_protected, group_protected
    if ok  then
        for i = 1, #result do
            local column_id = result[i].COLUMN_NAME
            if(column_id == "EXA_ROW_TENANT") then
                tenant_protected = true
            elseif(column_id == "EXA_ROW_ROLES") then
                role_protected = true
            elseif(column_id == "EXA_ROW_GROUP") then
                group_protected = true
            else
                local column_type = result[i].SQL_TYPE
                columns[i] = {name = column_id, dataType = {type = column_type}}
            end
        end
        return columns, tenant_protected, role_protected, group_protected
    else
        error("E-MDR-3: Unable to read column metadata from source table " .. table_id .. ".  Caused by: "
            .. result.error_message)
    end
end

local function read_tables(schema_id)
    local ok, result = exa.pquery('SELECT "TABLE_NAME" FROM "CAT"')
    local tables = {}
    local table_protection = {}
    if ok then
        for i = 1, #result do
            local table_id = result[i].TABLE_NAME
            if (table_id ~= "EXA_RLS_USERS") and (table_id ~= "EXA_ROLE_MAPPING") and (table_id ~= "EXA_GROUP_MEMBERS")
            then
                local columns, tenant_protected, role_protected, group_protected = read_columns(table_id)
                tables[i] = {name = table_id, columns = columns}
                local protection = (tenant_protected and "t" or "-") .. (role_protected and "r" or "-")
                        .. (group_protected and "g" or "-")
                log.debug('Found table "' .. table_id .. '" (' .. #columns .. ' columns). Protection: ' .. protection)
                table.insert(table_protection, table_id .. ":" .. protection)
            end
        end
        return tables, table_protection
    else
        error("E-MDR-2: Unable to read table metadata from source schema. Caused by: " .. result.error_message)
    end
end

---
-- Read the database metadata of the given schema (i.e. the internal structure of that schema)
--
-- @param schema schema to be scanned
--
-- @return schema metadata
--
function M.read(schema_id)
    open_schema(schema_id)
    local tables, table_protection = read_tables(schema_id)
    return {tables = tables, adapterNotes = table.concat(table_protection, ",")}
end

return M
