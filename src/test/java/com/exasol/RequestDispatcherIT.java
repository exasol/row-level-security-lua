package com.exasol;

import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.containers.ExasolContainer;
import com.exasol.dbbuilder.AdapterScript;
import com.exasol.dbbuilder.AdapterScript.Language;
import com.exasol.dbbuilder.ExasolObjectFactory;
import com.exasol.dbbuilder.ObjectPrivilege;
import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;
import com.exasol.matcher.ResultSetStructureMatcher;

@Testcontainers
class RequestDispatcherIT {
    private static final Path RLS_PACKAGE_PATH = Path.of("target/row-level-security-dist-0.2.0.lua");
    @Container
    private static ExasolContainer<? extends ExasolContainer<?>> container = new ExasolContainer<>(
            "exasol/docker-db:7.0.0") //
                    .withRequiredServices() //
                    .withExposedPorts(8563);
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
    private static ExasolObjectFactory factory;
    private static Schema scriptSchema;

    @BeforeAll
    static void beforeAll() throws NoDriverFoundException, SQLException {
        connection = container.createConnection("");
        factory = new ExasolObjectFactory(connection);
        scriptSchema = factory.createSchema("L");
    }

    @Test
    void testUnprotected() throws IOException, SQLException {
        final String sourceSchemaName = "UNPROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN") //
                .insert("true") //
                .insert("false");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("UP_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + sourceSchemaName + "_RLS.T", user),
                ResultSetStructureMatcher.table("BOOLEAN").row(true).row(false).matches());
    }

    private VirtualSchema createVirtualSchema(final Schema sourceSchema) throws IOException {
        final String name = sourceSchema.getName();
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(RLS_PACKAGE_PATH);
        final AdapterScript adapterScript = scriptSchema.createAdapterScript(name + "_ADAPTER", Language.LUA, content);
        return factory.createVirtualSchemaBuilder(name + "_RLS") //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .properties(Map.of("LOG_LEVEL", "TRACE", "DEBUG_ADDRESS", "172.17.0.1:3000")).build();
    }

    private ResultSet executeRlsQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = container.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        final ResultSet result = statement.executeQuery(query);
        return result;
    }

    @Test
    void testTenantProtected() throws IOException, SQLException {
        final String sourceSchemaName = "TENANT_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE", "EXA_ROW_TENANT", "VARCHAR(128)") //
                .insert("false", "2020-01-01", "NON_TENANT_USER") //
                .insert("true", "2020-02-02", "TENANT_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("TENANT_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        factory.createLoginUser("NON_TENANT_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + sourceSchemaName + "_RLS.T", user),
                ResultSetStructureMatcher.table("BOOLEAN").row(true).matches());
    }

    @Test
    void testGroupProtected() throws IOException, SQLException {
        final String sourceSchemaName = "GROUP_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("G", "C1", "BOOLEAN", "C2", "DATE", "EXA_ROW_GROUP", "VARCHAR(128)") //
                .insert("false", "2020-01-01", "G1") //
                .insert("true", "2020-02-02", "G2");
        sourceSchema.createTable("EXA_GROUP_MEMBERS", "EXA_RLS_GROUP", "VARCHAR(128)", "EXA_RLS_USER", "VARCHAR(128)") //
                .insert("G1", "GROUP_USER") //
                .insert("G2", "OTHER_GROUP_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("GROUP_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        // FIXME: Remove this line once the permissions of Lua VS are based on owner instead of caller.
        // https://github.com/exasol/row-level-security-lua/issues/12
        user.grant(sourceSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + sourceSchemaName + "_RLS.G", user),
                ResultSetStructureMatcher.table("BOOLEAN").row(false).matches());
    }
}