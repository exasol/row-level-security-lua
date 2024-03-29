import { Instance } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME } from "./common";
import { ExtendedContext } from "./extension";

export function findInstances(context: ExtendedContext): Instance[] {
    const result = context.sqlClient.query("SELECT SCHEMA_NAME FROM SYS.EXA_ALL_VIRTUAL_SCHEMAS"
        + " WHERE ADAPTER_SCRIPT_SCHEMA = ? AND ADAPTER_SCRIPT_NAME = ? "
        + " ORDER BY SCHEMA_NAME", context.extensionSchemaName, ADAPTER_SCRIPT_NAME)
    return result.rows.map(row => {
        const schemaName = <string>row[0];
        return { id: schemaName, name: schemaName }
    })
}
