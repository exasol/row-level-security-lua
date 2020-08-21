# Row Level Security (Lua)

<img alt="row-level-security logo" src="doc/images/row-level-security_128x128.png" style="float:left; padding:0px 10px 10px 10px;"/>

[![Build Status](https://api.travis-ci.com/exasol/row-level-security.svg?branch=master)](https://travis-ci.org/exasol/row-level-security)

SonarCloud results:

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=alert_status)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)

[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=security_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=sqale_index)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)

[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=code_smells)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=coverage)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=duplicated_lines_density)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Arow-level-security&metric=ncloc)](https://sonarcloud.io/dashboard?id=com.exasol%3Arow-level-security)

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
| [LuaSocket][luasocket]                   | Socket communication                                   | MIT License                   |

Note that Lua CSON and LuaSucket both are pre-installed on an Exasol database. For local unit testing you need to install them on the test machine though.

[luacjson]: https://www.kyne.com.au/~mark/software/lua-cjson.php
[luasocket]: http://w3.impa.br/~diego/software/luasocket/

### Test Dependencies

| Dependency                               | Purpose                                                | License                       |
|------------------------------------------|--------------------------------------------------------|-------------------------------|
| [luaunit][luaunit]                       | Unit testing framework                                 | BSD License                   |
| [Mockagne][mockagne]                     | Mocking framework                                      | MIT License                   |

[luaunit]: https://github.com/bluebird75/luaunit
[mockagne]: https://github.com/vertti/mockagne

### Build Dependencies

| Dependency                               | Purpose                                                | License                       |
|------------------------------------------|--------------------------------------------------------|-------------------------------|
| [LuaRocks][luarocks]                     | Package management                                     | MIT License                   |
| [Amalg][amalg]                           | Bundling Lua modules (and scripts)                     | MIT License                   |

[luarocks]: https://luarocks.org/
[amalg]: https://github.com/siffiejoe/lua-amalg