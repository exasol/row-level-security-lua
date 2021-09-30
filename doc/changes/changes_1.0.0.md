# Exasol Row Level Security (Lua) 1.0.0, released 2021-09-30

Code name: Table filter

Version 1.0.0 of Row Level Security (Lua) adds a table filter controlled by the `TABLE_FILTER` property. This allows users to selectively include tables from the source schema into the Virtual Schema. It helps reducing the projected tables on a need-to-know basis and speeds up meta-data scanning, since only the listed tables are scanned instead of all in the schema.

## Features

* [#75](https://github.com/exasol/row-level-security-lua/issues/75): Added table filter.

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:5.0.0` to `5.1.0`
* Updated `com.exasol:hamcrest-resultset-matcher:1.4.1` to `1.5.0`
