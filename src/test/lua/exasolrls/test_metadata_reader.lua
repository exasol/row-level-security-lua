local luaunit = require("luaunit")
local mockagne = require("mockagne")
local reader = require("exasolrls.metadata_reader")

test_metadata_reader = {}

local function mock_open_schema(exa_mock)
    mockagne.when(exa_mock.pquery('OPEN SCHEMA "S"')).thenAnswer(true)
end

local function mock_describe_table(exa_mock, table, columns)
    mockagne.when(exa_mock.pquery('DESCRIBE "' .. table ..'"')).thenAnswer(true, columns)
end

local function mock_read_table_catalog(exa_mock, tables)
    mockagne.when(exa_mock.pquery('SELECT "TABLE_NAME" FROM "CAT"')).thenAnswer(true, tables)
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
-- @param ... list of table definitions.
--
local function mock_tables(exa_mock, ...)
    _G.exa = exa_mock
    mock_open_schema(exa_mock)
    local tables = {}
    local i = 1
    for _, table_definition in ipairs({...}) do
        local table = table_definition.table
        tables[i] = {TABLE_NAME = table}
        mock_describe_table(exa_mock, table, table_definition.columns)
        i = i + 1
    end
    mock_read_table_catalog(exa_mock, tables)
end

function test_metadata_reader.test_hide_control_tables()
    local exa_mock = mockagne.getMock()
    mock_tables(exa_mock,
        {
            table = "T2",
            columns = {{COLUMN_NAME = "C2", SQL_TYPE = "DATE"}}
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
    mock_tables(exa_mock,
        {
            table = "T3",
            columns = {
                {COLUMN_NAME = "C3_1", SQL_TYPE = "BOOLEAN"},
                {COLUMN_NAME = "EXA_ROW_TENANT"},
                {COLUMN_NAME = "EXA_ROW_ROLES"}
            }
        },
        {
            table = "T4",
            columns = {
                {COLUMN_NAME = "C4_1", SQL_TYPE = "DATE"},
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
    mock_tables(exa_mock,
        {
            table = "T",
            columns = {{COLUMN_NAME = "C1", SQL_TYPE = type}}
        }
    )
end

local function assert_column_type_translation(exa_mock, translation)
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
    assert_column_type_translation(exa_mock, {type = "BOOLEAN"})
end

function test_metadata_reader.test_date_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DATE")
    assert_column_type_translation(exa_mock, {type = "DATE"})
end

function test_metadata_reader.test_decimal_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DECIMAL(13,8)")
    assert_column_type_translation(exa_mock, {type = "DECIMAL", precision = 13, scale = 8})
end

function test_metadata_reader.test_double_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"DOUBLE PRECISION")
    assert_column_type_translation(exa_mock, {type = "DOUBLE PRECISION"})
end

function test_metadata_reader.test_char_utf8_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"CHAR(130) UTF8")
    assert_column_type_translation(exa_mock, {type = "CHAR", characterSet = "UTF8", size = 130})
end

function test_metadata_reader.test_char_ascii_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"CHAR(2000000) ASCII")
    assert_column_type_translation(exa_mock, {type = "CHAR", characterSet = "ASCII", size = 2000000})
end

function test_metadata_reader.test_varchar_utf8_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"VARCHAR(70) UTF8")
    assert_column_type_translation(exa_mock, {type = "VARCHAR", characterSet = "UTF8", size = 70})
end

function test_metadata_reader.test_varchar_ascii_column_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"VARCHAR(2000000) ASCII")
    assert_column_type_translation(exa_mock, {type = "VARCHAR", characterSet = "ASCII", size = 2000000})
end

function test_metadata_reader.test_hashtype_bit_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"HASHTYPE(5 BYTE)")
    assert_column_type_translation(exa_mock, {type = "HASHTYPE", bytesize = 5})
end

function test_metadata_reader.test_timestamp_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"TIMESTAMP")
    assert_column_type_translation(exa_mock, {type = "TIMESTAMP"})
end

function test_metadata_reader.test_timestamp_with_local_time_zone_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"TIMESTAMP WITH LOCAL TIME ZONE")
    assert_column_type_translation(exa_mock, {type = "TIMESTAMP", withLocalTimeZone = true})
end

function test_metadata_reader.test_geometry_with_default_srid_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"GEOMETRY")
    assert_column_type_translation(exa_mock, {type = "GEOMETRY", srid = 0})
end

function test_metadata_reader.test_geometry_with_srid_translation()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"GEOMETRY(4)")
    assert_column_type_translation(exa_mock, {type = "GEOMETRY", srid = 4})
end

function test_metadata_reader.test_interval_year_to_month()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"INTERVAL YEAR(6) TO MONTH")
    assert_column_type_translation(exa_mock, {type = "INTERVAL", fromTo= "YEAR TO MONTH", precision = 6})
end

function test_metadata_reader.test_interval_day_to_second()
    local exa_mock = mockagne.getMock()
    mock_table_with_single_column_of_type(exa_mock,"INTERVAL DAY(9) TO SECOND(5)")
    assert_column_type_translation(exa_mock, {type = "INTERVAL", fromTo= "DAY TO SECONDS", precision = 9, fraction = 5})
end

os.exit(luaunit.LuaUnit.run())
