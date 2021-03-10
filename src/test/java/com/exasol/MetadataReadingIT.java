package com.exasol;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.Schema;

@Testcontainers
class MetadataReadingIT extends AbstractLuaVirtualSchemaIT {
    /***
     * This is a regression test for <a href="https://github.com/exasol/row-level-security-lua/issues/33">#33</a>.
     *
     * A table is created after the creation of the group membership table.
     *
     * @throws IOException
     * @throws SQLException
     */
    @Test
    void testDealingWithUnregistedTable() throws IOException, SQLException {
        final String sourceSchemaName = "SCHEMA_WITH_UNREGISTERED_TABLE";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "EXA_RLS_GROUP", "VARCHAR(128)");
        assertDoesNotThrow(() -> createVirtualSchema(sourceSchema));
    }
}