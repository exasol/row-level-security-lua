package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local rewriter = require("exasolrls.QueryRewriter")

describe("Query rewriter", function()
    local function assert_rewrite(original_query, source_schema, adapter_cache, expected)
        local rewritten_query = rewriter.rewrite(original_query, source_schema, adapter_cache)
        assert.is(expected, rewritten_query)
    end

    it("rewrites a query with an unprotected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "UNPROT"},
                {type = "column", name = "C2", tableName = "UNPROT"}
            },
            from = {type = "table", name = "UNPROT"}
        }
        assert_rewrite(original_query, "S", "UNPROT:---", 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "S"."UNPROT"')
    end)

    it("rewrites a query with a tenant-protected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "PROT"},
            },
            from = {type = "table", name = "PROT"}
        }
        assert_rewrite(original_query, "S", "PROT:t--",
                'SELECT "PROT"."C1" FROM "S"."PROT" WHERE ("PROT"."EXA_ROW_TENANT" = CURRENT_USER)')
    end)

    it("rewrites a query with a group-protected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "PROT"},
            },
            from = {type = "table", name = "PROT"}
        }
        assert_rewrite(original_query, "S", "PROT:-g-",
                'SELECT "PROT"."C1" FROM "S"."PROT" WHERE EXISTS('
                        .. 'SELECT 1 FROM "S"."EXA_GROUP_MEMBERS" '
                        .. 'WHERE (("EXA_GROUP_MEMBERS"."EXA_GROUP" = "PROT"."EXA_ROW_GROUP")'
                        .. ' AND ("EXA_GROUP_MEMBERS"."EXA_USER_NAME" = CURRENT_USER)))')
    end)

    it("rewrites a query with a table that is both tenant-protected and group-protected at the same time", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "PROT"},
            },
            from = {type = "table", name = "PROT"}
        }
        assert_rewrite(original_query, "S", "PROT:tg-",
                'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER) '
                        .. 'OR EXISTS('
                        .. 'SELECT 1 FROM "S"."EXA_GROUP_MEMBERS"'
                        .. ' WHERE (("EXA_GROUP_MEMBERS"."EXA_GROUP" = "PROT"."EXA_ROW_GROUP")'
                        .. ' AND ("EXA_GROUP_MEMBERS"."EXA_USER_NAME" = CURRENT_USER))))')
    end)

    it("rewrites a query with a role-protected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "PROT"},
            },
            from = {type = "table", name = "PROT"}
        }
        assert_rewrite(original_query, "S", "PROT:--r",
                'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (BIT_CHECK("PROT"."EXA_ROW_ROLES", 63)'
                        .. ' OR EXISTS('
                        .. 'SELECT 1 FROM "S"."EXA_RLS_USERS"'
                        .. ' WHERE (("EXA_RLS_USERS"."EXA_USER_NAME" = CURRENT_USER)'
                        .. ' AND (BIT_AND("PROT"."EXA_ROW_ROLES", "EXA_RLS_USERS"."EXA_ROLE_MASK") <> 0))))')
    end)

    it("rewrites a query with a table that is both tenant-protected and role-protected at the same time", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "PROT"},
            },
            from = {type = "table", name = "PROT"}
        }
        assert_rewrite(original_query, "S", "PROT:t-r",
                'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER)'
                        .. ' OR BIT_CHECK("PROT"."EXA_ROW_ROLES", 63)'
                        .. ' OR EXISTS('
                        .. 'SELECT 1 FROM "S"."EXA_RLS_USERS"'
                        .. ' WHERE (("EXA_RLS_USERS"."EXA_USER_NAME" = CURRENT_USER)'
                        .. ' AND (BIT_AND("PROT"."EXA_ROW_ROLES", "EXA_RLS_USERS"."EXA_ROLE_MASK") <> 0))))')
    end)

    it("raises an error if group-protection and role-protection are combined on the same table", function()
        for _, protection in ipairs({"-gr", "tgr"}) do
            local original_query = {
                type = "select",
                selectList = {
                    {type = "column", name = "C1", tableName = "T1"},
                },
                from = {type = "table", name = "T1"}
            }
            assert.error_matches(function()
                rewriter.rewrite(original_query, "S1", "T1:" .. protection)
            end,
                    "Unsupported combination of protection methods on the same table 'S1'.'T1'", 1, true)
        end
    end)

    it("raises an error if the query to be rewritten is nil.", function()
        assert.error_matches(function()
            rewriter.rewrite(nil, nil, nil)
        end,
                "Unable to rewrite query because it was <nil>.", 1, true)
    end)

    it("raises an error if the query to be rewritten is not a SELECT", function()
        local original_query = {type = "insert"}
        assert.error_matches(function()
            rewriter.rewrite(original_query)
        end,
                "Unable to rewrite push-down query of type 'insert'. Only 'select' is supported.", 1, true)
    end)

    it("raises an error if the protection scheme is unknown", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "T"},
            },
            from = {type = "table", name = "T"}
        }
        assert.error_matches(function()
            rewriter.rewrite(original_query, "S", "T:tgr")
        end,
                "Unsupported combination of protection methods on the same table 'S'.'T': 'tenant + group + role'",
                1, true)
    end)
end)