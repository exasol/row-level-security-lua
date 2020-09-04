local log = require("remotelog")

local M = {}

---
-- Get the RLS groups the current database user is a member of.
--
-- @param source_schema_id name of the source schema protected by RLS and schema where the configuration resides
--
-- @return list of groups
--
function M.get_groups(source_schema_id)
    local groups = {}
    local ok, result = exa.pquery('SELECT "EXA_GROUP" FROM "' .. source_schema_id .. "' WHERE EXA_USER = CURRENT_USER")
    if(ok) then
        for i = 1, #result do
            groups[i] = result[i][1]
        end
    else
    end
    log.debug("Current user is a member of %d groups.", #groups)
    return groups
end

return M;
