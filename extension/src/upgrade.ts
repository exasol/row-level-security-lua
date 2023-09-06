import { PreconditionFailedError, UpgradeResult } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, extractVersion } from "./common";
import { ExtendedContext } from "./extension";
import { install } from "./install";

export function upgrade(context: ExtendedContext): UpgradeResult {
    const previousVersion = getAdapterVersion(context)
    const newVersion = context.version
    install(context, newVersion)
    return { previousVersion, newVersion };
}

function getAdapterVersion(context: ExtendedContext): string {
    const adapterScript = context.metadata.getScriptByName(ADAPTER_SCRIPT_NAME)
    if (!adapterScript) {
        throw new PreconditionFailedError(`Adapter script '${ADAPTER_SCRIPT_NAME}' is not installed`)
    }
    const version = extractVersion(adapterScript.text)
    if (version.type === "failure") {
        throw new PreconditionFailedError(`Failed to extract version from adapter script ${adapterScript.schema}.${adapterScript.name}: ${version.message}`)
    } else if (version.result === context.version) {
        throw new PreconditionFailedError(`Extension is already installed in latest version ${context.version}`)
    }
    return version.result
}
