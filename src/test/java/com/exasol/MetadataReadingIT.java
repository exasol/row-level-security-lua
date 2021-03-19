package com.exasol;

import static com.exasol.RlsTestConstants.IDENTIFIER_TYPE;
import static com.exasol.RlsTestConstants.ROW_GROUP_COLUMN;
import static com.exasol.dbbuilder.ObjectPrivilege.SELECT;
import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.Matchers.anything;

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

    @Test
    void testDetermineColumnTypes() {
        final String sourceSchemaName = "SCHEMA_COLUMN_TYPES";
        final String userName = "USER_COLUMN_TYPE";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTableBuilder("T") //
                .column("BO", "BOOLEAN") //
                .column("CA", "CHAR(34) ASCII") //
                .column("CU", "CHAR(345) UTF8") //
                .column("DA", "DATE") //
                .column("DO", "DOUBLE") //
                .column("DE", "DECIMAL(15,9)") //
                .column("G1", "GEOMETRY(7)") //
                .column("G2", "GEOMETRY") //
                .column("H1", "HASHTYPE(32 BIT)") //
                .column("H2", "HASHTYPE(20 BYTE)") //
                .column("I1", "INTERVAL YEAR TO MONTH") //
                .column("I2", "INTERVAL YEAR(7) TO MONTH") //
                .column("I3", "INTERVAL DAY TO SECOND") //
                .column("I4", "INTERVAL DAY(4) TO SECOND(2)") //
                .column("T1", "TIMESTAMP") //
                .column("T2", "TIMESTAMP WITH LOCAL TIME ZONE") //
                .column("VA", "VARCHAR(123) ASCII") //
                .column("VU", "VARCHAR(12) UTF8") //
                .build();
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess(userName, virtualSchema) //
                .grant(sourceSchema, SELECT); // FIXME: https://github.com/exasol/row-level-security-lua/issues/39
        assertRlsQueryWithUser("DESCRIBE " + virtualSchema.getName() + ".T", user, //
                table() //
                        .row("BO", "BOOLEAN", anything(), anything(), anything())
                        .row("CA", "CHAR(34) ASCII", anything(), anything(), anything())
                        .row("CU", "CHAR(345) UTF8", anything(), anything(), anything())
                        .row("DA", "DATE", anything(), anything(), anything())
                        .row("DO", "DOUBLE", anything(), anything(), anything())
                        .row("DE", "DECIMAL(15,9)", anything(), anything(), anything())
                        .row("G1", "GEOMETRY(7)", anything(), anything(), anything())
                        .row("G2", "GEOMETRY", anything(), anything(), anything())
                        .row("H1", "HASHTYPE(4 BYTE)", anything(), anything(), anything())
                        .row("H2", "HASHTYPE(20 BYTE)", anything(), anything(), anything())
                        .row("I1", "INTERVAL YEAR(2) TO MONTH", anything(), anything(), anything())
                        .row("I2", "INTERVAL YEAR(7) TO MONTH", anything(), anything(), anything())
                        .row("I3", "INTERVAL DAY(2) TO SECOND(3)", anything(), anything(), anything())
                        .row("I4", "INTERVAL DAY(4) TO SECOND(2)", anything(), anything(), anything())
                        .row("T1", "TIMESTAMP", anything(), anything(), anything())
                        .row("T2", "TIMESTAMP WITH LOCAL TIME ZONE", anything(), anything(), anything())
                        .row("VA", "VARCHAR(123) ASCII", anything(), anything(), anything())
                        .row("VU", "VARCHAR(12) UTF8", anything(), anything(), anything()) //
                        .matches());
    }
}