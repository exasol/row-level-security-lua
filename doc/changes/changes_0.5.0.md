# row-level-security-lua 0.5.0, released 2021-09-01

Code name: Support for Default SRID

## Summary

Version 0.5.0 of `row-level-security` adds support for `GEOMETRY` columns without explicit SRID.

You can now prevent specific SQL constructs from being pushed down by using the `EXCLUDED_CAPABILITIES` property.

Also, we migrated the system requirement specification over from RLS Java and added a UML model that serves as design.

## Feature

* #47: Support `GEOMETRY` columns without explicit SRID.
* #58: Added option to exclude capabilities.

## Documentation

* #50: Clarified what to do with the Lua adapter after download from GitHub in the user guide.
* #79: Migrated requirements from RLS Java, added UML model as design.

## Dependency Updates
