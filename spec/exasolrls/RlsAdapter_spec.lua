package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local assert = require("luassert")
local mockagne = require("mockagne")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local RlsAdapter = require("exasolrls.RlsAdapter")
require("exasolrls.RlsAdapterProperties")
local pom = require("spec.pom.reader")

describe("RlsAdapter", function()
    local adapter
    local metadata_reader_mock
    local properties_stub

    before_each(function()
        metadata_reader_mock = mockagne.getMock()
        adapter = RlsAdapter:new(metadata_reader_mock)
        properties_stub = {
            get_table_filter = function() return {} end,
            has_excluded_capabilities = function() return false end
        }
    end)

    it("has the same version number as the project in the Maven POM file", function()
        assert.are.equal(pom.get_version(), adapter:get_version())
    end)

    it("reports the name of the adapter", function()
        assert.are.equal("Row-level Security adapter (Lua)", adapter:get_name())
    end)

    it("answers a request to create the Virtual Schema with the metadata of the source schema", function()
        local schema_metadata = {
            tables = {
                {type = "table", name = "T1", columns = {{name = "C1", dataType = {type = "BOOLEAN"}}}}
            }
        }
        mockagne.when(metadata_reader_mock:read("S", {})).thenAnswer(schema_metadata)
        local expected = {type = "createVirtualSchema",
                          schemaMetadata = schema_metadata}
        local request = {schemaMetadataInfo = {name = "V"}}
        properties_stub.validate = function()  end
        properties_stub.get_schema_name = function() return "S" end
        local actual = adapter:create_virtual_schema(request, properties_stub)
        assert.are.same(expected, actual)
    end)

    it("confirms a request to drop the Virtual Schema with an empty response", function()
        assert.are.same({type = "dropVirtualSchema"}, adapter:drop_virtual_schema())
    end)

    it("reports the supported capabilities", function()
        local request = {}
        local expected = {type = "getCapabilities", capabilities = adapter_capabilities}
        local actual = adapter:get_capabilities(request, properties_stub)
        assert.are.same(expected, actual)
    end)

    it("raises an error if the SCHEMA parameter is missing when trying to create a Virtual Schema", function()
        properties_stub.validate = function() error("validation failed") end
        local request = {schemaMetadataInfo = {name = "V"}}
        assert.error_matches(function() adapter:create_virtual_schema(request, properties_stub) end, "validation failed")
    end)
end)