package com.exasol.rls.administration;

import static com.exasol.RlsTestConstants.USERS_TABLE;
import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.stream.Stream;

import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.testcontainers.junit.jupiter.Testcontainers;

// [itest -> dsn~assigning-roles-to-users~0]
@Tag("integration")
@Tag("slow")
@Testcontainers
class AssignRolesToUserIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "ASSIGN_ROLES_TO_USER", PATH_TO_EXA_RLS_BASE, PATH_TO_EXA_IDENTIFIER,
                PATH_TO_ASSIGN_ROLES_TO_USER);
        schema.createTable(EXA_ROLES_MAPPING_TABLE_NAME, "ROLE_NAME", "VARCHAR(128)", "ROLE_ID", "DECIMAL(2,0)") //
                .insert("role_1", 1) //
                .insert("role_2", 2) //
                .insert("role_3", 3) //
                .insert("role_4", 4) //
                .insert("role_53", 53) //
                .insert("role_63", 63);
    }

    @AfterEach
    void afterEach() throws SQLException {
        execute("DROP TABLE IF EXISTS " + getUserTableName());
    }

    private String getUserTableName() {
        return schema.getFullyQualifiedName() + "." + USERS_TABLE;
    }

    @ParameterizedTest
    @MethodSource("provideValuesForTestAssignRolesToUser")
    void testAssignRolesToUser(final List<String> rolesToAssign, final long maskValue) throws SQLException {
        script.execute("MONICA", rolesToAssign);
        assertThat(query("SELECT EXA_USER_NAME, EXA_ROLE_MASK FROM " + getUserTableName()), table() //
                .row("MONICA", maskValue) //
                .matches(NO_JAVA_TYPE_CHECK));
    }

    static Stream<Arguments> provideValuesForTestAssignRolesToUser() {
        return Stream.of(Arguments.of(List.of("role_1"), 1), //
                Arguments.of(List.of("role_1", "role_2"), 3), //
                Arguments.of(List.of("role_1", "role_4"), 9), //
                Arguments.of(List.of("role_1", "role_2", "role_3", "role_4"), 15), //
                Arguments.of(List.of("role_2", "role_3", "role_53", "role_63"),
                        BitField64.ofIndices(1, 2, 52, 62).toLong()));
    }

    @Test
    void testAssignRolesToUserUpdatesUserRoles() throws SQLException {
        script.execute("NORBERT", List.of("role_1", "role_2", "role_63"));
        script.execute("NORBERT", List.of("role_1"));
        assertThat(query("SELECT EXA_USER_NAME, EXA_ROLE_MASK FROM " + getUserTableName()), table() //
                .row("NORBERT", 1) //
                .matches(NO_JAVA_TYPE_CHECK));
    }

    @MethodSource("com.exasol.rls.administration.AbstractAdminScriptIT#produceInvalidIdentifiers")
    @ParameterizedTest
    void testAssingingToIllegalUserThrowsException(final String userName, final String quotedUserName) {
        assertScriptThrows("The user name " + quotedUserName + " is invalid. " + ALLOWED_IDENTIFIER_EXPLAINATION,
                userName, List.of("role_1"));
    }

    @MethodSource("com.exasol.rls.administration.AbstractAdminScriptIT#produceInvalidIdentifiersInList")
    @ParameterizedTest
    void testAssignIllegalRoleToUserThrowsException(final List<String> invalidRoleNames, final String quotedRoleNames) {
        assertScriptThrows(
                "The following role names are invalid: " + quotedRoleNames + ". " + ALLOWED_IDENTIFIER_EXPLAINATION,
                "USER_1", invalidRoleNames);
    }
}