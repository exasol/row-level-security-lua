package com.exasol.rls.administration;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.SQLException;

import static com.exasol.rls.administration.TestsConstants.EXA_ROLES_MAPPING_TABLE_NAME;
import static com.exasol.rls.administration.TestsConstants.PATH_TO_LIST_ALL_ROLES;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;

@Tag("integration")
@Tag("slow")
@Testcontainers
class ListAllRolesIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException {
        initialize(EXASOL, "LIST_ALL_ROLES", PATH_TO_LIST_ALL_ROLES);
    }

    @Override
    protected Connection getConnection() throws NoDriverFoundException, SQLException {
        return EXASOL.createConnection("");
    }

    // [itest->dsn~listing-all-roles~1]
    @Test
    void testListAllRoles() {
        try {
            schema.createTable(
                    EXA_ROLES_MAPPING_TABLE_NAME, "ROLE_NAME", "VARCHAR(128)", "ROLE_ID", "DECIMAL(2,0)") //
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