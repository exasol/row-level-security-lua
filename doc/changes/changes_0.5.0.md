# row-level-security-lua 0.5.0, released 2021-09-01

Code name: Schema refresh, exclude capabilities and default SRID

## Summary

Version 0.5.0 of `row-level-security` adds support for `GEOMETRY` columns without explicit SRID.

Lua Row Level Security (RLS) now supports `ALTER VIRTUAL SCHEMA ... REFRESH` to update the metadata of an existing virtual schema.

You can now prevent specific SQL constructs from being pushed down by using the `EXCLUDED_CAPABILITIES` property.

Also, we migrated the system requirement specification over from RLS Java and added a UML model that serves as design.

## Feature

* #47: Support `GEOMETRY` columns without explicit SRID.
* #58: Added option to exclude capabilities.
* #74: Users can now refresh the schema metadata with `ALTER VIRTUAL SCHEMA ... REFRESH`

## Documentation

* #50: Clarified what to do with the Lua adapter after download from GitHub in the user guide.
* #79: Migrated requirements from RLS Java, added UML model as design.

## Dependency Updates
