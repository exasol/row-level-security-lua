# Exasol Row Level Security (Lua) 1.4.0, released 2023-06-27

Code name: Aggregate Functions

## Summary

This release is based on the latest versions of `virtual-schema-common-lua` and `exasol-virtual-schema-common-lua`, so it now supports aggregate functions.

## Features

* #129: Used EVSCL base library

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.19` to `7.1.20`
* Updated `com.exasol:exasol-testcontainers:6.5.1` to `6.6.0`
* Updated `com.exasol:hamcrest-resultset-matcher:1.5.3` to `1.6.0`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.9.2` to `5.9.3`
* Updated `org.junit.jupiter:junit-jupiter-params:5.9.2` to `5.9.3`
* Updated `org.testcontainers:junit-jupiter:1.17.6` to `1.18.3`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.2.2` to `1.2.3`
* Updated `com.exasol:project-keeper-maven-plugin:2.9.6` to `2.9.7`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.10.1` to `3.11.0`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.2.1` to `3.3.0`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0-M8` to `3.0.0`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.0.0-M8` to `3.0.0`
* Added `org.basepom.maven:duplicate-finder-maven-plugin:1.5.1`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.3.0` to `1.4.1`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.14.2` to `2.15.0`
* Updated `org.itsallcode:openfasttrace-maven-plugin:1.6.1` to `1.6.2`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.8` to `0.8.9`
