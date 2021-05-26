# row-level-security-lua 0.4.0, released 2020-05-XX

Code name: Test improvement

## Summary

Release 0.4.1 brings improved local unit tests.

Run `tools/runtests.sh` to execute the unit test, collect code coverage and run static code analysis. The test output contains summaries and you will find reports in the `luaunit-reports` and `luacov-reports` directories.

To remove the necessity for `pquery` in push-down, we packed the complete check into the rewritten push-down SQL. This eliminates querying the user's group and role mask.

## Refactoring

* #50: Improved unit test runner script
* #52: Replaced `pquery` in push-down
