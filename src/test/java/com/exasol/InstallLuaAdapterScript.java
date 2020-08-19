package com.exasol;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Logger;

import com.exasol.dbbuilder.AdapterScript.Language;
import com.exasol.dbbuilder.DatabaseObjectFactory;
import com.exasol.dbbuilder.ExasolObjectFactory;
import com.exasol.dbbuilder.Schema;

public class InstallLuaAdapterScript {
    private static final Logger LOGGER = Logger.getLogger(InstallLuaAdapterScript.class.getName());
    private static final String ADAPTER_SCHEMA_NAME = "LUA_TEST";
    private static final String ADAPTER_NAME = "THE_ADAPTER";
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
    private final String adapterName;
    private final String adapterSchemaName;
    private Connection connection;

    public static void main(final String[] args) {
        new InstallLuaAdapterScript(ADAPTER_NAME, ADAPTER_SCHEMA_NAME).run();
    }

    public InstallLuaAdapterScript(final String adapterName, final String adapterSchemaName) {
        this.adapterName = adapterName;
        this.adapterSchemaName = adapterSchemaName;
    }

    private void run() {
        try {
            this.connection = DriverManager.getConnection("jdbc:exa:127.0.0.1:8563", "sys", "exasol");
            final DatabaseObjectFactory factory = new ExasolObjectFactory(this.connection);
            cleanUpOldEntries();
            final Schema scriptSchema = factory.createSchema(this.adapterSchemaName);
            installAdapter(scriptSchema,
                    Path.of("/home/seb/git/row-level-security-lua/target/row-level-security-dist-0.1.0.lua"));
        } catch (final SQLException | IOException exception) {
            exception.printStackTrace();
        }
    }

    private void cleanUpOldEntries() throws SQLException {
        final Statement statement = this.connection.createStatement();
        statement.execute(
                "DROP ADAPTER SCRIPT IF EXISTS \"" + this.adapterSchemaName + "\".\"" + this.adapterName + "\"");
        statement.execute("DROP SCHEMA IF EXISTS \"" + this.adapterSchemaName + "\"");
    }

    private void installAdapter(final Schema scriptSchema, final Path scriptContent) throws IOException {
        LOGGER.info(() -> "Installing adpater script \"" + this.adapterName + "\" in schema \"" + scriptSchema.getName()
                + "\".");
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(scriptContent);
        scriptSchema.createAdapterScript(this.adapterName, Language.LUA, content);
    }
}