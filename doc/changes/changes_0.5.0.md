# row-level-security-lua 0.5.0, released 2021-09-01

Code name: Support for Default SRID

## Summary

Version 0.5.0 of `row-level-security` adds support for `GEOMETRY` columns without explicit SRID.

Also, we migrated the system requirement specification over from RLS Java and added a UML model that serves as design.

## Feature

* #47: Support `GEOMETRY` columns without explicit SRID.

## Documentation

* #79: Migrated requirements from RLS Java, added UML model as design.

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:6.2.5` to `7.1.0`
* Updated `com.exasol:exasol-testcontainers:3.5.1` to `4.0.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.4.0` to `1.4.1`
* Updated `com.exasol:test-db-builder-java:0.2.0` to `3.2.1`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.6.2` to `5.7.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.6.2` to `5.7.2`
* Updated `org.junit.platform:junit-platform-runner:1.6.2` to `1.7.2`
* Updated `org.slf4j:slf4j-jdk14:1.7.30` to `1.7.32`
* Updated `org.testcontainers:junit-jupiter:1.13.0` to `1.16.0`

### Plugin Dependency Updates

* Added `com.exasol:error-code-crawler-maven-plugin:0.1.1`
* Added `com.exasol:project-keeper-maven-plugin:0.10.0`
* Added `io.github.zlika:reproducible-build-maven-plugin:0.13`
* Added `org.apache.maven.plugins:maven-enforcer-plugin:3.0.0-M3`
* Added `org.codehaus.mojo:versions-maven-plugin:2.7`
* Added `org.jacoco:jacoco-maven-plugin:0.8.5`
