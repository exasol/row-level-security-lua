# Row Level Security lua 1.5.5, released 2024-05-07

Code name: Improve error handling for extension

## Summary

This release improves error handling when creating a new Virtual Schema using the extension: the extension now checks if a schema with the same name exists and returns a helpful error message. This check is case-insensitive to be consistent with other virtual schemas.

## Bugfix

* #155: Improved error handling for creating Virtual Schema using the extension

## Dependency Updates

### Exasol Row Level Security (Lua)

#### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:7.0.1` to `7.1.0`
* Updated `com.exasol:extension-manager-integration-test-java:0.5.9` to `0.5.11`
* Updated `org.slf4j:slf4j-jdk14:2.0.12` to `2.0.13`

### Extension

#### Development Dependency Updates

* Updated `typescript-eslint:^7.6.0` to `^7.8.0`
* Updated `typescript:^5.4.4` to `^5.4.5`
