# Exasol Row Level Security (Lua) 1.5.1, released 2023-10-25

Code name: Fix CVE-2023-42503 and source schema switching

## Summary

In this release we updated the test dependency `exasol-testcontainers` to version 6.6.2 in order to update the transitive dependency `org.apache.commons:commons-compress` to 1.24.0. This fixes CVE-2023-42505.

We also fixed a bug that prevented users from switching the source schema with `ALTER VIRTUAL SCHEMA ... SET SCHEMA_NAME=`.

## Features

* #136: Fixed source schema switching
* #140: Updated test dependency to fix CVE-2023-42505

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.6.1` to `6.6.2`
* Updated `com.exasol:extension-manager-integration-test-java:0.5.0` to `0.5.4`
* Updated `com.exasol:hamcrest-resultset-matcher:1.6.0` to `1.6.1`
* Updated `com.exasol:test-db-builder-java:3.5.0` to `3.5.1`
* Updated `org.testcontainers:junit-jupiter:1.19.0` to `1.19.1`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.3.0` to `1.3.1`
* Updated `com.exasol:project-keeper-maven-plugin:2.9.11` to `2.9.14`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.4.0` to `3.4.1`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.16.0` to `2.16.1`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.10` to `0.8.11`
* Updated `org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184` to `3.10.0.2594`
