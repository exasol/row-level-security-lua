row-level-security-lua, released 2020-09-03
 
Code name: Prototype
 
## Summary
 
The prototype offers tenant-security, and has full unit test and integration test coverage.
 
## Features / Enhancements
 
* #1: Prototype

 
## Refactoring
 
* #2: Removed `remotelog` sources and added the module as a LuaRocks dependency.
 
## Dependency updates
 
* Added `remotelog:1.0.0`

Note that `row-level-security-lua` also has dependencies to `cjson` and `luasockets`, both of which are pre-installed on Exasol.