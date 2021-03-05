# row-level-security-lua, released 2020-03-??

Code name: Single group optimization

## Summary

Release 0.4.0 brings support for empty push-down select lists &mdash; which can happen in case all selected expressions are constants or things that are not covered by capabilities (e.g. `IPROC()`). We also added literals for booleans, the null value and UTC timestamps.

## Bugfixes

* #35: Now replacing empty select lists with constant dummy expression to get back a dummy result set where only the number of rows matters.

## Dependency updates

### Test Dependency Updates

* Updated `com.exasol:hamcrest-resultset-matcher:1.1.0` to `1.4.0`