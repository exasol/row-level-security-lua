package com.exasol;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import org.hamcrest.Matcher;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.ArrayList;
import java.util.List;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.Matchers.*;

// Note that the Exasol core only pushes a subset of all supported aggregate functions. The reason is that the query
// graph is evaluated and broken down first. Only the necessary resulting queries are pushed.
//
// Here is a list of functions that have no capabilities in the VS API:
//
// CORR, COVAR_*, GROUPING
//
@Testcontainers
class AggregateFunctionsIT extends AbstractLuaVirtualSchemaIT {
    @CsvSource({ //
            "ANY(C1), SOME(\"T\".\"C1\"), ANY_ALIAS_OF_SOME", //
            "APPROXIMATE_COUNT_DISTINCT(C1), APPROXIMATE_COUNT_DISTINCT(\"T\".\"C1\"), APPROXIMATE_COUNT_DISTINCT", //
            "AVG(C1), AVG(\"T\".\"C1\"), AVG", //
            "AVG(DISTINCT C1), AVG(DISTINCT \"T\".\"C1\"), AVG_DISTINCT", //
            "COUNT(*), COUNT(*), COUNT_STAR",//
            "COUNT(C1), COUNT(\"T\".\"C1\"), COUNT", //
            "'COUNT((C1, C2))', 'COUNT((\"T\".\"C1\", \"T\".\"C2\"))', COUNT_TUPLE", // Note the extra parenthesis!
            "COUNT(DISTINCT C1), COUNT(DISTINCT \"T\".\"C1\"), COUNT_DISTINCT", //
            "EVERY(C1), EVERY(\"T\".\"C1\"), EVERY", //
            "FIRST_VALUE(C1), FIRST_VALUE(\"T\".\"C1\"), FIRST_VALUE", //
            "LAST_VALUE(C1), LAST_VALUE(\"T\".\"C1\"), LAST_VALUE", //
            "MAX(C1), MAX(\"T\".\"C1\"), MAX", //
            "MEDIAN(C1), MEDIAN(\"T\".\"C1\"), MEDIAN", //
            "MIN(C1), MIN(\"T\".\"C1\"), MIN", //
            "MUL(C1), MUL(\"T\".\"C1\"), MUL", //
            "MUL(DISTINCT C1), MUL(DISTINCT \"T\".\"C1\"), MUL_DISTINCT", //
            "SOME(C1), SOME(\"T\".\"C1\"), SOME", //
            "STDDEV(C1), STDDEV(\"T\".\"C1\"), STDDEV", //
            "STDDEV(DISTINCT C1), STDDEV(DISTINCT \"T\".\"C1\"), STDDEV_DISTINCT", //
            "STDDEV_POP(C1), STDDEV_POP(\"T\".\"C1\"), STDDEV_POP", //
            "STDDEV_POP(DISTINCT C1), STDDEV_POP(DISTINCT \"T\".\"C1\"), STDDEV_POP_DISTINCT", //
            "STDDEV_SAMP(C1), STDDEV_SAMP(\"T\".\"C1\", STDDEV_SAMP", //
            "STDDEV_SAMP(DISTINCT C1), STDDEV_SAMP(DISTINCT \"T\".\"C1\"), STDDEV_SAMP_DISTINCT", //
            "SUM(C1), SUM(\"T\".\"C1\"), SUM", //
            "SUM(DISTINCT C1), SUM(DISTINCT \"T\".\"C1\"), SUM_DISTINCT", //
            "VARIANCE(C1), VARIANCE(\"T\".\"C1\"), VARIANCE", //
            "VARIANCE(DISTINCT C1), VARIANCE(DISTINCT \"T\".\"C1\"), VARIANCE_DISTINCT", //
            "VAR_POP(C1), VAR_POP(\"T\".\"C1\"), VAR_POP", //
            "VAR_POP(DISTINCT C1), VAR_POP(DISTINCT \"T\".\"C1\"), VAR_POP_DISTINCT", //
            "VAR_SAMP(C1), VAR_SAMP(\"T\".\"C1\"), VAR_SAMP", //
            "VAR_SAMP(DISTINCT C1), VAR_SAMP(DISTINCT \"T\".\"C1\"), VAR_SAMP_DISTINCT" //
    })
    @ParameterizedTest
    void testAggregateFunctionGetsPushedDown(final String inputFunction, final String expectedPushedFunction,
                                             final String testName) {
        final Schema sourceSchema = createSchema(testName + "_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER", "C2", "INTEGER")
                .insert(1, 1).insert(2, 2).insert(3, 4).insert(5, 8).insert(8, 16).insert(13, 32);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess(testName + "_USER", virtualSchema);
        assertPushDown("SELECT " + inputFunction + " FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                containsString(expectedPushedFunction));
    }

    @Test
    void testStIntersectionGetsPushedDown() {
        final Schema sourceSchema = createSchema("ST_INTERSECTION_SCHEMA");
        sourceSchema.createTable("T", "C1", "GEOMETRY")
                .insert("LINESTRING(0 0, 2 0)").insert("LINESTRING(1 0, 3 0)");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ST_INTERSECTION_USER", virtualSchema);
        assertPushDown("SELECT ST_INTERSECTION(C1) FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                containsString("ST_INTERSECTION(\"T\".\"C1\")"));
    }

    @Test
    void testStUnionGetsPushedDown() {
        final Schema sourceSchema = createSchema("ST_UNION_SCHEMA");
        sourceSchema.createTable("T", "C1", "GEOMETRY", "C2", "GEOMETRY")
                .insert("LINESTRING(0 0, 2 0)", "LINESTRING(1 0, 3 0)");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ST_UNION_USER", virtualSchema);
        assertPushDown("SELECT ST_UNION(C1) FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                containsString("ST_UNION(\"T\".\"C1\")"));
    }

    @Test
    void testListagg() {
        final Schema sourceSchema = createSchema("LISTAGG_SCHEMA");
        final Table sourceTable = sourceSchema.createTable("PEOPLE", "FIRSTNAME", "VARCHAR(50)", "LASTNAME",
                        "VARCHAR(50)") //
                .insert("Trisha", "McMillan") //
                .insert("Arthur", "Dent") //
                .insert("Zaphod", "Beeblebrox");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LISTAGG_USER", virtualSchema);
        final String sql = "SELECT LISTAGG(FIRSTNAME) FROM " + getVirtualSchemaName(sourceSchema) + ".PEOPLE";
        assertPushDown(sql, user, equalTo("SELECT LISTAGG(\"PEOPLE\".\"FIRSTNAME\" ON OVERFLOW ERROR) FROM "
                + sourceTable.getFullyQualifiedName()));
        assertRlsQueryWithUser(sql, user, table().row(matchesConcatenationInAnyOrder("Trisha", "Arthur", "Zaphod"))
                .matches());
    }

    private static Matcher<? super String> matchesConcatenationInAnyOrder(final String ... elements) {
        final List<Matcher<? super String>> subMatchers = new ArrayList<>(elements.length + 1);
        int totalLength = 0;
        for (final String element : elements) {
            subMatchers.add(containsString(element));
            totalLength += element.length();
        }
        subMatchers.add(hasLength(totalLength));
        return allOf(subMatchers);
    }


    @Test
    void testListaggWithOrder() {
        final Schema sourceSchema = createSchema("LISTAGG_WITH_ORDER_SCHEMA");
        final Table sourceTable = sourceSchema.createTable("PEOPLE", "FIRSTNAME", "VARCHAR(50)", "LASTNAME",
                        "VARCHAR(50)") //
                .insert("Trisha", "McMillan") //
                .insert("Arthur", "Dent") //
                .insert("Zaphod", "Beeblebrox");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LISTAGG_WITH_ORDER_USER", virtualSchema);
        final String sql = "SELECT LISTAGG(FIRSTNAME, ', ' ON OVERFLOW TRUNCATE ', .etc' WITH COUNT) WITHIN GROUP"
                + " (ORDER BY LASTNAME) FROM " + getVirtualSchemaName(sourceSchema) + ".PEOPLE";
        assertPushDown(sql, user,equalTo("SELECT LISTAGG(\"PEOPLE\".\"FIRSTNAME\", ', ' ON OVERFLOW TRUNCATE ', .etc'"
                + " WITH COUNT) WITHIN GROUP (ORDER BY \"PEOPLE\".\"LASTNAME\" ASC NULLS LAST) FROM "
                + sourceTable.getFullyQualifiedName()));
        assertRlsQueryWithUser(sql, user, table().row("Zaphod, Arthur, Trisha").matches());
    }
}