# Exasol Row Level Security (Lua) 1.0.1, released 2021-11-09

Code name: Unified error reporting

## Summary

As a preparation for contributing to Exasol's error catalog, all error messages in Lua RLS have been updated to use
[Uniform error reporting](https://github.com/exasol/error-reporting-lua).

Please note that this so far only covers errors raised in the RLS Virtual Schema adapter, the software that implement RLS. Administration scripts are not yet covered.

We also improved the test coverage in bad-weather scenarios (i.e. test that evaluate how the software handles error cases).

## Features

* #88: Added unified error reporting.

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.1` to `7.1.2`
* Updated `com.exasol:exasol-testcontainers:5.1.0` to `5.1.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.5.0` to `1.5.1`
* Updated `org.testcontainers:junit-jupiter:1.16.0` to `1.16.2`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:0.10.0` to `1.3.2`
