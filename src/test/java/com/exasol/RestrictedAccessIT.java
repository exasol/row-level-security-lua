package com.exasol;

import static com.exasol.RlsTestConstants.ROLE_MASK_TYPE;
import static com.exasol.RlsTestConstants.ROW_ROLES_COLUMN;
import static com.exasol.dbbuilder.ObjectPrivilege.SELECT;
import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.containers.ExasolDockerImageReference;
import com.exasol.dbbuilder.*;

@Testcontainers
class RestrictedAccessIT extends AbstractLuaVirtualSchemaIT {
    /**
     * Test accessing a role-protected table with a user who does not have any roles
     *
     * This is a regression test for <a href="https://github.com/exasol/row-level-security-lua/issues/32">#32</a>
     */
    @Test
    void testAccessRoleProtectedTableWithoutRole() {
        final Schema schema = createSchema("SCHEMA_FOR_ACCESS_WITHOUT_ROLE");
        schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("NOT ACESSIBLE", 1);
        createUserConfigurationTable(schema);
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_FOR_ACCESS_WITHOUT_ROLE", virtualSchema) //
                .grant(schema, SELECT); // FIXME: https://github.com/exasol/row-level-security-lua/issues/39
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user, table().matches());
    }

    /**
     * Test accessing a role-protected table with a user who does not have any roles
     *
     * <p>
     * This is a regression test for <a href="https://github.com/exasol/row-level-security-lua/issues/32">#32</a>.
     * </p>
     * <p>
     * Note the the LuaVS prototype based on Exasol 7.0 contains a bug that causes an internal server error if
     * <code>pquery</code> fails (e.g. because of missing tables). This test requires 7.1 or later.
     */
    @Test
    void testAccessRoleProtectedTableWhenUserMappingIsMissing() {
        assumeExasolSevenOneOrLater();
        final Schema schema = createSchema("SCHEMA_FOR_ACCESS_WITHOUT_ROLE");
        schema.createTable("T", "C1", "VARCHAR(20)", ROW_ROLES_COLUMN, ROLE_MASK_TYPE) //
                .insert("NOT ACESSIBLE", 1);
        final VirtualSchema virtualSchema = createVirtualSchema(schema);
        final User user = createUserWithVirtualSchemaAccess("USER_FOR_ACCESS_WITHOUT_ROLE", virtualSchema) //
                .grant(schema, SELECT); // FIXME: https://github.com/exasol/row-level-security-lua/issues/39
        assertRlsQueryWithUser("SELECT C1 FROM " + virtualSchema.getName() + ".T", user, table().matches());
    }

    private void assumeExasolSevenOneOrLater() {
        final ExasolDockerImageReference imageReference = EXASOL.getDockerImageReference();
        assumeTrue((imageReference.getMajor() > 7)
                || ((imageReference.getMajor() == 7) && (imageReference.getMinor() > 0)));
    }
}