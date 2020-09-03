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

/**
 * This class contains an installation helper intended to simplify declaring Lua adapter scripts.
 * <p>
 * This script is intended for integration tests of Lua adapter scripts. It is a quick way to get the adapter script
 * installed.
 * </p>
 * <p>
 * <b>IMPORTANT:</b> This script creates a fresh schema around the adapter each time. Any other objects in that schema
 * will be lost!
 * </p>
 */
public class InstallLuaAdapterScript {
    private static final String USAGE = "Usage: java InstallLuaAdapterScript.java <schema> <adapter> <path-to-script>\n"
            + "       [<connection-string>] [<user>] [<password>]";
    private static final Logger LOGGER = Logger.getLogger(InstallLuaAdapterScript.class.getName());
    private static final String EXASOL_LUA_MODULE_LOADER_WORKAROUND = "table.insert(package.loaders,\n" //
            + "    function (module_name)\n" //
            + "        local loader = package.preload[module_name]\n" //
            + "        if not loader then\n" //
            + "            error(\"Module \" .. module_name .. \" not found in package.preload.\")\n" //
            + "        else\n" //
            + "            return loader\n" //
            + "        end\n" //
            + "    end\n" //
            + ")\n\n";
    private static final String DEFAULT_CONNECTION_STRING = "jdbc:exa:127.0.0.1:8563";
    private static final String DEFAULT_DATABASE_USER = "SYS";
    private static final String DEFAULT_DATABASE_PWD = "exasol";
    private final String adapterName;
    private final String adapterSchemaName;
    private Connection connection;
    private final String password;
    private final Path scriptPath;
    private final String connectionString;
    private final String user;

    /**
     * Entry point for the Lua adapter script installer.
     * <p>
     * Note that the adapter schema should only be used for this adapter. The installer will remove an existing schema
     * of that name and recreate it.
     * </p>
     *
     * @param arguments array of command line arguments
     *                  <ul>
     *                  <li>name of the schema that the adapter will be installed in</li>
     *                  <li>adapter script name</li>
     *                  <li>path to script</li>
     *                  <li>database connection string (optional, defaults to "jdbc:exa:127.0.0.1:8563")</li>
     *                  <li>database user (optional, defaults to "SYS")</li>
     *                  <li>database password (optional, defaults to "exasol")</li>
     *                  </ul>
     */
    public static void main(final String[] arguments) {
        if (arguments.length < 3) {
            System.out.println(USAGE);
            System.exit(-1);
        }
        final String adapterSchemaName = arguments[0];
        final String adapterScriptName = arguments[1];
        final Path scriptPath = Path.of(arguments[2]);
        final String connectionString = getOptionalArgument(arguments, 3, DEFAULT_CONNECTION_STRING);
        final String user = getOptionalArgument(arguments, 4, DEFAULT_DATABASE_USER);
        final String password = getOptionalArgument(arguments, 5, DEFAULT_DATABASE_PWD);
        new InstallLuaAdapterScript(adapterSchemaName, adapterScriptName, scriptPath, connectionString, user, password)
                .run();
    }

    private static String getOptionalArgument(final String arguments[], final int index, final String defaultValue) {
        return (arguments.length > index) && (arguments[index] != null) ? arguments[index] : defaultValue;
    }

    private InstallLuaAdapterScript(final String adapterSchemaName, final String adapterName, final Path scriptPath,
            final String connectionString, final String user, final String password) {
        this.adapterName = adapterName;
        this.adapterSchemaName = adapterSchemaName;
        this.scriptPath = scriptPath;
        this.connectionString = connectionString;
        this.user = user;
        this.password = password;
    }

    private void run() {
        try {
            this.connection = DriverManager.getConnection(this.connectionString, this.user, this.password);
            final DatabaseObjectFactory factory = new ExasolObjectFactory(this.connection);
            cleanUpOldEntries();
            final Schema scriptSchema = factory.createSchema(this.adapterSchemaName);
            installAdapter(scriptSchema, this.scriptPath);
        } catch (final SQLException | IOException exception) {
            exception.printStackTrace();
        }
    }

    private void cleanUpOldEntries() throws SQLException {
        final Statement statement = this.connection.createStatement();
//        statement.execute(
//                "DROP ADAPTER SCRIPT IF EXISTS \"" + this.adapterSchemaName + "\".\"" + this.adapterName + "\"");
        statement.execute("DROP SCHEMA IF EXISTS \"" + this.adapterSchemaName + "\" CASCADE");
    }

    private void installAdapter(final Schema scriptSchema, final Path scriptContent) throws IOException {
        LOGGER.info(() -> "Installing adpater script \"" + this.adapterName + "\" in schema \"" + scriptSchema.getName()
                + "\".");
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(scriptContent);
        scriptSchema.createAdapterScript(this.adapterName, Language.LUA, content);
    }
}