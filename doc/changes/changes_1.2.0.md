# Exasol Row Level Security (Lua) 1.2.0, released 2022-05-??

Code name: `ORDER BY`, `LIMIT`, more functions and unified error handling

## Summary

Release 1.2.0 of `row-level-security-lua` upgrades the base module to `virtual-schema-common-lua` 1.1.0, which brings support for the `ORDER BY` and `LIMIT` clause as well as more scalar function coverage and uniform error reporting. 

Note that this version requires Exasol 7.1.10 or later to run stable, because earlier versions had a problem in handling Lua's `pcall` and `xpcall` functions. Please upgrade your database before running RLS!

We also added validation for Virtual Schema properties to all requests that use properties.

### Know Issues

Push-down of aggregate functions is not yet implemented. We will add that in a future version.

## Features 

* #118: `ORDER BY`, `LIMIT` more scalar functions
## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.7` to `7.1.10`
* Updated `com.exasol:test-db-builder-java:3.3.1` to `3.3.2`
* Updated `org.testcontainers:junit-jupiter:1.17.1` to `1.17.2`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:0.1.1` to `1.1.0`
* Updated `org.apache.maven.plugins:maven-jar-plugin:3.2.0` to `3.2.2`
* Updated `org.codehaus.mojo:build-helper-maven-plugin:3.2.0` to `3.3.0`
