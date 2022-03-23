local AbstractVirtualSchemaAdapter = require("exasolvs.AbstractVirtualSchemaAdapter")
local MetadataReader = require("exasolrls.MetadataReader")
local AdapterProperties = require("exasolrls.AdapterProperties")
local adapter_capabilities = require("exasolrls.adapter_capabilities")

-- Derive from AbstractVirtualSchemaAdapter
local RlsAdapter = AbstractVirtualSchemaAdapter:new()
local VERSION <const> = "1.1.1"

---
-- Create an <code>RlsAdapter</code>.
--
-- @param object to initialize the adapter with
--
-- @return RlsAdapter
--
function RlsAdapter.new(metadata_reader)
    self = AbstractVirtualSchemaAdapter:new()
    self.metadata_reader = metadata_reader

    ---
    -- Get the version number of the Virtual Schema adapter.
    --
    -- @return Virtual Schema adapter version
    --
    function self.get_version()
        return VERSION
    end

    local function get_adapter_properties(request)
        local properties = AdapterProperties.new(request.schemaMetadataInfo.properties)
        properties:validate()
        return properties
    end

    local function handle_schema_scanning_request(request)
        local properties = get_adapter_properties(request)
        return self.metadata_reader:read(properties:get_schema_name(), properties:get_table_filter())
    end

    ---
    -- Create a virtual schema.
    --
    -- @param _ Exasol metadata (not used)
    --
    -- @param request virtual schema request
    --
    -- @return response containing the metadata for the virtual schema like table and column structure
    --
    function self.create_virtual_schema(_, request)
        return {type = "createVirtualSchema", schemaMetadata = handle_schema_scanning_request(request)}
    end

    function self._define_capabilities()
        return adapter_capabilities
    end

    return self
end

return RlsAdapter