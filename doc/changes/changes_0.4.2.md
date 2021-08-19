# row-level-security-lua 0.4.2, released 2021-08-xx

Code name: 7.1 Compatibility

## Summary

This is the first release that uses the production version of Exasol 7.1 for the integration tests.
Switched build from Travis CI to GitHub Actions.
  
## Documentation

* #26: Added a user guide and a tutorial.

## Refactoring

* #39: Replaced custom docker image with official version in integration tests.
* #59: Activated full integration tests on CI.
* #63: Switched build from Travis CI to GitHub Actions.
* #65: Updated `dockerdb` in integration tests to `7.1.0-d1`.
* #72: Update dependencies for `0.4.2`.

## Dependency Updates

* Updated `com.exasol:exasol-jdbc:6.2.5` to `7.1.0`
* Updated `com.exasol:exasol-testcontainers:3.5.1` to `4.0.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.4.0` to `1.4.1`
* Updated `com.exasol:test-db-builder-java:0.2.0` to `3.2.1`
* Updated `org.testcontainers:junit-jupiter:1.13.0` to `1.16.0`
* Updated `org.slf4j:slf4j-jdk14:17.30` to `1.7.32`

## Plugin Updates

* Added `org.apache.maven.plugins:maven-enforcer-plugin:3.0.0-M3`
