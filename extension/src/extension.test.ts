import { ExaMetadata, Installation, NotFoundError, PreconditionFailedError } from '@exasol/extension-manager-interface';
import { failureResult, successResult } from '@exasol/extension-manager-interface/dist/base/common';
import { ExaScriptsRow } from '@exasol/extension-manager-interface/dist/exasolSchema';
import { describe, expect, it } from '@jest/globals';
import { ADAPTER_SCRIPT_NAME, extractVersion } from './common';
import { createExtension } from "./extension";
import { EXTENSION_DESCRIPTION } from './extension-description';
import { buildCreateScriptCommand } from './install';
import { createMockContext, getInstalledExtension, scriptWithVersion } from './test-utils';

const currentVersion = EXTENSION_DESCRIPTION.version

describe("Row Level Security Lua", () => {

    describe("installableVersions", () => {
        it("contains exactly one 'latest', non deprecated version", () => {
            const latestVersions = createExtension().installableVersions.filter(version => version.latest)
            expect(latestVersions).toHaveLength(1)
            expect(latestVersions[0].deprecated).toEqual(false)
            expect(latestVersions[0].name).toEqual(currentVersion)
        })
    })

    describe("extension registration", () => {
        it("creates an extension", () => {
            const ext = createExtension();
            expect(ext).not.toBeNull()
        })

        it("creates a new object for every call", () => {
            const ext1 = createExtension();
            const ext2 = createExtension();
            expect(ext1).not.toBe(ext2)
        })

        it("registers when loaded", () => {
            const installedExtension = getInstalledExtension();
            expect(installedExtension.extension).not.toBeNull()
            expect(typeof installedExtension.apiVersion).toBe('string');
            expect(installedExtension.apiVersion).not.toBe('');
        })
    })

    describe("extractVersion()", () => {
        it("extracts version from script", () => {
            expect(extractVersion('CREATE LUA ADAPTER SCRIPT "RLS_ADAPTER" AS\n-- RLS Lua version version number\nmore content')).toStrictEqual(successResult("version number"))
        })
        it("extracts version from script with whitespace", () => {
            expect(extractVersion('CREATE LUA ADAPTER SCRIPT "RLS_ADAPTER" AS\n  -- RLS Lua version version number  \n  more content')).toStrictEqual(successResult("version number"))
        })
        it("extracts version from script with dummy content", () => {
            expect(extractVersion('dummy\n-- RLS Lua version version number\ndummy')).toStrictEqual(successResult("version number"))
        })
        it("extracts version from script with only version comment", () => {
            expect(extractVersion('-- RLS Lua version version number')).toStrictEqual(successResult("version number"))
        })
        it("fails to extracts version from script", () => {
            expect(extractVersion('invalid script')).toStrictEqual(failureResult("version not found in script text 'invalid script'"))
        })
        it("recognizes it's own version tag", () => {
            const script = buildCreateScriptCommand("scriptName", "luaContent")
            expect(extractVersion(script)).toStrictEqual(successResult(currentVersion))
        })
    })

    describe("findInstallations()", () => {
        function findInstallations(allScripts: ExaScriptsRow[]): Installation[] {
            const metadata: ExaMetadata = {
                allScripts: { rows: allScripts },
                virtualSchemaProperties: { rows: [] },
                virtualSchemas: { rows: [] }
            }
            const installations = createExtension().findInstallations(createMockContext(), metadata)
            expect(installations).toBeDefined()
            return installations
        }

        function script({ schema = "schema", name = "name", inputType, resultType, type = "ADAPTER", text = "", comment }: Partial<ExaScriptsRow>): ExaScriptsRow {
            return { schema, name, inputType, resultType, type, text, comment }
        }

        it("returns empty list when no adapter script is available", () => {
            expect(findInstallations([])).toHaveLength(0)
        })

        it("returns single item when script is available", () => {
            const scripts: ExaScriptsRow[] = [script({ name: "RLS_ADAPTER", text: "-- RLS Lua version version" })]
            expect(findInstallations(scripts)).toStrictEqual([{ name: "schema.RLS_ADAPTER", version: "version" }])
        })

        it("returns unknown version for invalid script", () => {
            const scripts: ExaScriptsRow[] = [script({ name: "RLS_ADAPTER", text: "invalid" })]
            expect(findInstallations(scripts)).toStrictEqual([{ name: "schema.RLS_ADAPTER", version: "(unknown)" }])
        })
    })

    describe("install()", () => {
        it("executes expected statements", () => {
            const context = createMockContext();
            createExtension().install(context, EXTENSION_DESCRIPTION.version);
            const executeCalls = context.mocks.sqlExecute.mock.calls
            expect(executeCalls.length).toBe(2)

            const createScriptCommand = executeCalls[0][0]
            const createCommentCommand = executeCalls[1][0]

            expect(createScriptCommand).toContain(`CREATE OR REPLACE LUA ADAPTER SCRIPT \"ext-schema\".\"RLS_ADAPTER\" AS
-- RLS Lua version 1.5.0
table.insert(package.searchers,`)
            const expectedComment = `Created by Extension Manager for Row Level Security Lua ${EXTENSION_DESCRIPTION.version}`
            expect(createCommentCommand).toEqual(`COMMENT ON SCRIPT "ext-schema"."${ADAPTER_SCRIPT_NAME}" IS '${expectedComment}'`)
        })
        it("fails for wrong version", () => {
            expect(() => { createExtension().install(createMockContext(), "wrongVersion") })
                .toThrow(`Installing version 'wrongVersion' not supported, try '${EXTENSION_DESCRIPTION.version}'.`)
        })
    })

    describe("uninstall()", () => {
        it("executes query to check if schema exists", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [] });
            createExtension().uninstall(context, EXTENSION_DESCRIPTION.version)
            const calls = context.mocks.sqlQuery.mock.calls
            expect(calls.length).toEqual(1)
            expect(calls[0]).toEqual(["SELECT 1 FROM SYS.EXA_ALL_SCHEMAS WHERE SCHEMA_NAME=?", "ext-schema"])
        })
        it("skips drop statements when schema does not exist", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [] });
            createExtension().uninstall(context, EXTENSION_DESCRIPTION.version)
            expect(context.mocks.sqlExecute.mock.calls.length).toEqual(0)
        })
        it("executes expected statements", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [[1]] });
            createExtension().uninstall(context, EXTENSION_DESCRIPTION.version)
            const calls = context.mocks.sqlExecute.mock.calls
            expect(calls.length).toEqual(1)
            expect(calls[0]).toEqual([`DROP ADAPTER SCRIPT "ext-schema"."${ADAPTER_SCRIPT_NAME}"`])
        })
        it("fails for wrong version", () => {
            expect(() => { createExtension().uninstall(createMockContext(), "wrongVersion") })
                .toThrow(`Uninstalling version 'wrongVersion' not supported, try '${EXTENSION_DESCRIPTION.version}'.`)
        })
    })

    describe("getInstanceParameters()", () => {
        it("fails for wrong version", () => {
            expect(() => { createExtension().getInstanceParameters(createMockContext(), "wrongVersion") })
                .toThrowError(new NotFoundError(`Version 'wrongVersion' not supported, can only use '${EXTENSION_DESCRIPTION.version}'.`))
        })
        it("returns expected parameters", () => {
            const actual = createExtension().getInstanceParameters(createMockContext(), EXTENSION_DESCRIPTION.version)
            expect(actual).toHaveLength(6)
            expect(actual[0]).toStrictEqual({
                id: "virtualSchemaName", name: "Name of the new virtual schema", required: true, type: "string"
            })
            expect(actual[1]).toStrictEqual({
                id: "SCHEMA_NAME", name: "Name of the schema for which to apply row-level security", required: true, type: "string"
            })
        })
    })

    describe("addInstance()", () => {
        it("is not supported", () => {
            expect(() => { createExtension().addInstance(createMockContext(), "version", { values: [] }) })
                .toThrow("Creating instances not supported")
        })
    })

    describe("findInstances()", () => {
        it("is not supported", () => {
            expect(() => { createExtension().findInstances(createMockContext(), "version") })
                .toThrow("Finding instances not supported")
        })
    })

    describe("deleteInstance()", () => {
        it("is not supported", () => {
            expect(() => { createExtension().deleteInstance(createMockContext(), "version", "instId") })
                .toThrow("Deleting instances not supported")
        })
    })

    describe("readInstanceParameterValues()", () => {
        it("is not supported", () => {
            expect(() => { createExtension().readInstanceParameterValues(createMockContext(), "version", "instId") })
                .toThrow("Reading instance parameter values not supported")
        })
    })


    describe("upgrade()", () => {
        const version = "1.2.3"
        const importPath = scriptWithVersion("IMPORT_PATH", version)
        const importMetadata = scriptWithVersion("IMPORT_METADATA", version)
        const importFiles = scriptWithVersion("IMPORT_FILES", version)
        const exportPath = scriptWithVersion("EXPORT_PATH", version)
        const exportTable = scriptWithVersion("EXPORT_TABLE", version)
        const allScripts = [importPath, importMetadata, importFiles, exportPath, exportTable]

        describe("validateInstalledScripts()", () => {
            it("success", () => {
                const context = createMockContext()
                context.mocks.simulateScripts(allScripts)
                expect(createExtension().upgrade(context)).toStrictEqual({
                    previousVersion: version, newVersion: currentVersion
                })
                const executeCalls = context.mocks.sqlExecute.mock.calls
                expect(executeCalls.length).toBe(10)
            })
            describe("failure", () => {
                const tests: { name: string; scripts: ExaScriptsRow[], expectedMessage: string }[] = [
                    { name: "no script", scripts: [], expectedMessage: "Not all required scripts are installed: Validation failed: Script 'IMPORT_PATH' is missing, Script 'IMPORT_METADATA' is missing, Script 'IMPORT_FILES' is missing, Script 'EXPORT_PATH' is missing, Script 'EXPORT_TABLE' is missing" },
                    { name: "one missing script", scripts: [importPath, importMetadata, importFiles, exportPath], expectedMessage: "Not all required scripts are installed: Validation failed: Script 'EXPORT_TABLE' is missing" },
                    { name: "inconsistent versions", scripts: [importPath, importMetadata, importFiles, exportPath, scriptWithVersion("EXPORT_TABLE", "1.2.4")], expectedMessage: "Failed to validate script versions: Not all scripts use the same version. Found 2 different versions: '1.2.3, 1.2.4'" },
                    {
                        name: "version already up-to-date", scripts: [
                            scriptWithVersion("IMPORT_PATH", currentVersion), scriptWithVersion("IMPORT_METADATA", currentVersion),
                            scriptWithVersion("IMPORT_FILES", currentVersion), scriptWithVersion("EXPORT_PATH", currentVersion), scriptWithVersion("EXPORT_TABLE", currentVersion)
                        ],
                        expectedMessage: `Extension is already installed in latest version ${currentVersion}`
                    },
                ]
                tests.forEach(test => it(test.name, () => {
                    const context = createMockContext()
                    context.mocks.simulateScripts(test.scripts)
                    expect(() => createExtension().upgrade(context)).toThrowError(new PreconditionFailedError(test.expectedMessage))
                    const executeCalls = context.mocks.sqlExecute.mock.calls
                    expect(executeCalls.length).toBe(0)
                }))
            })
        })
    })
})

