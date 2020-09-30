# row-level-security-lua, released 2020-09-30

Code name: Single group optimization

## Summary

This release brings a couple now supported scalar functions and data types, static code analysis and a optimization of the RLS filter in case a user is a member of exactly one group.

## Features / Enhancements

* #10: Added rendering for special cases of scalar functions.
* #15: Implemented missing data types rendering.
* #22: Optimized RLS filter in case user is assigned to a single group.

## Refactoring

* #14: Added Travis CI build with unit tests and `luacheck`.
* #19: Fixed luacheck findings.