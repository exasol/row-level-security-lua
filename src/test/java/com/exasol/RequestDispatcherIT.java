package com.exasol;

import static com.exasol.RlsTestConstants.*;
import static com.exasol.dbbuilder.dialects.exasol.ExasolObjectPrivilege.SELECT;
import static com.exasol.matcher.ResultSetStructureMatcher.table;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class RequestDispatcherIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testUnprotected() {
        final String sourceSchemaName = "UNPROTECTED";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN") //
                .insert("true") //
                .insert("false");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("UP_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table("BOOLEAN").row(true).row(false).matches());
    }

    @Test
    void testTenantProtected() {
        final String sourceSchemaName = "TENANT_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE", ROW_TENANT_COLUMN, IDENTIFIER_TYPE) //
                .insert("false", "2020-01-01", "NON_TENANT_USER") //
                .insert("true", "2020-02-02", "TENANT_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("TENANT_USER").grant(virtualSchema, SELECT);
        factory.createLoginUser("NON_TENANT_USER").grant(virtualSchema, SELECT);
        assertRlsQueryWithUser("SELECT C1 FROM " + sourceSchemaName + "_RLS.T", user,
                table("BOOLEAN").row(true).matches());
    }

    @Test
    void testGroupProtected() {
        final String sourceSchemaName = "GROUP_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("G", "C1", "BOOLEAN", "C2", "DATE", ROW_GROUP_COLUMN, IDENTIFIER_TYPE) //
                .insert("false", "2020-01-01", "G1") //
                .insert("true", "2020-02-02", "G2");
        createGroupToUserMappingTable(sourceSchema) //
                .insert("G1", "GROUP_USER") //
                .insert("G2", "OTHER_GROUP_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("GROUP_USER").grant(virtualSchema, SELECT);
        assertRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".G", user,
                table("BOOLEAN").row(false).matches());
    }

    @Test
    void testRoleProtected() {
        final String sourceSchemaName = "ROLE_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("R", "C1", "BOOLEAN", "C2", "DATE", ROW_ROLES_COLUMN, IDENTIFIER_TYPE) //
                .insert("false", "2020-01-01", "1") //
                .insert("true", "2020-02-02", "2");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        createUserConfigurationTable(sourceSchema) //
                .insert("ROLE_USER", "5");
        final User user = factory.createLoginUser("ROLE_USER").grant(virtualSchema, SELECT);
        assertRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".R", user,
                table("BOOLEAN").row(false).matches());
    }
}