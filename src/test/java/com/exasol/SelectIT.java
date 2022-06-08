package com.exasol;

import static com.exasol.RlsTestConstants.IDENTIFIER_TYPE;
import static com.exasol.RlsTestConstants.ROW_TENANT_COLUMN;
import static com.exasol.matcher.ResultSetStructureMatcher.table;

import com.exasol.matcher.TypeMatchMode;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class SelectIT extends AbstractLuaVirtualSchemaIT {
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

    @Test
    void testSelectWithOrderByColumnAndLimit() {
        final String sourceSchemaName = "ORDER_LIMIT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "NR", "INTEGER").insert(1).insert(2).insert(3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT NR FROM " + getVirtualSchemaName(sourceSchemaName)
                        + ".T ORDER BY NR LIMIT 2", user,
                table().row(1).row(2).matches(TypeMatchMode.NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testSelectWithOrderByExpressionAndLimitWithOffset() {
        final String sourceSchemaName = "ORDER_LIMIT_OFFSET_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "TXT", "VARCHAR(10)").insert("a").insert("bb").insert("ccc").insert("dddd");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_OFFSET_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT TXT FROM " + getVirtualSchemaName(sourceSchemaName)
                        + ".T ORDER BY LENGTH(TXT) LIMIT 2 OFFSET 1", user,
                table().row("bb").row("ccc").matches());
    }
}