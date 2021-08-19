package com.exasol;

import static com.exasol.RlsTestConstants.ROLE_MASK_TYPE;
import static com.exasol.RlsTestConstants.ROW_ROLES_COLUMN;
import static com.exasol.basetypes.BitField64.bitsToLong;
import static com.exasol.matcher.ResultSetStructureMatcher.table;

import java.sql.*;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class RestrictedAccessIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testAccessRoleProtectedTableWithoutRole() {
        final Schema schema = createSchema("SCHEMA_FOR_ACCESS_WITHOUT_ROLE");
        schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("NOT ACESSIBLE", bitsToLong(0));
        createUserConfigurationTable(schema);
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_FOR_ACCESS_WITHOUT_ROLE", virtualSchema);
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user, table("VARCHAR").matches());
    }

    @Test
    void testAccessRoleProtectedTableWhenUserMappingIsMissingThrowsSqlCompilationError() {
        final Schema schema = createSchema("SCHEMA_FOR_ACCESS_WITHOUT_MAPPING");
        schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("NOT ACESSIBLE", bitsToLong(0));
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_FOR_ACCESS_WITHOUT_MAPPING", virtualSchema);
        assertRlsQueryThrowsExceptionWithMessageContaining("SELECT C1 FROM " + virtualSchema.getName() + ".T", user,
                "Error during compilation: object \"SCHEMA_FOR_ACCESS_WITHOUT_MAPPING\".\"EXA_RLS_USERS\" not found");
    }

    @Test
    void testPublicAccessRoleWithNoRoles() {
        final Schema schema = createSchema("SCHEMA_PUBLIC_ACCESS_NO_ROLE");
        final Table table = schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("FOR ROLE 1", bitsToLong(0));
        addPublicRoleEntry(table, "PUBLIC");
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_PUBLIC_ACCESS_NO_ROLE", virtualSchema);
        createUserConfigurationTable(schema);
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user,
                table().row("PUBLIC").matches());
    }

    private void addPublicRoleEntry(final Table table, final String string) {
        final String sql = "INSERT INTO " + table.getFullyQualifiedName() + "VALUES('" + string + "', BIT_SET(0, 63))";
        try {
            final Connection connection = EXASOL.createConnection();
            final Statement statement = connection.createStatement();
            statement.execute(sql);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to create table entry with public role: " + sql, exception);
        }
    }

    @Test
    void testPublicAccessRoleWithNonMatchingRole() {
        final Schema schema = createSchema("SCHEMA_PUBLIC_ACCESS_NON_MATCHING_ROLE");
        final Table table = schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("FOR ROLE 1", bitsToLong(0));
        addPublicRoleEntry(table, "PUBLIC");
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_PUBLIC_ACCESS_NON_MATCHING_ROLE", virtualSchema);
        createUserConfigurationTable(schema) //
                .insert(user.getName(), bitsToLong(1));
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T ORDER BY C1", user,
                table().row("PUBLIC").matches());
    }
}