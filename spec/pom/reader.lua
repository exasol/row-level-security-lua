---
-- @module This module reads information from a Maven POM
--

local function get_project_base_path()
    local fullpath = debug.getinfo(1,"S").source:sub(2)
    return fullpath:gsub("/[^/]*$", "") .. "/../.."
end

local function get_pom_path()
    return get_project_base_path() .. "/pom.xml"
end

local M = {
    pom_path = get_pom_path()
}

function M.get_version()
    local pom = assert(io.open(M.pom_path, "r"))
    local pom_version
    repeat
        local line = pom:read("*l")
        pom_version = string.match(line,"<version>%s*([0-9.]+)")
    until pom_version or (line == nil)
    pom:close()
    return pom_version
end

return M
