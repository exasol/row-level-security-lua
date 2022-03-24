local exaerror = require("exaerror")

--- This class decodes the table protection information as cached in the adapter notes.
--
-- @type TableProtectionReader
--
local TableProtectionReader = {}

---
-- Read table protection status from the adapter cache.
--
-- @param adapter_cache string representing the projection status of source tables
--
-- @param table_id name of the table for which we want to know the protection status
--
-- @return Lua table containing one entry per database table that lists the protection details
--
function TableProtectionReader.read(adapter_cache, table_id)
    for table_protection_cache in string.gmatch(adapter_cache, "[^,]+") do
        local colon_index = string.find(table_protection_cache, ":", 1, true)
        local extracted_table_id = string.sub(table_protection_cache, 1, colon_index - 1)
        if extracted_table_id == table_id then
            local protection_tags =
            string.sub(table_protection_cache, colon_index + 1, string.len(table_protection_cache))
            local tenant_protected = string.find(protection_tags, "t", 1, true) and true or false
            local group_protected = string.find(protection_tags, "g", 1, true) and true or false
            local role_protected = string.find(protection_tags, "r", 1, true) and true or false
            return {
                protected = tenant_protected or group_protected or role_protected,
                tenant_protected = tenant_protected,
                group_protected = group_protected,
                role_protected = role_protected
            }
        end
    end
    exaerror.create("E-RLSL-TPR-1", "Unable to determine the RLS protection type for table {{table}}."
        .. " No matching cache entry found.", {table = table_id})
        :add_ticket_mitigation()
        :raise()
end

return TableProtectionReader;
