package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

import java.sql.SQLException;
import java.util.Map;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class CapabilitiesIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testIncludeProjectionCapability() {
        final String sourceSchemaName = "HAS_PROJECTION_CAPABILITY_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("HLC_USER", virtualSchema);
        assertQueryWithUserRewrittenTo("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                "SELECT \"T\".\"C1\" FROM \"" + sourceSchemaName + "\".\"T\"");
    }

    @Test
    void testExcludeProjectionCapability() {
        final String sourceSchemaName = "NO_PROJECTION_CAPABILITY_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema,
                Map.of("EXCLUDED_CAPABILITIES", "SELECTLIST_PROJECTION"));
        final User user = createUserWithVirtualSchemaAccess("NLC_USER", virtualSchema);
        assertQueryWithUserRewrittenTo("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                "SELECT * FROM \"" + sourceSchemaName + "\".\"T\"");
    }

    @Test
    @Disabled("Disabled until we implement aggregate functions parsing https://github.com/exasol/row-level-security-lua/issues/103")
    void testAggregateSingleGroupCapability() {
        final String sourceSchemaName = "HAS_AGGREGATE_SINGLE_GROUP_CAPABILITY_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "DECIMAL(10,0)");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ASG_USER", virtualSchema);
        assertQueryWithUserRewrittenTo(
                "SELECT 1 AS BAR FROM (SELECT SUM(C1) X FROM " + getVirtualSchemaName(sourceSchemaName) + ".T)", user,
                "SELECT NULL FROM \"" + sourceSchemaName + "\".\"T\" GROUP BY ''a''");
    }

    @Test
    @DisplayName("Verify DISTINCT with integer literal")
    void testDistinctWithIntegerLiteral() throws SQLException {
        final String sourceSchemaName = "DISTINCT_WITH_INT_LITERAL";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        final Table table = sourceSchema.createTable("T", "C1", "INT") //
                .insert(1).insert(1).insert(2).insert(3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("DISTINCT_USER", virtualSchema);
        try {
            assertThat(
                    executeRlsQueryWithUser("SELECT DISTINCT c1, 0 AS attr from "
                            + virtualSchema.getFullyQualifiedName() + "." + table.getName(), user),
                    table("BIGINT", "SMALLINT") //
                            .row(1L, (short) 0).row(2L, (short) 0).row(3L, (short) 0) //
                            .matchesInAnyOrder());
        } finally {
            virtualSchema.drop();
        }
    }

    @Test
    @DisplayName("Verify GROUP BY with column number reference")
    void testGroupByWithColumnNumber() throws SQLException {
        final String sourceSchemaName = "GROUP_BY_WITH_COL_NUMBER";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        final Table table = sourceSchema.createTable("T", "C1", "INT") //
                .insert(1).insert(1).insert(2).insert(3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("GROUP_BY_USER", virtualSchema);
        try {
            assertThat(
                    executeRlsQueryWithUser("SELECT c1, count(c1) as count from "
                            + virtualSchema.getFullyQualifiedName() + "." + table.getName() + " group by 1", user),
                    table("BIGINT", "BIGINT") //
                            .row(1L, 2L).row(2L, 1L).row(3L, 1L) //
                            .matchesInAnyOrder());
        } finally {
            virtualSchema.drop();
        }
    }

    private void assertQueryWithUserRewrittenTo(final String sql, final User user, final String expectedQuery) {
        assertRlsQueryWithUser("EXPLAIN VIRTUAL " + sql, user,
                table().row(anything(), equalTo(expectedQuery), anything(), anything()).matches());
    }
}