local luaunit = require("luaunit")
local mockagne = require("mockagne")
local reader = require("exasolrls.metadata_reader")

test_metadata_reader = {}

function test_metadata_reader.test_read()
    local exa_mock = mockagne.getMock()
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery('OPEN SCHEMA "S"')).thenAnswer(true)
    mockagne.when(exa_mock.pquery('SELECT "TABLE_NAME" FROM "CAT"')).thenAnswer(true, {{TABLE_NAME = "T1"}})
    mockagne.when(exa_mock.pquery('DESCRIBE "T1"')).thenAnswer(true, {{COLUMN_NAME = "C1", SQL_TYPE = "BOOLEAN"}})
    luaunit.assertEquals(reader.read("S"),
            {tables = {{name = "T1", columns = {{name = "C1", dataType = {type = "BOOLEAN"}}}}},
                adapterNotes="T1:---"
            })
end

function test_metadata_reader.test_hide_control_tables()
    local exa_mock = mockagne.getMock()
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery('OPEN SCHEMA "S"')).thenAnswer(true)
    mockagne.when(exa_mock.pquery('SELECT "TABLE_NAME" FROM "CAT"'))
            .thenAnswer(true, {{TABLE_NAME = "T2"}, {TABLE_NAME = "EXA_RLS_USERS"}, {TABLE_NAME = "EXA_ROLE_MAPPING"},
                     {TABLE_NAME = "EXA_GROUP_MEMBERS"}})
    mockagne.when(exa_mock.pquery('DESCRIBE "T2"')).thenAnswer(true, {{COLUMN_NAME = "C2", SQL_TYPE = "DATE"}})
    luaunit.assertEquals(reader.read("S"),
            {tables = {{name = "T2", columns = {{name = "C2", dataType = {type = "DATE"}}}}}, adapterNotes="T2:---"})
end

function test_metadata_reader.test_hide_control_columns()
    local exa_mock = mockagne.getMock()
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery('OPEN SCHEMA "S"')).thenAnswer(true)
    mockagne.when(exa_mock.pquery('SELECT "TABLE_NAME" FROM "CAT"'))
            .thenAnswer(true, {{TABLE_NAME = "T3"}, {TABLE_NAME = "T4"}})
    mockagne.when(exa_mock.pquery('DESCRIBE "T3"'))
            .thenAnswer(true, {{COLUMN_NAME = "C3_1", SQL_TYPE = "BOOLEAN"}, {COLUMN_NAME = "EXA_ROW_TENANT"},
                    {COLUMN_NAME = "EXA_ROW_ROLES"}})
    mockagne.when(exa_mock.pquery('DESCRIBE "T4"'))
            .thenAnswer(true, {{COLUMN_NAME = "C4_1", SQL_TYPE = "DATE"}, {COLUMN_NAME = "EXA_ROW_GROUP"}})
    luaunit.assertEquals(reader.read("S"),
            {tables = {
                {name = "T3", columns = {{name = "C3_1", dataType = {type = "BOOLEAN"}}}},
                {name = "T4", columns = {{name = "C4_1", dataType = {type = "DATE"}}}}
             }, adapterNotes = "T3:tr-,T4:--g" })
end

os.exit(luaunit.LuaUnit.run())