package com.exasol;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;

import com.exasol.containers.ExasolContainer;
import com.exasol.dbbuilder.AdapterScript;
import com.exasol.dbbuilder.AdapterScript.Language;
import com.exasol.dbbuilder.ExasolObjectFactory;
import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;

abstract class AbstractLuaVirtualSchemaIT {
    private static final Path RLS_PACKAGE_PATH = Path.of("target/row-level-security-dist-0.4.0.lua");
    // FIXME: replace by officially released version once available
    @Container
    private static ExasolContainer<? extends ExasolContainer<?>> container = //
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
        connection = container.createConnection("");
        factory = new ExasolObjectFactory(connection);
        scriptSchema = factory.createSchema("L");
    }

    protected VirtualSchema createVirtualSchema(final Schema sourceSchema) throws IOException {
        final String name = sourceSchema.getName();
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(RLS_PACKAGE_PATH);
        final AdapterScript adapterScript = scriptSchema.createAdapterScript(name + "_ADAPTER", Language.LUA, content);
        return factory.createVirtualSchemaBuilder(getVirtualSchemaName(name)) //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .properties(Map.of("LOG_LEVEL", "TRACE", "DEBUG_ADDRESS", "172.17.0.1:3000")).build();
    }

    protected String getVirtualSchemaName(final String sourceSchemaName) {
        return sourceSchemaName + "_RLS";
    }

    protected ResultSet executeRlsQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = container.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        final ResultSet result = statement.executeQuery(query);
        return result;
    }
}