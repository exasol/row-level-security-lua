local M = {}

function string.startsWith(text, start)
    return start == string.sub(text,1,string.len(start))
end

function M.new (query)
    local self = {original_query = query, query_elements = {}}
    local OPERATORS = {
        predicate_equal = "=", predicate_less = "<", predicate_greater = ">", predicate_and = "AND", predicate_or = "or"
    }
    
    local function append(value)
        self.query_elements[#self.query_elements + 1] = value
    end
    
    local function comma(index)
        if(index > 1) then
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
    
    local function append_select_list()
        for i, select_list_element in ipairs(self.original_query.selectList) do
            local type = select_list_element.type
            comma(i)
            if(type == "column") then
                append_column_reference(select_list_element)
            end
        end
    end
    
    local function append_from()
        append(' FROM "')
        append(self.original_query.from.name)
        append('"')
    end
    
    local append_predicate -- forward declaration

    local function appendOperand(operand)
        if(operand.type == "column") then
            append_column_reference(operand)
        elseif(operand.type == "literal_exactnumeric") then
            append(operand.value)
        elseif(operand.type == "literal_string") then
            append("'")
            append(operand.value)
            append("'")
        elseif(string.startsWith(operand.type, "predicate_")) then
            append_predicate(operand)
        end
    end

    append_predicate = function (predicate)
        local type = predicate.type
        append("(")
        appendOperand(predicate.left)
        append(" ")
        append(OPERATORS[type])
        append(" ")
        appendOperand(predicate.right)
        append(")")
    end
    
    local function append_filter()
        if(self.original_query.filter) then
            append(" WHERE ")
            append_predicate(self.original_query.filter)
        end
    end
    
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