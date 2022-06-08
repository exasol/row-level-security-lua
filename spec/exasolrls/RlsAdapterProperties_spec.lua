package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local RlsAdapterProperties = require("exasolrls.RlsAdapterProperties")

describe("adapter_properties", function()
    describe("validates property rule:", function()
            local tests = {
                {
                    properties = {},
                    expected = "Missing mandatory property 'SCHEMA_NAME'",
                },
                {
                    properties = {SCHEMA_NAME = ""},
                    expected = "Missing mandatory property 'SCHEMA_NAME'",
                },
                {
                    properties = {SCHEMA_NAME = "THE_SCHEMA", TABLE_FILTER = ""},
                    expected = "Table filter property 'TABLE_FILTER' must not be empty."
                }
            }
            for _, test in ipairs(tests) do
                it(test.expected, function()
                    local properties = RlsAdapterProperties:new(test.properties)
                    assert.error_matches(function () properties:validate() end,  test.expected, 1, true)
                end)
            end
    end)

    it("gets the SCHEMA_NAME property", function()
        assert.is("a_schema", RlsAdapterProperties:new({SCHEMA_NAME = "a_schema"}):get_schema_name())
    end)

    describe("get the TABLE_FILTER property:", function()
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
            assert.is(test.expected, RlsAdapterProperties:new({TABLE_FILTER = test.filter}):get_table_filter(), test)
        end
    end)
end)