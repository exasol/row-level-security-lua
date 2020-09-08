local M = {}

-- TODO: Move to a separate module!
--
function string.starts_with(text, start)
    return start == string.sub(text, 1, string.len(start))
end

---
-- Create a new query renderer.
--
-- @param query query to be rendered
--
-- @return new query renderer instance
--
function M.new (query)
    local self = {original_query = query, query_elements = {}}
    local OPERATORS = {
        predicate_equal = "=", predicate_less = "<", predicate_greater = ">",
        predicate_and = "AND", predicate_or = "OR", predicate_not = "NOT"
    }

    -- forward declarations
    local append_unary_predicate, append_binary_predicate, append_iterated_predicate, append_expression

    local function append(value)
        self.query_elements[#self.query_elements + 1] = value
    end

    local function comma(index)
        if index > 1 then
            self.query_elements[#self.query_elements + 1] = ", "
        end
    end

    local function append_column_reference(column)
        append('"')
        append(column.tableName)
        append('"."')
        append(column.name)
        append('"')
    end

    -- Currently unsupported scalar function: EXTRACT, CASE, CAST, JSON_VALUE, SESSION_PARAMETER
    -- TODO: implement special cases: https://github.com/exasol/row-level-security-lua/issues/10
    local function append_scalar_function(scalar_function)
        local supported_scalar_functions = {
            -- Numeric functions
            ABS = true, ACOS = true, ASIN = true, ATAN = true, ATAN2 = true, CEIL = true, COS = true, COSH = true,
            COT = true, DEGREES = true, DIV = true, EXP = true, FLOOR = true, LN = true, LOG = true, MOD = true,
            POWER = true, RADIANS = true, RAND = true, ROUND = true, SIGN = true, SIN = true, SINH = true, SQRT = true,
            TAN = true, TANH = true, TO_CHAR = true, TO_NUMBER = true, TRUNC = true,
            -- String functions
            ASCII = true, BIT_LENGTH = true, CHR = true, COLOGNE_PHONETIC = true, CONCAT = true, DUMP = true,
            EDIT_DISTANCE = true, INSERT = true, INSTR = true, LENGTH = true, LOCATE = true, LOWER = true, LPAD = true,
            LTRIM = true, OCTET_LENGTH = true, REGEXP_INSTR = true, REGEXP_REPLACE = true, REGEXP_SUBSTR = true,
            REPEAT = true, REPLACE = true, REVERSE = true, RIGHT = true, RPAD = true, RTRIM = true, SOUNDEX = true,
            SPACE = true, SUBSTR = true, TRANSLATE = true, TRIM = true, UNICODE = true, UNICODECHR = true, UPPER = true,
            -- Date/Time functions
            ADD_DAYS = true, ADD_HOURS = true, ADD_MINUTES = true, ADD_MONTHS = true, ADD_SECONDS = true,
            ADD_WEEKS = true, ADD_YEARS = true, CONVERT_TZ = true, CURRENT_DATE = true, CURRENT_TIMESTAMP = true,
            DATE_TRUNC = true, DAY = true, DAYS_BETWEEN = true, DBTIMEZONE = true, HOURS_BETWEEN = true,
            LOCALTIMESTAMP = true, MINUTE = true, MINUTES_BETWEEN = true, MONTH = true, MONTH_BETWEEN = true,
            NUMTODSINTERVAL = true, NUMTOYMINTERVAL = true, POSIX_TIME = true, SECOND = true, SECONDS_BETWEEN = true,
            SESSIONTIMEZONE = true, SYSDATE = true, SYSTIMESTAMP = true, TO_DATE = true, TO_DSINTERVAL = true,
            TO_TIMESTAMP = true, TO_YMINTERVAL = true, WEEK = true, YEAR = true, YEARS_BETWEEN = true,
            -- Geospatial functions
            ST_AREA = true, ST_BOUNDARY = true, ST_BUFFER = true, ST_CENTROID = true, ST_CONTAINS = true,
            ST_CONVEXHULL = true, ST_CROSSES = true, ST_DIFFERENCE = true, ST_DIMENSION = true, ST_DISJOINT = true,
            ST_DISTANCE = true, ST_ENDPOINT = true, ST_ENVELOPE = true, ST_EQUALS = true, ST_EXTERIORRING = true,
            ST_FORCE2D = true, ST_GEOMETRYN = true, ST_GEOMETRYTYPE = true, ST_INTERIORRINGN = true,
            ST_INTERSECTION = true, ST_INTERSECTS = true, ST_ISCLOSED = true, ST_ISEMPTY = true, ST_ISRING = true,
            ST_ISSIMPLE = true, ST_LENGTH = true, ST_NUMGEOMETRIES = true, ST_NUMINTERIORRINGS = true,
            ST_NUMPOINTS = true, ST_OVERLAPS = true, ST_POINTN = true, ST_SETSRID = true, ST_STARTPOINT = true,
            ST_SYMDIFFERENCE = true, ST_TOUCHES = true, ST_TRANSFORM = true, ST_UNION = true, ST_WITHIN = true,
            ST_X = true, ST_Y = true,
            -- Bitwise functions
            BIT_AND = true, BIT_CHECK = true, BIT_NOT = true, BIT_OR = true, BIT_SET = true, BIT_TO_NUM = true,
            BIT_XOR = true,
            -- Other functions
            CURRENT_SCHEMA = true, CURRENT_SESSION = true, CURRENT_STATEMENT = true, CURRENT_USER = true,
            GREATEST = true, HASH_MD5 = true, HASHTYPE_MD5 = true, HASH_SHA = true, HASH_SHA1 = true,
            HASHTYPE_SHA1 = true, HASH_SHA256 = true, HASHTYPE_SHA256 = true, HASH_SHA512 = true,
            HASHTYPE_SHA512 = true, HASH_TIGER = true, HASHTYPE_TIGER = true, IS_NUMBER = true, IS_BOOLEAN = true,
            IS_DATE = true, IS_DSINTERVAL = true, IS_YMINTERVAL = true, IS_TIMESTAMP = true, NULLIFZERO = true,
            SYS_GUID = true, ZEROIFNULL = true
        }
        local function_name = string.upper(scalar_function.name)
        if supported_scalar_functions[function_name] then
            append(function_name)
            if function_name ~= "CURRENT_USER" and function_name ~= "SYSDATE" and function_name ~= "CURRENT_SCHEMA"
                    and function_name ~= "CURRENT_SESSION" and function_name ~= "CURRENT_STATEMENT" then
                append("(")
                local arguments = scalar_function.arguments
                if (arguments) then
                    for i = 1, #arguments do
                        comma(i)
                        append_expression(arguments[i])
                    end
                end
                append(")")
            end
        else
            error('E-VS-QR-3: Unable to render unsupported scalar function type "' .. function_name .. '".')
        end
    end

    local function append_select_list_elements(select_list)
        for i = 1, #select_list do
            local element = select_list[i]
            local type = element.type
            comma(i)
            append_expression(element)
        end
    end

    local function append_select_list()
        local select_list = self.original_query.selectList
        if not select_list then
            append("*")
        else
            append_select_list_elements(select_list)
        end
    end

    local function append_from()
        if self.original_query.from then
            append(' FROM "')
            if self.original_query.from.schema then
                append(self.original_query.from.schema)
                append('"."')
            end
            append(self.original_query.from.name)
            append('"')
        end
    end

    local function append_predicate(operand)
        local type = string.sub(operand.type, 11)
        if type == "equal" or type == "greater" or type == "less" then
            append_binary_predicate(operand)
        elseif type == "not" then
            append_unary_predicate(operand)
        elseif type == "and" or type == "or" then
            append_iterated_predicate(operand)
        else
            error('E-VS-QR-2: Unable to render unknown SQL predicate type "' .. type .. '".')
        end
    end

    append_expression = function (expression)
        local type = expression.type
        if type == "column" then
            append_column_reference(expression)
        elseif(type == "literal_exactnumeric" or type == "literal_boolean" or type == "literal_double") then
            append(expression.value)
        elseif(type == "literal_string" or type == 'literal_date' or type == 'literal_timestamp') then
            append("'")
            append(expression.value)
            append("'")
        elseif(type == "function_scalar") then
            append_scalar_function(expression)
        elseif(string.starts_with(type, "predicate_")) then
            append_predicate(expression)
        else
            error('E-VS-QR-1: Unable to render unknown SQL expression type "' .. expression.type .. '".')
        end
    end

    append_unary_predicate = function (predicate)
        local type = predicate.type
        append("(")
        append(OPERATORS[predicate.type])
        append(" ")
        append_expression(predicate.expression)
        append(")")
    end

    append_binary_predicate = function (predicate)
        append("(")
        append_expression(predicate.left)
        append(" ")
        append(OPERATORS[predicate.type])
        append(" ")
        append_expression(predicate.right)
        append(")")
    end

    append_iterated_predicate = function (predicate)
        append("(")
        local expressions = predicate.expressions
        for i = 1, #expressions do
            if i > 1 then
                append(" ")
                append(OPERATORS[predicate.type])
                append(" ")
            end
            append_expression(expressions[i])
        end
        append(")")
    end

    local function append_filter()
        if self.original_query.filter then
            append(" WHERE ")
            append_predicate(self.original_query.filter)
        end
    end

    --- Render the query to a string.
    --
    -- @return query as string
    --
    local function render()
        append("SELECT ")
        append_select_list()
        append_from()
        append_filter()
        return table.concat(self.query_elements, "")
    end

    return {render = render}
end

return M
