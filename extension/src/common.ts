
export const ADAPTER_SCRIPT_NAME = "RLS_ADAPTER"


function identity(arg: string): string {
    return arg;
}

export const convertInstanceIdToSchemaName = identity
export const convertSchemaNameToInstanceId = identity

