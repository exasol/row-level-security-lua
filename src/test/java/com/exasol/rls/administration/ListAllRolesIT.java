package com.exasol.rls.administration;

import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.EXA_ROLES_MAPPING_TABLE_NAME;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.PATH_TO_LIST_ALL_ROLES;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;

import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

@Tag("integration")
@Tag("slow")
@Testcontainers
class ListAllRolesIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException {
        initialize(EXASOL, "LIST_ALL_ROLES", PATH_TO_LIST_ALL_ROLES);
    }

    // [itest -> dsn~listing-all-roles~0]
    @Test
    void testListAllRoles() {
        try {
            schema.createTable(EXA_ROLES_MAPPING_TABLE_NAME, "ROLE_NAME", "VARCHAR(128)", "ROLE_ID", "DECIMAL(2,0)") //
                    .insert("Sales", 1) //
                    .insert("Development", 2) //
                    .insert("Finance", 3);
            assertThat(script.executeQuery(), contains(contains("Sales", (short) 1), contains("Development", (short) 2),
                    contains("Finance", (short) 3)));
        } finally {
            schema.drop();
        }
    }
}