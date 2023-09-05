<!-- @formatter:off -->
# Dependencies

## Test Dependencies

| Dependency                                     | License                           |
| ---------------------------------------------- | --------------------------------- |
| [EXASolution JDBC Driver][0]                   | [EXAClient License][1]            |
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

## Plugin Dependencies

| Dependency                                              | License                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| [SonarQube Scanner for Maven][20]                       | [GNU LGPL 3][21]                                               |
| [Apache Maven Compiler Plugin][22]                      | [Apache-2.0][23]                                               |
| [Apache Maven Enforcer Plugin][24]                      | [Apache-2.0][23]                                               |
| [Maven Flatten Plugin][25]                              | [Apache Software Licenese][23]                                 |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][26] | [ASL2][27]                                                     |
| [Maven Surefire Plugin][28]                             | [Apache-2.0][23]                                               |
| [Versions Maven Plugin][29]                             | [Apache License, Version 2.0][23]                              |
| [duplicate-finder-maven-plugin Maven Mojo][30]          | [Apache License 2.0][31]                                       |
| [Maven Failsafe Plugin][32]                             | [Apache-2.0][23]                                               |
| [JaCoCo :: Maven Plugin][33]                            | [Eclipse Public License 2.0][34]                               |
| [Project keeper maven plugin][35]                       | [The MIT License][36]                                          |
| [Exec Maven Plugin][37]                                 | [Apache License 2][23]                                         |
| [OpenFastTrace Maven Plugin][38]                        | [GNU General Public License v3.0][39]                          |
| [Build Helper Maven Plugin][40]                         | [The MIT License][41]                                          |
| [error-code-crawler-maven-plugin][42]                   | [MIT License][43]                                              |
| [Reproducible Build Maven Plugin][44]                   | [Apache 2.0][27]                                               |
| [Apache Maven JAR Plugin][45]                           | [Apache License, Version 2.0][23]                              |
| [Maven PlantUML plugin][46]                             | [Apache License
                Version 2.0, January 2004][47] |
| [Maven Clean Plugin][48]                                | [The Apache Software License, Version 2.0][27]                 |
| [Maven Resources Plugin][49]                            | [The Apache Software License, Version 2.0][27]                 |
| [Maven Install Plugin][50]                              | [The Apache Software License, Version 2.0][27]                 |
| [Maven Deploy Plugin][51]                               | [The Apache Software License, Version 2.0][27]                 |
| [Maven Site Plugin 3][52]                               | [The Apache Software License, Version 2.0][27]                 |

[0]: http://www.exasol.com
[1]: https://repo1.maven.org/maven2/com/exasol/exasol-jdbc/7.1.20/exasol-jdbc-7.1.20-license.txt
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
[22]: https://maven.apache.org/plugins/maven-compiler-plugin/
[23]: https://www.apache.org/licenses/LICENSE-2.0.txt
[24]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[25]: https://www.mojohaus.org/flatten-maven-plugin/
[26]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[27]: http://www.apache.org/licenses/LICENSE-2.0.txt
[28]: https://maven.apache.org/surefire/maven-surefire-plugin/
[29]: https://www.mojohaus.org/versions/versions-maven-plugin/
[30]: https://basepom.github.io/duplicate-finder-maven-plugin
[31]: http://www.apache.org/licenses/LICENSE-2.0.html
[32]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[33]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[34]: https://www.eclipse.org/legal/epl-2.0/
[35]: https://github.com/exasol/project-keeper/
[36]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[37]: https://www.mojohaus.org/exec-maven-plugin
[38]: https://github.com/itsallcode/openfasttrace-maven-plugin
[39]: https://www.gnu.org/licenses/gpl-3.0.html
[40]: https://www.mojohaus.org/build-helper-maven-plugin/
[41]: https://spdx.org/licenses/MIT.txt
[42]: https://github.com/exasol/error-code-crawler-maven-plugin/
[43]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[44]: http://zlika.github.io/reproducible-build-maven-plugin
[45]: https://maven.apache.org/plugins/maven-jar-plugin/
[46]: https://github.com/Huluvu424242/plantuml-maven-plugin
[47]: https://www.apache.org/licenses/LICENSE-2.0
[48]: http://maven.apache.org/plugins/maven-clean-plugin/
[49]: http://maven.apache.org/plugins/maven-resources-plugin/
[50]: http://maven.apache.org/plugins/maven-install-plugin/
[51]: http://maven.apache.org/plugins/maven-deploy-plugin/
[52]: http://maven.apache.org/plugins/maven-site-plugin/
