local luaunit = require("luaunit")
local props = require("exasolrls.adapter_properties")

test_rls_adapter = {}

function test_rls_adapter.test_validate_properties()
    local tests = {
        {
            properties = {},
            expected = 'Missing mandatory property "SCHEMA_NAME"',
        },
        {
            properties = {SCHEMA_NAME = ""},
            expected = 'Missing mandatory property "SCHEMA_NAME"',
        },
        {
            properties = {SCHEMA_NAME = "THE_SCHEMA", TABLE_FILTER = ""},
            expected = "Table filter property must not be empty."
        }
    }
    for _, test in ipairs(tests) do
        local properties = props:new({raw_properties = test.properties})
        luaunit.assertErrorMsgContains(test.expected, properties.validate, properties)
    end
end

function test_rls_adapter.test_get_schema_name()
    luaunit.assertEquals(props.create({SCHEMA_NAME = "a_schema"}):get_schema_name(), "a_schema")
end

function test_rls_adapter.test_get_table_filter()
    local tests = {
        {
            filter = "T1, T2, T3",
            expected = {"T1", "T2", "T3"}
        },
        {
            filter = " T1 ,T2,  T3 \t,T4 ",
            expected = {"T1", "T2", "T3", "T4"}
        },
        {
            filter = "T1 T2, T3",
            expected = {"T1 T2", "T3"}
        },
        {
            filter = "",
            expected = {}
        },
        {
            filter = nil,
            expected = nil
        }
    }
    for _, test in ipairs(tests) do
        luaunit.assertEquals(props.create({TABLE_FILTER = test.filter}):get_table_filter(), test.expected)
    end
end

os.exit(luaunit.LuaUnit.run())
