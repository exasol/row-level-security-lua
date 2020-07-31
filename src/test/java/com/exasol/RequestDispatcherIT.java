package com.exasol;

import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import com.exasol.dbbuilder.AdapterScript;
import com.exasol.dbbuilder.AdapterScript.Language;
import com.exasol.dbbuilder.ExasolObjectFactory;
import com.exasol.dbbuilder.Schema;
import com.exasol.matcher.ResultSetStructureMatcher;

import org.junit.jupiter.api.Test;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.containers.ExasolContainer;

@Testcontainers
class RequestDispatcherIT {
    private static final Path RLS_PACKAGE_PATH = Path.of("target/row-level-security-dist-0.1.0.lua");
    @Container
    private static ExasolContainer<? extends ExasolContainer<?>> container = new ExasolContainer<>(
            "exasol/docker-db:7.0.rc1-d1") //
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

    @Test
    void test() throws NoDriverFoundException, SQLException, IOException {
        final Connection connection = container.createConnection("");
        final ExasolObjectFactory factory = new ExasolObjectFactory(connection);
        final Schema sourceSchema = factory.createSchema("S");
        sourceSchema.createTable("T", "C1", "BOOLEAN") //
                .insert("true").insert("false");
        final Schema scriptSchema = factory.createSchema("L");
        String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(RLS_PACKAGE_PATH);
        final AdapterScript adapterScript = scriptSchema.createAdapterScript("RLS", Language.LUA, content);
        factory.createVirtualSchemaBuilder("R") //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .build();
        final Statement statement = connection.createStatement();
        final ResultSet result = statement.executeQuery("SELECT * FROM R.T");
        assertThat(result, ResultSetStructureMatcher.table("BOOLEAN").row("true").row("false").matches());
    }
}