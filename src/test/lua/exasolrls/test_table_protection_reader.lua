local luaunit = require("luaunit")
local reader = require("exasolrls.table_protection_reader")

test_table_protection_cache_reader = {}

function test_table_protection_cache_reader.test_read_unprotected()
    local status = reader.read("A:---", "A")
    luaunit.assertEquals(status, {protected = false, tenant_protected = false, group_protected = false,
        role_protected = false})
end

function test_table_protection_cache_reader.test_read_tenant_protected()
    local status = reader.read("B:t--", "B")
    luaunit.assertEquals(status, {protected = true, tenant_protected = true, group_protected = false,
        role_protected = false})
end

function test_table_protection_cache_reader.test_read_group_protected()
    local status = reader.read("C:-g-", "C")
    luaunit.assertEquals(status, {protected = true, tenant_protected = false, group_protected = true,
        role_protected = false})
end

function test_table_protection_cache_reader.test_read_tenant_and_group_protected()
    local status = reader.read("D:tg-", "D")
    luaunit.assertEquals(status, {protected = true, tenant_protected = true, group_protected = true,
        role_protected = false})
end

function test_table_protection_cache_reader.test_read_role_protected()
    local status = reader.read("E:--r", "E")
    luaunit.assertEquals(status, {protected = true, tenant_protected = false, group_protected = false,
        role_protected = true})
end

function test_table_protection_cache_reader.test_read_find_table()
    local status = reader.read("A:---,B:t--,C:-g-,D:tg-", "D")
    luaunit.assertEquals(status, {protected = true, tenant_protected = true, group_protected = true,
        role_protected = false})
end

function test_table_protection_cache_reader.test_read_throws_error_when_table_not_found()
    luaunit.assertErrorMsgContains('Could not find table protection cache entry for table "X"',
        function () reader.read("A:---,B:t--,C:-g-,D:tg-", "X") end)
end

os.exit(luaunit.LuaUnit.run())