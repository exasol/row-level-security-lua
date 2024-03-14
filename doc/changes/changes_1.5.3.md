# Exasol Row Level Security Lua 1.5.3, released 2024-03-14

Code name: Fixed CVE-2024-26308 and CVE-2024-25710 in test dependencies

## Summary

In this security release we fixed CVE-2024-26308 and CVE-2024-25710 by updating test dependencies.

### CVE-2024-25710

Loop with Unreachable Exit Condition ('Infinite Loop') vulnerability in Apache Commons Compress.This issue affects Apache Commons Compress: from 1.3 through 1.25.0.

## References

- https://ossindex.sonatype.org/vulnerability/CVE-2024-25710?component-type=maven&component-name=org.apache.commons%2Fcommons-compress&utm_source=ossindex-client&utm_medium=integration&utm_content=1.8.1
- http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2024-25710
- https://lists.apache.org/thread/cz8qkcwphy4cx8gltn932ln51cbtq6kf

### CVE-2024-26308

Allocation of Resources Without Limits or Throttling vulnerability in Apache Commons Compress.This issue affects Apache Commons Compress: from 1.21 before 1.26.

## References
- 
- https://ossindex.sonatype.org/vulnerability/CVE-2024-26308?component-type=maven&component-name=org.apache.commons%2Fcommons-compress&utm_source=ossindex-client&utm_medium=integration&utm_content=1.8.1
- http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2024-26308
- https://lists.apache.org/thread/ch5yo2d21p7vlqrhll9b17otbyq4npfg
- https://www.openwall.com/lists/oss-security/2024/02/19/2

## Features

* #146: Fixed CVE-2024-25710 by updating test dependency
* #147: Fixed CVE-2024-26308 by updating test dependency

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.20` to `24.0.0`
* Updated `com.exasol:exasol-testcontainers:6.6.3` to `7.0.1`
* Updated `com.exasol:extension-manager-integration-test-java:0.5.7` to `0.5.8`
* Updated `com.exasol:hamcrest-resultset-matcher:1.6.2` to `1.6.5`
* Updated `com.exasol:test-db-builder-java:3.5.2` to `3.5.4`
* Updated `org.junit.jupiter:junit-jupiter-engine:5.10.1` to `5.10.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.10.1` to `5.10.2`
* Updated `org.slf4j:slf4j-jdk14:2.0.9` to `2.0.12`
* Updated `org.testcontainers:junit-jupiter:1.19.2` to `1.19.7`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:2.9.16` to `4.1.0`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.11.0` to `3.12.1`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.2.2` to `3.2.5`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.2.2` to `3.2.5`
* Added `org.apache.maven.plugins:maven-toolchains-plugin:3.1.0`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.5.0` to `1.6.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.16.1` to `2.16.2`
* Updated `org.itsallcode:openfasttrace-maven-plugin:1.6.2` to `1.8.0`
