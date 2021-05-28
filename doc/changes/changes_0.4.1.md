# row-level-security-lua 0.4.0, released 2020-05-28

Code name: Query-free push-down and validation improvements

## Summary

Release 0.4.1 removes queries during push-down, brings improved local unit tests and additional validations.

Run `tools/runtests.sh` to execute the unit test, collect code coverage and run static code analysis. The test output contains summaries and you will find reports in the `luaunit-reports` and `luacov-reports` directories.

To remove the necessity for `pquery` in push-down, we packed the complete check into the rewritten push-down SQL. This eliminates querying the user's group and role mask.

## Refactoring

* #12: Change #52 made the "grant workaround" unnecessary, so we removed it.
       Even if the problem still persists in the current development version Lua VS database, it no longer affects Lua RLS.
* #25: Made sure project version from POM is the same as in installer and Lua main module
* #37: Blocked unsupported combination of group and role security
* #50: Improved unit test runner script
* #52: Replaced `pquery` in push-down
* #57: Replaced `OPEN SCHEMA` + `CAT` with direct reading from system tables