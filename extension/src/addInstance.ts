import { Instance, NotFoundError, Parameter, ParameterValues } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, convertSchemaNameToInstanceId } from "./common";
import { ExtendedContext } from "./extension";
import { getAllParameterDefinitions } from "./parameterDefinitions";

export function addInstance(context: ExtendedContext, version: string, paramValues: ParameterValues): Instance {
    if (context.version !== version) {
        throw new NotFoundError(`Version '${version}' not supported, can only use '${context.version}'.`)
    }

    const allParams = getAllParameterDefinitions();
    const virtualSchemaName = getParameterValue(paramValues, allParams.virtualSchemaName);
    const schemaName = getParameterValue(paramValues, allParams.schemaName);
    const excludedCapabilities = getOptionalParameterValue(paramValues, allParams.excludedCapabilities);
    const tableFilter = getOptionalParameterValue(paramValues, allParams.tableFilter);

    const createVirtualSchemaStmt = createVirtualSchemaStatement(virtualSchemaName, context.extensionSchemaName, schemaName, excludedCapabilities, tableFilter);
    context.sqlClient.execute(createVirtualSchemaStmt);
    const comment = `Created by extension manager for row-level-security-lua ${escapeSingleQuotes(virtualSchemaName)} (version ${context.version})`;
    context.sqlClient.execute(`COMMENT ON SCHEMA "${virtualSchemaName}" IS '${comment}'`);
    return { id: convertSchemaNameToInstanceId(virtualSchemaName), name: virtualSchemaName }
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

function createVirtualSchemaStatement(name: string, adapterSchema: string, baseSchemaName: string, excludedCapabilities: string | undefined, tableFilter: string | undefined): string {
    let stmt = `CREATE VIRTUAL SCHEMA "${name}" USING "${adapterSchema}"."${ADAPTER_SCRIPT_NAME}" WITH SCHEMA_NAME = '${baseSchemaName}'`
    if (excludedCapabilities) {
        stmt += ` EXCLUDED_CAPABILITIES='${excludedCapabilities}'`
    }
    if (excludedCapabilities) {
        stmt += ` TABLE_FILTER='${tableFilter}'`
    }
    return stmt;
}

function escapeSingleQuotes(value: string): string {
    return value.replace(/'/g, "''")
}
