package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class CapabilitiesIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testIncludeLimitCapability() {
        final String sourceSchemaName = "HAS_LIMIT_CAPABILITY_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("HLC_USER", virtualSchema);
        assertQueryWithUserRewrittenTo("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                "SELECT \"T\".\"C1\" FROM \"" + sourceSchemaName + "\".\"T\"");
    }

    @Test
    void testExcludeLimitCapability() {
        final String sourceSchemaName = "NO_LIMIT_CAPABILITY_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "DATE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema,
                Map.of("EXCLUDED_CAPABILITIES", "SELECTLIST_PROJECTION"));
        final User user = createUserWithVirtualSchemaAccess("NLC_USER", virtualSchema);
        assertQueryWithUserRewrittenTo("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                "SELECT * FROM \"" + sourceSchemaName + "\".\"T\"");
    }

    private void assertQueryWithUserRewrittenTo(final String sql, final User user, final String expectedQuery) {
        assertRlsQueryWithUser("EXPLAIN VIRTUAL " + sql, user,
                table().row(anything(), equalTo(expectedQuery), anything(), anything()).matches());
    }
}