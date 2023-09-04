package com.exasol.rls.extension;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertAll;

import java.io.FileNotFoundException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.*;
import java.util.List;
import java.util.concurrent.TimeoutException;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.*;

import com.exasol.bucketfs.BucketAccessException;
import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.exasol.ExasolObjectFactory;
import com.exasol.dbbuilder.dialects.exasol.ExasolSchema;
import com.exasol.exasoltestsetup.ExasolTestSetup;
import com.exasol.exasoltestsetup.ExasolTestSetupFactory;
import com.exasol.extensionmanager.client.model.*;
import com.exasol.extensionmanager.itest.ExtensionManagerSetup;
import com.exasol.extensionmanager.itest.builder.ExtensionBuilder;
import com.exasol.mavenprojectversiongetter.MavenProjectVersionGetter;

class ExtensionIT {
    private static final String PREVIOUS_VERSION = "2.6.2";
    private static final Path EXTENSION_SOURCE_DIR = Paths.get("extension").toAbsolutePath();
    private static final String EXTENSION_ID = "row-level-security-extension.js";
    private static final int EXPECTED_PARAMETER_COUNT = 10;
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
    void listInstallations() {
        assertThat(setup.client().getInstallations(), emptyIterable());
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
    void createInstance() throws SQLException {
        setup.client().install();
        final String virtualSchemaName = "RLS_SCHEMA";
        setup.addVirtualSchemaToCleanupQueue(virtualSchemaName);
        final ExasolSchema schema = this.dbObjectFactory.createSchema("BASE_SCHEMA");
        final Table table = schema.createTable("TAB", "ID", "SMALLINT", "NAME", "varchar(10)").insert(1, "a")
                .insert(2, "b").insert(3, "c");
        setup.client().createInstance(
                List.of(param("virtualSchemaName", virtualSchemaName), param("SCHEMA_NAME", schema.getName())));
        assertResult("select * from " + virtualSchemaName + "." + table.getName() + " order by id",
                table("INTEGER", "VARCHAR").row(1, "a").row(2, "b").row(3, "c").matches());
    }

    private void assertResult(final String sql, final Matcher<ResultSet> matcher) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            assertThat(statement.executeQuery(sql), matcher);
        }
    }

    private ParameterValue param(final String name, final String value) {
        return new ParameterValue().name(name).value(value);
    }
}
