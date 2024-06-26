import { Result, failureResult, successResult } from "@exasol/extension-manager-interface/dist/base/common";
import { EXTENSION_DESCRIPTION } from "./extension-description";

export const ADAPTER_SCRIPT_NAME = "RLS_ADAPTER"
export const EXTENSION_NAME = "Row Level Security Lua"

function identity(arg: string): string {
    return arg;
}

export const convertInstanceIdToSchemaName = identity
export const convertSchemaNameToInstanceId = identity

const versionCommentRegexp = /^\s*-- RLS Lua version (.*?)\s*$/m
export function extractVersion(scriptText: string): Result<string> {
    const match = versionCommentRegexp.exec(scriptText)
    if (!match) {
        return failureResult(`version not found in script text '${scriptText}'`)
    }
    return successResult(match[1])
}

export function getScriptVersionComment(): string {
    return `-- RLS Lua version ${EXTENSION_DESCRIPTION.version}`
}
