package com.exasol.rls.administration;

import static com.exasol.RlsTestConstants.USERS_TABLE;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.*;
import static com.exasol.rls.administration.BitField64.bitsToLong;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

@Tag("integration")
@Tag("slow")
@Testcontainers
class ListUsersAndRolesIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "LIST_USERS_AND_ROLES", PATH_TO_LIST_USERS_AND_ROLES, PATH_TO_BIT_POSITIONS);
        schema.createTable(EXA_ROLES_MAPPING_TABLE_NAME, "ROLE_NAME", "VARCHAR(128)", "ROLE_ID", "DECIMAL(2,0)") //
                .insert("ROLE_1", 1) //
                .insert("ROLE_2", 2) //
                .insert("ROLE_53", 53) //
                .insert("ROLE_63", 63);
    }

    // [itest->dsn~listing-users-and-roles~1]
    @Test
    void testListRlsUsersWithRoles() {
        schema.createTable(USERS_TABLE, "EXA_USER_NAME", "VARCHAR(128)", "EXA_ROLE_MASK", "DECIMAL(20,0)") //
                .insert("RLS_USR_1", bitsToLong(0)) //
                .insert("RLS_USR_2", bitsToLong(0, 1)) //
                .insert("RLS_USR_3", bitsToLong(52, 62)) //
                .insert("RLE_USR_4", 0) //
                .insert("RLS_USR_5", bitsToLong(2)) //
                .insert("RLS_USR_6", bitsToLong(0, 1, 2, 3, 62));
        assertThat(script.executeQuery(), //
                contains( //
                        contains("RLS_USR_1", "ROLE_1"), //
                        contains("RLS_USR_2", "ROLE_1"), //
                        contains("RLS_USR_2", "ROLE_2"), //
                        contains("RLS_USR_3", "ROLE_53"), //
                        contains("RLS_USR_3", "ROLE_63"), //
                        contains("RLS_USR_5", "<has unmapped role(s)>"), //
                        contains("RLS_USR_6", "<has unmapped role(s)>"), //
                        contains("RLS_USR_6", "ROLE_1"), //
                        contains("RLS_USR_6", "ROLE_2"), //
                        contains("RLS_USR_6", "ROLE_63")));
    }
}