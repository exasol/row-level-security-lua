rockspec_format = "3.0"

local tag = "1.2.0"
local project = "row-level-security-lua"
local src = "src/main/lua"

package = project
version = tag .. "-1"

source = {
    url = "git://github.com/exasol/" .. project,
    tag = tag
}

description = {
    summary = "Row-level security implementation based on Exasol's Virtual Schemas for Lua",
    detailed = [[This project adds a Virtual Schema (a concept closely related to a database view) on top of an existing
    Exasol database schema, makes it read-only and adds access controls on a per-row level.]],
    homepage = "https://github.com/exasol/" .. project,
    license = "MIT",
    maintainer = 'Exasol <opensource@exasol.com>'
}

dependencies = {
    "virtual-schema-common-lua = 2.0.0"
}

build_dependencies = {
    "amalg"
}

test_dependencies = {
    "busted >= 2.0.0",
    "luacheck >= 0.25.0",
    "luacov >= 0.15.0",
    "luacov-coveralls >= 0.2.3"
}

test = {
    type = "busted"
}

local package_items = {
    "exasolrls.adapter_capabilities", "exasolrls.RlsAdapterProperties", "exasolrls.RlsAdapter",
    "exasolrls.MetadataReader", "exasolrls.TableProtectionReader", "exasolrls.QueryRewriter", "remotelog", "exaerror",
    "message_expander",
    -- from virtual-schema-common-lua"
    "exasolvs.AbstractVirtualSchemaAdapter", "exasolvs.AdapterProperties", "exasolvs.RequestDispatcher",
    "exasolvs.Query", "exasolvs.QueryRenderer",
    "exasolvs.queryrenderer.AbstractQueryAppender", "exasolvs.queryrenderer.ExpressionAppender",
    "exasolvs.queryrenderer.ScalarFunctionAppender", "exasolvs.queryrenderer.SelectAppender",
    "text"
}

local item_path_list = ""
for i = 1, #package_items do
    item_path_list = item_path_list .. " " .. package_items[i]
end

build = {
    type = "command",
    build_command = "cd " .. src .. " && amalg.lua "
            .. "-o ../../../target/row-level-security-dist-" .. tag .. ".lua "
            .. "-s entry.lua"
            .. item_path_list
}