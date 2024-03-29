package com.exasol.rls.administration;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.testcontainers.junit.jupiter.Testcontainers;

// [itest -> dsn~assigning-roles-to-users~0]
@Tag("integration")
@Tag("slow")
@Testcontainers
class AddRlsRoleIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "ADD_RLS_ROLE", PATH_TO_EXA_RLS_BASE, PATH_TO_ADD_RLS_ROLE);
    }

    @AfterEach
    void afterEach() throws SQLException {
        execute("DELETE FROM " + getRolesMappingTableName());
    }

    private String getRolesMappingTableName() {
        return schema.getFullyQualifiedName() + "." + EXA_ROLES_MAPPING_TABLE_NAME;
    }

    @Test
    void testAddRlsRole() throws SQLException {
        script.execute("Sales", 1);
        script.execute("Development", 2);
        script.execute("Finance", 3);
        assertThat(query("SELECT * FROM " + getRolesMappingTableName()), //
                table("VARCHAR", "SMALLINT") //
                        .row("Sales", (short) 1) //
                        .row("Development", (short) 2) //
                        .row("Finance", (short) 3) //
                        .matches());
    }

    @Test
    void testAddRlsRoleExistingIdException() throws SQLException {
        script.execute("Sales", 1);
        assertScriptThrows("Role id 1 already exists (role name \"Sales\").", "Finance", 1);
    }

    @ParameterizedTest
    @ValueSource(strings = { "SALES", "Sales", "sales" })
    void testAddRlsRoleExistingNameException(final String roleName) throws SQLException {
        script.execute("Sales", 1);
        assertScriptThrows("Role name \"" + roleName + "\" already exists (role id 1).", roleName, 2);
    }

    @ParameterizedTest
    @ValueSource(ints = { -5, 0, 64, 70 })
    void testAddRlsRoleInvalidRoleIdException(final int rlsRole) throws SQLException {
        assertScriptThrows("Invalid role id. Role id must be between 1 and 63.", "Sales", rlsRole);
    }
}