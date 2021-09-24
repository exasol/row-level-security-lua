# row-level-security-lua 0.5.0, released 2021-09-24

Code name: Schema refresh, scalar functions, exclude capabilities and default SRID

## Summary

Version 0.5.0 of `row-level-security` adds support for `GEOMETRY` columns without explicit SRID.

Lua Row Level Security (RLS) now supports `ALTER VIRTUAL SCHEMA ... REFRESH` to update the metadata of an existing virtual schema.

You can now prevent specific SQL constructs from being pushed down by using the `EXCLUDED_CAPABILITIES` property.

Since the adapter now reports the capabilities for all scalar functions, those functions can now be pushed down, resulting in better performance in many cases where scalar functions are used.

Also, we migrated the system requirement specification over from RLS Java and added a UML model that serves as design.

## Feature

* #47: Support `GEOMETRY` columns without explicit SRID.
* #68: Added option to exclude capabilities.
* #74: Users can now refresh the schema metadata with `ALTER VIRTUAL SCHEMA ... REFRESH`
* #84: Added scalar function capabilities

## Documentation

* #50: Clarified what to do with the Lua adapter after download from GitHub in the user guide.
* #79: Migrated requirements from RLS Java, added UML model as design.

## Dependency Updates

### Compile Dependency Updates

* Updated `com.exasol:maven-project-version-getter:0.1.0` to `1.0.0`

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.0` to `7.1.1`
* Updated `com.exasol:exasol-testcontainers:4.0.1` to `5.0.0`

### Plugin Dependency Updates

* Updated `org.apache.maven.plugins:maven-jar-plugin:2.4` to `3.2.0`
