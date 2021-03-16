package com.exasol;

import static com.exasol.RlsTestConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.util.Map;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;

import com.exasol.containers.ExasolContainer;
import com.exasol.dbbuilder.*;
import com.exasol.dbbuilder.AdapterScript.Language;

abstract class AbstractLuaVirtualSchemaIT {
    protected static final Map<String, String> DEBUG_PROPERTIES = Map.of("LOG_LEVEL", "TRACE", "DEBUG_ADDRESS",
            "172.17.0.1:3000");
    private static final Path RLS_PACKAGE_PATH = Path.of("target/row-level-security-dist-0.4.0.lua");
    // FIXME: replace by officially released version once available
    // https://github.com/exasol/row-level-security-lua/issues/39
    @Container
    protected static ExasolContainer<? extends ExasolContainer<?>> EXASOL = //
            new ExasolContainer<>("exasol/docker-db:7.0.0") //
                    .withRequiredServices() //
                    .withExposedPorts(8563) //
                    .withReuse(true);
    private static final String EXASOL_LUA_MODULE_LOADER_WORKAROUND = "table.insert(package.loaders,\n" //
            + "    function (module_name)\n" //
            + "        local loader = package.preload[module_name]\n" //
            + "        if(loader == nil) then\n" //
            + "            error(\"Module \" .. module_name .. \" not found in package.preload.\")\n" //
            + "        else\n" //
            + "            return loader\n" //
            + "        end\n" //
            + "    end\n" //
            + ")\n\n";
    private static Connection connection;
    protected static ExasolObjectFactory factory;
    private static Schema scriptSchema;

    @BeforeAll
    static void beforeAll() throws NoDriverFoundException, SQLException {
        connection = EXASOL.createConnection("");
        factory = new ExasolObjectFactory(connection);
        scriptSchema = factory.createSchema("L");
    }

    protected VirtualSchema createVirtualSchema(final Schema sourceSchema) {
        final String name = sourceSchema.getName();
        AdapterScript adapterScript;
        try {
            adapterScript = createAdapterScript(name);
        } catch (final IOException exception) {
            throw new AssertionError("Unable to prepare adapter script \"" + name + "\" required for test", exception);
        }
        return factory.createVirtualSchemaBuilder(getVirtualSchemaName(name)) //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .properties(DEBUG_PROPERTIES) //
                .build();
    }

    protected AdapterScript createAdapterScript(final String prefix) throws IOException {
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(RLS_PACKAGE_PATH);
        return scriptSchema.createAdapterScript(prefix + "_ADAPTER", Language.LUA, content);
    }

    protected String getVirtualSchemaName(final String sourceSchemaName) {
        return sourceSchemaName + "_RLS";
    }

    protected ResultSet executeRlsQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = EXASOL.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        final ResultSet result = statement.executeQuery(query);
        return result;
    }

    protected Table createUserConfigurationTable(final Schema schema) {
        return schema.createTable(USERS_TABLE, USER_NAME_COLUMN, IDENTIFIER_TYPE, ROLE_MASK_COLUMN, ROLE_MASK_TYPE);
    }

    protected Table creatGroupMembershipTable(final Schema sourceSchema) {
        return sourceSchema.createTable(GROUP_MEMBERSHIP_TABLE, USER_NAME_COLUMN, IDENTIFIER_TYPE, ROW_GROUP_COLUMN,
                IDENTIFIER_TYPE);
    }

    protected User createUserWithVirtualSchemaAccess(final String name, final VirtualSchema virtualSchema) {
        return factory.createLoginUser(name).grant(virtualSchema, ObjectPrivilege.SELECT);
    }

    protected Schema createSchema(final String sourceSchemaName) {
        return factory.createSchema(sourceSchemaName);
    }

    protected void assertRlsQueryWithUser(final String sql, final User user, final Matcher<ResultSet> expected) {
        try {
            assertThat(executeRlsQueryWithUser(sql, user), expected);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run assertion query.", exception);
        }
    }
}