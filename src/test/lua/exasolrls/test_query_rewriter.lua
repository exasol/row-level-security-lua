local luaunit = require("luaunit")
local rewriter = require("exasolrls.query_rewriter")

_G.test_query_rewriter = {}

local function assert_rewrite(original_query, source_schema, adapter_cache, expected)
    local rewritten_query = rewriter.rewrite(original_query, source_schema, adapter_cache)
    luaunit.assertEquals(rewritten_query, expected)
end

function test_query_rewriter.test_unprotected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "UNPROT"},
            {type = "column", name = "C2", tableName = "UNPROT"}
        },
        from = {type  = "table", name = "UNPROT"}
    }
    assert_rewrite(original_query, "S", "UNPROT:---", 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "S"."UNPROT"')
end

function test_query_rewriter.test_tenant_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, "S", "PROT:t--",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE ("PROT"."EXA_ROW_TENANT" = CURRENT_USER)')
end

function test_query_rewriter.test_group_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, "S", "PROT:-g-",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE EXISTS('
        .. 'SELECT 1 FROM "S"."EXA_GROUP_MEMBERS" WHERE (("EXA_GROUP_MEMBERS"."EXA_GROUP" = "PROT"."EXA_ROW_GROUP")'
        .. ' AND ("EXA_GROUP_MEMBERS"."EXA_USER_NAME" = CURRENT_USER)))')
end

function test_query_rewriter.test_tenant_plus_group_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, "S", "PROT:tg-",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER) '
        .. 'OR EXISTS('
        .. 'SELECT 1 FROM "S"."EXA_GROUP_MEMBERS" WHERE (("EXA_GROUP_MEMBERS"."EXA_GROUP" = "PROT"."EXA_ROW_GROUP")'
        .. ' AND ("EXA_GROUP_MEMBERS"."EXA_USER_NAME" = CURRENT_USER))))')
end

function test_query_rewriter.test_role_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, "S", "PROT:--r",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (BIT_CHECK("PROT"."EXA_ROW_ROLES", 63)'
        .. ' OR EXISTS('
        .. 'SELECT 1 FROM "S"."EXA_RLS_USERS"'
        .. ' WHERE (("EXA_RLS_USERS"."EXA_USER_NAME" = CURRENT_USER)'
        .. ' AND (BIT_AND("PROT"."EXA_ROW_ROLES", "EXA_RLS_USERS"."EXA_ROLE_MASK") <> 0))))')
end

function test_query_rewriter.test_tenant_plus_role_protected_table()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    assert_rewrite(original_query, "S", "PROT:t-r",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER)'
            ..' OR BIT_CHECK("PROT"."EXA_ROW_ROLES", 63)'
            ..' OR EXISTS('
        .. 'SELECT 1 FROM "S"."EXA_RLS_USERS"'
        .. ' WHERE (("EXA_RLS_USERS"."EXA_USER_NAME" = CURRENT_USER)'
        .. ' AND (BIT_AND("PROT"."EXA_ROW_ROLES", "EXA_RLS_USERS"."EXA_ROLE_MASK") <> 0))))')
end

function test_query_rewriter.test_combination_of_group_and_role_security_raises_error()
    for _, protection in ipairs({"-gr", "tgr"}) do
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "T1"},
            },
            from = {type  = "table", name = "T1"}
        }
        luaunit.assertErrorMsgContains("Unsupported combination of protection methods on the same table 'S1'.'T1'",
            rewriter.rewrite, original_query, "S1", "T1:" .. protection)
    end
end

function test_query_rewriter.test_rewriting_nil_query_raises_error()
    luaunit.assertErrorMsgContains("Unable to rewrite query because it was <nil>.", rewriter.rewrite, nil, nil, nil)
end

function test_query_rewriter.test_rewriting_non_select_request_raises_error()
    local original_query = {type = "insert"}
    luaunit.assertErrorMsgContains("Unable to rewrite push-down query of type 'insert'. Only 'select' is supported.",
        rewriter.rewrite, original_query)
end

function test_query_rewriter.test_unsupported_protection_scheme_raises_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "T"},
        },
        from = {type  = "table", name = "T"}
    }
    luaunit.assertErrorMsgContains("Unsupported combination of protection methods on the same table 'S'.'T':"
        .. " tenant + group + role",
        rewriter.rewrite, original_query, "S", "T:tgr")
end

os.exit(luaunit.LuaUnit.run())
