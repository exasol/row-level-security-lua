<!-- @formatter:off -->
# Dependencies

## Exasol row Level Security (lua)

### Test Dependencies

| Dependency                                     | License                           |
| ---------------------------------------------- | --------------------------------- |
| [Exasol JDBC Driver][0]                        | [EXAClient License][1]            |
| [Test containers for Exasol on Docker][2]      | [MIT License][3]                  |
| [Testcontainers :: JUnit Jupiter Extension][4] | [MIT][5]                          |
| [Hamcrest][6]                                  | [BSD License 3][7]                |
| [Matcher for SQL Result Sets][8]               | [MIT License][9]                  |
| [JUnit Jupiter Engine][10]                     | [Eclipse Public License v2.0][11] |
| [JUnit Jupiter Params][10]                     | [Eclipse Public License v2.0][11] |
| [SLF4J JDK14 Provider][12]                     | [MIT License][13]                 |
| [Test Database Builder for Java][14]           | [MIT License][15]                 |
| [Maven Project Version Getter][16]             | [MIT License][17]                 |
| [Extension integration tests library][18]      | [MIT License][19]                 |
| [exasol-test-setup-abstraction-java][20]       | [MIT License][21]                 |

### Plugin Dependencies

| Dependency                                              | License                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| [SonarQube Scanner for Maven][22]                       | [GNU LGPL 3][23]                                               |
| [Apache Maven Toolchains Plugin][24]                    | [Apache-2.0][25]                                               |
| [Project Keeper Maven plugin][26]                       | [The MIT License][27]                                          |
| [Apache Maven Compiler Plugin][28]                      | [Apache-2.0][25]                                               |
| [Apache Maven Enforcer Plugin][29]                      | [Apache-2.0][25]                                               |
| [Maven Flatten Plugin][30]                              | [Apache Software Licenese][25]                                 |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][31] | [ASL2][32]                                                     |
| [Maven Surefire Plugin][33]                             | [Apache-2.0][25]                                               |
| [Versions Maven Plugin][34]                             | [Apache License, Version 2.0][25]                              |
| [duplicate-finder-maven-plugin Maven Mojo][35]          | [Apache License 2.0][36]                                       |
| [Maven Failsafe Plugin][37]                             | [Apache-2.0][25]                                               |
| [JaCoCo :: Maven Plugin][38]                            | [EPL-2.0][39]                                                  |
| [Exec Maven Plugin][40]                                 | [Apache License 2][25]                                         |
| [OpenFastTrace Maven Plugin][41]                        | [GNU General Public License v3.0][42]                          |
| [Build Helper Maven Plugin][43]                         | [The MIT License][44]                                          |
| [error-code-crawler-maven-plugin][45]                   | [MIT License][46]                                              |
| [Reproducible Build Maven Plugin][47]                   | [Apache 2.0][32]                                               |
| [Apache Maven JAR Plugin][48]                           | [Apache License, Version 2.0][25]                              |
| [Maven PlantUML plugin][49]                             | [Apache License
                Version 2.0, January 2004][50] |

## Extension

### Compile Dependencies

| Dependency                                | License |
| ----------------------------------------- | ------- |
| [@exasol/extension-manager-interface][51] | MIT     |

[0]: http://www.exasol.com/
[1]: https://repo1.maven.org/maven2/com/exasol/exasol-jdbc/24.1.0/exasol-jdbc-24.1.0-license.txt
[2]: https://github.com/exasol/exasol-testcontainers/
[3]: https://github.com/exasol/exasol-testcontainers/blob/main/LICENSE
[4]: https://java.testcontainers.org
[5]: http://opensource.org/licenses/MIT
[6]: http://hamcrest.org/JavaHamcrest/
[7]: http://opensource.org/licenses/BSD-3-Clause
[8]: https://github.com/exasol/hamcrest-resultset-matcher/
[9]: https://github.com/exasol/hamcrest-resultset-matcher/blob/main/LICENSE
[10]: https://junit.org/junit5/
[11]: https://www.eclipse.org/legal/epl-v20.html
[12]: http://www.slf4j.org
[13]: http://www.opensource.org/licenses/mit-license.php
[14]: https://github.com/exasol/test-db-builder-java/
[15]: https://github.com/exasol/test-db-builder-java/blob/main/LICENSE
[16]: https://github.com/exasol/maven-project-version-getter/
[17]: https://github.com/exasol/maven-project-version-getter/blob/main/LICENSE
[18]: https://github.com/exasol/extension-manager/
[19]: https://github.com/exasol/extension-manager/blob/main/LICENSE
[20]: https://github.com/exasol/exasol-test-setup-abstraction-java/
[21]: https://github.com/exasol/exasol-test-setup-abstraction-java/blob/main/LICENSE
[22]: http://sonarsource.github.io/sonar-scanner-maven/
[23]: http://www.gnu.org/licenses/lgpl.txt
[24]: https://maven.apache.org/plugins/maven-toolchains-plugin/
[25]: https://www.apache.org/licenses/LICENSE-2.0.txt
[26]: https://github.com/exasol/project-keeper/
[27]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[28]: https://maven.apache.org/plugins/maven-compiler-plugin/
[29]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[30]: https://www.mojohaus.org/flatten-maven-plugin/
[31]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[32]: http://www.apache.org/licenses/LICENSE-2.0.txt
[33]: https://maven.apache.org/surefire/maven-surefire-plugin/
[34]: https://www.mojohaus.org/versions/versions-maven-plugin/
[35]: https://basepom.github.io/duplicate-finder-maven-plugin
[36]: http://www.apache.org/licenses/LICENSE-2.0.html
[37]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[38]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[39]: https://www.eclipse.org/legal/epl-2.0/
[40]: https://www.mojohaus.org/exec-maven-plugin
[41]: https://github.com/itsallcode/openfasttrace-maven-plugin
[42]: https://www.gnu.org/licenses/gpl-3.0.html
[43]: https://www.mojohaus.org/build-helper-maven-plugin/
[44]: https://spdx.org/licenses/MIT.txt
[45]: https://github.com/exasol/error-code-crawler-maven-plugin/
[46]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[47]: http://zlika.github.io/reproducible-build-maven-plugin
[48]: https://maven.apache.org/plugins/maven-jar-plugin/
[49]: https://github.com/Huluvu424242/plantuml-maven-plugin
[50]: https://www.apache.org/licenses/LICENSE-2.0
[51]: https://registry.npmjs.org/@exasol/extension-manager-interface/-/extension-manager-interface-0.4.2.tgz
