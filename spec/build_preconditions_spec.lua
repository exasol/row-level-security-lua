package.path = "spec/?.lua;" .. package.path
require("busted.runner")()
local Reader = require("pom.Reader")

local function get_project_base_path()
    return debug.getinfo(1,"S").source:sub(2):gsub("[^/]*$", "") .. ".."
end

local reader = Reader:new(get_project_base_path() .. "/pom.xml")

local function load_rockspec(path)
    local env = {}
    local rockspec_function = assert(loadfile(path, "t", env))
    rockspec_function()
    return env
end

local function get_rockspec_path() --
    return get_project_base_path() .. "/"
            .. (string.format("%s-%s-1.rockspec", reader:get_artifact_id(), reader:get_artifact_version()))
end

local rockspec = load_rockspec(get_rockspec_path())

describe("Build precondition", function()
    describe("Rockspec file", function()
        it("has correct filename", function()
            local rockspec_path = get_rockspec_path()
            local file = io.open(rockspec_path, "r")
            finally(function()
                if file then file:close() end
            end)
            assert(file, "Expected rockspec to have filename " .. rockspec_path .. " but file not found.")
        end)

        describe("version field", function()
            it("is of type string", function()
                assert.is.same("string", type(rockspec.version))
            end)

            it("starts with the same version number as the main artifact in the Maven POM file", function()
                assert.matches(reader:get_artifact_version() .. "%-%d+", rockspec.version)
            end)
        end)
    end)
end)