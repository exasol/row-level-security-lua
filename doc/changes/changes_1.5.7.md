# Row Level Security lua 1.5.7, released 2025-03-10

Code name: Fixed CVE-2025-25193 and CVE-2025-24970 in test dependencies

## Summary

This release fixes vulnerabilities CVE-2025-25193 and CVE-2025-24970 in test dependencies. We also added file `SECURITY.md` with instructions for reporting vulnerabilities in this project.

## Security

* #160: Fixed CVE-2025-25193 in `io.netty:netty-common:jar:4.1.115.Final:test`
* #161: Fixed CVE-2025-24970 in `io.netty:netty-handler:jar:4.1.115.Final:test`

## Dependency Updates

### Exasol Row Level Security (Lua)

#### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:24.2.0` to `25.2.2`
* Removed `com.exasol:exasol-test-setup-abstraction-java:2.1.6`
* Updated `com.exasol:exasol-testcontainers:7.1.1` to `7.1.3`
* Updated `com.exasol:extension-manager-integration-test-java:0.5.13` to `0.5.15`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.11.3` to `5.12.0`
* Updated `org.junit.jupiter:junit-jupiter-params:5.11.3` to `5.12.0`
* Updated `org.slf4j:slf4j-jdk14:2.0.16` to `2.0.17`
* Updated `org.testcontainers:junit-jupiter:1.20.4` to `1.20.6`

#### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:4.4.0` to `4.5.0`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.5.1` to `3.5.2`
* Updated `org.apache.maven.plugins:maven-site-plugin:3.9.1` to `3.21.0`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.5.1` to `3.5.2`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.17.1` to `2.18.0`
* Updated `org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121` to `5.0.0.4389`

### Extension

#### Compile Dependency Updates

* Updated `@exasol/extension-manager-interface:0.4.3` to `0.5.0`

#### Development Dependency Updates

* Updated `eslint:9.14.0` to `9.22.0`
* Updated `ts-jest:^29.2.5` to `^29.2.6`
* Updated `typescript-eslint:^8.15.0` to `^8.26.0`
* Updated `typescript:^5.6.3` to `^5.8.2`
* Updated `esbuild:^0.24.0` to `^0.25.1`
