renderer = require("exasolvs.query_renderer")

local M  = {}

local function validate(query)
    if(query == nil) then
        error("E-QR-1: Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        error('E-QR-2: Unable to rewrite push-down request of type "' .. push_down_type
                .. '". Only SELECT is supported.')
    end
end

---
-- Rewrite the original query with RLS restrictions.
-- 
-- @param original_query structure containing the original push-down query
-- 
-- @return string containing the rewritten query
-- 
function M.rewrite(original_query)
    validate(original_query)
    local query = original_query
    -- TODO: Rewrite by adding structure elements here.
    return renderer.new(query).render()
end

return M