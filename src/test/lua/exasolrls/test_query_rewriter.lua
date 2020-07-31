local luaunit = require("luaunit")
local rewriter = require("exasolrls.query_rewriter")

test_query_rewriter = {}

function test_query_rewriter.test_unprotected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "UNPROT"},
            {type = "column", name = "C2", tableName = "UNPROT"}
        },
        from = { type  = "table", name = "UNPROT"}}
    luaunit.assertEquals(rewriter.rewrite(original_query), 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "UNPROT"');
end

os.exit(luaunit.LuaUnit.run())