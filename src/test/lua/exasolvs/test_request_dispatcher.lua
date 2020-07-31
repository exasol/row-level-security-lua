luaunit = require("luaunit")
cjson = require("cjson")
dispatcher = require("exasolvs.request_dispatcher")

test_request_dispatcher = {}

local function json_assert(actual, expected)
    luaunit.assertEquals(cjson.decode(actual), expected)
end

function test_request_dispatcher.test_get_capabilities()
    local response = adapter_call('{"type" : "getCapabilities"}')
    local expected = {type = "getCapabilities", capabilities = {
        "SELECTLIST_PROJECTION",
        "AGGREGATE_SINGLE_GROUP",
        "AGGREGATE_GROUP_BY_COLUMN",
        "AGGREGATE_GROUP_BY_TUPLE",
        "AGGREGATE_HAVING",
        "ORDER_BY_COLUMN",
        "LIMIT",
        "LIMIT_WITH_OFFSET"
    }}
    json_assert(response, expected)
end

os.exit(luaunit.LuaUnit.run())