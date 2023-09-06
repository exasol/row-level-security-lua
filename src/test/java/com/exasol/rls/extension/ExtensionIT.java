package com.exasol.rls.extension;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

import java.io.FileNotFoundException;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.*;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeoutException;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.*;

import com.exasol.bucketfs.BucketAccessException;
import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.exasol.AdapterScript.Language;
import com.exasol.dbbuilder.dialects.exasol.ExasolObjectFactory;
import com.exasol.dbbuilder.dialects.exasol.ExasolSchema;
import com.exasol.exasoltestsetup.ExasolTestSetup;
import com.exasol.exasoltestsetup.ExasolTestSetupFactory;
import com.exasol.extensionmanager.client.model.*;
import com.exasol.extensionmanager.itest.*;
import com.exasol.extensionmanager.itest.builder.ExtensionBuilder;
import com.exasol.mavenprojectversiongetter.MavenProjectVersionGetter;

class ExtensionIT {
    private static final String PREVIOUS_VERSION = "2.6.2";
    private static final Path EXTENSION_SOURCE_DIR = Paths.get("extension").toAbsolutePath();
    private static final String EXTENSION_ID = "row-level-security-extension.js";
    private static final int EXPECTED_PARAMETER_COUNT = 6;
    private static final String PROJECT_VERSION = MavenProjectVersionGetter.getCurrentProjectVersion();
    private static ExasolTestSetup exasolTestSetup;
    private static ExtensionManagerSetup setup;
    private Connection connection;
    private ExasolObjectFactory dbObjectFactory;

    @BeforeAll
    static void setup() throws FileNotFoundException, BucketAccessException, TimeoutException {
        exasolTestSetup = new ExasolTestSetupFactory(Path.of("no-such-file")).getTestSetup();
        setup = ExtensionManagerSetup.create(exasolTestSetup, ExtensionBuilder.createDefaultNpmBuilder(
                EXTENSION_SOURCE_DIR, EXTENSION_SOURCE_DIR.resolve("dist").resolve(EXTENSION_ID)));
    }

    @BeforeEach
    void setupTest() throws SQLException {
        connection = exasolTestSetup.createConnection();
        dbObjectFactory = new ExasolObjectFactory(exasolTestSetup.createConnection());
    }

    @AfterAll
    static void teardown() throws Exception {
        if (setup != null) {
            setup.close();
        }
        exasolTestSetup.close();
    }

    @AfterEach
    void cleanup() throws SQLException {
        connection.close();
        setup.cleanup();
    }

    @Test
    void listExtensions() {
        final List<ExtensionsResponseExtension> extensions = setup.client().getExtensions();
        assertAll(() -> assertThat(extensions, hasSize(1)), //
                () -> assertThat(extensions.get(0).getName(), equalTo("Row Level Security Lua")),
                () -> assertThat(extensions.get(0).getInstallableVersions().get(0).getName(), equalTo(PROJECT_VERSION)),
                () -> assertThat("isLatest", extensions.get(0).getInstallableVersions().get(0).isLatest(), is(true)),
                () -> assertThat("isDeprecated", extensions.get(0).getInstallableVersions().get(0).isDeprecated(),
                        is(false)),
                () -> assertThat(extensions.get(0).getDescription(),
                        equalTo("Lua implementation of Exasol's row-level-security")));
    }

    @Test
    void listInstallationsEmpty() {
        assertThat(setup.client().getInstallations(), emptyIterable());
    }

    @Test
    void listInstallations_ignoresWrongScriptNames() {
        createAdapter("wrong_adapter_name");
        final List<InstallationsResponseInstallation> installations = setup.client().getInstallations();
        assertThat(installations, hasSize(0));
    }

    @Test
    void listInstallations_findsMatchingScripts() {
        createAdapter("RLS_ADAPTER");
        final List<InstallationsResponseInstallation> installations = setup.client().getInstallations();
        assertAll(() -> assertThat(installations, hasSize(1)), //
                () -> assertThat(installations.get(0).getName(),
                        equalTo(ExtensionManagerSetup.EXTENSION_SCHEMA_NAME + ".RLS_ADAPTER")),
                () -> assertThat(installations.get(0).getVersion(), equalTo("dummy.version")));
    }

    @Test
    void listInstallations_findsOwnInstallation() {
        setup.client().install();
        final List<InstallationsResponseInstallation> installations = setup.client().getInstallations();
        assertAll(() -> assertThat(installations, hasSize(1)), //
                () -> assertThat(installations.get(0).getName(),
                        equalTo(ExtensionManagerSetup.EXTENSION_SCHEMA_NAME + ".RLS_ADAPTER")),
                () -> assertThat(installations.get(0).getVersion(), equalTo(PROJECT_VERSION)));
    }

    @Test
    void install_createsScripts() {
        setup.client().install();
        assertScriptsExist();
    }

    @Test
    void install_worksIfCalledTwice() {
        setup.client().install();
        setup.client().install();
        assertScriptsExist();
    }

    @Test
    void install_failsForUnsupportedVersion() {
        final ExtensionManagerClient client = setup.client();
        client.assertRequestFails(() -> client.install("unsupported"),
                equalTo("Installing version 'unsupported' not supported, try '" + PROJECT_VERSION + "'."),
                equalTo(400));
        setup.exasolMetadata().assertNoScripts();
    }

    @Test
    void getExtensionDetailsFailsForUnknownVersion() {
        setup.client().assertRequestFails(() -> setup.client().getExtensionDetails("unknownVersion"),
                equalTo("Version 'unknownVersion' not supported, can only use '" + PROJECT_VERSION + "'."),
                equalTo(404));
    }

    @Test
    void getExtensionDetailsSuccess() {
        final ExtensionDetailsResponse extensionDetails = setup.client().getExtensionDetails(PROJECT_VERSION);
        final List<ParamDefinition> parameters = extensionDetails.getParameterDefinitions();
        final ParamDefinition param1 = new ParamDefinition().id("virtualSchemaName")
                .name("Name of the new virtual schema").definition(Map.of("id", "virtualSchemaName", "name",
                        "Name of the new virtual schema", "required", true, "type", "string"));
        assertAll(() -> assertThat(extensionDetails.getId(), equalTo(EXTENSION_ID)),
                () -> assertThat(extensionDetails.getVersion(), equalTo(PROJECT_VERSION)),
                () -> assertThat(parameters, hasSize(EXPECTED_PARAMETER_COUNT)),
                () -> assertThat(parameters.get(0), equalTo(param1)));
    }

    @Test
    void installWrongVersionFails() {
        setup.client().assertRequestFails(() -> setup.client().install("0.0.0"),
                "Installing version '0.0.0' not supported, try '" + PROJECT_VERSION + "'.", 400);
    }

    @Test
    void installExtensions() {
        setup.client().install();
        assertThat(setup.client().getInstallations(),
                contains(new InstallationsResponseInstallation().name(EXTENSION_ID).version(PROJECT_VERSION)));
    }

    @Test
    void createInstanceFailsWithoutRequiredParameters() {
        final ExtensionManagerClient client = setup.client();
        client.install();
        client.assertRequestFails(() -> client.createInstance(List.of()), startsWith(
                "invalid parameters: Failed to validate parameter 'Name of the new virtual schema': This is a required parameter."),
                equalTo(400));
    }

    @Test
    void uninstall_failsForUnknownVersion() {
        setup.client().assertRequestFails(() -> setup.client().uninstall("unknownVersion"),
                equalTo("Uninstalling version 'unknownVersion' not supported, try '" + PROJECT_VERSION + "'."),
                equalTo(404));
    }

    @Test
    void uninstall_succeedsForNonExistingInstallation() {
        assertDoesNotThrow(() -> setup.client().uninstall());
    }

    @Test
    void uninstall_removesAdapters() {
        setup.client().install();
        assertAll(() -> assertScriptsExist(), //
                () -> assertThat(setup.client().getInstallations(), hasSize(1)));
        setup.client().uninstall(PROJECT_VERSION);
        assertAll(() -> assertThat(setup.client().getInstallations(), is(empty())),
                () -> setup.exasolMetadata().assertNoScripts());
    }

    @Test
    void upgradeFailsWhenNotInstalled() {
        setup.client().assertRequestFails(() -> setup.client().upgrade(),
                "extension is not installed, the following scripts are missing: S3_FILES_ADAPTER, IMPORT_FROM_S3_DOCUMENT_FILES",
                404);
    }

    @Test
    void upgradeFailsWhenAlreadyUpToDate() {
        setup.client().install();
        setup.client().assertRequestFails(() -> setup.client().upgrade(),
                "Extension is already installed in latest version " + PROJECT_VERSION, 412);
    }

    @Test
    void upgradeFromPreviousVersion() throws InterruptedException, BucketAccessException, TimeoutException,
            FileNotFoundException, URISyntaxException {
        final PreviousExtensionVersion previousVersion = createPreviousVersion();
        previousVersion.prepare();
        previousVersion.install();
        final String virtualTable = createVirtualSchema(previousVersion.getExtensionId(), PREVIOUS_VERSION);
        verifyVirtualTableContainsData(virtualTable);
        assertInstalledVersion("EXA_EXTENSIONS.RLS_ADAPTER", PREVIOUS_VERSION);
        previousVersion.upgrade();
        assertInstalledVersion("EXA_EXTENSIONS.RLS_ADAPTER", PROJECT_VERSION);
        verifyVirtualTableContainsData(virtualTable);
    }

    private PreviousExtensionVersion createPreviousVersion() {
        return setup.previousVersionManager().newVersion().currentVersion(PROJECT_VERSION) //
                .previousVersion(PREVIOUS_VERSION) //
                .extensionFileName(EXTENSION_ID) //
                .project("row-level-security-lua") //
                .build();
    }

    private void assertInstalledVersion(final String expectedName, final String expectedVersion) {
        final List<InstallationsResponseInstallation> installations = setup.client().getInstallations();
        final InstallationsResponseInstallation expectedInstallation = new InstallationsResponseInstallation()
                .name(expectedName).version(expectedVersion);
        // The extension is installed twice (previous and current version), so each one returns the same installation.
        assertAll(() -> assertThat(installations, hasSize(2)),
                () -> assertThat(installations.get(0), equalTo(expectedInstallation)),
                () -> assertThat(installations.get(1), equalTo(expectedInstallation)));
    }

    @Test
    void createInstance() {
        setup.client().install();
        final String virtualTableName = createVirtualSchema();
        verifyVirtualTableContainsData(virtualTableName);
    }

    private String createVirtualSchema() {
        return createVirtualSchema(EXTENSION_ID, PROJECT_VERSION);
    }

    private String createVirtualSchema(final String extensionId, final String extensionVersion) {
        final String virtualSchemaName = "RLS_SCHEMA";
        final Table baseTable = createBaseTable();
        createInstance(virtualSchemaName, baseTable);
        return virtualSchemaName + "." + baseTable.getName();
    }

    private Table createBaseTable() {
        final ExasolSchema baseSchema = this.dbObjectFactory.createSchema("BASE_SCHEMA");
        return baseSchema.createTable("TAB", "ID", "SMALLINT", "NAME", "varchar(10)").insert(1, "a").insert(2, "b")
                .insert(3, "c");
    }

    private void createInstance(final String virtualSchemaName, final Table baseTable) {
        createInstance(EXTENSION_ID, PROJECT_VERSION, virtualSchemaName, baseTable);
    }

    private void createInstance(final String extensionId, final String extensionVersion, final String virtualSchemaName,
            final Table baseTable) {
        setup.addVirtualSchemaToCleanupQueue(virtualSchemaName);
        final String instanceName = setup.client().createInstance(List.of(param("virtualSchemaName", virtualSchemaName),
                param("SCHEMA_NAME", baseTable.getParent().getName())));
        assertThat(instanceName, equalTo(virtualSchemaName));
    }

    private void verifyVirtualTableContainsData(final String tableName) {
        assertResult("select * from " + tableName + " order by id",
                table("INTEGER", "VARCHAR").row(1, "a").row(2, "b").row(3, "c").matches());
    }

    private void assertResult(final String sql, final Matcher<ResultSet> matcher) {
        try (Statement statement = connection.createStatement()) {
            assertThat(statement.executeQuery(sql), matcher);
        } catch (final SQLException exception) {
            throw new AssertionError("Failed to execute query '" + sql + "': " + exception.getMessage(), exception);
        }
    }

    private ParameterValue param(final String name, final String value) {
        return new ParameterValue().name(name).value(value);
    }

    private void assertScriptsExist() {
        final String comment = "Created by Extension Manager for Row Level Security Lua " + PROJECT_VERSION;
        setup.exasolMetadata()
                .assertScript(table()
                        .row("RLS_ADAPTER", "ADAPTER", null, null,
                                allOf(containsString("CREATE LUA  ADAPTER SCRIPT \"RLS_ADAPTER\" AS"), //
                                        containsString("-- RLS Lua version " + PROJECT_VERSION)),
                                comment) //
                        .matches());
    }

    private void createAdapter(final String adapterScriptName) {
        final ExasolSchema schema = setup.createExtensionSchema();
        schema.createAdapterScriptBuilder(adapterScriptName).language(Language.LUA)
                .content("-- RLS Lua version dummy.version").build();
    }
}
