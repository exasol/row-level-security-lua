package com.exasol;

import static com.exasol.dbbuilder.ObjectPrivilege.SELECT;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;
import com.exasol.matcher.ResultSetStructureMatcher;

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
    void testTableRegisteredAfterRlsMetaTable() throws IOException, SQLException {
        final String sourceSchemaName = "SCHEMA_FOR_LATE_REGISTERED_TABLE";
        final String userName = "USER_FOR_LATE_REGISTERED_TABLE";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        final String groupName = "GROUP_THE_USER_HAS";
        sourceSchema
                .createTable("EXA_GROUP_MEMBERS", "EXA_RLS_USER_NAME", "VARCHAR(128)", "EXA_RLS_GROUP", "VARCHAR(128)")
                .insert(userName, groupName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "EXA_ROW_GROUP", "VARCHAR(128)") //
                .insert(true, groupName) //
                .insert(false, "GROUP_THE_USER_DOES_NOT_HAVE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess(userName, virtualSchema) //
                .grant(sourceSchema, SELECT); // FIXME: https://github.com/exasol/row-level-security-lua/issues/39
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user),
                ResultSetStructureMatcher.table().row(true).matches());
    }
}