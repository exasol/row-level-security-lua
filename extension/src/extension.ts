import { Context, ExasolExtension, NotFoundError, registerExtension } from "@exasol/extension-manager-interface";
import { addInstance } from "./addInstance";
import { EXTENSION_NAME } from "./common";
import { deleteInstance } from "./deleteInstance";
import { EXTENSION_DESCRIPTION } from "./extension-description";
import { findInstallations } from "./findInstallations";
import { findInstances } from "./findInstances";
import { install } from "./install";
import { createInstanceParameters } from "./parameterDefinitions";
import { uninstall } from "./uninstall";
import { upgrade } from "./upgrade";

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
        name: EXTENSION_NAME,
        description: "Lua implementation of Exasol's row-level-security",
        category: "security",
        bucketFsUploads: [],
        installableVersions: [{ name: EXTENSION_DESCRIPTION.version, deprecated: false, latest: true }],
        findInstallations(context, metadata) {
            return findInstallations(extendContext(context), metadata.allScripts.rows)
        },
        install(context, versionToInstall) {
            install(extendContext(context), versionToInstall)
        },
        uninstall(context, versionToUninstall) {
            uninstall(extendContext(context), versionToUninstall)
        },
        upgrade(context) {
            return upgrade(extendContext(context))
        },
        findInstances(context, _version) {
            return findInstances(extendContext(context))
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
        deleteInstance(context, version, instanceId) {
            deleteInstance(extendContext(context), version, instanceId)
        },
        readInstanceParameterValues(_context, _version, _instanceId) {
            throw new NotFoundError("Reading instance parameter values not supported")
        },
    }
    return baseExtension
}

registerExtension(createExtension())