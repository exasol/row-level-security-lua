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