renderer = require("exasolvs.query_renderer")

local M  = {}

function M.rewrite(original_query)
    local query = original_query
    renderer.new(query).render()
end


return M