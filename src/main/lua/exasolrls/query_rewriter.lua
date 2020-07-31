renderer = require("exasolvs.query_renderer")

local M  = {}
---
-- Rewrite the original query with RLS restrictions.
-- 
-- @param original_query structure containing the original push-down query
-- 
-- @return string containing the rewritten query
-- 
function M.rewrite(original_query)
    local query = original_query
    return renderer.new(query).render()
end

return M