package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local reader = require("exasolrls.TableProtectionReader")

describe("table_protection_reader", function()
    it("interprets that a table is unprotected", function()
        assert.are.same({protected = false, tenant_protected = false, group_protected = false, role_protected = false},
                reader.read("A:---", "A"))
    end)

    it("interprets that a table is tenant-protected", function()
        assert.are.same({protected = true, tenant_protected = true, group_protected = false, role_protected = false},
                reader.read("B:t--", "B"))
    end)

    it("interprets that a table is group-protected", function()
        assert.are.same({protected = true, tenant_protected = false, group_protected = true, role_protected = false},
                reader.read("C:-g-", "C"))
    end)

    it("interprets that a table is tenant-protected and group-protected", function()
        assert.are.same({protected = true, tenant_protected = true, group_protected = true, role_protected = false},
                reader.read("D:tg-", "D"))
    end)

    it("interprets that a table is role-protected", function()
        assert.are.same({protected = true, tenant_protected = false, group_protected = false, role_protected = true},
                reader.read("E:--r", "E"))
    end)

    it("finds a table protection definition in a group of definitions", function()
        assert.are.same({protected = true, tenant_protected = true, group_protected = true, role_protected = false},
                reader.read("A:---,B:t--,C:-g-,D:tg-", "D"))
    end)

    it("throws an error when asked for a table for which no protection definition exists", function()
        assert.error_matches(function () reader.read("A:---,B:t--,C:-g-,D:tg-", "X") end,
            "Unable to determine the RLS protection type for table 'X'", 1, true)
    end)
end)