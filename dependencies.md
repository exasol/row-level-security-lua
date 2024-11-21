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
| [Apache Maven Clean Plugin][22]                         | [Apache-2.0][23]                                               |
| [Apache Maven Install Plugin][24]                       | [Apache-2.0][23]                                               |
| [Apache Maven Resources Plugin][25]                     | [Apache-2.0][23]                                               |
| [Apache Maven Site Plugin][26]                          | [Apache License, Version 2.0][23]                              |
| [SonarQube Scanner for Maven][27]                       | [GNU LGPL 3][28]                                               |
| [Apache Maven Toolchains Plugin][29]                    | [Apache-2.0][23]                                               |
| [Project Keeper Maven plugin][30]                       | [The MIT License][31]                                          |
| [Apache Maven Compiler Plugin][32]                      | [Apache-2.0][23]                                               |
| [Apache Maven Enforcer Plugin][33]                      | [Apache-2.0][23]                                               |
| [Maven Flatten Plugin][34]                              | [Apache Software Licenese][23]                                 |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][35] | [ASL2][36]                                                     |
| [Maven Surefire Plugin][37]                             | [Apache-2.0][23]                                               |
| [Versions Maven Plugin][38]                             | [Apache License, Version 2.0][23]                              |
| [duplicate-finder-maven-plugin Maven Mojo][39]          | [Apache License 2.0][40]                                       |
| [Maven Failsafe Plugin][41]                             | [Apache-2.0][23]                                               |
| [JaCoCo :: Maven Plugin][42]                            | [EPL-2.0][43]                                                  |
| [Quality Summarizer Maven Plugin][44]                   | [MIT License][45]                                              |
| [Exec Maven Plugin][46]                                 | [Apache License 2][23]                                         |
| [OpenFastTrace Maven Plugin][47]                        | [GNU General Public License v3.0][48]                          |
| [Build Helper Maven Plugin][49]                         | [The MIT License][50]                                          |
| [error-code-crawler-maven-plugin][51]                   | [MIT License][52]                                              |
| [Reproducible Build Maven Plugin][53]                   | [Apache 2.0][36]                                               |
| [Apache Maven JAR Plugin][54]                           | [Apache License, Version 2.0][23]                              |
| [Maven PlantUML plugin][55]                             | [Apache License
                Version 2.0, January 2004][56] |

## Extension

### Compile Dependencies

| Dependency                                | License |
| ----------------------------------------- | ------- |
| [@exasol/extension-manager-interface][57] | MIT     |

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
[22]: https://maven.apache.org/plugins/maven-clean-plugin/
[23]: https://www.apache.org/licenses/LICENSE-2.0.txt
[24]: https://maven.apache.org/plugins/maven-install-plugin/
[25]: https://maven.apache.org/plugins/maven-resources-plugin/
[26]: https://maven.apache.org/plugins/maven-site-plugin/
[27]: http://sonarsource.github.io/sonar-scanner-maven/
[28]: http://www.gnu.org/licenses/lgpl.txt
[29]: https://maven.apache.org/plugins/maven-toolchains-plugin/
[30]: https://github.com/exasol/project-keeper/
[31]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[32]: https://maven.apache.org/plugins/maven-compiler-plugin/
[33]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[34]: https://www.mojohaus.org/flatten-maven-plugin/
[35]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[36]: http://www.apache.org/licenses/LICENSE-2.0.txt
[37]: https://maven.apache.org/surefire/maven-surefire-plugin/
[38]: https://www.mojohaus.org/versions/versions-maven-plugin/
[39]: https://basepom.github.io/duplicate-finder-maven-plugin
[40]: http://www.apache.org/licenses/LICENSE-2.0.html
[41]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[42]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[43]: https://www.eclipse.org/legal/epl-2.0/
[44]: https://github.com/exasol/quality-summarizer-maven-plugin/
[45]: https://github.com/exasol/quality-summarizer-maven-plugin/blob/main/LICENSE
[46]: https://www.mojohaus.org/exec-maven-plugin
[47]: https://github.com/itsallcode/openfasttrace-maven-plugin
[48]: https://www.gnu.org/licenses/gpl-3.0.html
[49]: https://www.mojohaus.org/build-helper-maven-plugin/
[50]: https://spdx.org/licenses/MIT.txt
[51]: https://github.com/exasol/error-code-crawler-maven-plugin/
[52]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[53]: http://zlika.github.io/reproducible-build-maven-plugin
[54]: https://maven.apache.org/plugins/maven-jar-plugin/
[55]: https://github.com/Huluvu424242/plantuml-maven-plugin
[56]: https://www.apache.org/licenses/LICENSE-2.0
[57]: https://registry.npmjs.org/@exasol/extension-manager-interface/-/extension-manager-interface-0.4.2.tgz
