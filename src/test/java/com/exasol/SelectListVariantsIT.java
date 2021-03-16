package com.exasol;

import static com.exasol.RlsTestConstants.IDENTIFIER_TYPE;
import static com.exasol.RlsTestConstants.ROW_TENANT_COLUMN;
import static com.exasol.matcher.ResultSetStructureMatcher.table;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.*;

@Testcontainers
class SelectListVariantsIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testSelectStarOnUnprotectedTable() {
        final String sourceSchemaName = "SELECT_STAR_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("SELECT_STAR_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row(true).row(false).matches());
    }

    @Test
    void testSelectStarOnProtectedTable() {
        final String sourceSchemaName = "SELECT_STAR_PROTECTED_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", ROW_TENANT_COLUMN, IDENTIFIER_TYPE) //
                .insert(true, "SELECT_STAR_PROTECTED_USER") //
                .insert(false, "NOONE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("SELECT_STAR_PROTECTED_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row(true).matches());
    }

    // This test case describes a situation where a push-down query request with an empty select list is received. This
    // might happen because the core database evaluates constant expressions before performing the push-down query to
    // the Virtual Schema. In such cases the adapter internally fills the select list with a dummy expression that only
    // serves the purpose of providing the right number of rows in the result set.
    @Test
    void testEmptySelectList() {
        final String sourceSchemaName = "EMPTY_SELECT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("EMPTY_SELECT_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT 'foo' FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row("foo").row("foo").matches());
    }
}