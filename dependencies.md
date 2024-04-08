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
| [Apache Maven Toolchains Plugin][22]                    | [Apache License, Version 2.0][23]                              |
| [Project Keeper Maven plugin][24]                       | [The MIT License][25]                                          |
| [Apache Maven Compiler Plugin][26]                      | [Apache-2.0][23]                                               |
| [Apache Maven Enforcer Plugin][27]                      | [Apache-2.0][23]                                               |
| [Maven Flatten Plugin][28]                              | [Apache Software Licenese][23]                                 |
| [Apache Maven JAR Plugin][29]                           | [Apache License, Version 2.0][23]                              |
| [Maven PlantUML plugin][30]                             | [Apache License
                Version 2.0, January 2004][31] |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][32] | [ASL2][33]                                                     |
| [Maven Surefire Plugin][34]                             | [Apache-2.0][23]                                               |
| [Versions Maven Plugin][35]                             | [Apache License, Version 2.0][23]                              |
| [duplicate-finder-maven-plugin Maven Mojo][36]          | [Apache License 2.0][37]                                       |
| [Maven Failsafe Plugin][38]                             | [Apache-2.0][23]                                               |
| [JaCoCo :: Maven Plugin][39]                            | [EPL-2.0][40]                                                  |
| [Exec Maven Plugin][41]                                 | [Apache License 2][23]                                         |
| [OpenFastTrace Maven Plugin][42]                        | [GNU General Public License v3.0][43]                          |
| [Build Helper Maven Plugin][44]                         | [The MIT License][45]                                          |
| [error-code-crawler-maven-plugin][46]                   | [MIT License][47]                                              |
| [Reproducible Build Maven Plugin][48]                   | [Apache 2.0][33]                                               |

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
[29]: https://maven.apache.org/plugins/maven-jar-plugin/
[30]: https://github.com/Huluvu424242/plantuml-maven-plugin
[31]: https://www.apache.org/licenses/LICENSE-2.0
[32]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[33]: http://www.apache.org/licenses/LICENSE-2.0.txt
[34]: https://maven.apache.org/surefire/maven-surefire-plugin/
[35]: https://www.mojohaus.org/versions/versions-maven-plugin/
[36]: https://basepom.github.io/duplicate-finder-maven-plugin
[37]: http://www.apache.org/licenses/LICENSE-2.0.html
[38]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[39]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[40]: https://www.eclipse.org/legal/epl-2.0/
[41]: https://www.mojohaus.org/exec-maven-plugin
[42]: https://github.com/itsallcode/openfasttrace-maven-plugin
[43]: https://www.gnu.org/licenses/gpl-3.0.html
[44]: https://www.mojohaus.org/build-helper-maven-plugin/
[45]: https://spdx.org/licenses/MIT.txt
[46]: https://github.com/exasol/error-code-crawler-maven-plugin/
[47]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[48]: http://zlika.github.io/reproducible-build-maven-plugin
[49]: https://registry.npmjs.org/@exasol/extension-manager-interface/-/extension-manager-interface-0.4.1.tgz
