package com.exasol;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.AdapterScript;
import com.exasol.dbbuilder.VirtualSchema;

@Testcontainers
class PropertiesValidationIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testCreateVirtualSchemaWithMissingSchemaName() throws IOException {
        final String virtualSchemaName = "VIRTUAL_SCHEMA_FOR_MISSING_SCHEMA_PROPERTY";
        final AdapterScript adapter = createAdapterScript("SCHEMA_FOR_MISSING_SCHEMA_PROPERTY");
        final VirtualSchema.Builder virtualSchemaBuilder = factory.createVirtualSchemaBuilder(virtualSchemaName) //
                .adapterScript(adapter) //
                .properties(DEBUG_PROPERTIES);
        final Exception exception = assertThrows(Exception.class, () -> virtualSchemaBuilder.build());
        assertThat(exception.getCause().getMessage(), //
                equalTo("F-RLS-ADA-1: Missing mandatory property \"SCHEMA_NAME\". "
                        + "Please define the name of the source schema."));
    }
}
