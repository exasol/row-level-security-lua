local luaunit = require("luaunit")
local mockagne = require("mockagne")
local log_mock = mockagne.getMock()
package.preload["remotelog"] = function () return log_mock end
local cjson = require("cjson")
local adapter = require("exasolrls.rls_adapter")
local dispatcher = require("exasolvs.request_dispatcher").init(adapter)
local adapter_capabilities = require("exasolrls.adapter_capabilities")

local verify = mockagne.verify

test_request_dispatcher = {}

local function json_assert(actual, expected)
    luaunit.assertEquals(cjson.decode(actual), expected)
end

function test_request_dispatcher.test_get_capabilities()
    local response = dispatcher.adapter_call('{"type" : "getCapabilities"}')
    local expected = {type = "getCapabilities", capabilities = adapter_capabilities}
    json_assert(response, expected)
end

function test_request_dispatcher.test_setup_remote_logging()
    dispatcher.adapter_call('{"type" : "getCapabilities", "schemaMetadataInfo" : '
        .. '{"properties" : {"DEBUG_ADDRESS" : "10.0.0.1:4000", "LOG_LEVEL" : "TRACE"}}}')
    verify(log_mock.set_level("TRACE"))
    verify(log_mock.connect("10.0.0.1", "4000"))
end

os.exit(luaunit.LuaUnit.run())
