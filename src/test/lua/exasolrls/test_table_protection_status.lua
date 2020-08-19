local luaunit = require("luaunit")

local mockagne = require("mockagne")

local protection = require("exasolrls.table_protection_status")

test_table_protection_status = {}

function test_table_protection_status.test_is_protected_calculated_from_cache_true()
    local source_schema = "S"
    local adapter_cache = "CITIES:---,PEOPLE:t--"
    luaunit.assertEquals(protection.is_table_protected(source_schema, "PEOPLE", adapter_cache), true)
    luaunit.assertEquals(protection.is_table_protected(source_schema, "CITIES", adapter_cache), false)
end

function test_table_protection_status.test_is_protected_false()
    local source_schema = "S"
    local table = "MONTHS"
    local exa_mock = mockagne.getMock()
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery('DESCRIBE "' .. source_schema .. '"."' .. table .. '"'))
        .thenAnswer(true, {{COLUMN_NAME = "C1", SQL_TYPE = "BOOLEAN"}})
    luaunit.assertEquals(protection.is_table_protected(source_schema, table), false)
end

function test_table_protection_status.test_is_protected_true()
    local source_schema = "S"
    local table = "PEOPLE"
    local exa_mock = mockagne.getMock()
    _G.exa = exa_mock
    mockagne.when(exa_mock.pquery('DESCRIBE "' .. source_schema .. '"."'.. table .. '"'))
        .thenAnswer(true, {
            {COLUMN_NAME = "C1", SQL_TYPE = "BOOLEAN"},
            {COLUMN_NAME = "EXA_ROW_TENANT", SQL_TYPE = "VARCHAR"}
        })
    luaunit.assertEquals(protection.is_table_protected(source_schema, table), true)
end

os.exit(luaunit.LuaUnit.run())
