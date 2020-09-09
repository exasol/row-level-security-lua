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
            expected = "SELECT DAY('2010-10-20')"
        },
        {
            func_name = "MINUTE",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT MINUTE('2010-10-20 11:59:40.123')"
        },
        {
            func_name = "MONTH",
            arg_type = "literal_date",
            arg_value = "2010-10-20",
            expected = "SELECT MONTH('2010-10-20')"
        },
        {
            func_name = "POSIX_TIME",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT POSIX_TIME('2010-10-20 11:59:40.123')"
        },
        {
            func_name = "SECOND",
            arg_type = "literal_timestamp",
            arg_value = "2010-10-20 11:59:40.123",
            expected = "SELECT SECOND('2010-10-20 11:59:40.123')"
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
            expected = "SELECT WEEK('2012-01-05')"
        },
        {
            func_name = "YEAR",
            arg_type = "literal_date",
            arg_value = "2012-01-05",
            expected = "SELECT YEAR('2012-01-05')"
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
            func_name = "HASH_SHA",
            arg_type = "literal_string",
            arg_value = "abc",
            expected = "SELECT HASH_SHA('abc')"
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
            func_name = "NULLIFZERO",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT NULLIFZERO(5)"
        },
        {
            func_name = "ZEROIFNULL",
            arg_type = "literal_exactnumeric",
            arg_value = 5,
            expected = "SELECT ZEROIFNULL(5)"
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
            second_arg_value = "\+?\d+",
            expected = "SELECT REGEXP_INSTR('Phone: +497003927877678', '\+?\d+')"
        },
        {
            func_name = "REGEXP_REPLACE",
            first_arg_type = "literal_string",
            first_arg_value = "Phone: +497003927877678",
            second_arg_type = "literal_string",
            second_arg_value = "\+?\d+",
            expected = "SELECT REGEXP_REPLACE('Phone: +497003927877678', '\+?\d+')"
        },
        {
            func_name = "REGEXP_SUBSTR",
            first_arg_type = "literal_string",
            first_arg_value = "Phone: +497003927877678",
            second_arg_type = "literal_string",
            second_arg_value = "\+?\d+",
            expected = "SELECT REGEXP_SUBSTR('Phone: +497003927877678', '\+?\d+')"
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
            expected = "SELECT ADD_DAYS('2000-02-28', 2)"
        },
        {
            func_name = "ADD_HOURS",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_HOURS('2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_MINUTES",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_MINUTES('2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_MONTHS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_MONTHS('2000-02-28', 2)"
        },
        {
            func_name = "ADD_SECONDS",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 00:00:00",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_SECONDS('2000-01-01 00:00:00', 2)"
        },
        {
            func_name = "ADD_WEEKS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_WEEKS('2000-02-28', 2)"
        },
        {
            func_name = "ADD_YEARS",
            first_arg_type = "literal_date",
            first_arg_value = "2000-02-28",
            second_arg_type = "literal_exactnumeric",
            second_arg_value = 2,
            expected = "SELECT ADD_YEARS('2000-02-28', 2)"
        },
        {
            func_name = "DATE_TRUNC",
            first_arg_type = "literal_string",
            first_arg_value = "month",
            second_arg_type = "literal_date",
            second_arg_value = "2006-12-31",
            expected = "SELECT DATE_TRUNC('month', '2006-12-31')"
        },
        {
            func_name = "DAYS_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT DAYS_BETWEEN('1999-12-31', '2000-01-01')"
        },
        {
            func_name = "HOURS_BETWEEN",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 12:00:00",
            second_arg_type = "literal_timestamp",
            second_arg_value = "2000-01-01 11:01:05.1",
            expected = "SELECT HOURS_BETWEEN('2000-01-01 12:00:00', '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "MINUTES_BETWEEN",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2000-01-01 12:00:00",
            second_arg_type = "literal_timestamp",
            second_arg_value = "2000-01-01 11:01:05.1",
            expected = "SELECT MINUTES_BETWEEN('2000-01-01 12:00:00', '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "MONTH_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT MONTH_BETWEEN('1999-12-31', '2000-01-01')"
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
            expected = "SELECT SECONDS_BETWEEN('2000-01-01 12:00:00', '2000-01-01 11:01:05.1')"
        },
        {
            func_name = "YEARS_BETWEEN",
            first_arg_type = "literal_date",
            first_arg_value = "1999-12-31",
            second_arg_type = "literal_date",
            second_arg_value = "2000-01-01",
            expected = "SELECT YEARS_BETWEEN('1999-12-31', '2000-01-01')"
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
            func_name = "CONVERT_TZ",
            first_arg_type = "literal_timestamp",
            first_arg_value = "2012-05-10 12:00:00",
            second_arg_type = "literal_string",
            second_arg_value = "UTC",
            third_arg_type = "literal_string",
            third_arg_value = "Europe/Berlin",
            expected = "SELECT CONVERT_TZ('2012-05-10 12:00:00', 'UTC', 'Europe/Berlin')"
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
