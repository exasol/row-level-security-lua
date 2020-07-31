luaunit = require("luaunit")
renderer = require("exasolvs.query_renderer")

test_query_renderer = {}

local function assertRendersTo(original_query, expected)
    luaunit.assertEquals(renderer.new(original_query).render(), expected);
end

function test_query_renderer.test_render_simple_select()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "C1", tableName = "T1"},
            {type = "column", name = "C2", tableName = "T1"}
        },
        from = {type  = "table", name = "T1"}
    }
    assertRendersTo(original_query, 'SELECT "T1"."C1", "T1"."C2" FROM "T1"');
end

function test_query_renderer.test_render_with_single_predicate_filter()
    local original_query = {
        type = "select",
        selectList = {{type = "column", name ="NAME", tableName = "MONTHS"}},
        from = {type = "table", name = "MONTHS"},
        filter = {
            type = "predicate_greater",
            left = {type = "column", name="DAYS_IN_MONTH", tableName = "MONTHS"},
            right = {type = "literal_exactnumeric", value = "30"}
        }
    }
    assertRendersTo(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE ("MONTHS"."DAYS_IN_MONTH" > 30)');
end

function test_query_renderer.test_render_nested_predicate_filter()
    local original_query = {
        type = "select",
        selectList = {{type = "column", name ="NAME", tableName = "MONTHS"}},
        from = {type = "table", name = "MONTHS"},
        filter = {
            type = "predicate_and",
            left = {
                type = "predicate_equal",
                left = {type = "literal_string", value = "Q3"},
                right = {type = "column", name="QUARTER", tableName = "MONTHS"}
            },
            right ={
                type = "predicate_greater",
                left = {type = "column", name="DAYS_IN_MONTH", tableName = "MONTHS"},
                right = {type = "literal_exactnumeric", value = "30"}
            }
        }
    }
    assertRendersTo(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS"'
            .. ' WHERE ((\'Q3\' = "MONTHS"."QUARTER") AND ("MONTHS"."DAYS_IN_MONTH" > 30))');
end

function test_query_renderer.test_render_unary_not_filter()
    local original_query = {
        type = "select",
        selectList = {{type = "column", name ="NAME", tableName = "MONTHS"}},
        from = {type = "table", name = "MONTHS"},
        filter = {
            type = "predicate_not",
            right = {
                type = "predicate_equal",
                left = {type = "literal_string", value = "Q3"},
                right = {type = "column", name="QUARTER", tableName = "MONTHS"}
            },
        }
    }
    assertRendersTo(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS"'
            .. ' WHERE (NOT (\'Q3\' = "MONTHS"."QUARTER"))');
end

os.exit(luaunit.LuaUnit.run())