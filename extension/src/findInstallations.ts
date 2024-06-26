import { ExaScriptsRow, Installation } from "@exasol/extension-manager-interface";
import { ADAPTER_SCRIPT_NAME, extractVersion } from "./common";
import { ExtendedContext } from "./extension";

export function findInstallations(context: ExtendedContext, scripts: ExaScriptsRow[]): Installation[] {
    const adapterScript = scripts.find(script => script.name === ADAPTER_SCRIPT_NAME);
    if (!adapterScript) {
        return []
    }
    const versionResult = extractVersion(adapterScript.text)
    if (versionResult.type === "failure") {
        console.warn(versionResult.message)
    }
    const version = versionResult.type === "success" ? versionResult.result : "(unknown)"
    return [{ name: "Row Level Security Lua", version }];
}
