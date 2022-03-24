package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local mockagne = require("mockagne")
local MetadataReader = require("exasolrls.MetadataReader")

local CATALOG_QUERY <const> = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE '
        .. '"TABLE_SCHEMA" = :s'
local DESCRIBE_TABLE_QUERY <const> = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE"'
        .. ' FROM "SYS"."EXA_ALL_COLUMNS" WHERE "COLUMN_SCHEMA" = :s AND "COLUMN_TABLE" = :t'

describe("Metadata reader", function()
    local exa_mock
    local reader

    before_each(function()
        exa_mock = mockagne.getMock()
        reader = MetadataReader:new(exa_mock)
    end)

    local function mock_describe_table(schema_id, table_id, columns)
        mockagne.when(exa_mock.pquery_no_preprocessing(DESCRIBE_TABLE_QUERY, {s = schema_id, t = table_id}))
                .thenAnswer(true, columns)
    end

    local function mock_read_table_catalog(schema_id, tables)
        mockagne.when(exa_mock.pquery_no_preprocessing(CATALOG_QUERY, {s = schema_id}))
                .thenAnswer(true, tables)
    end

    --- Mock queries used to retrieve the metadata of tables.
    -- </p>
    -- The table definitions used in this method have the following form:
    -- </p>
    -- <pre><code>
    -- {{table = "T1", columns= {<column-query-mock-response>}}, ...}
    -- </code></pre>
    -- <p>
    -- Table metadata query mocks and the corresponding column metadata query mocks are guaranteed to be configured in
    -- the same order as in the table definition list.
    -- </p>
    -- @param schema_id string name of the schema
    -- @param ... any list of table definitions.
    local function mock_tables(schema_id, ...)
        local tables = {}
        local i = 1
        for _, table_definition in ipairs({...}) do
            local table_id = table_definition.table
            tables[i] = {TABLE_NAME = table_id}
            mock_describe_table(schema_id, table_id, table_definition.columns)
            i = i + 1
        end
        mock_read_table_catalog(schema_id, tables)
    end

    it("hides control tables", function()
        mock_tables("S",
                {
                    table = "T2",
                    columns = {{COLUMN_NAME = "C2", COLUMN_TYPE = "DATE"}}
                },
                {
                    table = "EXA_RLS_USERS"
                },
                {
                    table = "EXA_ROLE_MAPPING"
                }
        )
        assert.are.same(
                {
                    tables = {
                        {
                            name = "T2",
                            columns = {{name = "C2", dataType = {type = "DATE"}}}
                        }
                    },
                    adapterNotes = "T2:---"
                },
                reader:read("S")
        )
    end)

    it("hides control columns", function()
        mock_tables("S",
                {
                    table = "T3",
                    columns = {
                        {COLUMN_NAME = "C3_1", COLUMN_TYPE = "BOOLEAN"},
                        {COLUMN_NAME = "EXA_ROW_TENANT"},
                        {COLUMN_NAME = "EXA_ROW_ROLES"}
                    }
                },
                {
                    table = "T4",
                    columns = {
                        {COLUMN_NAME = "C4_1", COLUMN_TYPE = "DATE"},
                        {COLUMN_NAME = "EXA_ROW_GROUP"}
                    }
                }
        )
        assert.are.same(
                {
                    tables = {
                        {
                            name = "T3",
                            columns = {{name = "C3_1", dataType = {type = "BOOLEAN"}}}
                        },
                        {
                            name = "T4",
                            columns = {{name = "C4_1", dataType = {type = "DATE"}}}
                        }
                    },
                    adapterNotes = "T3:tr-,T4:--g"
                },
                reader:read("S")
        )
    end)

    local function mock_table_with_single_column_of_type(type)
        mock_tables("S",
                {
                    table = "T",
                    columns = {{COLUMN_NAME = "C1", COLUMN_TYPE = type}}
                }
        )
    end

    local function assert_column_type_translation(translation)
        assert.are.same({tables = {{name = "T", columns = {{name = "C1", dataType = translation}}}},
                         adapterNotes = "T:---"}, reader:read("S"))
    end

    describe("translates column type:", function()
        local parameters = {
            {"BOOLEAN", {type = "BOOLEAN"}},
            {"DATE", {type = "DATE"}},
            {"DECIMAL(13,8)", {type = "DECIMAL", precision = 13, scale = 8}},
            {"DOUBLE PRECISION", {type = "DOUBLE PRECISION"}},
            {"CHAR(130) UTF8", {type = "CHAR", characterSet = "UTF8", size = 130}},
            {"CHAR(2000000) ASCII", {type = "CHAR", characterSet = "ASCII", size = 2000000}},
            {"VARCHAR(70) UTF8", {type = "VARCHAR", characterSet = "UTF8", size = 70}},
            {"VARCHAR(2000000) ASCII", {type = "VARCHAR", characterSet = "ASCII", size = 2000000}},
            {"HASHTYPE(5 BYTE)", {type = "HASHTYPE", bytesize = 5}},
            {"TIMESTAMP", {type = "TIMESTAMP"}},
            {"GEOMETRY(4)", {type = "GEOMETRY", srid = 4}},
            {"INTERVAL YEAR(6) TO MONTH", {type = "INTERVAL", fromTo = "YEAR TO MONTH", precision = 6}},
            {"INTERVAL DAY(9) TO SECOND(5)", {type = "INTERVAL", fromTo = "DAY TO SECONDS",
                                              precision = 9, fraction = 5}},
            {"TIMESTAMP WITH LOCAL TIME ZONE", {type = "TIMESTAMP", withLocalTimeZone = true}},
            {"GEOMETRY", {type = "GEOMETRY", srid = 0}}
        }
        for _, parameter in ipairs(parameters) do
            local sql, expected = table.unpack(parameter)
            it(sql, function()
                mock_table_with_single_column_of_type(sql)
                assert_column_type_translation(expected)
            end)
        end
    end)

    it("can filter the tables it reads the metadata of", function()
        mock_tables("S",
                {table = "T1", columns = {{COLUMN_NAME = "C1_1", COLUMN_TYPE = "BOOLEAN"}}},
                {table = "T2", columns = {{COLUMN_NAME = "C2_1", COLUMN_TYPE = "BOOLEAN"}}},
                {table = "T3", columns = {{COLUMN_NAME = "C3_1", COLUMN_TYPE = "BOOLEAN"}}},
                {table = "T4", columns = {{COLUMN_NAME = "C4_1", COLUMN_TYPE = "BOOLEAN"}}})
        assert.are.same(
                {tables = {
                    {name = "T2", columns = {{name = "C2_1", dataType = {type = "BOOLEAN"}}}},
                    {name = "T3", columns = {{name = "C3_1", dataType = {type = "BOOLEAN"}}}}
                },
                 adapterNotes = "T2:---,T3:---"
                },
                reader:read("S", {"T2", "T3"}))
    end)

    local function mock_schema_metadata_reading_error(schema_id, error_message)
        mockagne.when(exa_mock.pquery_no_preprocessing(CATALOG_QUERY, {s = schema_id}))
                .thenAnswer(false, {error_message = error_message})
    end

    it("raises an error if it can't read the table metadata", function()
        mock_schema_metadata_reading_error("the_schema", "the_cause")
        assert.error_matches(function()
            reader:read("the_schema")
        end,
                "Unable to read table metadata from source schema 'the_schema'. Caused by: 'the_cause'", 1, true)
    end)

    local function mock_table_metadata_reading_error(schema_id, table_id, error_message)
        mockagne.when(exa_mock.pquery_no_preprocessing(DESCRIBE_TABLE_QUERY, {s = schema_id, t = table_id}))
                .thenAnswer(false, {error_message = error_message})
    end

    it("raises an error if it can't read the column metadata", function()
        local schema_id = "S"
        mock_table_metadata_reading_error(schema_id, "T", "another_cause")
        mock_read_table_catalog(schema_id, {{TABLE_NAME = "T"}})
        assert.error_matches(function()
            reader:read("S")
        end,
                "Unable to read column metadata from source table '" .. schema_id
                        .. "'.'T'. Caused by: 'another_cause'", 1, true)
    end)

    it("raises an error if the column data type is not supported ", function()
        local schema_id = "THE_SCHEMA"
        mock_tables(schema_id,
                {table = "THE_TABLE", columns = {{COLUMN_NAME = "THE_COLUMN", COLUMN_TYPE = "THE_TYPE"}}}
        )
        assert.error_matches(function()
            reader:read(schema_id)
        end,
                "Column 'THE_TABLE'.'THE_COLUMN' has unsupported type 'THE_TYPE'", 1, true)
    end)
end)