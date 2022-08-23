--- This class implements a basic reader for information in a Maven projects POM file.
-- @classmod Reader
local Reader = {
    _artifact_version = nil,
    _artifact_id = nil
}

Reader.__index = Reader

--- Create a new instance of a `PomReader`.
-- @string path path to the POM file
-- @return new instance
function Reader:new(path)
    assert(path ~= nil, "Path to POM file must be given.")
    local instance = setmetatable({}, self)
    instance:_init(path)
    return instance
end

function Reader:_init(path)
    local pom = assert(io.open(path, "r"), "Failed to open POM: " .. path)
    repeat
        local line = pom:read("*l")
        self._artifact_version = string.match(line,"<version>%s*([0-9.]+)") or self._artifact_version
        self._artifact_id = string.match(line,"<artifactId>%s*([-.%w]+)") or self._artifact_id
    until (self._artifact_id and self._artifact_version) or (line == nil)
    pom:close()
end

--- Get the artifact version.
-- @return version of the Maven artifact
function Reader:get_artifact_version()
    return self._artifact_version
end

--- Get the artifact ID.
-- ID of the Maven artifact
function Reader:get_artifact_id()
    return self._artifact_id
end

return Reader
