# Exasol Row Level Security (Lua) 1.1.0, released 2021-11-??

Code name: New capabilities for GROUP BY

## Summary

In this release we have implemented GROUP BY capabilities support. The release also introduces a new foundation based on Exasol's `virtual-schema-common-lua`. We improved handling and validation of user-defined properties (like `SCHEMA_NAME` and `TABLE_FILTER`). We also improve Lua build, dependency management and testing.

## Bug Fixes

* #94: Added aggregationType parsing (single_group).

## Features 

* #99: Implemented GROUP BY capabilities support.

## Refactoring

* #106: Switched to `virtual-schema-common-lua` as basis for the Virtual Schema
* #109: Added a rockspec for Lua dependency management

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.2` to `7.1.7`
* Updated `com.exasol:exasol-testcontainers:5.1.1` to `6.1.1`
* Updated `org.testcontainers:junit-jupiter:1.16.2` to `1.16.3`
