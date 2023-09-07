import { NotFoundError } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME } from "./common";
import { ExtendedContext } from "./extension";

export function uninstall(context: ExtendedContext, versionToUninstall: string) {
    if (context.version !== versionToUninstall) {
        throw new NotFoundError(`Uninstalling version '${versionToUninstall}' not supported, try '${context.version}'.`)
    }

    function extensionSchemaExists(): boolean {
        const result = context.sqlClient.query("SELECT 1 FROM SYS.EXA_ALL_SCHEMAS WHERE SCHEMA_NAME=?", context.extensionSchemaName)
        return result.rows.length > 0
    }

    if (extensionSchemaExists()) { // Drop command fails when schema does not exist.
        context.sqlClient.execute(`DROP ADAPTER SCRIPT "${context.extensionSchemaName}"."${ADAPTER_SCRIPT_NAME}"`)
    }
}