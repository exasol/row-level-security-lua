package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static java.util.stream.Collectors.toList;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.ExasolSchema;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class RetailSchemaIT extends AbstractLuaVirtualSchemaIT {

    @Test
    void testRetailSchema() throws IOException, SQLException {
        final ExasolSchema sourceSchema = createRetailSchema();
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("RETAIL_USER", virtualSchema);
        final List<String> allTables = List.of("ARTICLE", "CITIES", "MARKETS", "SALES", "SALES_POSITIONS", "DIM_DATE");
        for (final String table : allTables) {
            assertRlsQueryWithUser("SELECT count(*) FROM " + virtualSchema.getName() + "." + table, user,
                    table().row(0L).matches());
        }
    }

    private ExasolSchema createRetailSchema() throws IOException, SQLException {
        final ExasolSchema schema = factory.createSchema("RETAIL_MINI");
        try (Statement statement = connection.createStatement()) {
            statement.execute("OPEN SCHEMA " + schema.getName());
            executeSqlScript(Path.of("src/test/resources/retail_mini.sql"), statement);
            statement.execute("COMMIT");
        }
        return schema;
    }

    private void executeSqlScript(final Path path, final Statement stmt) throws IOException {
        final List<String> sqlStatements = Arrays.stream(Files.readString(path).split(";")).collect(toList());
        for (final String sqlStatement : sqlStatements) {
            try {
                stmt.execute(sqlStatement);
            } catch (final SQLException exception) {
                throw new IllegalStateException(
                        "Failed to execute SQL statement '" + sqlStatement + "': " + exception.getMessage(), exception);
            }
        }
    }
}
