import { Parameter } from "@exasol/extension-manager-interface";

export type ScopedParameter = Parameter & { scope: "general" | "vs" }
export type ScopedParameters = { [key: string]: ScopedParameter }

const allParams: ScopedParameters = {
    virtualSchemaName: { scope: "general", id: "virtualSchemaName", name: "Name of the new virtual schema", type: "string", required: true },

    // Virtual Schema parameters
    schemaName: { scope: "vs", id: "SCHEMA_NAME", name: "Name of the schema for which to apply row-level security", type: "string", required: true, multiline: false },
    excludedCapabilities: { scope: "vs", id: "EXCLUDED_CAPABILITIES", name: "Comma-separated list of capabilities that should not be pushed-down, e.g. 'SELECTLIST_PROJECTION, ORDER_BY_COLUMN'", type: "string", required: false, multiline: false },
    tableFilter: { scope: "vs", id: "TABLE_FILTER", name: "Comma-separated list of tables that should be added to the schema, e.g. 'ORDERS, ORDER_ITEMS, PRODUCTS'. If this is empty, all tables are added.", type: "string", required: false, multiline: false },
};

export function getAllParameterDefinitions(): ScopedParameters {
    return allParams;
}

export function createInstanceParameters(): Parameter[] {
    return [
        allParams.virtualSchemaName,
        allParams.schemaName,
        allParams.excludedCapabilities,
        allParams.tableFilter,
    ];
}