local luaunit = require("luaunit")
local mockagne = require("mockagne")
local user = require("exasolrls.user_information")
local when, any = mockagne.when, mockagne.any

test_user_information = {}

function test_user_information:setUp()
    self.exa = mockagne.getMock()
    _G.exa = self.exa
end

function test_user_information:tearDwon()
    self.exa = nil
    _G.exa = nil
end

function test_user_information:test_get_groups()
    when(self.exa.pquery(any())).thenAnswer(true, {{"G1"}, {"G2"}})
    local source_schema_id = "S"
    local groups = user.get_groups(source_schema_id);
    luaunit.assertEquals(groups, {"G1", "G2"})
end

function test_user_information:test_get_groups_falls_back_if_groups_cannot_be_determined()
    when(self.exa.pquery(any())).thenAnswer(false, "<error message>")
    local source_schema_id = "S"
    local groups = user.get_groups(source_schema_id);
    luaunit.assertEquals(groups, {})
end

function test_user_information:test_get_role_mask()
    when(self.exa.pquery(any())).thenAnswer(true, {{7}})
    local source_schema_id = "S"
    local role_mask = user.get_role_mask(source_schema_id);
    luaunit.assertEquals(role_mask, 7)
end

function test_user_information:test_get_role_mask_falls_back_if_groups_cannot_be_determined()
    when(self.exa.pquery(any())).thenAnswer(false, "<error message>")
    local source_schema_id = "S"
    local role_mask = user.get_role_mask(source_schema_id);
    luaunit.assertEquals(role_mask, 0)
end

os.exit(luaunit.LuaUnit.run())
