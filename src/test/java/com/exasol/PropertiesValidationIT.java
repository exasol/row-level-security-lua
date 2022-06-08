package com.exasol;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.util.Map;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.exasol.AdapterScript;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class PropertiesValidationIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testCreateVirtualSchemaWithMissingSchemaName() throws IOException {
        final String virtualSchemaName = "VIRTUAL_SCHEMA_FOR_MISSING_SCHEMA_PROPERTY";
        final AdapterScript adapter = createAdapterScript("SCHEMA_FOR_MISSING_SCHEMA_PROPERTY");
        final VirtualSchema.Builder virtualSchemaBuilder = factory.createVirtualSchemaBuilder(virtualSchemaName) //
                .adapterScript(adapter) //
                .properties(addDebugProperties(Map.of()));
        final Exception exception = assertThrows(Exception.class, () -> virtualSchemaBuilder.build());
        assertThat(exception.getCause().getMessage(), containsString("Missing mandatory property 'SCHEMA_NAME'"));
    }
}