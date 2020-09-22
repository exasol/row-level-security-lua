local M = {
    supported_scalar_functions_list = {
        -- Numeric functions
        "ABS", "ACOS", "ASIN", "ATAN", "ATAN2", "CEIL", "COS", "COSH", "COT", "DEGREES", "DIV", "EXP", "FLOOR",
        "LN", "LOG", "MOD", "POWER", "RADIANS", "RAND", "ROUND", "SIGN", "SIN", "SINH", "SQRT", "TAN", "TANH",
        "TO_CHAR", "TO_NUMBER", "TRUNC",
        -- String functions
        "ASCII", "BIT_LENGTH", "CHR", "COLOGNE_PHONETIC", "CONCAT", "DUMP", "EDIT_DISTANCE", "INITCAP", "INSERT", "INSTR",
        "LENGTH", "LOCATE", "LOWER", "LPAD", "LTRIM", "OCTET_LENGTH", "REGEXP_INSTR", "REGEXP_REPLACE",
        "REGEXP_SUBSTR", "REPEAT", "REPLACE", "REVERSE", "RIGHT", "RPAD", "RTRIM", "SOUNDEX", "SPACE", "SUBSTR",
        "TRANSLATE", "TRIM", "UNICODE", "UNICODECHR", "UPPER",
        -- Date/Time functions
        "ADD_DAYS", "ADD_HOURS", "ADD_MINUTES", "ADD_MONTHS", "ADD_SECONDS", "ADD_WEEKS", "ADD_YEARS",
        "CONVERT_TZ", "CURRENT_DATE", "CURRENT_TIMESTAMP", "DATE_TRUNC", "DAY", "DAYS_BETWEEN", "DBTIMEZONE",
        "FROM_POSIX_TIME", "HOUR", "HOURS_BETWEEN", "LOCALTIMESTAMP", "MINUTE", "MINUTES_BETWEEN", "MONTH", "MONTH_BETWEEN",
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
        "BIT_AND", "BIT_CHECK", "BIT_LROTATE", "BIT_LSHIFT", "BIT_NOT", "BIT_OR", "BIT_RROTATE", "BIT_RSHIFT",
        "BIT_SET", "BIT_TO_NUM", "BIT_XOR",
        -- Other functions
        "CURRENT_SCHEMA", "CURRENT_SESSION", "CURRENT_STATEMENT", "CURRENT_USER", "GREATEST", "HASH_MD5",
        "HASHTYPE_MD5", "HASH_SHA", "HASH_SHA1", "HASHTYPE_SHA1", "HASH_SHA256", "HASHTYPE_SHA256", "HASH_SHA512",
        "HASHTYPE_SHA512", "HASH_TIGER", "HASHTYPE_TIGER", "IS_NUMBER", "IS_BOOLEAN", "IS_DATE", "IS_DSINTERVAL",
        "IS_YMINTERVAL", "IS_TIMESTAMP", "NULLIFZERO", "SYS_GUID", "ZEROIFNULL", "SESSION_PARAMETER"
    },
    supported_scalar_functions = {}
}

for index = 1, #M.supported_scalar_functions_list do
    M.supported_scalar_functions[M.supported_scalar_functions_list[index]] = true
end

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
        predicate_equal = "=", predicate_notequal = "<>", predicate_less = "<", predicate_greater = ">",
        predicate_and = "AND", predicate_or = "OR", predicate_not = "NOT"
    }

    -- forward declarations
    local append_unary_predicate, append_binary_predicate, append_iterated_predicate, append_expression,
        append_predicate_in

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

    local function append_scalar_function(scalar_function)
        local function_name = string.upper(scalar_function.name)
        if M.supported_scalar_functions[function_name] then
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

    local function append_scalar_function_extract(scalar_function_extract)
        local to_extract = string.upper(scalar_function_extract.toExtract)
        append("EXTRACT(")
        append(to_extract)
        append(" FROM ")
        append_expression(scalar_function_extract.arguments[1])
        append(")")
    end

    local function append_decimal(data_type)
        append("(")
        append(data_type.precision)
        append(",")
        append(data_type.scale)
        append(")")
    end

    local function append_char_or_varchar(data_type)
        append("(")
        append(data_type.size)
        append(")")
        local character_set = data_type.characterSet
        if (character_set ~= nil) then
            append(" ")
            append(character_set)
        end
    end

    local function append_timestamp(data_type)
        local with_local_time_zone = data_type.withLocalTimeZone
        if (with_local_time_zone ~= nil and with_local_time_zone == true) then
            append(" WITH LOCAL TIME ZONE")
        end
    end

    local function append_geometry(data_type)
        local srid = data_type.srid
        if srid ~= nil then
            append("(")
            append(srid)
            append(")")
        end
    end

    local function append_interval(data_type)
        if data_type.fromTo == "DAY TO SECONDS" then
            append(" DAY")
            local precision = data_type.precision
            if (precision ~= nil) then
                append("(")
                append(precision)
                append(")")
            end
            append(" TO SECOND")
            local fraction = data_type.fraction
            if (fraction ~= nil) then
                append("(")
                append(fraction)
                append(")")
            end
        else
            append(" YEAR")
            local precision = data_type.precision
            if (precision ~= nil) then
                append("(")
                append(precision)
                append(")")
            end
            append(" TO MONTH")
        end
    end

    local function append_hashtype(data_type)
        local bytesize = data_type.bytesize
        if bytesize ~= nil then
            append("(")
            append(bytesize)
            append(" BYTE)")
        end
    end

    local function append_data_type(data_type)
        local type = data_type.type
        append(type)
        if type == "DECIMAL" then
            append_decimal(data_type)
        elseif type == "VARCHAR" or type == "CHAR" then
            append_char_or_varchar(data_type)
        elseif type == "DOUBLE" or type == "DATE" or type == "BOOLEAN" then
            -- intentionally left empty
        elseif type == "TIMESTAMP" then
            append_timestamp(data_type)
        elseif type == "GEOMETRY" then
            append_geometry(data_type)
        elseif type == "INTERVAL" then
            append_interval(data_type)
        elseif type == "HASHTYPE" then
            append_hashtype(data_type)
        else
            error('E-VS-QR-4: Unable to render unknown data type "' .. type .. '".')
        end
    end

    local function append_scalar_function_cast(scalar_function_cast)
        append("CAST(")
        append_expression(scalar_function_cast.arguments[1])
        append(" AS ")
        append_data_type(scalar_function_cast.dataType)
        append(")")
    end

    local function append_scalar_function_json_value(scalar_function_cast_json_value)
        local arguments = scalar_function_cast_json_value.arguments
        local empty_behavior = scalar_function_cast_json_value.emptyBehavior
        local error_behavior = scalar_function_cast_json_value.errorBehavior
        append("JSON_VALUE(")
        append_expression(arguments[1])
        append(", ")
        append_expression(arguments[2])
        append(" RETURNING ")
        append_data_type(scalar_function_cast_json_value.dataType)
        append(" ")
        append(empty_behavior.type)
        if empty_behavior.type == "DEFAULT" then
            append(" ")
            append_expression(empty_behavior.expression)
        end
        append(" ON EMPTY ")
        append(error_behavior.type)
        if error_behavior.type == "DEFAULT" then
            append(" ")
            append_expression(error_behavior.expression)
        end
        append(" ON ERROR)")
    end

    local function append_scalar_function_case(scalar_function_case)
        local arguments = scalar_function_case.arguments
        local results = scalar_function_case.results
        append("CASE ")
        append_expression(scalar_function_case.basis)
        for i = 1, #arguments do
            local argument = arguments[i]
            local result = results[i]
            append(" WHEN ")
            append_expression(argument)
            append(" THEN ")
            append_expression(result)
        end
        if (#results > #arguments) then
            append(" ELSE ")
            append_expression(results[#results])
        end
        append(" END")
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
        if type == "equal" or type == "notequal" or type == "greater" or type == "less" then
            append_binary_predicate(operand)
        elseif type == "not" then
            append_unary_predicate(operand)
        elseif type == "and" or type == "or" then
            append_iterated_predicate(operand)
        elseif type == "in_constlist" then
            append_predicate_in(operand)
        else
            error('E-VS-QR-2: Unable to render unknown SQL predicate type "' .. type .. '".')
        end
    end

    local function append_quoted_literal_expression(literal_expression)
        append("'")
        append(literal_expression.value)
        append("'")
    end

    append_expression = function (expression)
        local type = expression.type
        if type == "column" then
            append_column_reference(expression)
        elseif(type == "literal_exactnumeric" or type == "literal_boolean" or type == "literal_double") then
            append(expression.value)
        elseif (type == "literal_string") then
            append_quoted_literal_expression(expression)
        elseif (type == 'literal_date') then
            append("DATE ")
            append_quoted_literal_expression(expression)
        elseif (type == 'literal_timestamp') then
            append("TIMESTAMP ")
            append_quoted_literal_expression(expression)
        elseif (type == "function_scalar") then
            append_scalar_function(expression)
        elseif (type == "function_scalar_extract") then
            append_scalar_function_extract(expression)
        elseif (type == "function_scalar_cast") then
            append_scalar_function_cast(expression)
        elseif (type == "function_scalar_json_value") then
            append_scalar_function_json_value(expression)
        elseif (type == "function_scalar_case") then
            append_scalar_function_case(expression)
        elseif (string.starts_with(type, "predicate_")) then
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
    
    append_predicate_in = function (predicate)
        append("(")
        append_expression(predicate.expression)
        append(" IN (")
        local arguments = predicate.arguments
        for i = 1, #arguments do
            comma(i)
            append_expression(arguments[i])
        end
        append("))")
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
