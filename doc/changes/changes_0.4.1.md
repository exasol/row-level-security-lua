# row-level-security-lua 0.4.0, released 2020-05-XX

Code name: Test improvement

## Summary

Release 0.4.1 brings improved local unit tests.

Run `tools/runtests.sh` to execute the unit test, collect code coverage and run static code analysis. The test output contains summaries and you will find reports in the `luaunit-reports` and `luacov-reports` directories.


## Refactoring

* #50: Improve unit test runner script
* #25: Made sure project version from POM is the same as in installer and Lua main module
