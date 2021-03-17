local luaunit = require("luaunit")
local mockagne = require("mockagne")
local log = require("remotelog")
log.set_level("TRACE")

local when, any = mockagne.when, mockagne.any

_G.test_query_rewriter = {}

function test_query_rewriter:setUp()
    self.user = mockagne.getMock()
    package.preload["exasolrls.user_information"] = function() return self.user end
    self.rewriter = require("exasolrls.query_rewriter")
end

function test_query_rewriter.tearDown()
    package.loaded["exasolrls.user_information"] = nil
    package.loaded["exasolrls.query_rewriter"] = nil
end

function test_query_rewriter:assert_rewrite(original_query, source_schema, adapter_cache, expected)
    local rewritten_query = self.rewriter.rewrite(original_query, source_schema, adapter_cache)
    luaunit.assertEquals(rewritten_query, expected)
end

function test_query_rewriter:test_unprotected_table()
    when(self.user.get_groups(any())).thenAnswer({})
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "UNPROT"},
            {type = "column", name = "C2", tableName = "UNPROT"}
        },
        from = {type  = "table", name = "UNPROT"}
    }
    self:assert_rewrite(original_query, "S", "UNPROT:---", 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "S"."UNPROT"')
end

function test_query_rewriter:test_tenant_protected_table()
    when(self.user.get_groups(any())).thenAnswer({})
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:t--",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE ("PROT"."EXA_ROW_TENANT" = CURRENT_USER)')
end

function test_query_rewriter:test_group_protected_table_with_multiple_groups()
    when(self.user.get_groups(any())).thenAnswer({"G1", "G2"})
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:-g-",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE ("PROT"."EXA_ROW_GROUP" IN (\'G1\', \'G2\'))')
end

function test_query_rewriter:test_group_protected_table_with_single_group()
    when(self.user.get_groups(any())).thenAnswer({"G1"})
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:-g-",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE ("PROT"."EXA_ROW_GROUP" = \'G1\')')
end

function test_query_rewriter:test_tenant_plus_group_protected_table()
    when(self.user.get_groups(any())).thenAnswer({"G1", "G2"})
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:tg-",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER) '
        .. 'OR ("PROT"."EXA_ROW_GROUP" IN (\'G1\', \'G2\')))')
end

function test_query_rewriter:test_role_protected_table()
    when(self.user.get_role_mask(any())).thenAnswer(5)
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:--r",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (BIT_AND("PROT"."EXA_ROW_ROLES", BIT_SET(5, 63)) <> 0)')
end

function test_query_rewriter:test_tenant_plus_role_protected_table()
    when(self.user.get_role_mask(any())).thenAnswer(13)
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "PROT"},
        },
        from = {type  = "table", name = "PROT"}
    }
    self:assert_rewrite(original_query, "S", "PROT:t-r",
        'SELECT "PROT"."C1" FROM "S"."PROT" WHERE (("PROT"."EXA_ROW_TENANT" = CURRENT_USER)'
            ..' OR (BIT_AND("PROT"."EXA_ROW_ROLES", BIT_SET(13, 63)) <> 0))')
end

os.exit(luaunit.LuaUnit.run())
