package com.exasol;

import static com.exasol.RlsTestConstants.IDENTIFIER_TYPE;
import static com.exasol.RlsTestConstants.ROW_GROUP_COLUMN;
import static com.exasol.dbbuilder.ObjectPrivilege.SELECT;
import static com.exasol.matcher.ResultSetStructureMatcher.table;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.*;

@Testcontainers
class MetadataReadingIT extends AbstractLuaVirtualSchemaIT {
    /***
     * This is a regression test for <a href="https://github.com/exasol/row-level-security-lua/issues/33">#33</a>.
     *
     * A table is created after the creation of the group membership table.
     */
    @Test
    void testTableRegisteredAfterRlsMetaTable() {
        final String sourceSchemaName = "SCHEMA_FOR_LATE_REGISTERED_TABLE";
        final String userName = "USER_FOR_LATE_REGISTERED_TABLE";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        final String groupName = "GROUP_THE_USER_HAS";
        creatGroupMembershipTable(sourceSchema) //
                .insert(userName, groupName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", ROW_GROUP_COLUMN, IDENTIFIER_TYPE) //
                .insert(true, groupName) //
                .insert(false, "GROUP_THE_USER_DOES_NOT_HAVE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess(userName, virtualSchema) //
                .grant(sourceSchema, SELECT); // FIXME: https://github.com/exasol/row-level-security-lua/issues/39
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user, table().row(true).matches());
    }
}