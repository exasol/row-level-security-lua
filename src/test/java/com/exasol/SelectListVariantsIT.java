package com.exasol;

import static com.exasol.dbbuilder.ObjectPrivilege.SELECT;
import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;

@Testcontainers
class SelectListVariantsIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testSelectStar() throws IOException, SQLException {
        final String sourceSchemaName = "SELECT_STAR_SCHEMA";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("SELECT_STAR_USER").grant(virtualSchema, SELECT);
        assertThat(executeRlsQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row(true).row(false).matches());
    }

    @Test
    void testSelectStarOnProtectedTable() throws IOException, SQLException {
        final String sourceSchemaName = "SELECT_STAR_PROTECTED_SCHEMA";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN", "EXA_ROW_TENANT", "VARCHAR(128)") //
                .insert(true, "SELECT_STAR_PROTECTED_USER") //
                .insert(false, "NOONE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("SELECT_STAR_PROTECTED_USER").grant(virtualSchema, SELECT);
        assertThat(executeRlsQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row(true).matches());
    }

    // Too understand, why this test is necessary, you need to realize that constant expressions are evaluated by the
    // core database before the push-down.
    // This means that in the case below you actually get a push-down query with an empty select list, that the adapter
    // internally needs to fill with a dummy expression that only serves the purpose of providing the right number of
    // rows in the result set.
    @Test
    void testEmptySelectList() throws IOException, SQLException {
        final String sourceSchemaName = "EMPTY_SELECT_SCHEMA";
        final Schema sourceSchema = factory.createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("EMPTY_SELECT_USER").grant(virtualSchema, SELECT);
        assertThat(executeRlsQueryWithUser("SELECT 'foo' FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row("foo").row("foo").matches());
    }

}