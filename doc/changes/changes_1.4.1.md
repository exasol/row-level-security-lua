# Exasol Row Level Security (Lua) 1.4.1, released 2023-07-14

Code name: Fix Issue With Integer Constants in `GROUP BY`

## Summary

This release fixes an issue with queries using `DISTINCT` with integer constants. The Exasol SQL processor turns `DISTINCT <integer>` into `GROUP BY <integer>` before push-down as an optimization. The adapter must not feed this back as Exasol interprets integers in `GROUP BY` clauses as column numbers which could lead to invalid results or the following error:

```
42000:Wrong column number. Too small value 0 as select list column reference in GROUP BY (smallest possible value is 1)
```

To fix this, Exasol VS now replaces integer constants in `GROUP BY` clauses with a constant string.

Please that you can still safely use `GROUP BY <column-number>` in your original query, since Exasol internally converts this to `GROUP BY "<column-name>"`, so that the virtual schema adapter can tell both situations apart.

The release also adds integration tests using Exasol v8 to the CI build.

## Bugfixes

* #133: Fixed issue with integer constants in `GROUP BY`

## Refactoring

* #134: Added integration tests using Exasol v8 to CI build

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.6.0` to `6.6.1`
* Updated `org.slf4j:slf4j-jdk14:1.7.36` to `2.0.7`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.2.3` to `1.3.0`
* Updated `com.exasol:project-keeper-maven-plugin:2.9.7` to `2.9.9`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0` to `3.1.2`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.0.0` to `3.1.2`
* Updated `org.basepom.maven:duplicate-finder-maven-plugin:1.5.1` to `2.0.1`
* Updated `org.codehaus.mojo:build-helper-maven-plugin:3.3.0` to `3.4.0`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.4.1` to `1.5.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.15.0` to `2.16.0`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.9` to `0.8.10`
