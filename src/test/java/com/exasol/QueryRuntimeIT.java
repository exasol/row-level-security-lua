package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.lessThanOrEqualTo;

import java.time.Duration;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInfo;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class QueryRuntimeIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testSelectOnFlatTable(final TestInfo testInfo) {
        final String sourceSchemaName = "FLAT_TABLE_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("FLAT_TABLE_USER", virtualSchema);
        final Duration duration = assertTimedRlsQueryWithUser(
                "SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row(true).row(false).matches(NO_JAVA_TYPE_CHECK));
        assertRanInLessThan(testInfo, duration, Duration.ofMillis(250));
    }

    private void assertRanInLessThan(final TestInfo testInfo, final Duration duration, final Duration maximumDuration) {
        System.out.println("Query in test '" + testInfo.getDisplayName() + "' ran in " + duration.toMillis() + " ms.");
        assertThat(duration, lessThanOrEqualTo(maximumDuration));
    }
}