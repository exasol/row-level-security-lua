local luaunit = require("luaunit")
local renderer = require("exasolvs.query_renderer")

test_query_renderer = {}

local function assert_renders_to(original_query, expected)
    luaunit.assertEquals(renderer.new(original_query).render(), expected)
end

local function assert_rendering_error_contains(original_query, message)
    luaunit.assertErrorMsgContains(message, renderer.new(original_query).render)
end

function test_query_renderer.test_render_select_star()
    local original_query = {
        type = "select",
        from = {type  = "table", name = "T1"}
    }
    assert_renders_to(original_query, 'SELECT * FROM "T1"')
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
    assert_renders_to(original_query, 'SELECT "T1"."C1", "T1"."C2" FROM "T1"')
end

function test_query_renderer.test_render_literal_in_select_list()
    local literals = {
        {
            input = {type = "literal_null"},
            expected = "null"
        },
        {
            input = {type = "literal_string", value = "a_string"},
            expected = "'a_string'"
        },
        {
            input = {type = "literal_double", value = 3.1415},
            expected = "3.1415"},
        {
            input = {type = "literal_exactnumeric", value = 9876543210},
            expected = "9876543210"
        },
        {
            input = {type = "literal_bool", value = true},
            expected = "true"
        },
        {
            input = {type = "literal_date", value = "2015-12-01"},
            expected = "DATE '2015-12-01'"
        },
        {
            input = {type = "literal_timestamp", value = "2015-12-01 12:01:01.1234"},
            expected = "TIMESTAMP '2015-12-01 12:01:01.1234'"
        },
        {
            input = {type = "literal_timestamputc", value = "2015-12-01 12:01:01.1234"},
            expected = "TIMESTAMP '2015-12-01 12:01:01.1234'"
        }
    }
    for _, literal in ipairs(literals) do
        local original_query = {
            type = "select",
            selectList = { literal.input },
            from = {type  = "table", name = "T1"}
        }
        assert_renders_to(original_query, 'SELECT ' .. literal.expected ..' FROM "T1"')
    end
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
    assert_renders_to(original_query, 'SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE ("MONTHS"."DAYS_IN_MONTH" > 30)')
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
        .. ' WHERE ((\'Q3\' = "MONTHS"."QUARTER") AND ("MONTHS"."DAYS_IN_MONTH" > 30))')
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
        .. ' WHERE (NOT (\'Q3\' = "MONTHS"."QUARTER"))')
end

function test_query_renderer.test_scalar_function_in_select_list_without_arguments()
    local parameters = {
        { func_name = "RAND", expected = "SELECT RAND()" },
        { func_name = "CURRENT_DATE", expected = "SELECT CURRENT_DATE()" },
        { func_name = "CURRENT_TIMESTAMP", expected = "SELECT CURRENT_TIMESTAMP()" },
        { func_name = "DBTIMEZONE", expected = "SELECT DBTIMEZONE()" },
        { func_name = "LOCALTIMESTAMP", expected = "SELECT LOCALTIMESTAMP()" },
        { func_name = "SESSIONTIMEZONE", expected = "SELECT SESSIONTIMEZONE()" },
        { func_name = "SYSDATE", expected = "SELECT SYSDATE" },
        { func_name = "SYSTIMESTAMP", expected = "SELECT SYSTIMESTAMP()" },
        { func_name = "CURRENT_SCHEMA", expected = "SELECT CURRENT_SCHEMA" },
        { func_name = "CURRENT_SESSION", expected = "SELECT CURRENT_SESSION" },
        { func_name = "CURRENT_STATEMENT", expected = "SELECT CURRENT_STATEMENT" },
        { func_name = "CURRENT_USER", expected = "SELECT CURRENT_USER" },
        { func_name = "SYS_GUID", expected = "SELECT SYS_GUID()" },
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
        {
            func_name = "ABS",
            arg_type = "literal_exactnumeric",
            arg_value = -123,
            expected = "SELECT ABS(-123)"
        },
        {
            func_name = "ACOS",
            arg_type = "literal_double",
            arg_value = 0.5,
            expected = "SELECT ACOS(0.5)"
        },
        {
            func_name = "ASIN",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT ASIN(1)"
        },
        {
            func_name = "ATAN",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT ATAN(1)"
        },
        {
            func_name = "CEIL",
            arg_type = "literal_double",
            arg_value = 0.234,
            expected = "SELECT CEIL(0.234)"
        },
        {
            func_name = "COS",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT COS(1)"
        },
        {
            func_name = "COSH",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT COSH(1)"
        },
        {
            func_name = "COT",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT COT(1)"
        },
        {
            func_name = "DEGREES",
            arg_type = "literal_exactnumeric",
            arg_value = 10,
            expected = "SELECT DEGREES(10)"
        },
        {
            func_name = "EXP",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT EXP(1)"
        },
        {
            func_name = "FLOOR",
            arg_type = "literal_double",
            arg_value = 4.567,
            expected = "SELECT FLOOR(4.567)"
        },
        {
            func_name = "LN",
            arg_type = "literal_exactnumeric",
            arg_value = 100,
            expected = "SELECT LN(100)"
        },
        {
            func_name = "NEG",
            arg_type = "literal_exactnumeric",
            arg_value = 42,
            expected = "SELECT -42"
        },
        {
            func_name = "RADIANS",
            arg_type = "literal_exactnumeric",
            arg_value = 180,
            expected = "SELECT RADIANS(180)"
        },
        {
            func_name = "SIGN",
            arg_type = "literal_exactnumeric",
            arg_value = -123,
            expected = "SELECT SIGN(-123)"
        },
        {
            func_name = "SIN",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT SIN(1)"
        },
        {
            func_name = "SINH",
            arg_type = "literal_exactnumeric",
            arg_value = 0,
            expected = "SELECT SINH(0)"
        },
        {
            func_name = "SQRT",
            arg_type = "literal_exactnumeric",
            arg_value = 2,
            expected = "SELECT SQRT(2)"
        },
        {
            func_name = "TAN",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT TAN(1)"
        },
        {
            func_name = "TO_CHAR",
            arg_type = "literal_double",
            arg_value = 123.67,
            expected = "SELECT TO_CHAR(123.67)"
        },
        {
            func_name = "ASCII",
            arg_type = "literal_string",
            arg_value = "X",
            expected = "SELECT ASCII('X')"
        },
        {
            func_name = "BIT_LENGTH",
            arg_type = "literal_string",
            arg_value = "aou",
            expected = "SELECT BIT_LENGTH('aou')"
        },
        {
            func_name = "CHR",
            arg_type = "literal_exactnumeric",
            arg_value = 88,
            expected = "SELECT CHR(88)"
        },
        {
            func_name = "COLOGNE_PHONETIC",
            arg_type = "literal_string",
            arg_value = "schmitt",
            expected = "SELECT COLOGNE_PHONETIC('schmitt')"
        },
        {
            func_name = "LENGTH",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT LENGTH('abc')"
        },
        {
            func_name = "LOWER",
            arg_type = "literal_string",
            arg_value = "AbCdEf",
            expected = "SELECT LOWER('AbCdEf')"
        },
        {
            func_name = "OCTET_LENGTH",
            arg_type = "literal_string",
            arg_value = "abcd",
            expected = "SELECT OCTET_LENGTH('abcd')"
        },
        {
            func_name = "REVERSE",
            arg_type = "literal_string",
            arg_value = "abcd",
            expected = "SELECT REVERSE('abcd')"
        },
        {
            func_name = "SOUNDEX",
            arg_type = "literal_string",
            arg_value = "Smith",
            expected = "SELECT SOUNDEX('Smith')"
        },
        {
            func_name = "SPACE",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT SPACE(5)"
        },
        {
            func_name = "TRIM",
            arg_type = "literal_string",
            arg_value = "  abc  ",
            expected = "SELECT TRIM('  abc  ')"
        },
        {
            func_name = "UNICODE",
            arg_type = "literal_string",
            arg_value = "a",
            expected = "SELECT UNICODE('a')"
        },
        {
            func_name = "UNICODECHR",
            arg_type = "literal_exactnumeric",
            arg_value = 255,
            expected = "SELECT UNICODECHR(255)"
        },
        {
            func_name = "UPPER",
            arg_type = "literal_string",
            arg_value = "bob",
            expected = "SELECT UPPER('bob')"
        },
        {
            func_name = "DAY",
            arg_type = "literal_date",
            arg_value = "2010-10-20",
            expected = "SELECT DAY(DATE '2010-10-20')"
        },
        {
            func_name = "MINUTE",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT MINUTE(TIMESTAMP '2010-10-20 11:59:40.123')"
        },
        {
            func_name = "MONTH",
            arg_type = "literal_date",
            arg_value = "2010-10-20",
            expected = "SELECT MONTH(DATE '2010-10-20')"
        },
        {
            func_name = "POSIX_TIME",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT POSIX_TIME(TIMESTAMP '2010-10-20 11:59:40.123')"
        },
        {
            func_name = "SECOND",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT SECOND(TIMESTAMP '2010-10-20 11:59:40.123')"
        },
        {
            func_name = "TO_DATE",
            arg_type = "literal_string",
            arg_value = "31-12-1999",
            expected = "SELECT TO_DATE('31-12-1999')"
        },
        {
            func_name = "TO_DSINTERVAL",
            arg_type = "literal_string",
            arg_value = "3 10:59:59.123",
            expected = "SELECT TO_DSINTERVAL('3 10:59:59.123')"
        },
        {
            func_name = "TO_TIMESTAMP",
            arg_type = "literal_string",
            arg_value = "1999-12-31 23:59:00",
            expected = "SELECT TO_TIMESTAMP('1999-12-31 23:59:00')"
        },
        {
            func_name = "TO_YMINTERVAL",
            arg_type = "literal_string",
            arg_value = "3-11",
            expected = "SELECT TO_YMINTERVAL('3-11')"
        },
        {
            func_name = "WEEK",
            arg_type = "literal_date",
            arg_value = "2012-01-05",
            expected = "SELECT WEEK(DATE '2012-01-05')"
        },
        {
            func_name = "YEAR",
            arg_type = "literal_date",
            arg_value = "2012-01-05",
            expected = "SELECT YEAR(DATE '2012-01-05')"
        },
        {
            func_name = "BIT_NOT",
            arg_type = "literal_exactnumeric",
            arg_value = 1,
            expected = "SELECT BIT_NOT(1)"
        },
        {
            func_name = "HASH_MD5",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_MD5('abc')"
        },
        {
            func_name = "HASHTYPE_MD5",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASHTYPE_MD5('abc')"
        },
        {
            func_name = "HASH_SHA1",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_SHA1('abc')"
        },
        {
            func_name = "HASHTYPE_SHA1",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASHTYPE_SHA1('abc')"
        },
        {
            func_name = "HASH_SHA256",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_SHA256('abc')"
        },
        {
            func_name = "HASHTYPE_SHA256",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASHTYPE_SHA256('abc')"
        },
        {
            func_name = "HASH_SHA512",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_SHA512('abc')"
        },
        {
            func_name = "HASHTYPE_SHA512",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASHTYPE_SHA512('abc')"
        },
        {
            func_name = "HASH_TIGER",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_TIGER('abc')"
        },
        {
            func_name = "HASHTYPE_TIGER",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASHTYPE_TIGER('abc')"
        },
        {
            func_name = "IS_NUMBER",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_NUMBER('abc')"
        },
        {
            func_name = "IS_BOOLEAN",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_BOOLEAN('abc')"
        },
        {
            func_name = "IS_DATE",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_DATE('abc')"
        },
        {
            func_name = "IS_DSINTERVAL",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_DSINTERVAL('abc')"
        },
        {
            func_name = "IS_YMINTERVAL",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_YMINTERVAL('abc')"
        },
        {
            func_name = "IS_TIMESTAMP",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT IS_TIMESTAMP('abc')"
        },
        {
            func_name = "MIN_SCALE",
            arg_type = "literal_exactnumeric",
            arg_value = 100.1245,
            expected = "SELECT MIN_SCALE(100.1245)"
        },
        {
            func_name = "NULLIFZERO",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT NULLIFZERO(5)"
        },
        {
            func_name = "TYPEOF",
            arg_type = "literal_string",
            arg_value = "foobar",
            expected = "SELECT TYPEOF('foobar')"
        },
        {
            func_name = "ZEROIFNULL",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT ZEROIFNULL(5)"
        },
        {
            func_name = "FROM_POSIX_TIME",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT FROM_POSIX_TIME(5)"
        },
        {
            func_name = "HOUR",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT HOUR(TIMESTAMP '2010-10-20 11:59:40.123')"
        },
        {
            func_name = "INITCAP",
            arg_type = "literal_string",
            arg_value = "ThiS is great",
            expected = "SELECT INITCAP('ThiS is great')"
        }
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
        {
            func_name = "ADD",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT 1 + 2"
        },
        {
            func_name = "ATAN2",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 1,
            expected = "SELECT ATAN2(1, 1)"
        },
        {
            func_name = "DIV",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 15,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 6,
            expected = "SELECT DIV(15, 6)"
        },
        {
            func_name = "FLOAT_DIV",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 20,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 4,
            expected = "SELECT 20 / 4"
        },
        {
            func_name = "LOG",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 2,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 1024,
            expected = "SELECT LOG(2, 1024)"
        },
        {
            func_name = "MOD",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 15,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 6,
            expected = "SELECT MOD(15, 6)"
        },
        {
            func_name = "MULT",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 3,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 7,
            expected = "SELECT 3 * 7"
        },
        {
            func_name = "POWER",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 2,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 10,
            expected = "SELECT POWER(2, 10)"
        },
        {
            func_name = "ROUND",
            first_arg_type = "literal_double",
            first_arg_value = 123.456,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ROUND(123.456, 2)"
        },
        {
            func_name = "SUB",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 444,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 222,
            expected = "SELECT 444 - 222"
        },
        {
            func_name = "TO_NUMBER",
            first_arg_type = "literal_string",
            first_arg_value = "-123.45",
            second_arg_type = "literal_string",
            second_arg_value = "99999.999",
            expected = "SELECT TO_NUMBER('-123.45', '99999.999')"
        },
        {
            func_name = "TRUNC",
            first_arg_type = "literal_double",
            first_arg_value = "123.456",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT TRUNC(123.456, 2)"
        },
        {
            func_name = "CONCAT",
            first_arg_type = "literal_string",
            first_arg_value = "abc",
            second_arg_type = "literal_string",
            second_arg_value = "def",
            expected = "SELECT CONCAT('abc', 'def')"
        },
        {
            func_name = "DUMP",
            first_arg_type = "literal_string",
            first_arg_value = "üäö45",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 16,
            expected = "SELECT DUMP('üäö45', 16)"
        },
        {
            func_name = "EDIT_DISTANCE",
            first_arg_type = "literal_string",
            first_arg_value = "schmitt",
            second_arg_type = "literal_string",
            second_arg_value = "Schmidt",
            expected = "SELECT EDIT_DISTANCE('schmitt', 'Schmidt')"
        },
        {
            func_name = "INSTR",
            first_arg_type = "literal_string",
            first_arg_value = "abcabcabc",
            second_arg_type = "literal_string",
            second_arg_value = "cab",
            expected = "SELECT INSTR('abcabcabc', 'cab')"
        },
        {
            func_name = "LOCATE",
            first_arg_type = "literal_string",
            first_arg_value = "cab",
            second_arg_type = "literal_string",
            second_arg_value = "abcabcabc",
            expected = "SELECT LOCATE('cab', 'abcabcabc')"
        },
        {
            func_name = "LPAD",
            first_arg_type = "literal_string",
            first_arg_value = "abc",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 5,
            expected = "SELECT LPAD('abc', 5)"
        },
        {
            func_name = "LTRIM",
            first_arg_type = "literal_string",
            first_arg_value = "ab cdef",
            second_arg_type = "literal_string",
            second_arg_value = "ab",
            expected = "SELECT LTRIM('ab cdef', 'ab')"
        },
        {
            func_name = "REGEXP_INSTR",
            first_arg_type = "literal_string",
            first_arg_value = "Phone: +497003927877678",
            second_arg_type = "literal_string",
            second_arg_value = "d+",
            expected = "SELECT REGEXP_INSTR('Phone: +497003927877678', 'd+')"
        },
        {
            func_name = "REGEXP_REPLACE",
            first_arg_type = "literal_string",
            first_arg_value = "Phone: +497003927877678",
            second_arg_type = "literal_string",
            second_arg_value = "d+",
            expected = "SELECT REGEXP_REPLACE('Phone: +497003927877678', 'd+')"
        },
        {
            func_name = "REGEXP_SUBSTR",
            first_arg_type = "literal_string",
            first_arg_value = "Phone: +497003927877678",
            second_arg_type = "literal_string",
            second_arg_value = "d+",
            expected = "SELECT REGEXP_SUBSTR('Phone: +497003927877678', 'd+')"
        },
        {
            func_name = "REPEAT",
            first_arg_type = "literal_string",
            first_arg_value = "abc",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT REPEAT('abc', 3)"
        },
        {
            func_name = "REPLACE",
            first_arg_type = "literal_string",
            first_arg_value = "Apple is very green",
            second_arg_type = "literal_string",
            second_arg_value = "very",
            expected = "SELECT REPLACE('Apple is very green', 'very')"
        },
        {
            func_name = "RIGHT",
            first_arg_type = "literal_string",
            first_arg_value = "abcdef",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT RIGHT('abcdef', 3)"
        },
        {
            func_name = "RPAD",
            first_arg_type = "literal_string",
            first_arg_value = "abc",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 5,
            expected = "SELECT RPAD('abc', 5)"
        },
        {
            func_name = "RTRIM",
            first_arg_type = "literal_string",
            first_arg_value = "abcdef",
            second_arg_type = "literal_string",
            second_arg_value = "afe",
            expected = "SELECT RTRIM('abcdef', 'afe')"
        },
        {
            func_name = "SUBSTR",
            first_arg_type = "literal_string",
            first_arg_value = "abcdef",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT SUBSTR('abcdef', 2)"
        },
        {
            func_name = "ADD_DAYS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_DAYS(DATE '2000-02-28', 2)"
        },
        {
            func_name = "ADD_HOURS",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_HOURS(TIMESTAMP '2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_MINUTES",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_MINUTES(TIMESTAMP '2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_MONTHS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_MONTHS(DATE '2000-02-28', 2)"
        },
        {
            func_name = "ADD_SECONDS",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_SECONDS(TIMESTAMP '2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_WEEKS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_WEEKS(DATE '2000-02-28', 2)"
        },
        {
            func_name = "ADD_YEARS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_YEARS(DATE '2000-02-28', 2)"
        },
        {
            func_name = "DATE_TRUNC",
            first_arg_type = "literal_string",
            first_arg_value = "month",
            second_arg_type = "literal_date",
            second_arg_value = "2006-12-31",
            expected = "SELECT DATE_TRUNC('month', DATE '2006-12-31')"
        },
        {
            func_name = "DAYS_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT DAYS_BETWEEN(DATE '1999-12-31', DATE '2000-01-01')"
        },
        {
            func_name = "HOURS_BETWEEN",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 12:00:00",
            second_arg_type = "literal_timestamp",
            second_arg_value = "2000-01-01 11:01:05.1",
            expected = "SELECT HOURS_BETWEEN(TIMESTAMP '2000-01-01 12:00:00', TIMESTAMP '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "MINUTES_BETWEEN",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 12:00:00",
            second_arg_type = "literal_timestamp",
            second_arg_value = "2000-01-01 11:01:05.1",
            expected = "SELECT MINUTES_BETWEEN(TIMESTAMP '2000-01-01 12:00:00', TIMESTAMP '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "MONTHS_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT MONTHS_BETWEEN(DATE '1999-12-31', DATE '2000-01-01')"
        },
        {
            func_name = "NUMTODSINTERVAL",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = "2",
            second_arg_type = "literal_string",
            second_arg_value = "HOUR",
            expected = "SELECT NUMTODSINTERVAL(2, 'HOUR')"
        },
        {
            func_name = "NUMTOYMINTERVAL",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = "2",
            second_arg_type = "literal_string",
            second_arg_value = "YEAR",
            expected = "SELECT NUMTOYMINTERVAL(2, 'YEAR')"
        },
        {
            func_name = "SECONDS_BETWEEN",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 12:00:00",
            second_arg_type = "literal_timestamp",
            second_arg_value = "2000-01-01 11:01:05.1",
            expected = "SELECT SECONDS_BETWEEN(TIMESTAMP '2000-01-01 12:00:00', TIMESTAMP '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "YEARS_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT YEARS_BETWEEN(DATE '1999-12-31', DATE '2000-01-01')"
        },
        {
            func_name = "BIT_AND",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT BIT_AND(9, 3)"
        },
        {
            func_name = "BIT_CHECK",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT BIT_CHECK(9, 3)"
        },
        {
            func_name = "BIT_OR",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT BIT_OR(9, 3)"
        },
        {
            func_name = "BIT_SET",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT BIT_SET(9, 3)"
        },
        {
            func_name = "BIT_TO_NUM",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 1,
            expected = "SELECT BIT_TO_NUM(1, 1)"
        },
        {
            func_name = "BIT_XOR",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT BIT_XOR(9, 3)"
        },
        {
            func_name = "GREATEST",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 9,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 3,
            expected = "SELECT GREATEST(9, 3)"
        },
        {
            func_name = "BIT_LROTATE",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1024,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 63,
            expected = "SELECT BIT_LROTATE(1024, 63)"
        },
        {
            func_name = "BIT_RROTATE",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1024,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 63,
            expected = "SELECT BIT_RROTATE(1024, 63)"
        },
        {
            func_name = "BIT_LSHIFT",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1024,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 63,
            expected = "SELECT BIT_LSHIFT(1024, 63)"
        },
        {
            func_name = "BIT_RSHIFT",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = 1024,
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 63,
            expected = "SELECT BIT_RSHIFT(1024, 63)"
        }
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

function test_query_renderer.test_scalar_function_in_select_list_with_three_arguments()
    local parameters = {
        {
            func_name = "TRANSLATE",
            first_arg_type = "literal_string",
            first_arg_value = "abcd",
            second_arg_type = "literal_string",
            second_arg_value = "abc",
            third_arg_type = "literal_string",
            third_arg_value = "xy",
            expected = "SELECT TRANSLATE('abcd', 'abc', 'xy')"
        },
        {
            func_name = "LEAST",
            first_arg_type = "literal_exactnumeric",
            first_arg_value = "7",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = "101",
            third_arg_type = "literal_exactnumeric",
            third_arg_value = "23",
            expected = "SELECT LEAST(7, 101, 23)"
        },
        {
            func_name = "CONVERT_TZ",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2012-05-10 12:00:00",
            second_arg_type = "literal_string",
            second_arg_value = "UTC",
            third_arg_type = "literal_string",
            third_arg_value = "Europe/Berlin",
            expected = "SELECT CONVERT_TZ(TIMESTAMP '2012-05-10 12:00:00', 'UTC', 'Europe/Berlin')"
        },
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
                        { type = parameter.third_arg_type, value = parameter.third_arg_value }
                    }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_in_select_list_with_four_arguments()
    local parameters = {
        {
            func_name = "INSERT",
            first_arg_type = "literal_string",
            first_arg_value = "abc",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            third_arg_type = "literal_exactnumeric",
            third_arg_value = 2,
            forth_arg_type = "literal_string",
            forth_arg_value = "xxx",
            expected = "SELECT INSERT('abc', 2, 2, 'xxx')"
        },
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

function test_query_renderer.test_scalar_function_extract()
    local parameters = {
        {
            to_extract = 'YEAR',
            argument = {
                columnNr = 0,
                name = "col_1",
                tableName = "t",
                type = "column"
            },
            expected = 'SELECT EXTRACT(YEAR FROM "t"."col_1")'
        },
        {
            to_extract = 'MONTH',
            argument = {
                columnNr = 0,
                name = "col_1",
                tableName = "t",
                type = "column"
            },
            expected = 'SELECT EXTRACT(MONTH FROM "t"."col_1")'
        },
        {
            to_extract = 'SECOND',
            argument = { type = 'literal_timestamp', value = '2019-02-12 12:07:00' },
            expected = "SELECT EXTRACT(SECOND FROM TIMESTAMP '2019-02-12 12:07:00')"
        }
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar_extract",
                    name = "EXTRACT",
                    toExtract = parameter.to_extract,
                    arguments = { parameter.argument }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_cast()
    local parameters = {
        {
            argument = {
                columnNr = 0,
                name = "col_1",
                tableName = "t",
                type = "column"
            },
            data_type = { size = 10, type = "VARCHAR" },
            expected = 'SELECT CAST("t"."col_1" AS VARCHAR(10))'
        },
        {
            argument = { type = 'literal_string', value = '100' },
            data_type = { size = 100, type = "CHAR", characterSet = "UTF8" },
            expected = "SELECT CAST('100' AS CHAR(100) UTF8)"
        },
        {
            argument = { type = 'literal_string', value = '1999-12-31' },
            data_type = { type = "DATE" },
            expected = "SELECT CAST('1999-12-31' AS DATE)"
        },
        {
            argument = { type = 'literal_string', value = '1999-12-31 23:59:00' },
            data_type = { type = "TIMESTAMP", withLocalTimeZone = true },
            expected = "SELECT CAST('1999-12-31 23:59:00' AS TIMESTAMP WITH LOCAL TIME ZONE)"
        },
        {
            argument = { type = 'literal_string', value = 'true' },
            data_type = { type = "BOOLEAN" },
            expected = "SELECT CAST('true' AS BOOLEAN)"
        },
        {
            argument = { type = 'literal_string', value = '100' },
            data_type = { type = "DOUBLE" },
            expected = "SELECT CAST('100' AS DOUBLE)"
        },
        {
            argument = { type = 'literal_string', value = 'POINT (1 2)' },
            data_type = { type = "GEOMETRY", srid = 1 },
            expected = "SELECT CAST('POINT (1 2)' AS GEOMETRY(1))"
        },
        {
            argument = { type = 'literal_string', value = '2 12:50:10.123' },
            data_type = { type = "INTERVAL", fromTo = "DAY TO SECONDS", precision = 3, fraction = 4 },
            expected = "SELECT CAST('2 12:50:10.123' AS INTERVAL DAY(3) TO SECOND(4))"
        },
        {
            argument = { type = 'literal_string', value = '5-3' },
            data_type = { type = "INTERVAL", fromTo = "YEAR TO MONTH", precision = 3 },
            expected = "SELECT CAST('5-3' AS INTERVAL YEAR(3) TO MONTH)"
        },
        {
            argument = { type = 'literal_string', value = '550e8400-e29b-11d4-a716' },
            data_type = { type = "HASHTYPE", bytesize = 10 },
            expected = "SELECT CAST('550e8400-e29b-11d4-a716' AS HASHTYPE(10 BYTE))"
        },
        {
            argument = { type = 'literal_string', value = '100' },
            data_type = { precision = 10, scale = 0, type = "DECIMAL" },
            expected = "SELECT CAST('100' AS DECIMAL(10,0))"
        }
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar_cast",
                    name = "CAST",
                    dataType = parameter.data_type,
                    arguments = { parameter.argument }
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_session_parameter()
    local original_query = {
        type = "select",
        selectList = {
            {
                arguments =
                {
                    { arguments = {}, name = "CURRENT_SESSION", type = "function_scalar" },
                    {
                        columnNr = 0,
                        name = "col_1",
                        tableName = "t",
                        type = "column"
                    }
                },
                name = "SESSION_PARAMETER",
                numArgs = 2,
                type = "function_scalar"
            }
        }
    }
    assert_renders_to(original_query, 'SELECT SESSION_PARAMETER(CURRENT_SESSION, "t"."col_1")')
end

function test_query_renderer.test_scalar_function_json_value()
    local parameters = {
        {
            argument_1 = { type = 'literal_string', value = '{\"a\": 1}' },
            argument_2 = { type = 'literal_string', value = '$.a' },
            empty_behavior = {
                type = "DEFAULT",
                expression = { type = 'literal_string', value = '*** error ***' }
            },
            error_behavior = {
                type = "DEFAULT",
                expression = { type = 'literal_string', value = '*** error ***' }
            },
            data_type = { size = 1000, type = "VARCHAR", characterSet = "UTF8" },
            expected = "SELECT JSON_VALUE('{\"a\": 1}', '$.a' RETURNING VARCHAR(1000) UTF8 " ..
            "DEFAULT '*** error ***' ON EMPTY DEFAULT '*** error ***' ON ERROR)"
        },
        {
            argument_1 = { type = 'literal_string', value = '{\"a\": 1}' },
            argument_2 = { type = 'literal_string', value = '$.a' },
            empty_behavior = { type = "NULL", },
            error_behavior = { type = "ERROR" },
            data_type = { size = 100, type = "VARCHAR" },
            expected = "SELECT JSON_VALUE('{\"a\": 1}', '$.a' RETURNING VARCHAR(100) NULL ON EMPTY ERROR ON ERROR)"
        },
    }
    for _, parameter in ipairs(parameters) do
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar_json_value",
                    name = "JSON_VALUE",
                    dataType = parameter.data_type,
                    arguments = { parameter.argument_1, parameter.argument_2 },
                    returningDataType = parameter.data_type,
                    emptyBehavior = parameter.empty_behavior,
                    errorBehavior = parameter.error_behavior
                }
            }
        }
        assert_renders_to(original_query, parameter.expected)
    end
end

function test_query_renderer.test_scalar_function_case()
    local original_query = {
        type = "select",
        selectList = {
            {
                type = "function_scalar_case",
                name = "CASE",
                basis = {
                    columnNr = 1,
                    name = "grade",
                    tableName = "t",
                    type = "column"
                },
                arguments = {
                    { type = "literal_exactnumeric", value = "1" },
                    { type = "literal_exactnumeric", value = "2" },
                    { type = "literal_exactnumeric", value = "3" }
                },
                results = {
                    { type = "literal_string", value = "GOOD" },
                    { type = "literal_string", value = "FAIR" },
                    { type = "literal_string", value = "POOR" },
                    { type = "literal_string", value = "INVALID" }
                }
            }
        }
    }
    assert_renders_to(original_query, "SELECT CASE \"t\".\"grade\" " ..
        "WHEN 1 THEN 'GOOD' WHEN 2 THEN 'FAIR' WHEN 3 THEN 'POOR' ELSE 'INVALID' END")
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
    assert_renders_to(original_query, 'SELECT "PEOPLE"."LASTNAME" FROM "PEOPLE" ' ..
        'WHERE (LOWER("PEOPLE"."FIRSTNAME") = \'eve\')')
end

function test_query_renderer.test_current_user()
    local original_query = {
        type = "select",
        selectList = {{type = "function_scalar", name = "CURRENT_USER"}}
    }
    assert_renders_to(original_query, 'SELECT CURRENT_USER')
end

function test_query_renderer.test_current_cluster()
    local original_query = {
        type = "select",
        selectList = {{type = "function_scalar", name = "CURRENT_CLUSTER"}}
    }
    assert_renders_to(original_query, 'SELECT CURRENT_CLUSTER')
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

function test_query_renderer.test_subselect()
    local original_query = {
        type = "select",
        selectList = {
            {type = "column", name = "NAME", tableName = "FRUITS"},
            {type = "column", name = "SUGAR_PERCENTAGE", tableName = "FRUITS"}
        },
        from = {type = "table", name = "FRUITS"},
        filter = {
            type = "predicate_greater",
            left = {type = "column", name = "SUGAR_PERCENTAGE", tableName = "FRUITS"},
            right = {
                type = "sub_select",
                selectList ={{type = "column", name = "SUGAR_PERCENTAGE", tableName = "SNACKS"}},
                from = {type = "table", name = "SNACKS"},
                filter = {
                    type = "predicate_equal",
                    left = {type = "column", name = "CATEGORY", tableName = "SNACKS"},
                    right = {type = "literal_string", value = "desert"}
                }
            }
        }
    }
    assert_renders_to(original_query,
        'SELECT "FRUITS"."NAME", "FRUITS"."SUGAR_PERCENTAGE" FROM "FRUITS"'
        .. ' WHERE ("FRUITS"."SUGAR_PERCENTAGE"'
        .. ' > ('
        .. 'SELECT "SNACKS"."SUGAR_PERCENTAGE" FROM "SNACKS" WHERE ("SNACKS"."CATEGORY" = \'desert\'))'
        .. ')'
    )
end

function test_query_renderer.test_join()
    for join_type, join_keyword in pairs(renderer.join_types) do
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "AMOUNT", tableName = "ORDERS"},
                {type = "column", name = "NAME", tableName = "ITEMS"},
            },
            from = {
                type = "join",
                join_type = join_type,
                left = {type = "table", name = "ORDERS"},
                right = {type = "table", name = "ITEMS"},
                condition = {
                    type = "predicate_equal",
                    left = {type = "column", name = "ITEM_ID", tableName = "ORDERS"},
                    right = {type = "column", name = "ITEM_ID", tableName = "ITEMS"}
                }
            }
        }
        assert_renders_to(original_query,
            'SELECT "ORDERS"."AMOUNT", "ITEMS"."NAME"'
            .. ' FROM "ORDERS" ' .. join_keyword .. ' JOIN "ITEMS"'
            .. ' ON ("ORDERS"."ITEM_ID" = "ITEMS"."ITEM_ID")'
        )
    end
end

function test_query_renderer.test_exists()
        local original_query = {
        type = "select",
        selectList = {
            {type = "literal_string", value = "yes"}
        },
        filter = {
            type = "predicate_exists",
            query = {
                type = "sub_select",
                selectList ={{type = "literal_bool", value = true}},
            }
        }
    }
    assert_renders_to(original_query,
        "SELECT 'yes' WHERE EXISTS(SELECT true)"
    )
end

function test_query_renderer.test_unknown_from_type_throws_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "literal_bool", value = false}
        },
        from = {
            type = "unknown"
        }
    }
    assert_rendering_error_contains(original_query, "unknown SQL FROM clause type")
end

function test_query_renderer.test_unknown_join_type_throws_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "literal_bool", value = false}
        },
        from = {
            type = "join",
            join_type = "illegal"
        }
    }
    assert_rendering_error_contains(original_query, "unknown join type")
end

function test_query_renderer.test_unknown_predicate_type_throws_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "predicate_illegal"}
        }
    }
    assert_rendering_error_contains(original_query, "unknown SQL predicate type")
end

function test_query_renderer.test_unknown_expression_type_throws_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "illegal"}
        },
    }
    assert_rendering_error_contains(original_query, "unknown SQL expression type")
end

function test_query_renderer.test_unknown_scalar_function_type_throws_error()
    local original_query = {
        type = "select",
        selectList = {
            {type = "function_scalar", name = "illegal"}
        },
    }
    assert_rendering_error_contains(original_query, "unsupported scalar function type")
end

function test_query_renderer.test_unknown_data_type_throws_error()
    local original_query = {
       type = "select",
       selectList = {
            {
                type = "function_scalar_cast", name = "CAST",
                dataType = {type = "illegal"},
                arguments = {
                    {type = "literal_string", value = "100"}
                }
            }
       }
    }
    assert_rendering_error_contains(original_query, "unknown data type")
end

os.exit(luaunit.LuaUnit.run())
