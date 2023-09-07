import { NotFoundError } from "@exasol/extension-manager-interface";
import { convertInstanceIdToSchemaName } from "./common";
import { ExtendedContext } from "./extension";

export function deleteInstance(context: ExtendedContext, version: string, instanceId: string): void {
    if (context.version !== version) {
        throw new NotFoundError(`Version '${version}' not supported, can only use '${context.version}'.`)
    }
    const schemaName = convertInstanceIdToSchemaName(instanceId);
    context.sqlClient.execute(dropVirtualSchemaStatement(schemaName));
}

function dropVirtualSchemaStatement(schemaName: string): string {
    return `DROP VIRTUAL SCHEMA IF EXISTS "${schemaName}" CASCADE`;
}
