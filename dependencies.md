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

### Plugin Dependencies

| Dependency                                              | License                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| [SonarQube Scanner for Maven][20]                       | [GNU LGPL 3][21]                                               |
| [Apache Maven Toolchains Plugin][22]                    | [Apache-2.0][23]                                               |
| [Project Keeper Maven plugin][24]                       | [The MIT License][25]                                          |
| [Apache Maven Compiler Plugin][26]                      | [Apache-2.0][23]                                               |
| [Apache Maven Enforcer Plugin][27]                      | [Apache-2.0][23]                                               |
| [Maven Flatten Plugin][28]                              | [Apache Software Licenese][23]                                 |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][29] | [ASL2][30]                                                     |
| [Maven Surefire Plugin][31]                             | [Apache-2.0][23]                                               |
| [Versions Maven Plugin][32]                             | [Apache License, Version 2.0][23]                              |
| [duplicate-finder-maven-plugin Maven Mojo][33]          | [Apache License 2.0][34]                                       |
| [Maven Failsafe Plugin][35]                             | [Apache-2.0][23]                                               |
| [JaCoCo :: Maven Plugin][36]                            | [EPL-2.0][37]                                                  |
| [Exec Maven Plugin][38]                                 | [Apache License 2][23]                                         |
| [OpenFastTrace Maven Plugin][39]                        | [GNU General Public License v3.0][40]                          |
| [Build Helper Maven Plugin][41]                         | [The MIT License][42]                                          |
| [error-code-crawler-maven-plugin][43]                   | [MIT License][44]                                              |
| [Reproducible Build Maven Plugin][45]                   | [Apache 2.0][30]                                               |
| [Apache Maven JAR Plugin][46]                           | [Apache License, Version 2.0][23]                              |
| [Maven PlantUML plugin][47]                             | [Apache License
                Version 2.0, January 2004][48] |

## Extension

### Compile Dependencies

| Dependency                                | License |
| ----------------------------------------- | ------- |
| [@exasol/extension-manager-interface][49] | MIT     |

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
[20]: http://sonarsource.github.io/sonar-scanner-maven/
[21]: http://www.gnu.org/licenses/lgpl.txt
[22]: https://maven.apache.org/plugins/maven-toolchains-plugin/
[23]: https://www.apache.org/licenses/LICENSE-2.0.txt
[24]: https://github.com/exasol/project-keeper/
[25]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[26]: https://maven.apache.org/plugins/maven-compiler-plugin/
[27]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[28]: https://www.mojohaus.org/flatten-maven-plugin/
[29]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[30]: http://www.apache.org/licenses/LICENSE-2.0.txt
[31]: https://maven.apache.org/surefire/maven-surefire-plugin/
[32]: https://www.mojohaus.org/versions/versions-maven-plugin/
[33]: https://basepom.github.io/duplicate-finder-maven-plugin
[34]: http://www.apache.org/licenses/LICENSE-2.0.html
[35]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[36]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[37]: https://www.eclipse.org/legal/epl-2.0/
[38]: https://www.mojohaus.org/exec-maven-plugin
[39]: https://github.com/itsallcode/openfasttrace-maven-plugin
[40]: https://www.gnu.org/licenses/gpl-3.0.html
[41]: https://www.mojohaus.org/build-helper-maven-plugin/
[42]: https://spdx.org/licenses/MIT.txt
[43]: https://github.com/exasol/error-code-crawler-maven-plugin/
[44]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[45]: http://zlika.github.io/reproducible-build-maven-plugin
[46]: https://maven.apache.org/plugins/maven-jar-plugin/
[47]: https://github.com/Huluvu424242/plantuml-maven-plugin
[48]: https://www.apache.org/licenses/LICENSE-2.0
[49]: https://registry.npmjs.org/@exasol/extension-manager-interface/-/extension-manager-interface-0.4.2.tgz
