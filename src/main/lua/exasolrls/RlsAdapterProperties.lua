local text = require("text")
local exaerror = require("exaerror")
local AdapterProperties = require("exasolvs/AdapterProperties")

--- This class abstracts access to the user-defined properties of the Virtual Schema.
-- @type RlsAdapterProperties
local RlsAdapterProperties = AdapterProperties:new()

--- Factory method for RLS adapter properties
-- @param raw_properties comma-separated list of property names
-- @return RLS adapter properties object
function RlsAdapterProperties.create(raw_properties)
    return RlsAdapterProperties:new({raw_properties = raw_properties})
end

--- Create a new <code>RlsAdapterProperties</code> instance
-- @param object pre-initialized object
-- @return new RLS adaper properties
function RlsAdapterProperties:new(object)
    object = AdapterProperties.new(self, object)
    self.__index = self
    setmetatable(object, self)
    return object
end

local SCHEMA_NAME_PROPERTY <const> = "SCHEMA_NAME"
local TABLE_FILTER_PROPERTY <const> = "TABLE_FILTER"

--- Validate the adapter properties.
-- @raise validation error
function RlsAdapterProperties:validate()
    AdapterProperties.validate(self) -- super call
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

--- Get the name of the Virtual Schema's source schema.
-- @return name of the source schema
function RlsAdapterProperties:get_schema_name()
    return self:get(SCHEMA_NAME_PROPERTY)
end

--- Get the list of tables that the Virtual Schema should show after applying the table filter.
-- @return list of tables
function RlsAdapterProperties:get_table_filter()
    local filtered_tables = self:get(TABLE_FILTER_PROPERTY)
    return text.split(filtered_tables)
end

return RlsAdapterProperties