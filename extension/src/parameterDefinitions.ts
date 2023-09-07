import { Parameter, SelectOption } from "@exasol/extension-manager-interface";

/**
 * This describes all mandatory and optional parameters for creating an instance of this extension.
 */
interface AllParameters {
    virtualSchemaName: Parameter
    schemaName: Parameter
    excludedCapabilities: Parameter
    tableFilter: Parameter
    debugAddress: Parameter
    logLevel: Parameter
}

const REMOTELOG_LUA_LOG_LEVELS: string[] = ["NONE", "FATAL", "ERROR", "WARN", "INFO", "CONFIG", "DEBUG", "TRACE"];
const LOG_LEVEL_OPTIONS: SelectOption[] = REMOTELOG_LUA_LOG_LEVELS.map(level => { return { id: level, name: level } })

const allParams: AllParameters = {
    virtualSchemaName: { id: "virtualSchemaName", name: "Name of the new virtual schema", type: "string", required: true },

    // Virtual Schema parameters
    schemaName: { id: "SCHEMA_NAME", name: "Name of the schema for which to apply row-level security", type: "string", required: true },
    excludedCapabilities: { id: "EXCLUDED_CAPABILITIES", name: "Comma-separated list of capabilities that should not be pushed-down, e.g. 'SELECTLIST_PROJECTION, ORDER_BY_COLUMN'", type: "string", required: false },
    tableFilter: { id: "TABLE_FILTER", name: "Comma-separated list of tables that should be added to the schema, e.g. 'ORDERS, ORDER_ITEMS, PRODUCTS'. If this is empty, all tables are added.", type: "string", required: false },
    debugAddress: { id: "DEBUG_ADDRESS", name: "Network address and port to which to send debug output, e.g. '192.168.179.38:3000'", type: "string", required: false },
    logLevel: { id: "LOG_LEVEL", name: "Log level for debug output", type: "select", required: false, options: LOG_LEVEL_OPTIONS },
};


export function getAllParameterDefinitions(): AllParameters {
    return allParams;
}

export function createInstanceParameters(): Parameter[] {
    return [
        allParams.virtualSchemaName,
        allParams.schemaName,
        allParams.excludedCapabilities,
        allParams.tableFilter,
        allParams.debugAddress,
        allParams.logLevel,
    ];
}