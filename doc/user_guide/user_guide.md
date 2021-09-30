# Row Level Security

Row-Level Security (short "RLS") is a security mechanism based on Exasol's Virtual Schemas. It allows database administrators to control access to a table's row depending on a user's roles, group membership or username.

RLS only supports Exasol databases. That means you cannot use RLS between Exasol and a 3rd-party data source.

The RLS installation package contains everything you need to extend an existing Exasol installation with Row-Level Security.

## Introduction

### Row-Level Security Works on a Per-Schema Level

As mentioned before, RLS is a specialized Lua implementation of a [Virtual Schema](https://docs.exasol.com/database_concepts/virtual_schemas.htm). As the name suggests a database schema is the scope that can be protected. That means if you want to protect multiple schemas, you need to configure multiple RLS Virtual Schemas on top of them.

### RLS Variants

RLS comes in three flavors which can also be used in combination:

1. Role-based security
1. Tenant-based security
1. Group-based security

Additionally, use can combine the flavours:

1. Combine group and tenant
1. Combine group and role

The main difference between the three variants is the use case behind them.

In a *role-based* scenario you want multiple people to be able to access the same rows &mdash; based on roles that are assigned to those users. The number of roles in this scenario is small.

Note that when we talk about "roles" in this document, we mean RLS roles, not database roles. [Database roles](https://docs.exasol.com/sql/create_role.htm) are a completely disparate concept. While database roles control permissions on database objects like tables, they must be managed by a database administrator. RLS roles on the other hand are on a higher level and can be managed without database administrator privileges by the owner of the schema that needs to be protected.

This is an important distinction since it allows for separation of concerns. Database administrators are in this scenario responsible for the security of the database as a whole. Schema owners get to decide who sees what in their schema.

*Tenant* security on the other hand assumes that data belongs to a tenant and that other tenants are not allowed to see that data.

*Group-based* also allows multiple users to access one row. Users can be members of multiple groups, but each row can belong to only one group.

All the flavors also allow data to be marked *public*. As the name suggests, this data is accessible for all users, independently of roles, groups or whether they own the data.

### Protection Scopes of RLS

First, the regular protection mechanisms of Exasol apply. You can for example control who has access to the Virtual Schema that provides RLS. RLS is an additional mechanism on top of that which offers finer control for data visibility.

RLS protects individual rows inside selected tables. Tables inside an Exasol RLS Virtual Schema can either be RLS-protected or public. In a public table all users who can access the Virtual Schema can see the data inside the table.

On the lowest level RLS protects data per row (aka. dataset). To determine whether a user is allowed to read a row, RLS checks the existence and contents of special system columns in that table. In the following section we discuss the details.

## Administering Row Protection

In this section we will go through the administrative steps required to prepare a schema and its tables so that you can then protect it by an RLS Virtual Schema.

As an example we are going to create a small set of tables and contents in a schema called `SIMPLE_SALES`.

### Installing the Administration Scripts

RLS provides functions that make administration of RLS more user-friendly.

**Important:** all the scripts must be created in the same schema as the tables that you plan to protect with row-level-security.

To install the administration scripts, run the SQL batch file `administration-sql-scripts-<last-version>.sql`.

### Role-based security

Role-based security is a way to secure a table by assigning one or more roles to each user and specifying the roles which are allowed to see a row for each row in the table.

#### Roles

A role in the real world is a responsibility that comes with certain privileges. In a soccer team for example you have the role of a goal keeper, defenders or a coach. All have different responsibilities and different things they are allowed to do. The goal keeper for example is the only player in the game allowed to touch the ball with the hands.

Don't confuse roles with groups. In our example the football team would be a group. We will talk about [groups in a later section](#group-based-security).

RLS supports up to 63 general-purpose roles. Those can be freely named by you.

You assign roles to users and data rows and RLS matches the assigned roles to determine if a user is allowed to access a row or not.

There is one additional reserved role that always exists. The *public role*. If you assign this role to a row in RLS, every user with access to the schema can see this row, independently of that user's own roles. So even if a user has no roles assigned at all, that user can still see all rows that have the public role set.

Note also that if a row has the public role set, other roles have no effect on that row. After all it can't be more accessible than being public.

Assigning the public role to a user has no effect since implicitly all users have that role anyway.

### Role Masks

For performance reasons, RLS internally translates assigned roles into bit masks. Both for roles assigned to users and to rows.

The function `ROLE_MASK` returns the bit mask for an individual role ID.

#### Creating Roles

Create user roles using `ADD_RLS_ROLE(role_name, role_id)` script.

`role_name` is a unique role name. The check for an existing role is **case-insensitive** that means you can't have roles `sales` and `Sales` at the same time.
`role_id` is a unique role id. It can be in range from 1 to 63.

Examples:

```sql
EXECUTE SCRIPT ADD_RLS_ROLE('Sales', 1);
EXECUTE SCRIPT ADD_RLS_ROLE('Development', 2);
EXECUTE SCRIPT ADD_RLS_ROLE('Finance', 3);
```

#### Listing Roles

The following statement shows a list of existing roles and their IDs.

```sql
EXECUTE SCRIPT LIST_ALL_ROLES();
```

#### Assigning Roles to Users

Assign roles to users using `ASSIGN_ROLES_TO_USER(user_name, array roles)` script.

`user_name` is a name of user created inside Exasol database.
`roles` is an array of existing roles to assign. This parameter is **case-sensitive**.

Examples:

```sql
EXECUTE SCRIPT ASSIGN_ROLES_TO_USER('RLS_USR_1', ARRAY('Sales', 'Development'));
EXECUTE SCRIPT ASSIGN_ROLES_TO_USER('RLS_USR_2', ARRAY('Development'));
```

**Important:** if you assign roles to the same user several times, the script rewrites user roles each time using a new array. That means that at any time a user has the exact set of roles stated in the _last_ assignment command.

This script checks that the user name and the role names that are given are valid identifiers, to prevent SQL injection.

What it does not check is whether the user or roles exist. The reason is that this script is likely to be used in batch jobs and a check with every call would be too expensive.

If you try to assign a role that does not exist to a user, that non-existent role is ignored. That means that you could by accident assign too few roles, but never too many.

If you want to make sure check that the roles exist before calling this script.

#### Getting Users With Assigned Roles

The following statement shows a list of existing users and their roles:

```sql
EXECUTE SCRIPT LIST_USERS_AND_ROLES();
```

If you only want to see the list of all roles assigned to a single user, use the following statement:

```sql
EXECUTE SCRIPT LIST_USER_ROLES('RLS_USR_1');
```

#### Protecting a Table With Role-based RLS

In case you want to use role-based security, add a column called `EXA_ROW_ROLES DECIMAL(20,0)` to all the tables you want to protect.

For our example we will create very simple order item list as shown below.

```sql
CREATE OR REPLACE TABLE MY_SCHEMA.ORDER_ITEM 
(  
    ORDER_ID DECIMAL(18,0),  
    CUSTOMER VARCHAR(50),  
    PRODUCT VARCHAR(100),  
    QUANTITY DECIMAL(18,0),
    EXA_ROW_ROLES DECIMAL(20,0)  
);
```

Assigning the right role to a row requires calculating the role bit mask. Here is an example that shows how to calculate that mask from a list of role names.

```sql
SELECT SUM(DISTINCT ROLE_MASK(ROLE_ID)) FROM MY_SCHEMA.EXA_ROLES_MAPPING WHERE ROLE_NAME IN ('ACCOUNTING', 'HR', 'SALES');
```

What that code does is creating one individual bit mask per given role and then merging them into one &mdash; simply by summing them up.

**Important:** Role names are **case-sensitive**.

You can insert generated masks directly to the table:

```sql
INSERT INTO MY_SCHEMA.ORDER_ITEM VALUES
(1, 'John Smith', 'Pen', 3, 1),
(1, 'John Smith', 'Paper', 100, 3),
(1, 'John Smith', 'Eraser', 1, 7),
(2, 'Jane Doe', 'Pen', 2, 2),
(2, 'Jane Doe', 'Paper', 200, 1);
```

An example of updating the table using `ROLES_MASK` function:

```sql 
UPDATE ORDER_ITEM
SET EXA_ROW_ROLES = (SELECT MY_SCHEMA.ROLES_MASK(ROLE_ID) FROM MY_SCHEMA.EXA_ROLES_MAPPING WHERE ROLE_NAME IN ('Sales', 'Development'))
WHERE customer IN ('John Smith', 'Jane Doe');
```

`NULL` values in the `EXA_ROW_ROLES` column are treated like a role mask with all roles unset, making the row effectively inaccessible.

#### Making a Row in a Role-protected Table Public

You can make rows in a table protected with role-security public. For this you use the *reserved* public role. If a row has the public bit set, all other roles are irrelevant. The row is visible for everyone.

```sql
INSERT INTO MY_SCHEMA.ORDER_ITEM VALUES
(1, 'John Smith', 'Gold Bar', 3, 1),
(2, 'Jane Doe', 'Ruby', 10, 2),
(3, 'Joe Avarage', 'Six pack', 2, BIT_SET(0,63));
```

`BIT_SET(0,63)` is a shorter and more readable variant of saying `9223372036854775808` which is a 64 bit number with the highest bit set. Since bit positions are counted from 0, the highest bit position has the index 63. Exasol does not support hexadecimal literals, so you unfortunately can't express this as `0x8000` which would be even more compact.

If you want it to be even more readable and don't mind the extra work, you can also define the following SQL function:

```sql
CREATE OR REPLACE FUNCTION PUBLIC_ROLE_MASK() RETURN DECIMAL(20,0)
BEGIN
    return 9223372036854775808;
END
/
```

The `INSERT` command in the example above then reads:

```sql
INSERT INTO MY_SCHEMA.ORDER_ITEM VALUES
(1, 'John Smith', 'Gold Bar', 3, 1),
(2, 'Jane Doe', 'Ruby', 10, 2),
(3, 'Joe Avarage', 'Six pack', 2, PUBLIC_ROLE_MASK());
```

#### Deleting Roles

Delete roles using `DELETE_RLS_ROLE(role_name)` script. The script removes the role from all places where it is mentioned:

1. From the list of existing roles.
2. From users who have the role in the roles mask.
3. From all tables which are roles-secured.

`role_name` is a unique role name. This parameter is **case-insensitive**.

Example:

```sql 
EXECUTE SCRIPT DELETE_RLS_ROLE('Sales');
```

### Tenant-based security

Tenant-based security is a way to secure a table assigning each row to only one user.

If you want to use tenant security, you must add an additional column `EXA_ROW_TENANT VARCHAR(128)` to the tables you want to secure.

Example:

```sql
CREATE OR REPLACE TABLE MY_SCHEMA.ORDER_ITEM_WITH_TENANT 
(
    ORDER_ID DECIMAL(18,0),
    CUSTOMER VARCHAR(50),
    PRODUCT VARCHAR(100),
    QUANTITY DECIMAL(18,0),
    EXA_ROW_TENANT VARCHAR(128)
);
```

For each row define which tenant it belongs to. The tenant is identical to a username in Exasol.

`NULL` or an empty value in the `EXA_ROW_TENANT` column make the row inaccessible.

### Group-based security

If you apply group-based security, each row in a protected table can be associated with exactly one group. Users can be members of multiple groups though. This is very similar to the user group concept of a typical unix-style filesystem.

#### Creating and Deleting Groups

You don't need to explicitly create or delete a group. A group comes into existence when the first user is assigned to it and ceases to exist, when the last user is removed from it.

#### Adding a User to a Group

To add a user named `BOB` to the RLS group `COWORKERS`, run the following command:

```sql
EXECUTE SCRIPT ADD_USER_TO_GROUP('RLS_USR_1', ARRAY('COWORKERS'));
```

Thanks to the array, you can also add the same user to multiple groups at the same time.

```sql
EXECUTE SCRIPT ADD_USER_TO_GROUP('RLS_USR_1', ARRAY('COWORKERS', 'DEVELOPERS'));
```

#### Listing Groups

The following statement shows a list of groups and the number of their members:

```sql
EXECUTE SCRIPT LIST_ALL_GROUPS();
```

If you want to list the groups user called `ALICE` is a member of, type the following:

```sql
EXECUTE SCRIPT LIST_USER_GROUPS('RLS_USR_1');
```

#### Removing a User From a Group

To remove the user `BOB` from the RLS group `COWORKERS`) run:

```sql
EXECUTE SCRIPT REMOVE_USER_FROM_GROUP('RLS_USR_1', ARRAY('COWORKERS'));
```

#### Protecting a Table With Group-based RLS

In case you want to use group-based security, add a column called `EXA_ROW_GROUP VARCHAR(128)` to all the tables you want to protect.

For our example we will create very simple order item list as shown below.

```sql
CREATE OR REPLACE TABLE MY_SCHEMA.ORDER_ITEM_GROUP 
(  
    ORDER_ID DECIMAL(18,0),  
    CUSTOMER VARCHAR(50),  
    PRODUCT VARCHAR(100),  
    QUANTITY DECIMAL(18,0),
    EXA_ROW_GROUP VARCHAR(128)  
);
```

When inserting records into this table, provide the name of the group in the column `EXA_ROW_GROUP`.

`NULL` or blank values prohibit access to the row.

### Protection Scheme Combinations

In this section we discuss which combinations of protection schemes are supported and what their combined effects are. Combinations that are not listed are forbidden.

### Tenant- Plus Role-Security

If a table is protected with tenant- and role-security, a user must be the tenant or have the right role to access a row.

### Tenant- Plus Group-Security

In case you combine tenant- and group-security, a user must either be the tenant or be in the group stated in a row to access it.

## Creating a Virtual Schema

We prepared the schema and tables we want to protect with RLS in section ["Administering Row Protection"](#administering-row-protection). The next step is to create the RLS Virtual Schema. That Virtual Schema is the "portal" through which regular users access an RLS-protected schema.

### Installing RLS Virtual Schema Package

Download the latest available release from [Row Level Security (Lua)](https://github.com/exasol/row-level-security-lua/releases). In the next step you will copy the contents into the `CREATE LUA ADAPTER SCRIPT` command.

### Creating Virtual Schema Adapter Script

Create a schema or use an existing one to hold the adapter script.

```sql
CREATE SCHEMA RLS_SCHEMA;
```

Create a Lua adapter script:

```sql
CREATE OR REPLACE LUA ADAPTER SCRIPT RLS_SCHEMA.RLS_ADAPTER AS
    table.insert(package.searchers,
        function (module_name)
            local loader = package.preload[module_name]
            if(loader == nil) then
                error("Module " .. module_name .. " not found in package.preload.")
            else
                return loader
            end
        end
    )
    
    <copy the whole content of row-level-security-dist-<version>.lua here>
/
;
```
The first fixed part is a module loading preamble that is required with 7.1.0. Later versions will make this unnecessary, the user guide will be updated accordingly if an Exasol release is available that incorporates that module loading feature by default.
### Creating Virtual Schema

```sql
CREATE VIRTUAL SCHEMA RLS_VIRTUAL_SCHEMA
    USING RLS_SCHEMA.RLS_ADAPTER
    WITH
    SCHEMA_NAME     = '<schema name>'
```

### Granting Access to the Virtual Schema

Remember that RLS is an additional layer of access control _on top_ of the measures built into the core database. So in order to read columns in an RLS Virtual Schema, users first need to be allowed to access that schema.

A word or warning before you start granting permissions. Make sure you grant only access to the RLS Virtual Schema to regular users and _not to the orignial_ schema. Otherwise, those users can simply bypass RLS protection by going to the source.

Here is an example for allowing `SELECT` statements to a user.

```sql
GRANT SELECT ON SCHEMA <virtual schema name> TO <user>;
```

Please refer to the documentation of the [`GRANT`](https://docs.exasol.com/sql/grant.htm) statement for further details.

The minimum requirements for a regular user in order to be able to access the RLS are:

* User must exist (`CREATE USER`)
* User is allowed to create sessions (`GRANT CREATE SESSION`)
* User can execute `SELECT` statements on the Virtual Schema (`GRANT SELECT`)

### Adapter Capabilities

RLS is based on Exasol's Virtual Schema. Which constructs are pushed-down is decided by the optimizer based on the original query and on the capabilities reported by the Virtual Schema adapter (i.e. the software driving RLS).

RLS defines the following capabilities:

* `SELECTLIST_PROJECTION`
* `AGGREGATE_SINGLE_GROUP`
* `AGGREGATE_GROUP_BY_COLUMN`
* `AGGREGATE_GROUP_BY_TUPLE`
* `AGGREGATE_HAVING`
* `ORDER_BY_COLUMN`
* `LIMIT`
* `LIMIT_WITH_OFFSET`

Please note that excluded capabilities are not the only reason why a construct might not be pushed down. Given the nature of the queries pushed to RLS, the `LIMIT`-clause for example will rarely &mdash; if ever &mdash; be pushed down even though the adapter can handle that. RLS creates `SELECT` statements and not `IMPORT` statements.
The simple reason `LIMIT` not pushed is, that the optimizer decides it is more efficient in this particular case.

#### Excluding Capabilities

Sometimes you want to prevent constructs from being pushed down. In this case, you can tell the RLS adapter to exclude one or more capabilities from being reported to the core database.

The core database will then refrain from pushing down the related SQL constructs.

Just add the property `EXCLUDED_CAPABILITIES` to the Virtual Schema creation statement and provide a comma-separated list of capabilities you want to exclude.

```sql
CREATE VIRTUAL SCHEMA RLS_VIRTUAL_SCHEMA
    USING RLS_SCHEMA.RLS_ADAPTER
    WITH
    SCHEMA_NAME           = '<schema name>'
    EXCLUDED_CAPABILITIES = 'SELECTLIST_PROJECTION, ORDER_BY_COLUMN'
```

### Filtering Tables

Often you will not need or even want all of the tables in the source schema to be visible in the RLS-protected schema. In those cases you can simply specify an include list as a property when creating the RLS Virtual Schema.

Just provide a comma-separated list of table names in the property `TABLE_FILTER` and the scan of the source schema will skip all tables that are not listed. In a source schema with a large number of tables, this can also speed up the scan.

```sql
CREATE VIRTUAL SCHEMA RLS_VIRTUAL_SCHEMA
    USING RLS_SCHEMA.RLS_ADAPTER
    WITH
    SCHEMA_NAME  = '<schema name>'
    TABLE_FILTER = 'ORDERS, ORDER_ITEMS, PRODUCTS'
```

Spaces around the table names are ignored.

### Changing the Properties of an Existing Virtual Schema

While you could in theory drop and re-create an Virtual Schema, there is a more convenient way to apply changes in the adapter properties.

Use `ALTER VIRTUAL SCHEMA ... SET ...` to update the properties of an existing Virtual Schema.

Example:

```sql
ALTER VIRTUAL SCHEMA RLS_VIRTUAL_SCHEMA
SET SCHEMA_NAME = '<new schema name>'
```

You can for example change the `SCHEMA_NAME` property to point the Virtual Schema to a new source schema or the [table filter](#filtering-tables).

## Updating a Virtual Schema

All Virtual Schemas cache their metadata. That metadata for example contains all information about structure and data types of the underlying data source. RLS is a Virtual Schema and uses the same caching mechanism.

To let RLS know that something changed in the metadata, please use the [`ALTER VIRTUAL SCHEMA ... REFRESH`](https://docs.exasol.com/sql/alter_schema.htm) statement.

```
ALTER VIRTUAL SCHEMA <virtul schema name> REFRESH
```

Please note that this is also required if you change the special columns that control the RLS protection.

## Public Data

To recap: data in an RLS-protected schema is publicly readable if

* either the table does not use any of the RLS protection mechanisms
* or the table is protected with [role-based security](#role-based-security) and selected rows are assigned to the special "public role"

## Known Limitations

* `SELECT *` is not yet supported due to an issue between the core database and the LUA Virtual Schemas in push-down requests (SPOT-10626)
* RLS only works with Exasol as source and destination of the Virtual Schema.
* Source Schema and Virtual Schema must be on the same database.
* RLS Virtual Schema do not support JOIN capabilities.
