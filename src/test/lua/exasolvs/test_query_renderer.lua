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

function test_query_renderer.test_scalar_function_in_select_list_without_arguments()
    local parameters = {
        { func_name = "PI", expected = "SELECT PI()" },
        { func_name = "RAND", expected = "SELECT RAND()" },
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select", selectList = { { type = "function_scalar", name = parameter.func_name } }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_in_select_list_with_single_argument()
    local parameters = {
        { func_name = "ABS", arg_type = "literal_exactnumeric", arg_value = -123, expected = "SELECT ABS(-123)" },
        { func_name = "ACOS", arg_type = "literal_double", arg_value = 0.5, expected = "SELECT ACOS(0.5)" },
        { func_name = "ASIN", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT ASIN(1)" },
        { func_name = "ATAN", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT ATAN(1)" },
        { func_name = "CEIL", arg_type = "literal_double", arg_value = 0.234, expected = "SELECT CEIL(0.234)" },
        { func_name = "COS", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT COS(1)" },
        { func_name = "COSH", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT COSH(1)" },
        { func_name = "COT", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT COT(1)" },
        { func_name = "DEGREES", arg_type = "literal_exactnumeric", arg_value = 10, expected = "SELECT DEGREES(10)" },
        { func_name = "EXP", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT EXP(1)" },
        { func_name = "FLOOR", arg_type = "literal_double", arg_value = 4.567, expected = "SELECT FLOOR(4.567)" },
        { func_name = "LN", arg_type = "literal_exactnumeric", arg_value = 100, expected = "SELECT LN(100)" },
        { func_name = "LOG10", arg_type = "literal_exactnumeric", arg_value = 10000, expected = "SELECT LOG10(10000)" },
        { func_name = "LOG2", arg_type = "literal_exactnumeric", arg_value = 1024, expected = "SELECT LOG2(1024)" },
        { func_name = "RADIANS", arg_type = "literal_exactnumeric", arg_value = 180, expected = "SELECT RADIANS(180)" },
        { func_name = "SIGN", arg_type = "literal_exactnumeric", arg_value = -123, expected = "SELECT SIGN(-123)" },
        { func_name = "SIN", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT SIN(1)" },
        { func_name = "SINH", arg_type = "literal_exactnumeric", arg_value = 0, expected = "SELECT SINH(0)" },
        { func_name = "SQRT", arg_type = "literal_exactnumeric", arg_value = 2, expected = "SELECT SQRT(2)" },
        { func_name = "TAN", arg_type = "literal_exactnumeric", arg_value = 1, expected = "SELECT TAN(1)" },
        { func_name = "TO_CHAR", arg_type = "literal_double", arg_value = 123.67, expected = "SELECT TO_CHAR(123.67)" },
        { func_name = "ASCII", arg_type = "literal_string", arg_value = "X", expected = "SELECT ASCII('X')" },
        { func_name = "BIT_LENGTH", arg_type = "literal_string", arg_value = "aou", expected = "SELECT BIT_LENGTH('aou')" },
        { func_name = "CHARACTER_LENGTH", arg_type = "literal_string", arg_value = "aou", expected = "SELECT CHARACTER_LENGTH('aou')" },
        { func_name = "CHR", arg_type = "literal_exactnumeric", arg_value = 88, expected = "SELECT CHR(88)" },
        { func_name = "COLOGNE_PHONETIC", arg_type = "literal_string", arg_value = 'schmitt', expected = "SELECT COLOGNE_PHONETIC('schmitt')" },
        { func_name = "INITCAP", arg_type = "literal_string", arg_value = 'Hello wOrLd', expected = "SELECT INITCAP('Hello wOrLd')" },
        { func_name = "LCASE", arg_type = "literal_string", arg_value = 'AbCdEf', expected = "SELECT LCASE('AbCdEf')" },
        { func_name = "LENGTH", arg_type = "literal_string", arg_value = 'abc', expected = "SELECT LENGTH('abc')" },
        { func_name = "LOWER", arg_type = "literal_string", arg_value = 'AbCdEf', expected = "SELECT LOWER('AbCdEf')" },
        { func_name = "OCTET_LENGTH", arg_type = "literal_string", arg_value = 'abcd', expected = "SELECT OCTET_LENGTH('abcd')" },
        { func_name = "UPPER", arg_type = "literal_string", arg_value = "bob", expected = "SELECT UPPER('bob')" },
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar",
                    name = parameter.func_name,
                    arguments = { { type = parameter.arg_type, value = parameter.arg_value } }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_in_select_list_with_two_arguments()
    local parameters = {
        { func_name = "ATAN2", first_arg_type = "literal_exactnumeric", first_arg_value = 1,
          second_arg_type = "literal_exactnumeric", second_arg_value = 1, expected = "SELECT ATAN2(1, 1)" },
        { func_name = "DIV", first_arg_type = "literal_exactnumeric", first_arg_value = 15,
            second_arg_type = "literal_exactnumeric", second_arg_value = 6, expected = "SELECT DIV(15, 6)" },
        { func_name = "LOG", first_arg_type = "literal_exactnumeric", first_arg_value = 2,
            second_arg_type = "literal_exactnumeric", second_arg_value = 1024, expected = "SELECT LOG(2, 1024)" },
        { func_name = "MOD", first_arg_type = "literal_exactnumeric", first_arg_value = 15,
            second_arg_type = "literal_exactnumeric", second_arg_value = 6, expected = "SELECT MOD(15, 6)" },
        { func_name = "POWER", first_arg_type = "literal_exactnumeric", first_arg_value = 2,
            second_arg_type = "literal_exactnumeric", second_arg_value = 10, expected = "SELECT POWER(2, 10)" },
        { func_name = "ROUND", first_arg_type = "literal_double", first_arg_value = 123.456,
            second_arg_type = "literal_exactnumeric", second_arg_value = 2, expected = "SELECT ROUND(123.456, 2)" },
        { func_name = "TO_NUMBER", first_arg_type = "literal_string", first_arg_value = '-123.45',
            second_arg_type = "literal_string", second_arg_value = '99999.999', expected = "SELECT TO_NUMBER('-123.45', '99999.999')" },
        { func_name = "TRUNC", first_arg_type = "literal_double", first_arg_value = '123.456',
            second_arg_type = "literal_exactnumeric", second_arg_value = 2, expected = "SELECT TRUNC(123.456, 2)" },
        { func_name = "CONCAT", first_arg_type = "literal_string", first_arg_value = 'abc',
            second_arg_type = "literal_string", second_arg_value = 'def', expected = "SELECT CONCAT('abc', 'def')" },
        { func_name = "DUMP", first_arg_type = "literal_string", first_arg_value = 'üäö45',
            second_arg_type = "literal_exactnumeric", second_arg_value = 16, expected = "SELECT DUMP('üäö45', 16)" },
        { func_name = "EDIT_DISTANCE", first_arg_type = "literal_string", first_arg_value = 'schmitt',
            second_arg_type = "literal_string", second_arg_value = 'Schmidt', expected = "SELECT EDIT_DISTANCE('schmitt', 'Schmidt')" },
        { func_name = "INSTR", first_arg_type = "literal_string", first_arg_value = 'abcabcabc',
            second_arg_type = "literal_string", second_arg_value = 'cab', expected = "SELECT INSTR('abcabcabc', 'cab')" },
        { func_name = "LEFT", first_arg_type = "literal_string", first_arg_value = 'abcdef',
            second_arg_type = "literal_exactnumeric", second_arg_value = 3, expected = "SELECT LEFT('abcdef', 3)" },
        { func_name = "LOCATE", first_arg_type = "literal_string", first_arg_value = 'cab',
            second_arg_type = "literal_string", second_arg_value = 'abcabcabc', expected = "SELECT LOCATE('cab', 'abcabcabc')" },
        { func_name = "LPAD", first_arg_type = "literal_string", first_arg_value = 'abc',
            second_arg_type = "literal_exactnumeric", second_arg_value = 5, expected = "SELECT LPAD('abc', 5)" },
        { func_name = "LTRIM", first_arg_type = "literal_string", first_arg_value = 'ab cdef',
            second_arg_type = "literal_string", second_arg_value = 'ab', expected = "SELECT LTRIM('ab cdef', 'ab')" },
        { func_name = "MID", first_arg_type = "literal_string", first_arg_value = 'abcdef',
            second_arg_type = "literal_exactnumeric", second_arg_value = 2, expected = "SELECT MID('abcdef', 2)" },
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar",
                    name = parameter.func_name,
                    arguments = {
                        { type = parameter.first_arg_type, value = parameter.first_arg_value },
                        { type = parameter.second_arg_type, value = parameter.second_arg_value }
                    }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_in_select_list_with_four_arguments()
    local parameters = {
        { func_name = "INSERT", first_arg_type = "literal_string", first_arg_value = 'abc',
            second_arg_type = "literal_exactnumeric", second_arg_value = 2,
            third_arg_type = "literal_exactnumeric", third_arg_value = 2,
            forth_arg_type = "literal_string", forth_arg_value = "xxx", expected = "SELECT INSERT('abc', 2, 2, 'xxx')" },
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar",
                    name = parameter.func_name,
                    arguments = {
                        { type = parameter.first_arg_type, value = parameter.first_arg_value },
                        { type = parameter.second_arg_type, value = parameter.second_arg_value },
                        { type = parameter.third_arg_type, value = parameter.third_arg_value },
                        { type = parameter.forth_arg_type, value = parameter.forth_arg_value }
                    }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
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

os.exit(luaunit.LuaUnit.run())
