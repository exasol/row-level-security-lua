# row-level-security-lua 0.4.0, released 2020-03-??

Code name: Single group optimization

## Summary

Release 0.4.0 brings support for empty push-down select lists &mdash; which can happen in case all selected expressions are constants or things that are not covered by capabilities (e.g. `IPROC()`). We also added literals for booleans, the null value and UTC timestamps.

On protected tables a `SELECT *` is now turned into the explicit column list minus the hidden columns.

## Bugfixes

* #27: Added validation for Virtual Schema properties.
* #30: Added support for `SELECT *` on protected tables.
* #33: Fixed table indexing when skipping RLS metadata tables.
* #35: Now replacing empty select lists with constant dummy expression to get back a dummy result set where only the number of rows matters.

## Dependency updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:3.0.0` to `3.5.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.1.0` to `1.4.0`