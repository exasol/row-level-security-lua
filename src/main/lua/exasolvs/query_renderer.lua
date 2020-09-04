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

    local function append_scalar_function(scalar_function)
        local supported_scalar_functions = {
            -- Numeric functions
            ABS = true, ACOS = true, ASIN = true, ATAN = true, ATAN2 = true, CEIL = true, COS = true, COSH = true,
            COT = true, DEGREES = true, DIV = true, EXP = true, FLOOR = true, LN = true, LOG = true, LOG10 = true,
            LOG2 = true, MOD = true, PI = true, POWER = true, RADIANS = true, RAND = true, ROUND = true, SIGN = true,
            SIN = true, SINH = true, SQRT = true, TAN = true, TO_CHAR = true, TO_NUMBER = true, TRUNC = true,
            -- String Functions
            ASCII = true, BIT_LENGTH = true, CHARACTER_LENGTH = true, CHR = true, COLOGNE_PHONETIC = true,
            CONCAT = true, DUMP = true, EDIT_DISTANCE = true, INITCAP = true, INSERT = true, INSTR = true, LCASE = true,
            LEFT = true, LENGTH = true, LOCATE = true, LOWER = true, LPAD = true, LTRIM = true, MID = true,
            OCTET_LENGTH = true,
            CURRENT_USER = true, LOWER = true, UPPER = true,
        }
        local function_name = string.upper(scalar_function.name)
        if supported_scalar_functions[function_name] then
            append(function_name)
            if function_name ~= "CURRENT_USER" then
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
        elseif(type == "literal_string") then
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
