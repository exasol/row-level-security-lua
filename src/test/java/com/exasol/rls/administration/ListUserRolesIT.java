package com.exasol.rls.administration;

import static com.exasol.RlsTestConstants.USERS_TABLE;
import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.*;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.junit.jupiter.api.Assertions.assertAll;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

@Tag("integration")
@Tag("slow")
@Testcontainers
class ListUserRolesIT extends AbstractAdminScriptIT {
    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "LIST_USER_ROLES", PATH_TO_LIST_USER_ROLES, PATH_TO_BIT_POSITIONS);
        schema.createTable(EXA_ROLES_MAPPING_TABLE_NAME, "ROLE_NAME", "VARCHAR(128)", "ROLE_ID", "DECIMAL(2,0)") //
                .insert("ROLE_1", 1) //
                .insert("ROLE_2", 2) //
                .insert("ROLE_53", 53) //
                .insert("ROLE_63", 63);
    }

    // [itest->dsn~listing-user-roles~1]
    @Test
    void testListRlsSingleUser() {
        schema.createTable(USERS_TABLE, "EXA_USER_NAME", "VARCHAR(128)", "EXA_ROLE_MASK", "DECIMAL(20,0)") //
                .insert("RLS_USR_1", BitField64.bitsToLong(0)) //
                .insert("RLS_USR_2", BitField64.bitsToLong(0, 1)) //
                .insert("RLS_USR_3", BitField64.bitsToLong(52, 62)) //
                .insert("RLS_USR_4", 0) //
                .insert("RLS_USR_5", BitField64.bitsToLong(3)) //
                .insert("RLS_USR_6", BitField64.bitsToLong(0, 3, 62));

        assertAll( //
                () -> assertThat(script.executeQuery("RLS_USR_1"), //
                        contains(contains("RLS_USR_1", "ROLE_1"))), //
                () -> assertThat(script.executeQuery("RLS_USR_2"), //
                        contains( //
                                contains("RLS_USR_2", "ROLE_1"), //
                                contains("RLS_USR_2", "ROLE_2"))), //
                () -> assertThat(script.executeQuery("RLS_USR_3"), //
                        contains( //
                                contains("RLS_USR_3", "ROLE_53"), //
                                contains("RLS_USR_3", "ROLE_63"))), //
                () -> assertThat(script.executeQuery("RLS_USR_4"), empty()),
                () -> assertThat(script.executeQuery("RLS_USR_5"), //
                        contains(contains("RLS_USR_5", "<has unmapped role(s)>"))), //
                () -> assertThat(script.executeQuery("RLS_USR_6"), //
                        contains( //
                                contains("RLS_USR_6", "<has unmapped role(s)>"), //
                                contains("RLS_USR_6", "ROLE_1"), //
                                contains("RLS_USR_6", "ROLE_63"))));
    }
}