package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class ScalarFunctionsIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testIproc() {
        final Schema sourceSchema = createSchema("IPROC_SCHEMA");
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("IPROC_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT IPROC() FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                table().row(0).row(0).matches(NO_JAVA_TYPE_CHECK));
    }

    @CsvSource({ //
            "+, PLUS, 20, 4, 24", //
            "-, MINUS, 20, 4, 16", //
            "*, MULTIPLIED, 20, 4, 80", //
            "/, DIVIDED, 20, 4, 5" //
    })
    @ParameterizedTest
    void testBinaryArithmeticOperator(final String operator, final String testName, final int left, final int right,
            final int expected) {
        final Schema sourceSchema = createSchema(testName + "_SCHEMA");
        sourceSchema.createTable("T", "C1", "Decimal", "C2", "Decimal").insert(left, right);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess(testName + "_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT C1 " + operator + " C2 FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                table().row(expected).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testUnaryArithmeticMinus() {
        final Schema sourceSchema = createSchema("UNARY_MINUS_SCHEMA");
        sourceSchema.createTable("T", "C1", "Decimal").insert(16);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("UNARY_MINUS_USER", virtualSchema);
        assertRlsQueryWithUser("SELECT -C1 FROM " + getVirtualSchemaName(sourceSchema) + ".T", user,
                table().row(-16).matches(NO_JAVA_TYPE_CHECK));
    }
}