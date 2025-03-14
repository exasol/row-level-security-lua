rockspec_format = "3.0"

local tag = "1.5.7"
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
    "exasol-virtual-schema-common-lua = 1.0.2"
}

build_dependencies = {
    "amalg"
}

test_dependencies = {
    "busted >= 2.2.0-1",
    "luacheck >= 1.2.0-1",
    "luacov >= 0.16.0-1",
    "luacov-coveralls >= 0.2.3-1"
}

test = {
    type = "busted"
}

local package_items = {
    "exasol.rls.adapter_capabilities", "exasol.rls.RlsAdapter",
    "exasol.rls.RlsMetadataReader", "exasol.rls.TableProtectionReader", "exasol.rls.RlsQueryRewriter",
    "remotelog", "ExaError", "MessageExpander",
    -- from virtual-schema-common-lua"
    "exasol.vscl.AbstractVirtualSchemaAdapter", "exasol.vscl.AdapterProperties", "exasol.vscl.RequestDispatcher",
    "exasol.vscl.Query", "exasol.vscl.QueryRenderer",
    "exasol.vscl.queryrenderer.AbstractQueryAppender", "exasol.vscl.queryrenderer.AggregateFunctionAppender",
    "exasol.vscl.queryrenderer.ExpressionAppender", "exasol.vscl.queryrenderer.ImportAppender",
    "exasol.vscl.queryrenderer.ScalarFunctionAppender", "exasol.vscl.queryrenderer.SelectAppender",
    "exasol.vscl.text", "exasol.vscl.validator",
    -- from exasol-virtual-schema-common-lua
    "exasol.evscl.AbstractMetadataReader", "exasol.evscl.AbstractQueryRewriter",
    "exasol.evscl.ExasolBaseAdapterProperties", "exasol.evscl.LocalMetadataReader",
    "exasol.evscl.LocalQueryRewriter"
}

local item_path_list = ""
for i = 1, #package_items do
    item_path_list = item_path_list .. " " .. package_items[i]
end

build = {
    type = "command",
    build_command = "cd " .. src .. " && amalg.lua "
            .. "--output=../../../target/row-level-security-dist-" .. tag .. ".lua "
            .. "--script=entry.lua"
            .. item_path_list
}
