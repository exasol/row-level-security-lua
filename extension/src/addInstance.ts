import { Instance, NotFoundError, Parameter, ParameterValues } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, convertSchemaNameToInstanceId } from "./common";
import { ExtendedContext } from "./extension";
import { getAllParameterDefinitions } from "./parameterDefinitions";

interface VirtualSchemaConfig {
    virtualSchemaName: string
    baseSchemaName: string
    excludedCapabilities: string | undefined
    tableFilter: string | undefined
    debugAddress: string | undefined
    logLevel: string | undefined
}

export function addInstance(context: ExtendedContext, version: string, paramValues: ParameterValues): Instance {
    if (context.version !== version) {
        throw new NotFoundError(`Version '${version}' not supported, can only use '${context.version}'.`)
    }
    const config = buildVirtualSchemaConfig(paramValues)
    const createVirtualSchemaStmt = createVirtualSchemaStatement(context.extensionSchemaName, config);
    context.sqlClient.execute(createVirtualSchemaStmt);
    const comment = `Created by extension manager for row-level-security-lua ${escapeSingleQuotes(config.virtualSchemaName)} (version ${context.version})`;
    context.sqlClient.execute(`COMMENT ON SCHEMA "${config.virtualSchemaName}" IS '${comment}'`);
    return { id: convertSchemaNameToInstanceId(config.virtualSchemaName), name: config.virtualSchemaName }
}

function buildVirtualSchemaConfig(paramValues: ParameterValues): VirtualSchemaConfig {
    const allParams = getAllParameterDefinitions();
    return {
        virtualSchemaName: getParameterValue(paramValues, allParams.virtualSchemaName),
        baseSchemaName: getParameterValue(paramValues, allParams.schemaName),
        tableFilter: getOptionalParameterValue(paramValues, allParams.tableFilter),
        excludedCapabilities: getOptionalParameterValue(paramValues, allParams.excludedCapabilities),
        debugAddress: getOptionalParameterValue(paramValues, allParams.debugAddress),
        logLevel: getOptionalParameterValue(paramValues, allParams.logLevel)
    }
}

function getParameterValue(paramValues: ParameterValues, definition: Parameter): string {
    const value = getOptionalParameterValue(paramValues, definition)
    if (value) {
        return value
    }
    throw new Error(`Missing parameter "${definition.id}"`)
}

function getOptionalParameterValue(paramValues: ParameterValues, definition: Parameter): string | undefined {
    for (const value of paramValues.values) {
        if (value.name === definition.id) {
            return value.value
        }
    }
    return undefined
}

function createVirtualSchemaStatement(adapterSchema: string, config: VirtualSchemaConfig): string {
    let stmt = `CREATE VIRTUAL SCHEMA "${config.virtualSchemaName}" USING "${adapterSchema}"."${ADAPTER_SCRIPT_NAME}" WITH SCHEMA_NAME = '${config.baseSchemaName}'`
    if (config.excludedCapabilities) {
        stmt += ` EXCLUDED_CAPABILITIES='${config.excludedCapabilities}'`
    }
    if (config.excludedCapabilities) {
        stmt += ` TABLE_FILTER='${config.tableFilter}'`
    }
    if (config.debugAddress) {
        stmt += ` DEBUG_ADDRESS='${config.debugAddress}'`
    }
    if (config.logLevel) {
        stmt += ` LOG_LEVEL='${config.logLevel}'`
    }
    return stmt;
}

function escapeSingleQuotes(value: string): string {
    return value.replace(/'/g, "''")
}
