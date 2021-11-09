local luaunit = require("luaunit")
local mockagne = require("mockagne")
local reader = require("exasolrls.metadata_reader")

local CATALOG_QUERY = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE "TABLE_SCHEMA" = :s'
local DESCRIBE_TABLE_QUERY = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"'
    .. ' WHERE "COLUMN_SCHEMA" = :s AND "COLUMN_TABLE" = :t'

test_metadata_reader = {
}

local function mock_describe_table(exa_mock, schema_id, table_id, columns)
    mockagne.when(exa_mock.pquery_no_preprocessing(DESCRIBE_TABLE_QUERY, {s = schema_id, t = table_id}))
        .thenAnswer(true, columns)
end

local function mock_read_table_catalog(exa_mock, schema_id, tables)
    mockagne.when(exa_mock.pquery_no_preprocessing(CATALOG_QUERY, {s = schema_id}))
        .thenAnswer(true, tables)
end

---
-- Mock queries used to retrieve the metadata of tables.
-- <p>
-- The table definitions used in this method have the following form:
-- </p>
-- <pre><code>
-- {{table = "T1", columns= {<column-query-mock-response>}}, ...}
-- </code></pre>
-- <p>
-- Table metadata query mocks and the corresponding column metadata query mocks are guaranteed to be configured in the
-- same order as in the table definition list.
-- </p>
--
-- @param exa_mock mock <code>exa</code> object (the object that provides <code>query</code> and <code>pquery</code>)
--
-- @param schema_id name of the schema
--
-- @param ... list of table definitions.
--
local function mock_tables(exa_mock, schema_id, ...)
    _G.exa = exa_mock
    local tables = {}
    local i = 1
    for _, table_definition in ipairs({...}) do
        local table_id = table_definition.table
        tables[i] = {TABLE_NAME = table_id}
        mock_describe_table(exa_mock, schema_id, table_id, table_definition.columns)
        i = i + 1
    end
    mock_read_table_catalog(exa_mock, schema_id, tables)
end

function test_metadata_reader.test_hide_control_tables()
    local exa_mock = mockagne.getMock()
    mock_tables(exa_mock, "S",
        {
            table = "T2",
            columns = {{COLUMN_NAME = "C2", COLUMN_TYPE = "DATE"}}
        },
        {
            table = "EXA_RLS_USERS"
        },
        {
            table = "EXA_ROLE_MAPPING"
        }
    )
    luaunit.assertEquals(reader.read("S"),
        {
            tables =
            {
                {
                    name = "T2",
                    columns = {{name = "C2", dataType = {type = "DATE"}}}
                }
            },
            adapterNotes="T2:---"
        }
    )
end

function test_metadata_reader.test_hide_control_columns()
    local exa_mock = mockagne.getMock()
    mock_tables(exa_mock, "S",
        {
            table = "T3",
            columns = {
                {COLUMN_NAME = "C3_1", COLUMN_TYPE = "BOOLEAN"},
                {COLUMN_NAME = "EXA_ROW_TENANT"},
                {COLUMN_NAME = "EXA_ROW_ROLES"}
            }
        },
        {
            table = "T4",
            columns = {
                {COLUMN_NAME = "C4_1", COLUMN_TYPE = "DATE"},
                {COLUMN_NAME = "EXA_ROW_GROUP"}
            }
        }
    )
    luaunit.assertEquals(reader.read("S"),
        {
            tables =
            {
                {
                    name = "T3",
                    columns = {{name = "C3_1", dataType = {type = "BOOLEAN"}}}
                },
                {
                    name = "T4",
                    columns = {{name = "C4_1", dataType = {type = "DATE"}}}
                }
            },
            adapterNotes = "T3:tr-,T4:--g"
        }
    )
end

local function mock_table_with_single_column_of_type(exa_mock, type)
    mock_tables(exa_mock, "S",
        {
            table = "T",
            columns = {{COLUMN_NAME = "C1", COLUMN_TYPE = type}}
        }
    )
end

local function assert_column_type_translation(translation)
    luaunit.assertEquals(reader.read("S"),
        {
            tables =
            {
                {name = "T", columns = {{name = "C1", dataType = translation}}}
            },
            adapterNotes="T:---"
        }
    )
end

function test_metadata_reader.test_boolean_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"BOOLEAN")
    assert_column_type_translation({type = "BOOLEAN"})
end

function test_metadata_reader.test_date_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DATE")
    assert_column_type_translation({type = "DATE"})
end

function test_metadata_reader.test_decimal_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DECIMAL(13,8)")
    assert_column_type_translation({type = "DECIMAL", precision = 13, scale = 8})
end

function test_metadata_reader.test_double_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DOUBLE PRECISION")
    assert_column_type_translation({type = "DOUBLE PRECISION"})
end

function test_metadata_reader.test_char_utf8_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"CHAR(130) UTF8")
    assert_column_type_translation({type = "CHAR", characterSet = "UTF8", size = 130})
end

function test_metadata_reader.test_char_ascii_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"CHAR(2000000) ASCII")
    assert_column_type_translation({type = "CHAR", characterSet = "ASCII", size = 2000000})
end

function test_metadata_reader.test_varchar_utf8_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"VARCHAR(70) UTF8")
    assert_column_type_translation({type = "VARCHAR", characterSet = "UTF8", size = 70})
end

function test_metadata_reader.test_varchar_ascii_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"VARCHAR(2000000) ASCII")
    assert_column_type_translation({type = "VARCHAR", characterSet = "ASCII", size = 2000000})
end

function test_metadata_reader.test_hashtype_bit_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"HASHTYPE(5 BYTE)")
    assert_column_type_translation({type = "HASHTYPE", bytesize = 5})
end

function test_metadata_reader.test_timestamp_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"TIMESTAMP")
    assert_column_type_translation({type = "TIMESTAMP"})
end

function test_metadata_reader.test_timestamp_with_local_time_zone_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"TIMESTAMP WITH LOCAL TIME ZONE")
    assert_column_type_translation({type = "TIMESTAMP", withLocalTimeZone = true})
end

function test_metadata_reader.test_geometry_with_default_srid_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"GEOMETRY")
    assert_column_type_translation({type = "GEOMETRY", srid = 0})
end

function test_metadata_reader.test_geometry_with_srid_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"GEOMETRY(4)")
    assert_column_type_translation({type = "GEOMETRY", srid = 4})
end

function test_metadata_reader.test_interval_year_to_month()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"INTERVAL YEAR(6) TO MONTH")
    assert_column_type_translation({type = "INTERVAL", fromTo= "YEAR TO MONTH", precision = 6})
end

function test_metadata_reader.test_interval_day_to_second()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"INTERVAL DAY(9) TO SECOND(5)")
    assert_column_type_translation({type = "INTERVAL", fromTo= "DAY TO SECONDS", precision = 9, fraction = 5})
end

function test_metadata_reader.test_table_filter()
    local exa_mock = mockagne.getMock()
    mock_tables(exa_mock, "S",
        {table = "T1", columns = {{COLUMN_NAME = "C1_1", COLUMN_TYPE = "BOOLEAN"}}},
        {table = "T2", columns = {{COLUMN_NAME = "C2_1", COLUMN_TYPE = "BOOLEAN"}}},
        {table = "T3", columns = {{COLUMN_NAME = "C3_1", COLUMN_TYPE = "BOOLEAN"}}},
        {table = "T4", columns = {{COLUMN_NAME = "C4_1", COLUMN_TYPE = "BOOLEAN"}}}
    )
    luaunit.assertEquals(reader.read("S", {"T2", "T3"}),
        {
            tables =
            {
                {
                    name = "T2",
                    columns = {{name = "C2_1", dataType = {type = "BOOLEAN"}}}
                },
                {
                    name = "T3",
                    columns = {{name = "C3_1", dataType = {type = "BOOLEAN"}}}
                }
            },
            adapterNotes = "T2:---,T3:---"
        }
    )
end

local function mock_schema_metadata_reading_error(exa_mock, schema_id, error_message)
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery_no_preprocessing(CATALOG_QUERY, {s = schema_id}))
        .thenAnswer(false, {error_message = error_message})
end

function test_metadata_reader.test_unable_to_read_schema_metadata_raises_error()
    local exa_mock = mockagne.getMock()
    mock_schema_metadata_reading_error(exa_mock, "the_schema", "the_cause")
    luaunit.assertErrorMsgContains("Unable to read table metadata from source schema 'the_schema'."
        .. " Caused by: 'the_cause'", reader.read, "the_schema")
end

local function mock_table_metadata_reading_error(exa_mock, schema_id, table_id, error_message)
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery_no_preprocessing(DESCRIBE_TABLE_QUERY, {s = schema_id, t = table_id}))
        .thenAnswer(false, {error_message = error_message})
end

function test_metadata_reader.test_unable_to_read_table_metadata_raises_error()
    local exa_mock = mockagne.getMock()
    local schema_id = "S"
    mock_table_metadata_reading_error(exa_mock, schema_id, "T", "another_cause")
    mock_read_table_catalog(exa_mock, schema_id, {{TABLE_NAME = "T"}})
    luaunit.assertErrorMsgContains("Unable to read column metadata from source table '" .. schema_id .. "'.'T'."
        .. " Caused by: 'another_cause'", reader.read, "S")
end

function test_metadata_reader.test_unknown_column_type_raises_error()
    local exa_mock = mockagne.getMock()
    local schema_id = "THE_SCHEMA"
    mock_tables(exa_mock, schema_id,
        {table = "THE_TABLE", columns = {{COLUMN_NAME = "THE_COLUMN", COLUMN_TYPE = "THE_TYPE"}}}
    )
    luaunit.assertErrorMsgContains("Column 'THE_TABLE'.'THE_COLUMN' has unsupported type 'THE_TYPE'",
        reader.read, schema_id)
end

os.exit(luaunit.LuaUnit.run())
