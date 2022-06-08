package.path = "target/?.lua;" .. package.path
require("busted.runner")()

local pom = require("spec.pom.reader")

local VERSION <const> = pom.get_version()
local PROJECT <const> = "row-level-security"
local DISTRIBUTION_MODULE <const> = PROJECT .. "-dist"
local DISTRIBUTION_PATH = "target"


local function load_distribution()
    local filename = DISTRIBUTION_MODULE .. "-" .. VERSION .. ".lua"
    local path = DISTRIBUTION_PATH .. "/" .. filename
    print("Loading distribution module from " .. path)
    local file <close> = io.open(path, "rb")
    if file then
        local content = assert(file:read("*a"))
        load(content, DISTRIBUTION_MODULE)()
        return true
    else
        return false
    end
end

if load_distribution() then
    describe("Distribution (smoke test)", function()
        it("handles an adapter call to drop the virtual schema", function()
            local result = _G.adapter_call([[{"type" : "dropVirtualSchema"}]])
            assert.are.equal([[{"type":"dropVirtualSchema"}]], result)
        end)

        local function create_exasol_context_stub()
            return {
                pquery_no_preprocessing = function(query)
                    if string.find(query, "EXA_ALL_TABLES", 1, true) then
                        return true, {{TABLE_NAME = "T"}}
                    else
                        return true, {{COLUMN_NAME = "C", COLUMN_TYPE = "BOOLEAN"}}
                    end
                end
            }
        end

        it("handles an adapter call to create the virtual schema", function()
            _G.exa = create_exasol_context_stub()
            local result = _G.adapter_call(
                    [[{"type" : "createVirtualSchema",
                         "schemaMetadataInfo" : {
                            "properties" : {"SCHEMA_NAME" : "S"}
                         }
                    }]])
            _G.exa = nil
            assert.are.matches('"type" *: *"createVirtualSchema"', result)
        end)
    end)
else
    print("Skipped smoke test because distribution file does not exist (yet). Please build first.")
end
