# row-level-security-lua 0.4.0, released 2020-03-19

Code name: Prototype fixes

## Summary

Release 0.4.0 brings support for empty push-down select lists &mdash; which can happen in case all selected expressions are constants or things that are not covered by capabilities (e.g. `IPROC()`). We also added literals for booleans, the null value and UTC timestamps.

All Exasol column types are now supported.

On protected tables a `SELECT *` is now turned into the explicit column list minus the hidden columns.

## Features

* #29: Added support for all column types.
* #36: Added support for the public-access role.
* #47: Added support for `GEOMETRY` without SRID.

## Bugfixes

* #27: Added validation for Virtual Schema properties.
* #30: Added support for `SELECT *` on protected tables.
* #31: Aligned RLS meta-column names with Java variant of RLS.
* #32: Fixed situation where accessing a role-protected row with a user who has no role assignment entry caused an exception.
* #33: Fixed table indexing when skipping RLS metadata tables.
* #35: Now replacing empty select lists with constant dummy expression to get back a dummy result set where only the number of rows matters.

## Dependency updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:3.0.0` to `3.5.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.1.0` to `1.4.0`