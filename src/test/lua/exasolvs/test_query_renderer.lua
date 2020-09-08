luaunit = require("luaunit")
renderer = require("exasolvs.query_renderer")

test_query_renderer = {}

local function assert_renders_to(original_query, expected)
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
    assert_renders_to(original_query, 'SELECT "T1"."C1", "T1"."C2" FROM "T1"');
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
    assert_renders_to(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE ("MONTHS"."DAYS_IN_MONTH" > 30)');
end

function test_query_renderer.test_render_nested_predicate_filter()
    local original_query = {
        type = "select",
        selectList = {{type = "column", name ="NAME", tableName = "MONTHS"}},
        from = {type = "table", name = "MONTHS"},
        filter = {
            type = "predicate_and",
            expressions = {{
                type = "predicate_equal",
                left = {type = "literal_string", value = "Q3"},
                right = {type = "column", name="QUARTER", tableName = "MONTHS"}
            }, {
                type = "predicate_greater",
                left = {type = "column", name="DAYS_IN_MONTH", tableName = "MONTHS"},
                right = {type = "literal_exactnumeric", value = "30"}
            }
            }
        }
    }
    assert_renders_to(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS"'
        .. ' WHERE ((\'Q3\' = "MONTHS"."QUARTER") AND ("MONTHS"."DAYS_IN_MONTH" > 30))');
end

function test_query_renderer.test_render_unary_not_filter()
    local original_query = {
        type = "select",
        selectList = {{type = "column", name ="NAME", tableName = "MONTHS"}},
        from = {type = "table", name = "MONTHS"},
        filter = {
            type = "predicate_not",
            expression = {
                type = "predicate_equal",
                left = {type = "literal_string", value = "Q3"},
                right = {type = "column", name="QUARTER", tableName = "MONTHS"}
            },
        }
    }
    assert_renders_to(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS"'
        .. ' WHERE (NOT (\'Q3\' = "MONTHS"."QUARTER"))');
end

function test_query_renderer.test_scalar_function_in_select_list()
    local original_query = {
        type = "select",
        selectList = {
            {type = "function_scalar", name ="UPPER", arguments = {{type = "literal_string", value = "bob"}}}
        }
    }
    assert_renders_to(original_query, "SELECT UPPER('bob')")
end

function test_query_renderer.test_scalar_function_in_select_list()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "LASTNAME", tableName = "PEOPLE"}
        },
        from = {type = "table", name = "PEOPLE"},
        filter = {
            type = "predicate_equal",
            left = {
                type = "function_scalar",
                name = "LOWER",
                arguments = {
                    {type = "column", name = "FIRSTNAME", tableName = "PEOPLE"},
                }
            },
            right = {type = "literal_string", value = "eve"}
        }
    }
    assert_renders_to(original_query, 'SELECT "PEOPLE"."LASTNAME" FROM "PEOPLE" WHERE (LOWER("PEOPLE"."FIRSTNAME") = \'eve\')')
end

function test_query_renderer.test_current_user()
    local original_query = {
        type = "select",
        selectList = {{type = "function_scalar", name = "CURRENT_USER"}}
    }
    assert_renders_to(original_query, 'SELECT CURRENT_USER')

end

function test_query_renderer.test_predicate_in_constlist()
    local original_query = {
        type = "select",
        selectList = {{type = "literal_string", value = "hello"}},
        from = {type = "table", name = "T1"},
        filter = {
            type = "predicate_in_constlist",
            expression = {type = "column", name = "C1", tableName = "T1"},
            arguments = {
                {type = "literal_string", value = "A1"},
                {type = "literal_string", value = "A2"}
            }
        }
    }
    assert_renders_to(original_query, 'SELECT \'hello\' FROM "T1" WHERE ("T1"."C1" IN (\'A1\', \'A2\'))')
end

os.exit(luaunit.LuaUnit.run())
