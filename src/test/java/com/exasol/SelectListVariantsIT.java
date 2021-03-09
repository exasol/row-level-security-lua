package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;

import java.io.IOException;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.ObjectPrivilege;
import com.exasol.dbbuilder.Schema;
import com.exasol.dbbuilder.User;
import com.exasol.dbbuilder.VirtualSchema;

@Testcontainers
class SelectListVariantsIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testSelectStar() throws IOException, SQLException {
        final String sourceSchemaName = "SELECT_STAR_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = factory.createLoginUser("SELECT_STAR_USER").grant(virtualSchema, ObjectPrivilege.SELECT);
        assertThat(executeRlsQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row(true).row(false).matches());
    }

    // This test case describes a situation where a push-down query request with an empty select list is received. This
    // might happen because the core database evaluates constant expressions before performing the push-down query to
    // the Virtual Schema. In such cases the adapter internally fills the select list with a dummy expression that only
    // serves the purpose of providing the right number of rows in the result set.
    @Test
    void testEmptySelectList() throws IOException, SQLException {
        final String sourceSchemaName = "EMPTY_SELECT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("EMPTY_SELECT_USER", virtualSchema);
        assertThat(executeRlsQueryWithUser("SELECT 'foo' FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user),
                table().row("foo").row("foo").matches());
    }
}