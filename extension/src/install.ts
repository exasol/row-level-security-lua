import { BadRequestError } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, EXTENSION_NAME, getScriptVersionComment } from "./common";
import { ExtendedContext } from "./extension";

export function install(context: ExtendedContext, versionToInstall: string) {
    if (context.version !== versionToInstall) {
        throw new BadRequestError(`Installing version '${versionToInstall}' not supported, try '${context.version}'.`)
    }
    const qualifiedScriptName = `"${context.extensionSchemaName}"."${ADAPTER_SCRIPT_NAME}"`
    const createScriptCommand = buildCreateScriptCommand(qualifiedScriptName, context.luaScriptContent);
    const createCommentCommand = `COMMENT ON SCRIPT ${qualifiedScriptName} IS 'Created by Extension Manager for ${EXTENSION_NAME} version ${context.version}'`;
    context.sqlClient.execute(createScriptCommand)
    context.sqlClient.execute(createCommentCommand);
}

const luaModuleLoadingPreamble = `table.insert(package.searchers,
    function (module_name)
        local loader = package.preload[module_name]
        if(loader == nil) then
            error("Module " .. module_name .. " not found in package.preload.")
        else
            return loader
        end
    end
)`;

export function buildCreateScriptCommand(qualifiedScriptName: string, luaScriptContent: string) {
    const createScriptCommand = `CREATE OR REPLACE LUA ADAPTER SCRIPT ${qualifiedScriptName} AS
${getScriptVersionComment()}
${luaModuleLoadingPreamble}
${luaScriptContent}
/`;
    return createScriptCommand;
}

