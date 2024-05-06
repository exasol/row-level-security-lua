package com.exasol.rls.extension;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertAll;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.*;
import java.util.Collection;
import java.util.List;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.*;

import com.exasol.dbbuilder.dialects.exasol.AdapterScript.Language;
import com.exasol.dbbuilder.dialects.exasol.ExasolObjectFactory;
import com.exasol.dbbuilder.dialects.exasol.ExasolSchema;
import com.exasol.exasoltestsetup.ExasolTestSetup;
import com.exasol.exasoltestsetup.ExasolTestSetupFactory;
import com.exasol.extensionmanager.client.model.*;
import com.exasol.extensionmanager.itest.*;
import com.exasol.extensionmanager.itest.base.AbstractVirtualSchemaExtensionIT;
import com.exasol.extensionmanager.itest.base.ExtensionITConfig;
import com.exasol.extensionmanager.itest.builder.ExtensionBuilder;
import com.exasol.mavenprojectversiongetter.MavenProjectVersionGetter;

class ExtensionIT extends AbstractVirtualSchemaExtensionIT {
    private static final String PREVIOUS_VERSION = "1.5.4";
    private static final Path EXTENSION_SOURCE_DIR = Paths.get("extension").toAbsolutePath();
    private static final String EXTENSION_ID = "row-level-security-extension.js";
    private static final int EXPECTED_PARAMETER_COUNT = 6;
    private static final String PROJECT_VERSION = MavenProjectVersionGetter.getCurrentProjectVersion();
    private static final long CURRENT_TIME = System.currentTimeMillis();
    private static final String BASE_SCHEMA_NAME = "BASE_SCHEMA_" + CURRENT_TIME;
    private static ExasolTestSetup exasolTestSetup;
    private static ExtensionManagerSetup setup;
    private Connection connection;
    private ExasolObjectFactory dbObjectFactory;

    @BeforeAll
    static void setup() {
        if (System.getProperty("com.exasol.dockerdb.image") == null) {
            System.setProperty("com.exasol.dockerdb.image", "8.26.0");
        }
        exasolTestSetup = new ExasolTestSetupFactory(Path.of("no-such-file")).getTestSetup();
        ExasolVersionCheck.assumeExasolVersion8(exasolTestSetup);
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
    @Override
    public void cleanup() {
        try {
            connection.createStatement().execute("drop schema if exists " + BASE_SCHEMA_NAME + " cascade");
            connection.close();
        } catch (final SQLException exception) {
            throw new IllegalStateException("Failed to clean up test resources.", exception);
        }
        super.cleanup();
    }

    @Override
    protected ExtensionITConfig createConfig() {
        return ExtensionITConfig.builder().currentVersion(PROJECT_VERSION).previousVersion(PREVIOUS_VERSION)
                .expectedParameterCount(EXPECTED_PARAMETER_COUNT)
                .extensionDescription("Lua implementation of Exasol's row-level-security").extensionId(EXTENSION_ID)
                .extensionName("Row Level Security Lua").projectName("row-level-security-lua")
                .virtualSchemaNameParameterName("virtualSchemaName").build();
    }

    @Override
    protected ExtensionManagerSetup getSetup() {
        return setup;
    }

    @Override
    protected void assertScriptsExist() {
        final String comment = "Created by Extension Manager for Row Level Security Lua version " + PROJECT_VERSION;
        setup.exasolMetadata()
                .assertScript(table()
                        .row("RLS_ADAPTER", "ADAPTER", null, null,
                                allOf(containsString("CREATE LUA  ADAPTER SCRIPT \"RLS_ADAPTER\" AS"), //
                                        containsString("-- RLS Lua version " + PROJECT_VERSION)),
                                comment) //
                        .matches());
    }

    @Override
    protected void prepareInstance() {
        final ExasolSchema baseSchema = this.dbObjectFactory.createSchema(BASE_SCHEMA_NAME);
        baseSchema.createTable("TAB", "ID", "SMALLINT", "NAME", "varchar(10)").insert(1, "a").insert(2, "b").insert(3,
                "c");
    }

    @Override
    protected void assertVirtualSchemaContent(final String virtualSchemaName) {
        assertResult("select * from \"" + virtualSchemaName + "\".TAB order by id",
                table("INTEGER", "VARCHAR").row(1, "a").row(2, "b").row(3, "c").matches());
    }

    private void assertResult(final String sql, final Matcher<ResultSet> matcher) {
        try (Statement statement = connection.createStatement()) {
            assertThat(statement.executeQuery(sql), matcher);
        } catch (final SQLException exception) {
            throw new AssertionError("Failed to execute query '" + sql + "': " + exception.getMessage(), exception);
        }
    }

    @Override
    protected void createScripts() {
        final ExasolSchema schema = setup.createExtensionSchema();
        schema.createAdapterScriptBuilder("RLS_ADAPTER").language(Language.LUA)
                .content("-- RLS Lua version " + PROJECT_VERSION + "\n").build();
    }

    @Override
    protected Collection<ParameterValue> createValidParameterValues() {
        return List.of(param("SCHEMA_NAME", BASE_SCHEMA_NAME));
    }

    /**
     * {@inheritDoc}
     * <p>
     * Extension does not create a CONNECTION.
     */
    @Test
    @Override
    public void createTwoInstances() {
        getSetup().client().install();
        createInstance("vs1");
        createInstance("vs2");
        assertAll(() -> getSetup().exasolMetadata().assertConnection(table("VARCHAR", "VARCHAR").matches()),
                () -> getSetup().exasolMetadata().assertVirtualSchema(table()
                        .row("vs1", "SYS", EXTENSION_SCHEMA, not(emptyOrNullString()), emptyOrNullString())
                        .row("vs2", "SYS", EXTENSION_SCHEMA, not(emptyOrNullString()), emptyOrNullString()).matches()),
                () -> assertThat(getSetup().client().listInstances(), allOf(hasSize(2),
                        equalTo(List.of(new Instance().id("vs1").name("vs1"), new Instance().id("vs2").name("vs2"))))));
    }

    /**
     * {@inheritDoc}
     * <p>
     * Extension does not create a CONNECTION.
     */
    @Test
    @Override
    public void createTwoInstancesDifferentCase() {
        getSetup().client().install();
        createInstance("my_VS");
        createInstance("MY_vs");
        assertAll(() -> getSetup().exasolMetadata().assertConnection(table("VARCHAR", "VARCHAR").matches()),
                () -> getSetup().exasolMetadata()
                        .assertVirtualSchema(table()
                                .row("MY_vs", "SYS", EXTENSION_SCHEMA, not(emptyOrNullString()), emptyOrNullString())
                                .row("my_VS", "SYS", EXTENSION_SCHEMA, not(emptyOrNullString()), emptyOrNullString())
                                .matches()),
                () -> assertThat(getSetup().client().listInstances(), allOf(hasSize(2), equalTo(
                        List.of(new Instance().id("MY_vs").name("MY_vs"), new Instance().id("my_VS").name("my_VS"))))));
    }

    /**
     * {@inheritDoc}
     * <p>
     * Extension does not create a CONNECTION.
     */
    @Test
    @Override
    public void createInstanceCreatesDbObjects() {
        getSetup().client().install();
        final String name = "my_virtual_SCHEMA";
        createInstance(name);
        assertAll(() -> getSetup().exasolMetadata().assertConnection(table("VARCHAR", "VARCHAR").matches()),
                () -> getSetup().exasolMetadata()
                        .assertVirtualSchema(table().row("my_virtual_SCHEMA", "SYS", EXTENSION_SCHEMA,
                                not(emptyOrNullString()), emptyOrNullString()).matches()),
                () -> assertThat(getSetup().client().listInstances(),
                        allOf(hasSize(1), equalTo(List.of(new Instance().id(name).name(name))))));
    }

    /**
     * {@inheritDoc}
     * <p>
     * Extension does not create a CONNECTION.
     */
    @Test
    @Override
    public void createInstanceWithSingleQuote() {
        getSetup().client().install();
        final String virtualSchemaName = "Quoted'schema";
        createInstance(virtualSchemaName);
        assertAll(() -> getSetup().exasolMetadata().assertConnection(table("VARCHAR", "VARCHAR").matches()),
                () -> getSetup().exasolMetadata().assertVirtualSchema(table()
                        .row(virtualSchemaName, "SYS", EXTENSION_SCHEMA, not(emptyOrNullString()), emptyOrNullString())
                        .matches()));
    }

    /*
     * Previous version has a different name.
     */
    @Override
    protected void assertInstalledVersion(final String expectedVersion,
            final PreviousExtensionVersion previousVersion) {
        final List<InstallationsResponseInstallation> installations = getSetup().client().getInstallations();
        assertAll(() -> assertThat("installations after upgrade", installations, hasSize(greaterThan(1))),
                () -> assertThat("installations after upgrade", installations,
                        containsInAnyOrder(
                                new InstallationsResponseInstallation().name(config.getExtensionName())
                                        .version(expectedVersion).id(config.getExtensionId()), //
                                new InstallationsResponseInstallation().name("EXA_EXTENSIONS.RLS_ADAPTER")
                                        .version(expectedVersion).id(previousVersion.getExtensionId()))));
    }
}
