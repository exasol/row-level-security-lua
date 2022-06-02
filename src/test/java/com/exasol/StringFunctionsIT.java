package com.exasol;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import org.hamcrest.Matchers;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.testcontainers.junit.jupiter.Testcontainers;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.Matchers.anything;

@Testcontainers
class StringFunctionsIT extends AbstractLuaVirtualSchemaIT {
    @CsvSource({ //
            "ASCII, X, 88", //
            "BIT_LENGTH, bits, 32", //
            "CHR, 88, X", //
            "DUMP, foobar, 'Len=6 CharacterSet=UTF8: 102,111,111,98,97,114'", //
            "INITCAP, breaking news: water still wet, Breaking News: Water Still Wet", //
            "COLOGNE_PHONETIC, Schmitt, 862", //
            "LENGTH, letters, 7", //
            "LOWER, TEXT, text", //
            "REVERSE, abc, cba", //
            "TRIM, ' spaces ', 'spaces'", //
            "UPPER, text, TEXT"
    })
    @ParameterizedTest
    void testStringFunctionsWithSingleParameter(final String function, final String original, final String expected) {
        final Schema sourceSchema = createSchema("FUNCTION_" + function + "_SCHEMA");
        sourceSchema.createTable("T", "C", "VARCHAR(50)").insert(original);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("FUNCTION_" + function + "_USER", virtualSchema);
        final String select = "SELECT " + function + "(C) FROM " + getVirtualSchemaName(sourceSchema) + ".T";
        assertRlsQueryWithUser(select, user, table().row(expected).matches(NO_JAVA_TYPE_CHECK));
        final String explain = "EXPLAIN VIRTUAL " + select;
        assertRlsQueryWithUser(explain, user, table().row(anything(),
                Matchers.containsString(function + "(\"T\".\"C\")"), anything(), anything()).matches());
    }
}