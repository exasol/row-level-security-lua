package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local assert = require("luassert")
local mockagne = require("mockagne")
local text = require("text")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local RlsAdapter = require("exasolrls.RlsAdapter")
local pom = require("spec.pom.reader")

describe("RlsAdapter", function ()
    local adapter
    local metadata_reader_mock

    before_each(function()
        metadata_reader_mock = mockagne.getMock()
        adapter = RlsAdapter.new(metadata_reader_mock)
    end)

    it("has the same version number as the project in the Maven POM file", function()
        assert.is(pom.get_version(), adapter:get_version())
    end)

    it("reports the name of the adapter", function()
        assert.is("Row-level Security adapter (LUA)", adapter.get_name)
    end)

    it("answers a request to create the Virtual Schema with the metadata of the source schema", function()
        local schema_metadata = {
            tables = {
                {type = "table", name = "T1", columns = {{name = "C1", dataType = { type = "BOOLEAN"}}}}
            }
        }
        mockagne.when(metadata_reader_mock.read("S")).thenAnswer(schema_metadata)
        local expected = {type = "createVirtualSchema",
                          schemaMetadata = schema_metadata}
        local request = {schemaMetadataInfo = {name = "V", properties = {SCHEMA_NAME = "S"}}}
        local actual = adapter:create_virtual_schema(request)
        assert.is(expected, actual)
    end)

    it("confirms a request to drop the Virtual Schema with an empty response", function()
        assert.are.same({type = "dropVirtualSchema"}, RlsAdapter.drop_virtual_schema())
    end)

    it("reports the supported capabilities", function()
        local request = {}
        local expected = {type = "getCapabilities", capabilities = adapter_capabilities}
        local actual = adapter:get_capabilities(request)
        assert.is(expected, actual)
    end)

    describe("reports the supported capabilities minus ones in the EXCLUDED_CAPABILITIES property:", function()
        local input_variants = {
            "AGGREGATE_GROUP_BY_COLUMN,AGGREGATE_GROUP_BY_TUPLE,AGGREGATE_GROUP_BY_EXPRESSION, AGGREGATE_SINGLE_GROUP",
            "AGGREGATE_GROUP_BY_COLUMN, AGGREGATE_GROUP_BY_TUPLE, AGGREGATE_GROUP_BY_EXPRESSION, AGGREGATE_SINGLE_GROUP",
            " AGGREGATE_GROUP_BY_COLUMN, AGGREGATE_GROUP_BY_TUPLE, AGGREGATE_GROUP_BY_EXPRESSION, AGGREGATE_SINGLE_GROUP, ",
            "AGGREGATE_GROUP_BY_COLUMN,  AGGREGATE_GROUP_BY_TUPLE  , AGGREGATE_GROUP_BY_EXPRESSION, AGGREGATE_SINGLE_GROUP",
            ",AGGREGATE_GROUP_BY_COLUMN, , AGGREGATE_GROUP_BY_TUPLE,, AGGREGATE_GROUP_BY_EXPRESSION, AGGREGATE_SINGLE_GROUP",
        }
        for _, input_variant in pairs(input_variants) do
            it(input_variant, function()
                local request = {
                    schemaMetadataInfo = {
                        properties = {EXCLUDED_CAPABILITIES = input_variant}
                    }
                }
                local expected_capabilities = {}
                for _, capability_name in ipairs(adapter_capabilities) do
                    if not text.starts_with(capability_name, "AGGREGATE") then
                        table.insert(expected_capabilities, capability_name)
                    end
                end
                local expected = {type = "getCapabilities", capabilities = expected_capabilities}
                assert.is(expected, adapter:get_capabilities(request))
            end)
        end
    end)
end)