package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
require("entry")

describe("Entry script", function()
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

    _G.exa = create_exasol_context_stub()

    it("handles an adapter call to drop the virtual schema", function()
        local result = _G.adapter_call([[{"type" : "dropVirtualSchema"}]])
        assert.are.equal([[{"type":"dropVirtualSchema"}]], result)
    end)

    it("handles an adapter call to create the virtual schema", function()
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