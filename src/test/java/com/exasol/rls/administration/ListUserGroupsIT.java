package com.exasol.rls.administration;

import static com.exasol.rls.administration.AdministrationScriptsTestsConstants.EXA_GROUP_MEMBERS_TABLE_NAME;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Table;

@Tag("integration")
@Tag("slow")
@Testcontainers
class ListUserGroupsIT extends AbstractAdminScriptIT {
    private static Table memberTable;

    @BeforeAll
    static void beforeAll() throws SQLException, IOException {
        initialize(EXASOL, "LIST_USER_GROUPS", AdministrationScriptsTestsConstants.PATH_TO_LIST_USER_GROUPS);
        memberTable = schema.createTable(EXA_GROUP_MEMBERS_TABLE_NAME, "EXA_USER_NAME", "VARCHAR(128)", "EXA_GROUP",
                "VARCHAR(128)");
        memberTable.insert("KLAUS", "TENNIS_PLAYERS") //
                .insert("KLAUS", "SOCCER_PLAYERS") //
                .insert("VIVIANNE", "SOCCER_PLAYERS") //
                .insert("TAKESHI", "MARTIAL_ARTISTS");
    }

    // [itest -> dsn~listing-a-users-groups~0]
    @Test
    void testListRlsGroupsSingleUser() {
        assertThat(script.executeQuery("KLAUS"), contains(contains("SOCCER_PLAYERS"), contains("TENNIS_PLAYERS")));
    }
}