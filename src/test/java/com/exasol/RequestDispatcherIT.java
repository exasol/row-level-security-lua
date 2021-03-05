package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.ObjectPrivilege;
import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;

@Testcontainers
class RequestDispatcherIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testUnprotected() throws IOException, SQLException {
        final String sourceSchemaName = "UNPROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN") //
                .insert("true") //
                .insert("false");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("UP_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table("BOOLEAN").row(true).row(false).matches());
    }

    @Test
    void testTenantProtected() throws IOException, SQLException {
        final String sourceSchemaName = "TENANT_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE", "EXA_ROW_TENANT", "VARCHAR(128)") //
                .insert("false", "2020-01-01", "NON_TENANT_USER") //
                .insert("true", "2020-02-02", "TENANT_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("TENANT_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        factory.createLoginUser("NON_TENANT_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + sourceSchemaName + "_RLS.T", user),
                table("BOOLEAN").row(true).matches());
    }

    @Test
    void testGroupProtected() throws IOException, SQLException {
        final String sourceSchemaName = "GROUP_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("G", "C1", "BOOLEAN", "C2", "DATE", "EXA_ROW_GROUP", "VARCHAR(128)") //
                .insert("false", "2020-01-01", "G1") //
                .insert("true", "2020-02-02", "G2");
        sourceSchema
                .createTable("EXA_GROUP_MEMBERS", "EXA_RLS_GROUP", "VARCHAR(128)", "EXA_RLS_USER_NAME", "VARCHAR(128)") //
                .insert("G1", "GROUP_USER") //
                .insert("G2", "OTHER_GROUP_USER");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("GROUP_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        // FIXME: Remove this line once the permissions of Lua VS are based on owner instead of caller.
        // https://github.com/exasol/row-level-security-lua/issues/12
        user.grant(sourceSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".G", user),
                table("BOOLEAN").row(false).matches());
    }

    @Test
    void testRoleProtected() throws IOException, SQLException {
        final String sourceSchemaName = "ROLE_PROTECTED";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("R", "C1", "BOOLEAN", "C2", "DATE", "EXA_ROW_ROLES", "DECIMAL(20,0)") //
                .insert("false", "2020-01-01", "1") //
                .insert("true", "2020-02-02", "2");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        sourceSchema.createTable("EXA_RLS_USERS", "EXA_USER_NAME", "VARCHAR(128)", "EXA_ROLE_MASK", "DECIMAL(20,0)")
                .insert("ROLE_USER", "5");
        final User user = factory.createLoginUser("ROLE_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        // FIXME: Remove this line once the permissions of Lua VS are based on owner instead of caller.
        // https://github.com/exasol/row-level-security-lua/issues/12
        user.grant(sourceSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".R", user),
                table("BOOLEAN").row(false).matches());
    }
}