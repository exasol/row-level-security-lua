# Row Level Security lua 1.5.6, released 2024-11-21

Code name: Fix CVE-2024-47535 in io.netty:netty-common:jar:4.1.108.Final:test

## Summary

This release fixes CVE-2024-47535 in transitive test dependency `io.netty:netty-common:jar:4.1.108.Final:test`.
It also includes additional integration tests.

## Security

* #158: Fixed CVE-2024-47535 in `io.netty:netty-common:jar:4.1.108.Final:test`

## Features

* ISSUE_NUMBER: description

## Dependency Updates

### Exasol Row Level Security (Lua)

#### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:24.1.0` to `24.2.0`
* Added `com.exasol:exasol-test-setup-abstraction-java:2.1.6`
* Updated `com.exasol:exasol-testcontainers:7.1.0` to `7.1.1`
* Updated `com.exasol:extension-manager-integration-test-java:0.5.11` to `0.5.13`
* Updated `com.exasol:hamcrest-resultset-matcher:1.6.5` to `1.7.0`
* Updated `com.exasol:maven-project-version-getter:1.2.0` to `1.2.1`
* Updated `com.exasol:test-db-builder-java:3.5.4` to `3.6.0`
* Updated `org.hamcrest:hamcrest:2.2` to `3.0`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.10.2` to `5.11.3`
* Updated `org.junit.jupiter:junit-jupiter-params:5.10.2` to `5.11.3`
* Updated `org.slf4j:slf4j-jdk14:2.0.13` to `2.0.16`
* Updated `org.testcontainers:junit-jupiter:1.19.7` to `1.20.4`

#### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:4.3.0` to `4.4.0`
* Added `com.exasol:quality-summarizer-maven-plugin:0.2.0`
* Updated `io.github.zlika:reproducible-build-maven-plugin:0.16` to `0.17`
* Updated `org.apache.maven.plugins:maven-clean-plugin:2.5` to `3.4.0`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.4.1` to `3.5.0`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.2.5` to `3.5.1`
* Updated `org.apache.maven.plugins:maven-install-plugin:2.4` to `3.1.3`
* Updated `org.apache.maven.plugins:maven-resources-plugin:2.6` to `3.3.1`
* Updated `org.apache.maven.plugins:maven-site-plugin:3.3` to `3.9.1`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.2.5` to `3.5.1`
* Updated `org.apache.maven.plugins:maven-toolchains-plugin:3.1.0` to `3.2.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.16.2` to `2.17.1`
* Updated `org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922` to `4.0.0.4121`

### Extension

#### Development Dependency Updates

* Updated `ts-jest:^29.1.2` to `^29.1.3`
* Updated `typescript-eslint:^7.8.0` to `^7.10.0`
* Updated `esbuild:^0.20.2` to `^0.21.3`
