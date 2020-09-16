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
    --local sql = 'SELECT "EXA_RLS_GROUP" FROM "' .. source_schema_id .. '"."EXA_GROUP_MEMBERS" WHERE "EXA_RLS_USER" = CURRENT_USER'
    local sql = 'SELECT "EXA_RLS_GROUP" FROM VALUES (\'G1\')'
    --local sql = 'SELECT \'G1\' FROM "EXA_GROUP_MEMBERS"'
    log.trace("Determining user groups with: %s", sql)
    local ok, result = exa.pquery(sql)
    if(ok) then
        for i = 1, #result do
            groups[i] = result[i][1]
        end
        log.debug("Current user is a member of %d RLS groups.", #groups)
    else
        log.warn("W-USI-1: Unable to determine group membership of current user. Cause: %s", result)
    end
    return groups
end

return M;
