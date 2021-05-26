local luaunit = require("luaunit")

local mockagne = require("mockagne")
local metadata_reader_mock = mockagne.getMock()
package.preload["exasolrls.metadata_reader"] = function () return metadata_reader_mock end

local adapter = require("exasolrls.adapter")

test_rls_adapter = {}

function test_rls_adapter.test_version_matches_maven_pom()
    luaunit.fail("not implemented yet")
end

function test_rls_adapter.test_drop_virtual_schema()
    luaunit.assertEquals(adapter.drop_virtual_schema(), {type="dropVirtualSchema"})
end

function test_rls_adapter.test_create_virtual_schema()
    local schema_metadata = {tables = {{type = "table", name = "T1", columns =
        {{name = "C1", dataType = { type = "BOOLEAN"}}}}}}
    mockagne.when(metadata_reader_mock.read("S")).thenAnswer(schema_metadata)
    local expected = {type = "createVirtualSchema",
        schemaMetadata = schema_metadata}
    local request = {schemaMetadataInfo = {name = "V", properties = {SCHEMA_NAME = "S"}}}
    local actual = adapter.create_virtual_schema(nil, request)
    luaunit.assertEquals(actual, expected)
end

function test_rls_adapter.test_get_capabilites()
    local expected = {type = "getCapabilities",
        capabilities = {"SELECTLIST_PROJECTION", "AGGREGATE_SINGLE_GROUP", "AGGREGATE_GROUP_BY_COLUMN",
            "AGGREGATE_GROUP_BY_TUPLE", "AGGREGATE_HAVING", "ORDER_BY_COLUMN", "LIMIT",
            "LIMIT_WITH_OFFSET"}}
    local actual = adapter.get_capabilities()
    luaunit.assertEquals(actual, expected)
end

function test_rls_adapter.test_validate_properties_reports_missing_schema_name()
    local validations = {
        { input = {},
          expected = 'Missing mandatory property "SCHEMA_NAME"'
        },
        { input = {SCHEMA_NAME = ""},
          expected = 'Missing mandatory property "SCHEMA_NAME"'
        }
    }
    for _, validation in ipairs(validations) do
        local request = {schemaMetadataInfo = {name = "V", properties = validation.input}}
        luaunit.assertErrorMsgContains(validation.expected, adapter.create_virtual_schema, nil, request)
    end
end

os.exit(luaunit.LuaUnit.run())
