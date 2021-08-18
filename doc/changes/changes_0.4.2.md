# row-level-security-lua 0.4.2, released 2021-08-xx

Code name: 7.1 Compatibility

## Summary

This is the first release that uses the production version of Exasol 7.1 for the integration tests.
Switched build from Travis CI to GitHub Actions.

## Refactoring

* #39: Replaced custom docker image with official version in integration tests.
* #59: Activated full integration tests on CI.
* #63: Switched build from Travis CI to GitHub Actions.
* #65: Updated `dockerdb` in integration tests to `7.1.0-d1`.
* #72: Update dependencies for `0.4.2`.

## Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.0.11` to `7.1.0`
* Updated `com.exasol:exasol-testcontainers:4.0.0` to `4.0.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.4.0` to `1.4.1`
* Updated `com.exasol:test-db-builder-java:3.2.0` to `3.2.1`