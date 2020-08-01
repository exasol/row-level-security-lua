M = {}

local CONTROL_TABLES = {"EXA_RLS_USERS", "EXA_ROLE_MAPPING", "EXA_GROUP_MAPPING"}

local function open_schema(schema_id)
    local ok, result = exa.pquery('OPEN SCHEMA "' .. schema_id .. '"')
    if(not ok) then
        error("E-MDR-1: Unable to open source schema " .. schema_id .. " for reading metadata. Caused by: "
                .. result.error_message)
    end
end

local function read_columns(table_id)
    local ok, result = exa.pquery('DESCRIBE "' .. table_id .. '"')
    local columns = {}
    if(ok) then
        for i = 1, #result do
            local column_id = result[i].COLUMN_NAME
            if((column_id ~= "EXA_ROW_ROLES") and (column_id ~= "EXA_ROW_TENANT") and (column_id ~= "EXA_ROW_GROUP"))
            then
                local column_type = result[i].SQL_TYPE
                columns[i] = {name = column_id, dataType = {type = column_type}}
            end
        end
        return columns
    else
        error("E-MDR-3: Unable to read column metadata from source table " .. table_id .. ".  Caused by: "
                .. result.error_message)
    end
end

local function read_tables(schema_id)
    local ok, result = exa.pquery('SELECT "TABLE_NAME" FROM "CAT"')
    local tables = {}
    if(ok) then 
        for i = 1, #result do
            local table_id = result[i].TABLE_NAME
            if((table_id ~= "EXA_RLS_USERS") and (table_id ~= "EXA_ROLE_MAPPING") and (table_id ~= "EXA_GROUP_MEMBERS"))
            then
                local columns = read_columns(table_id)
                tables[i] = {name = table_id, columns = columns}
            end
        end
        return tables
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
    return {tables = read_tables(schema_id)}
end

return M