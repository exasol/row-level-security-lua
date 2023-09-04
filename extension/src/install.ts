import { BadRequestError } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME } from "./common";
import { ExtendedContext } from "./extension";

export function install(context: ExtendedContext, versionToInstall: string) {
    if (context.version !== versionToInstall) {
        throw new BadRequestError(`Installing version '${versionToInstall}' not supported, try '${context.version}'.`)
    }
    const qualifiedScriptName = `"${context.extensionSchemaName}"."${ADAPTER_SCRIPT_NAME}"`
    const luaModuleLoadingPreamble = `table.insert(package.searchers,
        function (module_name)
            local loader = package.preload[module_name]
            if(loader == nil) then
                error("Module " .. module_name .. " not found in package.preload.")
            else
                return loader
            end
        end
    )`
    const createScriptCommand = `CREATE OR REPLACE LUA ADAPTER SCRIPT ${qualifiedScriptName} AS\n${luaModuleLoadingPreamble}\n${context.luaScriptContent}\n/`;
    const createCommentCommand = `COMMENT ON SCRIPT ${qualifiedScriptName} IS 'Created by extension manager for Row Level Security Lua ${context.version}'`;
    context.sqlClient.execute(createScriptCommand)
    context.sqlClient.execute(createCommentCommand);
}
