package com.exasol;

import static com.exasol.RlsTestConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.time.Duration;
import java.util.*;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;

import com.exasol.containers.ExasolContainer;
import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.*;
import com.exasol.mavenprojectversiongetter.MavenProjectVersionGetter;

abstract class AbstractLuaVirtualSchemaIT {
    private static final int DEFAULT_LOG_PORT = 3000;
    private static final String LOG_PORT_PROPERTY = "com.exasol.log.port";
    private static final String LOG_HOST_PROPERTY = "com.exasol.log.host";
    private static final String VERSION = MavenProjectVersionGetter.getCurrentProjectVersion();
    private static final Path RLS_PACKAGE_PATH = Path.of("target/row-level-security-dist-" + VERSION + ".lua");
    @Container
    protected static final ExasolContainer<? extends ExasolContainer<?>> EXASOL = //
            new ExasolContainer<>(DOCKER_DB) //
                    .withRequiredServices() //
                    .withExposedPorts(8563) //
                    .withReuse(true);
    private static final String EXASOL_LUA_MODULE_LOADER_WORKAROUND = "table.insert(" //
            + "package.searchers" //
            + ",\n" //
            + "    function (module_name)\n" //
            + "        local loader = package.preload[module_name]\n" //
            + "        if(loader == nil) then\n" //
            + "            error(\"Module \" .. module_name .. \" not found in package.preload.\")\n" //
            + "        else\n" //
            + "            return loader\n" //
            + "        end\n" //
            + "    end\n" //
            + ")\n\n";
    protected static Connection connection;
    protected static ExasolObjectFactory factory;
    private static ExasolSchema scriptSchema;

    @BeforeAll
    static void beforeAll() throws NoDriverFoundException, SQLException {
        EXASOL.purgeDatabase();
        connection = EXASOL.createConnection("");
        factory = new ExasolObjectFactory(connection);
        scriptSchema = factory.createSchema("L");
    }

    protected VirtualSchema createVirtualSchema(final Schema sourceSchema, final Map<String, String> properties) {
        final String name = sourceSchema.getName();
        final AdapterScript adapterScript;
        try {
            adapterScript = createAdapterScript(name);
        } catch (final IOException exception) {
            throw new AssertionError("Unable to prepare adapter script \"" + name + "\" required for test", exception);
        }
        return factory.createVirtualSchemaBuilder(getVirtualSchemaName(name)) //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .properties(addDebugProperties(properties)) //
                .build();
    }

    protected Map<String, String> addDebugProperties(final Map<String, String> properties) {
        final String logHost = System.getProperty(LOG_HOST_PROPERTY);
        if (logHost == null) {
            return properties;
        } else {
            final int logPort = Integer
                    .parseInt(System.getProperty(LOG_PORT_PROPERTY, Integer.toString(DEFAULT_LOG_PORT)));
            final String debugAddress = logHost + ":" + logPort;
            final Map<String, String> mergedProperties = new HashMap<>();
            mergedProperties.put("DEBUG_ADDRESS", debugAddress);
            mergedProperties.put("LOG_LEVEL", "TRACE");
            mergedProperties.putAll(properties);
            return mergedProperties;
        }
    }

    protected VirtualSchema createVirtualSchema(final Schema sourceSchema) {
        return createVirtualSchema(sourceSchema, Collections.emptyMap());
    }

    protected AdapterScript createAdapterScript(final String prefix) throws IOException {
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(RLS_PACKAGE_PATH);
        return scriptSchema.createAdapterScript(prefix + "_ADAPTER", AdapterScript.Language.LUA, content);
    }

    protected String getVirtualSchemaName(final String sourceSchemaName) {
        return sourceSchemaName + "_RLS";
    }

    protected String getVirtualSchemaName(final Schema sourceSchema) {
        return getVirtualSchemaName(sourceSchema.getName());
    }

    protected ResultSet executeRlsQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = EXASOL.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        final ResultSet result = statement.executeQuery(query);
        return result;
    }

    protected TimedResultSet executeTimedRlsQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = EXASOL.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        final long before = System.nanoTime();
        final ResultSet result = statement.executeQuery(query);
        final long after = System.nanoTime();
        return new TimedResultSet(result, Duration.ofNanos(after - before));
    }

    protected Table createUserConfigurationTable(final Schema schema) {
        return schema.createTable(USERS_TABLE, USER_NAME_COLUMN, IDENTIFIER_TYPE, ROLE_MASK_COLUMN, ROLE_MASK_TYPE);
    }

    protected Table createGroupToUserMappingTable(final Schema sourceSchema) {
        return sourceSchema.createTable(GROUP_MEMBERSHIP_TABLE, GROUP_COLUMN, IDENTIFIER_TYPE, USER_NAME_COLUMN,
                IDENTIFIER_TYPE);
    }

    protected User createUserWithVirtualSchemaAccess(final String name, final VirtualSchema virtualSchema) {
        return factory.createLoginUser(name).grant(virtualSchema, ExasolObjectPrivilege.SELECT);
    }

    protected Schema createSchema(final String sourceSchemaName) {
        return factory.createSchema(sourceSchemaName);
    }

    protected void assertRlsQueryWithUser(final String sql, final User user, final Matcher<ResultSet> expected) {
        try {
            final ResultSet result = executeRlsQueryWithUser(sql, user);
            assertThat(result, expected);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run assertion query.", exception);
        }
    }

    protected Duration assertTimedRlsQueryWithUser(final String sql, final User user,
            final Matcher<ResultSet> expected) {
        try {
            final TimedResultSet timedResult = executeTimedRlsQueryWithUser(sql, user);
            assertThat(timedResult.getResultSet(), expected);
            return timedResult.getDuration();
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run assertion query.", exception);
        }
    }

    protected void assertRlsQueryThrowsExceptionWithMessageContaining(final String sql, final User user,
            final String expectedMessageFragment) {
        final SQLException exception = assertThrows(SQLException.class, () -> executeRlsQueryWithUser(sql, user));
        assertThat(exception.getMessage(), containsString(expectedMessageFragment));
    }
}