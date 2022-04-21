# Exasol Row Level Security (Lua) 1.1.0, released 2022-04-21

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
* #111: Switched to Project Keeper 2

## Dependency Updates

### Compile Dependency Updates

* Removed `com.exasol:maven-project-version-getter:1.0.0`

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.2` to `7.1.7`
* Updated `com.exasol:exasol-testcontainers:5.1.1` to `6.1.1`
* Added `com.exasol:maven-project-version-getter:1.1.0`
* Updated `com.exasol:test-db-builder-java:3.2.1` to `3.3.1`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.8.1` to `5.8.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.8.1` to `5.8.2`
* Removed `org.junit.platform:junit-platform-runner:1.8.1`
* Updated `org.slf4j:slf4j-jdk14:1.7.32` to `1.7.36`
* Updated `org.testcontainers:junit-jupiter:1.16.2` to `1.17.1`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:1.3.2` to `2.3.0`
* Added `com.github.funthomas424242:plantuml-maven-plugin:1.5.2`
* Updated `io.github.zlika:reproducible-build-maven-plugin:0.13` to `0.15`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.8.1` to `3.9.0`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.0.0-M3` to `3.0.0`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0-M4` to `3.0.0-M5`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.0.0-M4` to `3.0.0-M5`
* Added `org.codehaus.mojo:flatten-maven-plugin:1.2.7`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.7` to `2.8.1`
* Added `org.itsallcode:openfasttrace-maven-plugin:1.5.0`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.5` to `0.8.7`
* Added `org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184`
