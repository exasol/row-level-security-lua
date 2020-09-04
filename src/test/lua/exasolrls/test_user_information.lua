local luaunit = require("luaunit")
local mockagne = require("mockagne")
local user = require("exasolrls.user_information")
local when, any = mockagne.when, mockagne.any

test_user_information = {}

function test_user_information.test_get_groups()
    local exa = mockagne.getMock()
    when(exa.pquery(any())).thenAnswer(true, {{"G1"}, {"G2"}})
    _G.exa = exa
    local source_schema_id = "S"
    local groups = user.get_groups(source_schema_id);
    luaunit.assertEquals(groups, {"G1", "G2"})
end

os.exit(luaunit.LuaUnit.run())
