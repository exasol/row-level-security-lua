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
        local supported_scalar_functions_list = {
            -- Numeric functions
            "ABS", "ACOS", "ASIN", "ATAN", "ATAN2", "CEIL", "COS", "COSH", "COT", "DEGREES", "DIV", "EXP", "FLOOR",
            "LN", "LOG", "MOD", "POWER", "RADIANS", "RAND", "ROUND", "SIGN", "SIN", "SINH", "SQRT", "TAN", "TANH",
            "TO_CHAR", "TO_NUMBER", "TRUNC",
            -- String functions
            "ASCII", "BIT_LENGTH", "CHR", "COLOGNE_PHONETIC", "CONCAT", "DUMP", "EDIT_DISTANCE", "INSERT", "INSTR",
            "LENGTH", "LOCATE", "LOWER", "LPAD", "LTRIM", "OCTET_LENGTH", "REGEXP_INSTR", "REGEXP_REPLACE",
            "REGEXP_SUBSTR", "REPEAT", "REPLACE", "REVERSE", "RIGHT", "RPAD", "RTRIM", "SOUNDEX", "SPACE", "SUBSTR",
            "TRANSLATE", "TRIM", "UNICODE", "UNICODECHR", "UPPER",
            -- Date/Time functions
            "ADD_DAYS", "ADD_HOURS", "ADD_MINUTES", "ADD_MONTHS", "ADD_SECONDS", "ADD_WEEKS", "ADD_YEARS",
            "CONVERT_TZ", "CURRENT_DATE", "CURRENT_TIMESTAMP", "DATE_TRUNC", "DAY", "DAYS_BETWEEN", "DBTIMEZONE",
            "HOURS_BETWEEN", "LOCALTIMESTAMP", "MINUTE", "MINUTES_BETWEEN", "MONTH", "MONTH_BETWEEN",
            "NUMTODSINTERVAL", "NUMTOYMINTERVAL", "POSIX_TIME", "SECOND", "SECONDS_BETWEEN", "SESSIONTIMEZONE",
            "SYSDATE", "SYSTIMESTAMP", "TO_DATE", "TO_DSINTERVAL", "TO_TIMESTAMP", "TO_YMINTERVAL", "WEEK", "YEAR",
            "YEARS_BETWEEN",
            -- Geospatial functions
            "ST_AREA", "ST_BOUNDARY", "ST_BUFFER", "ST_CENTROID", "ST_CONTAINS", "ST_CONVEXHULL", "ST_CROSSES",
            "ST_DIFFERENCE", "ST_DIMENSION", "ST_DISJOINT", "ST_DISTANCE", "ST_ENDPOINT", "ST_ENVELOPE", "ST_EQUALS",
            "ST_EXTERIORRING", "ST_FORCE2D", "ST_GEOMETRYN", "ST_GEOMETRYTYPE", "ST_INTERIORRINGN", "ST_INTERSECTION",
            "ST_INTERSECTS", "ST_ISCLOSED", "ST_ISEMPTY", "ST_ISRING", "ST_ISSIMPLE", "ST_LENGTH", "ST_NUMGEOMETRIES",
            "ST_NUMINTERIORRINGS", "ST_NUMPOINTS", "ST_OVERLAPS", "ST_POINTN", "ST_SETSRID", "ST_STARTPOINT",
            "ST_SYMDIFFERENCE", "ST_TOUCHES", "ST_TRANSFORM", "ST_UNION", "ST_WITHIN", "ST_X", "ST_Y",
            -- Bitwise functions
            "BIT_AND", "BIT_CHECK", "BIT_NOT", "BIT_OR", "BIT_SET", "BIT_TO_NUM", "BIT_XOR",
            -- Other functions
            "CURRENT_SCHEMA", "CURRENT_SESSION", "CURRENT_STATEMENT", "CURRENT_USER", "GREATEST", "HASH_MD5",
            "HASHTYPE_MD5", "HASH_SHA", "HASH_SHA1", "HASHTYPE_SHA1", "HASH_SHA256", "HASHTYPE_SHA256", "HASH_SHA512",
            "HASHTYPE_SHA512", "HASH_TIGER", "HASHTYPE_TIGER", "IS_NUMBER", "IS_BOOLEAN", "IS_DATE", "IS_DSINTERVAL",
            "IS_YMINTERVAL", "IS_TIMESTAMP", "NULLIFZERO", "SYS_GUID", "ZEROIFNULL"
        }
        local supported_scalar_functions = {}
        for index = 1, #supported_scalar_functions_list do
            supported_scalar_functions[supported_scalar_functions_list[index]] = true
        end

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
