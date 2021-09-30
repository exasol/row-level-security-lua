---
-- This class provides an abstraction to the access of adapter properties.
--
local text = require("text")

local M = {
    SCHEMA_NAME_PROPERTY = "SCHEMA_NAME",
    TABLE_FILTER_PROPERTY = "TABLE_FILTER",
    raw_properties = {}
}

---
-- Create a new instance of adapter properties
--
-- @param object preinitialized object (optional)
--
-- @return new instance
--
function M:new (object)
    object = object or {}
    self.__index = self
    setmetatable(object, self)
    return object
end

---
-- Get the value of a property.
--
-- @param property_name name of the property to get
--
-- @return property value
--
function M:get(property_name)
    return self.raw_properties[property_name]
end

---
-- Check if the property is set.
--
-- @param property_name name of the property to check
--
-- @return <code>true</code> if the property is set (i.e. not <code>nil</code>)
--
function M:is_property_set(property_name)
    return self:get(property_name) ~= nil
end

---
-- Check if the property has a non-empty value.
--
-- @param property_name name of the property to check
--
-- @return <code>true</code> if the property has a non-empty value (i.e. not <code>nil</code> or an empty string)
--
function M:has_value(property_name)
    local value = self:get(property_name)
    return value ~= nil and value ~= ""
end

---
-- Check if the property value is empty.
--
-- @param property_name name of the property to check
--
-- @return <code>true</code> if the property's value is empty (i.e. the property is set to an empty string)
--
function M:is_empty(property_name)
    return self:get(property_name) == ""
end

---
-- Validate the adapter properties.
--
-- @raise validation error
--
-- @return self for fluent programming
--
function M:validate()
    if not self:has_value(M.SCHEMA_NAME_PROPERTY) then
        error('F-RLS-PROP-1: Missing mandatory property "' .. M.SCHEMA_NAME_PROPERTY
            .. '". Please define the name of the source schema.');
    end
    if self:is_property_set(M.TABLE_FILTER_PROPERTY) then
        if self:is_empty(M.TABLE_FILTER_PROPERTY) then
            error("F-RLS-PROP-2: Table filter property must not be empty. Please either remove the property "
                .. M.TABLE_FILTER_PROPERTY
                .. " or provide a comma separated list of tables to be included in the Virtual Schema.")
        end
    end
    return self
end

---
-- Get the name of the Virtual Schema's source schema.
--
-- @return name of the source schema
--
function M:get_schema_name()
    return self:get(M.SCHEMA_NAME_PROPERTY)
end

---
-- Get the list of tables that the Virtual Schema should show after applying the table filter.
--
-- @return list of tables
--
function M:get_table_filter()
    local filtered_tables = self:get(M.TABLE_FILTER_PROPERTY)
    return text.split(filtered_tables)
end

---
-- Factory method for a properties object.
--
-- @param raw_properties table containing properties with property names as keys and property values as values
--
-- @return new properties instance
--
function M.create(raw_properties)
    return M:new({raw_properties = raw_properties})
end

return M
