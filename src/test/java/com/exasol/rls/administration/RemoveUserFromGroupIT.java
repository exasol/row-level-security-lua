package com.exasol.rls.administration;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Table;

// [itest -> dsn~removing-users-from-groups~0]
@Testcontainers
@Tag("integration")
@Tag("slow")
class RemoveUserFromGroupIT extends AbstractAdminScriptIT {
    private Table memberTable;

    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "REMOVE_USER_FROM_GROUP", PATH_TO_EXA_IDENTIFIER, PATH_TO_REMOVE_USER_FROM_GROUP);
    }

    @BeforeEach
    void beforeEach() {
        this.memberTable = schema.createTable(EXA_GROUP_MEMBERS_TABLE_NAME, "EXA_USER_NAME", "VARCHAR(128)",
                "EXA_GROUP", "VARCHAR(128)");
    }

    @AfterEach
    void afterEach() throws SQLException {
        execute("DROP TABLE " + this.memberTable.getFullyQualifiedName());
    }

    @Test
    void testRemoveUserFromGroup() throws SQLException {
        this.memberTable.insert("ROLF", "ARTISTS") //
                .insert("ROLF", "HANDCRAFTERS") //
                .insert("ROLF", "TEACHERS") //
                .insert("GABI", "HANDCRAFTERS");
        script.execute("ROLF", List.of("ARTISTS", "HANDCRAFTERS"));
        assertThat(
                query("SELECT * FROM " + this.memberTable.getFullyQualifiedName()
                        + " ORDER BY EXA_USER_NAME, EXA_GROUP"), //
                table("VARCHAR", "VARCHAR") //
                        .row("GABI", "HANDCRAFTERS") //
                        .row("ROLF", "TEACHERS") //
                        .matches());
    }

    @MethodSource("com.exasol.rls.administration.AbstractAdminScriptIT#produceInvalidIdentifiers")
    @ParameterizedTest
    void testRemoveUserFromGroupValidatesUserName(final String identifier, final String quotedIdentifier) {
        assertScriptThrows("The user name " + quotedIdentifier + " is invalid. " + ALLOWED_IDENTIFIER_EXPLAINATION,
                identifier, List.of("IRRELEVANT"));
    }

    @MethodSource(value = "com.exasol.rls.administration.AbstractAdminScriptIT#produceInvalidIdentifiersInList")
    @ParameterizedTest
    void testRemoveUserFromGroupValidatesGroups(final List<String> invalidGroupNames, final String quotedGroupNames) {
        assertScriptThrows(
                "The following group names are invalid: " + quotedGroupNames + ". " + ALLOWED_IDENTIFIER_EXPLAINATION,
                "THE_USER", invalidGroupNames);
    }
}