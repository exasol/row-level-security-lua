import { BadRequestError, Instance, NotFoundError, Parameter, ParameterValues } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, EXTENSION_NAME, convertSchemaNameToInstanceId } from "./common";
import { ExtendedContext } from "./extension";
import { findInstances } from "./findInstances";
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
    verifySchemaDoesNotExist(context, config.virtualSchemaName)
    const createVirtualSchemaStmt = createVirtualSchemaStatement(context.extensionSchemaName, config);
    context.sqlClient.execute(createVirtualSchemaStmt);
    const comment = `Created by Extension Manager for ${EXTENSION_NAME} version ${context.version}`;
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
    throw new BadRequestError(`Missing parameter "${definition.id}"`)
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
    if (config.tableFilter) {
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

/**
 * Check if a virtual schema with the given name already exists. This is case-insensitive
 * because other virtual schemas that use `CONNECTION`s are case-insensitive and this
 * schema should behave the same way, even if it does not use a connection.
 * @param context extension context
 * @param virtualSchemaName name of the virtual schema to check
 */
function verifySchemaDoesNotExist(context: ExtendedContext, virtualSchemaName: string) {
    const existingSchema = findInstances(context)
        .filter(instance => instance.id.toUpperCase() === virtualSchemaName.toUpperCase());
    if (existingSchema.length > 0) {
        throw new BadRequestError(`Virtual Schema '${existingSchema[0].name}' already exists`)
    }
}
