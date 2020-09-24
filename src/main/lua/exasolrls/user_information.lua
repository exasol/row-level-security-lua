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
    local sql = 'SELECT "EXA_RLS_GROUP" FROM "' .. source_schema_id
        .. '"."EXA_GROUP_MEMBERS" WHERE "EXA_RLS_USER_NAME" = CURRENT_USER'
    local ok, result = _G.exa.pquery(sql)
    if ok then
        for i = 1, #result do
            groups[i] = result[i][1]
        end
        log.debug("Current user is a member of %d RLS groups.", #groups)
    else
        log.warn("W-RLS-USI-1: Unable to determine RLS group membership of current user. Cause: %s", result)
    end
    return groups
end

---
-- Get the bit mask that represents the user's RLS roles.
-- @param source_schema_id name of the source schema protected by RLS and schema where the configuration resides
--
-- @return role bit mask
--
function M.get_role_mask(source_schema_id)
    local sql = 'SELECT "EXA_ROLE_MASK" FROM "' .. source_schema_id
        .. '"."EXA_RLS_USERS" WHERE "EXA_USER_NAME" = CURRENT_USER'
    log.debug("Reading user's role mask: " .. sql)
    local ok, result = _G.exa.pquery(sql)
    if ok then
        return result[1][1] or 0
    else
        log.warn("W-RLS-USI-2: Unable to determine the current user's RLS roles. Cause: %s", result)
        return 0;
    end
end

return M;
