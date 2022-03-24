local text = require("text")
local exaerror = require("exaerror")

--- This class abstracts access to the user-defined properties of the Virtual Schema.
-- @type AdapterProperties
local AdapterProperties = {}

local SCHEMA_NAME_PROPERTY <const> = "SCHEMA_NAME"
local TABLE_FILTER_PROPERTY <const> = "TABLE_FILTER"

--- Create a new instance of adapter properties.
-- @param raw_properties unprocessed properties as provided by the Virtual Schema API
-- @return new instance
function AdapterProperties:new (raw_properties)
    local object = {raw_properties = raw_properties}
    self.__index = self
    setmetatable(object, self)
    return object
end


--- Get the value of a property.
-- @param property_name name of the property to get
-- @return property value
function AdapterProperties:get(property_name)
    return self.raw_properties[property_name]
end

--- Check if the property is set.
-- @param property_name name of the property to check
-- @return <code>true</code> if the property is set (i.e. not <code>nil</code>)
function AdapterProperties:is_property_set(property_name)
    return self:get(property_name) ~= nil
end

--- Check if the property has a non-empty value.
-- @param property_name name of the property to check
-- @return <code>true</code> if the property has a non-empty value (i.e. not <code>nil</code> or an empty string)
function AdapterProperties:has_value(property_name)
    local value = self:get(property_name)
    return value ~= nil and value ~= ""
end

--- Check if the property value is empty.
-- @param property_name name of the property to check
-- @return <code>true</code> if the property's value is empty (i.e. the property is set to an empty string)
function AdapterProperties:is_empty(property_name)
    return self:get(property_name) == ""
end

--- Validate the adapter properties.
-- @raise validation error
function AdapterProperties:validate()
    if not self:has_value(SCHEMA_NAME_PROPERTY) then
        exaerror.create("F-RLS-PROP-1", "Missing mandatory property '" .. SCHEMA_NAME_PROPERTY .. "' ")
                :add_mitigations("Please define the name of the source schema."):raise(0)
    end
    if self:is_property_set(TABLE_FILTER_PROPERTY) and self:is_empty(TABLE_FILTER_PROPERTY) then
        exaerror.create("F-RLS-PROP-2", "Table filter property '" .. TABLE_FILTER_PROPERTY .. "' must not be empty.")
                :add_mitigations("Please either remove the property or provide a comma separated list of tables"
                .. " to be included in the Virtual Schema."):raise(0)
    end
end

---
-- Get the name of the Virtual Schema's source schema.
--
-- @return name of the source schema
--
function AdapterProperties:get_schema_name()
    return self:get(SCHEMA_NAME_PROPERTY)
end

---
-- Get the list of tables that the Virtual Schema should show after applying the table filter.
--
-- @return list of tables
--
function AdapterProperties:get_table_filter()
    local filtered_tables = self:get(TABLE_FILTER_PROPERTY)
    return text.split(filtered_tables)
end

return AdapterProperties