local luaunit = require("luaunit")
local rewriter = require("exasolrls.query_rewriter")

test_query_rewriter = {}

function test_query_rewriter.test_unprotected_table()
    local original_query = {type = "select",
            selectList = {{type = "column", name = "C1"}, {type = "column", name = "C2"}},
            from = { type  = "table", name = "UNPROTECTED_TABLE"}}
    luaunit.assertEquals(rewriter.rewrite(), "SELECT C1, C2 FROM UNPROTECTED_TABLE");
end

os.exit(luaunit.LuaUnit.run())