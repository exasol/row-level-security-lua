local luaunit = require("luaunit")
local mockagne = require("mockagne")
local metadata_reader_mock = mockagne.getMock()
package.preload["exasolrls.metadata_reader"] = function () return metadata_reader_mock end
local text = require("text")
local adapter_capabilities = require("exasolrls.adapter_capabilities")
local adapter = require("exasolrls.rls_adapter")

test_rls_adapter = {}

local function get_project_base_path()
    local fullpath = debug.getinfo(1,"S").source:sub(2)
    return fullpath:gsub("/[^/]*$", "") .. "/../../../.."
end

local function get_pom_path()
    return get_project_base_path() .. "/pom.xml"
end

local function get_pom_version(pom_path)
    local pom = assert(io.open(pom_path, "r"))
    local pom_version
    repeat
        local line = pom:read("*l")
        pom_version = string.match(line,"<version>%s*([0-9.]+)")
    until pom_version or (line == nil)
    pom:close()
    return pom_version
end

function test_rls_adapter.test_version_matches_maven_pom()
    local pom_path = get_pom_path()
    luaunit.assertEquals(adapter.VERSION, get_pom_version(pom_path))
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
    local request = {}
    local expected = {type = "getCapabilities", capabilities = adapter_capabilities}
    local actual = adapter.get_capabilities(nil, request)
    luaunit.assertEquals(actual, expected)
end

function test_rls_adapter.test_get_capabilites_while_excluding_capabilities()
    local input_variants = {
        "AGGREGATE_GROUP_BY_COLUMN,AGGREGATE_GROUP_BY_TUPLE,AGGREGATE_HAVING, AGGREGATE_SINGLE_GROUP",
        "AGGREGATE_GROUP_BY_COLUMN, AGGREGATE_GROUP_BY_TUPLE, AGGREGATE_HAVING, AGGREGATE_SINGLE_GROUP",
        " AGGREGATE_GROUP_BY_COLUMN, AGGREGATE_GROUP_BY_TUPLE, AGGREGATE_HAVING, AGGREGATE_SINGLE_GROUP, ",
        "AGGREGATE_GROUP_BY_COLUMN,  AGGREGATE_GROUP_BY_TUPLE  , AGGREGATE_HAVING, AGGREGATE_SINGLE_GROUP",
        ",AGGREGATE_GROUP_BY_COLUMN, , AGGREGATE_GROUP_BY_TUPLE,, AGGREGATE_HAVING, AGGREGATE_SINGLE_GROUP",
    }
    for _, input_variant in pairs(input_variants) do
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
        local actual = adapter.get_capabilities(nil, request)
        luaunit.assertEquals(actual, expected)
    end
end

os.exit(luaunit.LuaUnit.run())
