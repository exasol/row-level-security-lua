local luaunit = require("luaunit")
local rewriter = require("exasolrls.query_rewriter")

test_query_rewriter = {}

function assert_rewrite(original_query, expected)
    luaunit.assertEquals(rewriter.rewrite(original_query), expected)
end

function test_query_rewriter.test_unprotected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "UNPROT"},
            {type = "column", name = "C2", tableName = "UNPROT"}
        },
        from = { type  = "table", name = "UNPROT"}
    }
    assert_rewrite(original_query, 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "UNPROT"')
end

function test_query_rewriter.test_tenant_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = { type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, 'SELECT "PROT"."C1" FROM "PROT" WHERE ("PROT"."EXA_ROW_TENANT" = CURRENT_USER())')
end

os.exit(luaunit.LuaUnit.run())