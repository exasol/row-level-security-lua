# Row Level Security Tutorial

Please follow the [Java-based RLS tutorial](https://github.com/exasol/row-level-security/blob/main/doc/user_guide/tutorial.md) till the `Protecting the Data with RLS` section and then return back here.

## Protecting the Data with RLS

### Creating the RLS Virtual Schema

Lua row-level security is a Lua implementation of [Virtual Schemas](https://docs.exasol.com/database_concepts/virtual_schemas.htm). If you know how views work, then consider Virtual Schemas a closely related concept.

A Virtual Schema is a projection of an underlying concrete schema. In the case of RLS, it adds a filter layer that makes sure that users only see what they are supposed to.

Execute the following SQL statements as user `SYS`.

```sql
CREATE SCHEMA RLS_VSADAPTER_SCHEMA;

CREATE OR REPLACE LUA ADAPTER SCRIPT RLS_VSADAPTER_SCHEMA.RLS_VSADAPTER AS
    <lua module loading preamble here>
    
    <lua script here>
/
;
```

Check the [user guide (section "Creating Virtual Schema Adapter Script")](user_guide.md#creating-virtual-schema-adapter-script) for more details.

```sql
CREATE VIRTUAL SCHEMA RLS_CHICAGO_TAXI_VS 
USING RLS_VSADAPTER_SCHEMA.RLS_VSADAPTER 
WITH
SCHEMA_NAME = 'CHICAGO_TAXI';
```

### Creating a User Account

The next step is to create a user account that you will need in order to see the effect RLS has.

One of the taxi companies is called "6743 - Luhak Corp" and the corresponding entry in the `EXA_ROW_TENANT` column is `LUHAK_CORP`.

So please create a user account with that name, allow it to log in and grant the `SELECT` privilege on the RLS Virtual Schema.

```sql
CREATE USER LUHAK_CORP IDENTIFIED BY "<password>";
GRANT CREATE SESSION TO LUHAK_CORP;
GRANT SELECT ON RLS_CHICAGO_TAXI_VS TO LUHAK_CORP;
```

### Querying the Data as Non-privileged User

Now is the moment of truth. You are going to impersonate a taxi company and verify that we only see entries that this company should be able to see.

Log in first with the owner account `BACP` and run this query:

```sql
SELECT COMPANY, COUNT(1)
FROM CHICAGO_TAXI.TRIPS
GROUP BY COMPANY
ORDER BY COMPANY;
```

Now login as `LUHAK_CORP` and run this query for comparison:

```sql
SELECT COMPANY, COUNT(1)
FROM RLS_CHICAGO_TAXI_VS.TRIPS
GROUP BY COMPANY
ORDER BY COMPANY;
```

In the second case you only see the number of trips that Luhak Corp made &mdash; and there are no other companies listed.

## Profiling

If you are curious about how queries using RLS perform, you can use [Exasol's profiling feature](https://docs.exasol.com/administration/on-premise/support/profiling_information.htm).

Run the following example as user `LUHAK_CORP`. It demonstrates how Exasol executes a query that joins the large fact table and a dimension table. There is a narrow filter on the fact table and we want to see that this filter is applied _before_ the join.

Otherwise, an unnecessarily large amount of data would go into the join.

First, switch profiling on, then run the query. Immediately afterwards, deactivate profiling to avoid flooding the log.

```sql
ALTER SESSION SET PROFILE = 'on';

SELECT *
FROM RLS_CHICAGO_TAXI_VS.TRIPS
LEFT JOIN RLS_CHICAGO_TAXI_VS.COMMUNITY_AREAS ON TRIPS.PICKUP_COMMUNITY_AREA=COMMUNITY_AREAS.AREA_NUMBER
WHERE RLS_CHICAGO_TAXI_VS.TRIPS.TRIP_SECONDS < 400;

ALTER SESSION SET PROFILE = 'off';

FLUSH STATISTICS;
```

Now let's take a look at the profiling data we collected

```sql
SELECT STMT_ID, COMMAND_NAME AS COMMAND, PART_NAME, PART_INFO,
    OBJECT_SCHEMA, OBJECT_NAME, OBJECT_ROWS AS OBJ_ROWS, OUT_ROWS, DURATION 
FROM EXA_STATISTICS.EXA_USER_PROFILE_LAST_DAY
WHERE SESSION_ID = CURRENT_SESSION
ORDER BY STMT_ID, PART_ID;
```

Your result should look similar to this:

|STMT_ID|COMMAND|PART_NAME|PART_INFO|OBJECT_SCHEMA|OBJECT_NAME|OBJ_ROWS|OUT_ROWS|DURATION|
|-------|-------|---------|---------|-------------|-----------|--------|--------|--------|
|54|SELECT|COMPILE / EXECUTE| | | | | |0.018|
|54|SELECT|PUSHDOWN| | | | | |0.004|
|54|SELECT|PUSHDOWN| | | | | |0.093|
|54|SELECT|INDEX CREATE| |CHICAGO_TAXI|COMMUNITY_AREAS|77|77|0.003|
|54|SELECT|INDEX CREATE|on REPLICATED table|CHICAGO_TAXI|COMMUNITY_AREAS|77|77|0.001|
|54|SELECT|SCAN| |CHICAGO_TAXI|TRIPS|1000000|124|0.022|
|54|SELECT|OUTER JOIN|on REPLICATED table|CHICAGO_TAXI|COMMUNITY_AREAS|77|124|0.000|
|54|SELECT|INSERT|on TEMPORARY table| |tmp_subselect0|0|124|0.036|
|55|COMMIT|COMMIT| | | | | |0.036|

The important part to realize here is that the `SCAN` happens _before_ the `OUTER JOIN`. And you should also notice that the number of rows going into the scan is a lot more than the result rows of the scan.

## Conclusion

In this tutorial we went through a real-world example where you learned how to securely set up an RLS-protected Virtual Schema in order to restrict what users are allowed to see.

You created a staging area and populated that with publicly available data by pointing the EXALoader to a public API and running an import.

You created a view in the staging area to fix a timestamp format and then imported the data into a production area. There you experienced the effect of RLS and profiled a query using built-in capabilities of the Exasol analytical platform.

Congratulations, you are now ready and able to protect your own data with RLS.
