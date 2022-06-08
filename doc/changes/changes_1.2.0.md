# Exasol Row Level Security (Lua) 1.2.0, released 2022-06-08

Code name: LIMIT, GROUP BY

## Summary

RLS (Lua) version 1.2.0 brings support for `LIMIT` with an optional offset and for `GROUP BY` clauses.

## Features

* #118: Added support for `LIMIT` and `GROUP BY` via update of `virtual-schema-common-lua`

## Refactoring

* #122: Applied new object-orientation style 

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.7` to `7.1.10`
* Updated `com.exasol:test-db-builder-java:3.3.1` to `3.3.2`
* Updated `org.testcontainers:junit-jupiter:1.17.1` to `1.17.2`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:0.1.1` to `1.1.1`
* Updated `com.exasol:project-keeper-maven-plugin:2.3.0` to `2.4.6`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.9.0` to `3.10.1`
* Updated `org.apache.maven.plugins:maven-jar-plugin:3.2.0` to `3.2.2`
* Updated `org.codehaus.mojo:build-helper-maven-plugin:3.2.0` to `3.3.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.8.1` to `2.10.0`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.7` to `0.8.8`
* Updated `org.sonatype.ossindex.maven:ossindex-maven-plugin:3.1.0` to `3.2.0`
