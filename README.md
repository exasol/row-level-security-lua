# Row Level Security (Lua)

Note: badges will be added once the project is published.

Protect access to database tables on a per-row level based on roles and / or tenants. 

## Features

Restrict access to rows (datasets) in tables to &hellip;

* set of roles
* tenants (owners)
* group of users
* combination of group and tenant
* combination of group and role

## Table of Contents

### Information for Users

* [User Guide](doc/user_guide/user_guide.md)
* [Tutorial](doc/user_guide/tutorial.md)
* [Changelog](doc/changes/changelog.md)

### Information for Contributors

Requirement, design documents and coverage tags are written in [OpenFastTrace](https://github.com/itsallcode/openfasttrace) format.

* [System Requirement Specification](doc/system_requirements.md)
* [Design](doc/design.md)
* [Developer Guide](doc/developer_guide.md)

### Run Time Dependencies

Running the RLS Lua Virtual Schema requires a Exasol with built-in Lua 5.1 or later.

| Dependency                               | Purpose                                                | License                       |
|------------------------------------------|--------------------------------------------------------|-------------------------------|
| [Lua CJSON][luacjson]                    | JSON parsing and writing                               | MIT License                   |
| [remotelog][remotelog]                   | Logging through a TCP socket                           | MIT License                   |

`remotelog` has a transitive dependency to [LuaSocket][luasocket] (MIT License). Note that Lua CSON and LuaSucket are pre-installed on an Exasol database.

For local unit testing you need to install them on the test machine though.

[luacjson]: https://www.kyne.com.au/~mark/software/lua-cjson.php
[luasocket]: http://w3.impa.br/~diego/software/luasocket/
[remotelog]: https://github.com/exasol/remotelog-lua

### Test Dependencies

#### Unit Test Dependencies

Unit tests are written in Lua. 

| Dependency                               | Purpose                                                | License                       |
|------------------------------------------|--------------------------------------------------------|-------------------------------|
| [luaunit][luaunit]                       | Unit testing framework                                 | BSD License                   |
| [Mockagne][mockagne]                     | Mocking framework                                      | MIT License                   |

[luaunit]: https://github.com/bluebird75/luaunit
[mockagne]: https://github.com/vertti/mockagne

#### Integration Test Dependencies

The integration tests require `exasol-testcontainers` to provide an Exasol instance. The are written in Java and require version 11 or later.

| Dependency                                         | Purpose                                                | License                       |
|----------------------------------------------------|--------------------------------------------------------|-------------------------------|
| [Exasol Testcontainers][exasol-testcontainers]     | Integration test Exasol instance on Docker             | MIT License                   |
| [Hamcrest Resultset Matcher][hamcrest-rs-matcher]  | Validating JDBC resultsets                             | MIT License                   |
| [Java Hamcrest][java-hamcrest]                     | Checking for conditions in code via matchers           | BSD License                   |
| [JUnit][junit5]                                    | Unit testing framework                                 | Eclipse Public License 1.0    |
| [Mockito][mockito]                                 | Mocking framework                                      | MIT License                   |
| [Test Database Builder][tddb-java]                 | Framework for writing database integration tests       | MIT License                   |
| [Testcontainers][testcontainers]                   | Container-based integration tests                      | MIT License                   |
| [SLF4J][slf4j]                                     | Logging facade                                         | MIT License                   |

[exasol-testcontainers]: https://github.com/exasol/exasol-testcontainers
[hamcrest-rs-matcher]: https://github.com/exasol/hamcrest-resultset-matcher
[java-hamcrest]: http://hamcrest.org/JavaHamcrest/
[junit5]: https://junit.org/junit5
[mockito]: http://site.mockito.org/
[tddb-java]: https://github.com/exasol/test-db-builder-java
[testcontainers]: https://www.testcontainers.org/
[slf4j]: http://www.slf4j.org/

### Build Dependencies

This project has a complex build setup due to the mixture of Lua and Java. [Apache Maven][maven] serves as the main build tool.

Lua build steps are also encapsulated by Maven.

| Dependency                                | Purpose                                                | License                       |
|-------------------------------------------|--------------------------------------------------------|-------------------------------|
| [Amalg][amalg]                            | Bundling Lua modules (and scripts)                     | MIT License                   |
| [Apache Maven][maven]                     | Build tool                                             | Apache License 2.0            |
| [Build Helper Maven Plugin][build-helper] | Register non-standard source directories (here Lua)    | MIT License                   |
| [Exec Maven Plugin][exec]                 | Execute external processes                             | Apache License 2.0            |
| [LuaRocks][luarocks]                      | Package management                                     | MIT License                   |
| [Maven Assembly Plugin][assembly]         | Building JAR archives                                  | Apache License 2.0            |
| [Maven Compiler Plugin][compiler]         | Setting required Java version                          | Apache License 2.0            |
| [Maven Failsafe Plugin][failsafe]         | Integration testing                                    | Apache License 2.0            |
| [Maven Jacoco Plugin][jacoco]             | Code coverage metering                                 | Eclipse Public License 2.0    |
| [Maven Source Plugin][source]             | Creating a source code JAR                             | Apache License 2.0            |
| [Maven Surefire Plugin][surefire]         | Unit testing                                           | Apache License 2.0            |
| [OpenFastTrace Maven Plugin][oft]         |Requirement Tracing                                     | GPL V3                        |
| [OSS Index Maven Plugin][oss-index]       | Dependency security monitoring                         | Apache License 2.0            |

[amalg]: https://github.com/siffiejoe/lua-amalg
[assembly]: https://maven.apache.org/plugins/maven-assembly-plugin/
[build-helper]: http://www.mojohaus.org/build-helper-maven-plugin/
[compiler]: https://maven.apache.org/plugins/maven-compiler-plugin/
[exec]: https://www.mojohaus.org/exec-maven-plugin/
[failsafe]: https://maven.apache.org/surefire/maven-surefire-plugin/
[jacoco]: https://www.eclemma.org/jacoco/trunk/doc/maven.html
[luarocks]: https://luarocks.org/
[maven]: https://maven.apache.org/
[oft]: https://github.com/itsallcode/openfasttrace-maven-plugin
[oss-index]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[source]: https://maven.apache.org/plugins/maven-source-plugin/
[surefire]: https://maven.apache.org/surefire/maven-surefire-plugin/