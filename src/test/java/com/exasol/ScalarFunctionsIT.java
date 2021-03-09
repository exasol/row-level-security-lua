package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;

@Testcontainers
class ScalarFunctionsIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testIproc() throws IOException, SQLException {
        final String sourceSchemaName = "IPROC_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("UP_USER", virtualSchema);
        assertThat(
                executeRlsQueryWithUser("SELECT IPROC() FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row(0).row(0).matches(NO_JAVA_TYPE_CHECK));
    }
}