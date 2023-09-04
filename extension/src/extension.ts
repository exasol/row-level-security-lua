import { Context, ExasolExtension, NotFoundError, registerExtension } from "@exasol/extension-manager-interface";
import { EXTENSION_DESCRIPTION } from "./extension-description";
import { install } from "./install";
import { createInstanceParameters } from "./parameterDefinitions";
import { uninstall } from "./uninstall";
import { addInstance } from "./addInstance";

export type ExtendedContext = Context & {
    version: string,
    luaScriptContent: string
}

function extendContext(context: Context): ExtendedContext {
    return {
        ...context,
        version: EXTENSION_DESCRIPTION.version,
        luaScriptContent: EXTENSION_DESCRIPTION.content
    }
}
export function createExtension(): ExasolExtension {
    const baseExtension: ExasolExtension = {
        name: "Row Level Security Lua",
        description: "Lua implementation of Exasol's row-level-security",
        category: "security",
        bucketFsUploads: [],
        installableVersions: [{ name: EXTENSION_DESCRIPTION.version, deprecated: false, latest: true }],
        findInstallations(context, metadata) {
            return []
        },
        install(context, versionToInstall) {
            install(extendContext(context), versionToInstall)
        },
        uninstall(context, versionToUninstall) {
            uninstall(extendContext(context), versionToUninstall)
        },
        upgrade(context) {
            return { previousVersion: "", newVersion: "" }
        },
        findInstances(context, version) {
            return []
        },
        getInstanceParameters(context, version) {
            if (EXTENSION_DESCRIPTION.version !== version) {
                throw new NotFoundError(`Version '${version}' not supported, can only use '${EXTENSION_DESCRIPTION.version}'.`)
            }
            return createInstanceParameters()
        },
        addInstance(context, version, params) {
            return addInstance(extendContext(context), version, params);
        },
        deleteInstance(context, extensionVersion, instanceId) {

        },
        readInstanceParameterValues(context, extensionVersion, instanceId) {
            return { values: [] }
        },
    }
    return baseExtension
}

registerExtension(createExtension())