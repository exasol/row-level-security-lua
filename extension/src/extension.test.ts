import { BadRequestError, ExaMetadata, Installation, Instance, NotFoundError, ParameterValue, ParameterValues, PreconditionFailedError, Row } from '@exasol/extension-manager-interface';
import { failureResult, successResult } from '@exasol/extension-manager-interface/dist/base/common';
import { ExaScriptsRow } from '@exasol/extension-manager-interface/dist/exasolSchema';
import { describe, expect, it } from '@jest/globals';
import { ADAPTER_SCRIPT_NAME, EXTENSION_NAME, extractVersion } from './common';
import { createExtension } from "./extension";
import { EXTENSION_DESCRIPTION } from './extension-description';
import { buildCreateScriptCommand } from './install';
import { ContextMock, createMockContext, getInstalledExtension, script } from './test-utils';

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

        it("returns empty list when no adapter script is available", () => {
            expect(findInstallations([])).toHaveLength(0)
        })

        it("returns single item when script is available", () => {
            const scripts: ExaScriptsRow[] = [script({ name: "RLS_ADAPTER", text: "-- RLS Lua version version" })]
            expect(findInstallations(scripts)).toStrictEqual([{ name: "Row Level Security Lua", version: "version" }])
        })

        it("returns unknown version for invalid script", () => {
            const scripts: ExaScriptsRow[] = [script({ name: "RLS_ADAPTER", text: "invalid" })]
            expect(findInstallations(scripts)).toStrictEqual([{ name: "Row Level Security Lua", version: "(unknown)" }])
        })
    })

    describe("install()", () => {
        it("executes expected statements", () => {
            const context = createMockContext();
            createExtension().install(context, currentVersion);
            const executeCalls = context.mocks.sqlExecute.mock.calls
            expect(executeCalls.length).toBe(2)

            const createScriptCommand = executeCalls[0][0]
            const createCommentCommand = executeCalls[1][0]

            expect(createScriptCommand).toContain(`CREATE OR REPLACE LUA ADAPTER SCRIPT "ext-schema"."RLS_ADAPTER" AS
-- RLS Lua version ${currentVersion}
table.insert(package.searchers,`)
            const expectedComment = `Created by Extension Manager for Row Level Security Lua version ${currentVersion}`
            expect(createCommentCommand).toEqual(`COMMENT ON SCRIPT "ext-schema"."${ADAPTER_SCRIPT_NAME}" IS '${expectedComment}'`)
        })
        it("fails for wrong version", () => {
            expect(() => { createExtension().install(createMockContext(), "wrongVersion") })
                .toThrow(`Installing version 'wrongVersion' not supported, try '${currentVersion}'.`)
        })
    })

    describe("uninstall()", () => {
        it("executes query to check if schema exists", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [] });
            createExtension().uninstall(context, currentVersion)
            const calls = context.mocks.sqlQuery.mock.calls
            expect(calls.length).toEqual(1)
            expect(calls[0]).toEqual(["SELECT 1 FROM SYS.EXA_ALL_SCHEMAS WHERE SCHEMA_NAME=?", "ext-schema"])
        })
        it("skips drop statements when schema does not exist", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [] });
            createExtension().uninstall(context, currentVersion)
            expect(context.mocks.sqlExecute.mock.calls.length).toEqual(0)
        })
        it("executes expected statements", () => {
            const context = createMockContext()
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [[1]] });
            createExtension().uninstall(context, currentVersion)
            const calls = context.mocks.sqlExecute.mock.calls
            expect(calls.length).toEqual(1)
            expect(calls[0]).toEqual([`DROP ADAPTER SCRIPT "ext-schema"."${ADAPTER_SCRIPT_NAME}"`])
        })
        it("fails for wrong version", () => {
            expect(() => { createExtension().uninstall(createMockContext(), "wrongVersion") })
                .toThrow(`Uninstalling version 'wrongVersion' not supported, try '${currentVersion}'.`)
        })
    })

    describe("getInstanceParameters()", () => {
        it("fails for wrong version", () => {
            expect(() => { createExtension().getInstanceParameters(createMockContext(), "wrongVersion") })
                .toThrowError(new NotFoundError(`Version 'wrongVersion' not supported, can only use '${currentVersion}'.`))
        })
        it("returns expected parameters", () => {
            const actual = createExtension().getInstanceParameters(createMockContext(), currentVersion)
            expect(actual).toHaveLength(6)
            expect(actual[0]).toStrictEqual({
                id: "virtualSchemaName",
                name: "Virtual Schema name",
                placeholder: "MY_VIRTUAL_SCHEMA",
                regex: "[a-zA-Z_]+", required: true, type: "string",
                "description": "Name for the new virtual schema",
            })
            expect(actual[1]).toStrictEqual({
                id: "SCHEMA_NAME", name: "Name of the schema for which to apply row-level security", required: true, type: "string"
            })
        })
    })

    describe("addInstance()", () => {
        let contextMock: ContextMock
        function addInstance(version: string, params: ParameterValues): Instance {
            return addInstanceSimulateExistingVs(version, params, [])
        }

        function addInstanceSimulateExistingVs(version: string, params: ParameterValues, sqlQueryRows: Row[]): Instance {
            contextMock = createMockContext();
            contextMock.mocks.sqlQuery.mockReturnValue({ columns: [], rows: sqlQueryRows });
            return createExtension().addInstance(contextMock, version, params)
        }

        it("fails for missing schema name", () => {
            expect(() => addInstance(currentVersion, { values: [] }))
                .toThrowError(new BadRequestError(`Missing parameter "virtualSchemaName"`))
        })

        it("fails for missing base schema name", () => {
            expect(() => addInstance(currentVersion, { values: [{ name: "virtualSchemaName", value: "new_vs" }] }))
                .toThrowError(new BadRequestError(`Missing parameter "SCHEMA_NAME"`))
        })

        describe("checks for existing virtual schema", () => {
            it("existing schema with same name", () => {
                expect(() => addInstanceSimulateExistingVs(currentVersion, { values: [{ name: "virtualSchemaName", value: "new_vs" }, { name: "SCHEMA_NAME", value: "baseSchema" }] }, [["new_vs"]]))
                    .toThrowError(new BadRequestError(`Virtual Schema 'new_vs' already exists`))
            })
            it("existing schema with same case-insensitive name", () => {
                expect(() => addInstanceSimulateExistingVs(currentVersion, { values: [{ name: "virtualSchemaName", value: "new_vs" }, { name: "SCHEMA_NAME", value: "baseSchema" }] }, [["NEW_vs"]]))
                    .toThrowError(new BadRequestError(`Virtual Schema 'NEW_vs' already exists`))
            })
            it("no existing schema", () => {
                expect(() => addInstanceSimulateExistingVs(currentVersion, { values: [{ name: "virtualSchemaName", value: "new_vs" }, { name: "SCHEMA_NAME", value: "baseSchema" }] }, []))
                    .not.toThrow()
            })
            it("existing schema with other name", () => {
                expect(() => addInstanceSimulateExistingVs(currentVersion, { values: [{ name: "virtualSchemaName", value: "new_vs" }, { name: "SCHEMA_NAME", value: "baseSchema" }] }, [["other_vs"]]))
                    .not.toThrow()
            })
        })

        it("executes expected statements", () => {
            const parameters = [{ name: "virtualSchemaName", value: "NEW_RLS_VS" }, { name: "SCHEMA_NAME", value: "baseSchema" }]
            const instance = addInstance(currentVersion, { values: parameters });
            expect(instance.name).toBe("NEW_RLS_VS")
            const calls = contextMock.mocks.sqlExecute.mock.calls
            expect(calls.length).toBe(2)

            expect(calls[0]).toEqual([`CREATE VIRTUAL SCHEMA "NEW_RLS_VS" USING "ext-schema"."RLS_ADAPTER" WITH SCHEMA_NAME = 'baseSchema'`])
            const comment = `Created by Extension Manager for ${EXTENSION_NAME} version ${currentVersion}`
            expect(calls[1]).toEqual([`COMMENT ON SCHEMA "NEW_RLS_VS" IS '${comment}'`])
        })

        describe("uses optional parameters", () => {
            const tests: { name: string, params: ParameterValue[], expectedScript: string }[] = [
                { name: "no optional param", params: [], expectedScript: "" },
                { name: "excluded capabilities", params: [{ name: "EXCLUDED_CAPABILITIES", value: "cap1, cap2" }], expectedScript: " EXCLUDED_CAPABILITIES='cap1, cap2'" },
                { name: "table filter", params: [{ name: "TABLE_FILTER", value: "tab1, tab2" }], expectedScript: " TABLE_FILTER='tab1, tab2'" },
                { name: "quoted table filter", params: [{ name: "TABLE_FILTER", value: `"tab1", tab2` }], expectedScript: ` TABLE_FILTER='"tab1", tab2'` },
                { name: "debug address", params: [{ name: "DEBUG_ADDRESS", value: "123.45.6.78:3000" }], expectedScript: " DEBUG_ADDRESS='123.45.6.78:3000'" },
                { name: "log level", params: [{ name: "LOG_LEVEL", value: "TRACE" }], expectedScript: " LOG_LEVEL='TRACE'" },
                {
                    name: "all optional params", params: [{ name: "EXCLUDED_CAPABILITIES", value: "cap1, cap2" }, { name: "TABLE_FILTER", value: "tab1, tab2" },
                    { name: "DEBUG_ADDRESS", value: "123.45.6.78:3000" }, { name: "LOG_LEVEL", value: "TRACE" }],
                    expectedScript: " EXCLUDED_CAPABILITIES='cap1, cap2' TABLE_FILTER='tab1, tab2' DEBUG_ADDRESS='123.45.6.78:3000' LOG_LEVEL='TRACE'"
                },
            ]
            tests.forEach(test => it(test.name, () => {
                const parameters = [{ name: "virtualSchemaName", value: "NEW_RLS_VS" }, { name: "SCHEMA_NAME", value: "baseSchema" }]
                test.params.forEach(p => parameters.push(p))
                const instance = addInstance(currentVersion, { values: parameters });
                expect(instance.name).toBe("NEW_RLS_VS")
                const calls = contextMock.mocks.sqlExecute.mock.calls
                expect(calls.length).toBe(2)
                expect(calls[0]).toEqual([`CREATE VIRTUAL SCHEMA "NEW_RLS_VS" USING "ext-schema"."RLS_ADAPTER" WITH SCHEMA_NAME = 'baseSchema'` + test.expectedScript])
            }))
        })

        it("returns id and name", () => {
            const parameters = [{ name: "virtualSchemaName", value: "NEW_RLS_VS" }, { name: "SCHEMA_NAME", value: "baseSchema" }]
            const instance = addInstance(currentVersion, { values: parameters });
            expect(instance).toStrictEqual({ id: "NEW_RLS_VS", name: "NEW_RLS_VS" })
        })

        it("fails for wrong version", () => {
            expect(() => { addInstance("wrongVersion", { values: [] }) })
                .toThrow(`Version 'wrongVersion' not supported, can only use '${currentVersion}'.`)
        })
    })

    describe("findInstances()", () => {
        function findInstances(rows: Row[]): Instance[] {
            const context = createMockContext();
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows });
            return createExtension().findInstances(context, "version")
        }
        it("returns empty list for empty metadata", () => {
            expect(findInstances([])).toEqual([])
        })
        it("returns single instance", () => {
            expect(findInstances([["rls_vs"]]))
                .toEqual([{ id: "rls_vs", name: "rls_vs" }])
        })
        it("returns multiple instance", () => {
            expect(findInstances([["vs1"], ["vs2"], ["vs3"]]))
                .toEqual([{ id: "vs1", name: "vs1" }, { id: "vs2", name: "vs2" }, { id: "vs3", name: "vs3" }])
        })
        it("filters by schema and script name", () => {
            const context = createMockContext();
            context.mocks.sqlQuery.mockReturnValue({ columns: [], rows: [] });
            createExtension().findInstances(context, "version")
            const queryCalls = context.mocks.sqlQuery.mock.calls
            expect(queryCalls.length).toEqual(1)
            expect(queryCalls[0]).toEqual(["SELECT SCHEMA_NAME FROM SYS.EXA_ALL_VIRTUAL_SCHEMAS WHERE ADAPTER_SCRIPT_SCHEMA = ? AND ADAPTER_SCRIPT_NAME = ?  ORDER BY SCHEMA_NAME", "ext-schema", "RLS_ADAPTER"])
        })
    })

    describe("deleteInstance()", () => {
        describe("deleteInstance()", () => {
            it("drops connection and virtual schema", () => {
                const context = createMockContext();
                createExtension().deleteInstance(context, currentVersion, "instId")
                const executeCalls = context.mocks.sqlExecute.mock.calls
                expect(executeCalls.length).toEqual(1)
                expect(executeCalls[0]).toEqual([`DROP VIRTUAL SCHEMA IF EXISTS "instId" CASCADE`])
            })
            it("fails for wrong version", () => {
                expect(() => { createExtension().deleteInstance(createMockContext(), "wrongVersion", "instId") })
                    .toThrow(`Version 'wrongVersion' not supported, can only use '${currentVersion}'.`)
            })
        })
    })

    describe("readInstanceParameterValues()", () => {
        it("is not supported", () => {
            expect(() => { createExtension().readInstanceParameterValues(createMockContext(), "version", "instId") })
                .toThrowError(new NotFoundError("Reading instance parameter values not supported"))
        })
    })


    describe("upgrade()", () => {

        function scriptWithVersion(name: string, version: string): ExaScriptsRow {
            return script({ name, text: "-- RLS Lua version " + version })
        }

        const version = "1.2.3"
        const adapterScript = scriptWithVersion("RLS_ADAPTER", version)

        it("success", () => {
            const context = createMockContext()
            context.mocks.simulateScripts([adapterScript])
            expect(createExtension().upgrade(context)).toStrictEqual({ previousVersion: version, newVersion: currentVersion })
            const executeCalls = context.mocks.sqlExecute.mock.calls
            expect(executeCalls.length).toBe(2)
        })
        describe("failure", () => {
            const tests: { name: string; scripts: ExaScriptsRow[], expectedMessage: string }[] = [
                { name: "no script", scripts: [], expectedMessage: "Not all required scripts are installed: Validation failed: Script 'RLS_ADAPTER' is missing" },
                {
                    name: "invalid version", scripts: [script({ name: "RLS_ADAPTER", text: "invalid script" })],
                    expectedMessage: `Failed to extract version from adapter script schema.RLS_ADAPTER: version not found in script text 'invalid script'`
                },
                {
                    name: "version already up-to-date", scripts: [scriptWithVersion("RLS_ADAPTER", currentVersion)],
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
