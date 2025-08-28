<!-- @formatter:off -->
# Dependencies

## Exasol row Level Security (lua)

### Test Dependencies

| Dependency                                     | License                           |
| ---------------------------------------------- | --------------------------------- |
| [Exasol JDBC Driver][0]                        | [EXAClient License][1]            |
| [Test containers for Exasol on Docker][2]      | [MIT License][3]                  |
| [Testcontainers :: JUnit Jupiter Extension][4] | [MIT][5]                          |
| [Hamcrest][6]                                  | [BSD-3-Clause][7]                 |
| [Matcher for SQL Result Sets][8]               | [MIT License][9]                  |
| [JUnit Jupiter Engine][10]                     | [Eclipse Public License v2.0][11] |
| [JUnit Jupiter Params][10]                     | [Eclipse Public License v2.0][11] |
| [SLF4J JDK14 Provider][12]                     | [MIT][13]                         |
| [Test Database Builder for Java][14]           | [MIT License][15]                 |
| [Maven Project Version Getter][16]             | [MIT License][17]                 |
| [Extension integration tests library][18]      | [MIT License][19]                 |

### Plugin Dependencies

| Dependency                                              | License                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| [Apache Maven Clean Plugin][20]                         | [Apache-2.0][21]                                               |
| [Apache Maven Install Plugin][22]                       | [Apache-2.0][21]                                               |
| [Apache Maven Resources Plugin][23]                     | [Apache-2.0][21]                                               |
| [Apache Maven Site Plugin][24]                          | [Apache-2.0][21]                                               |
| [SonarQube Scanner for Maven][25]                       | [GNU LGPL 3][26]                                               |
| [Apache Maven Toolchains Plugin][27]                    | [Apache-2.0][21]                                               |
| [Project Keeper Maven plugin][28]                       | [The MIT License][29]                                          |
| [Apache Maven Compiler Plugin][30]                      | [Apache-2.0][21]                                               |
| [Apache Maven Enforcer Plugin][31]                      | [Apache-2.0][21]                                               |
| [Maven Flatten Plugin][32]                              | [Apache Software Licenese][21]                                 |
| [Apache Maven JAR Plugin][33]                           | [Apache License, Version 2.0][21]                              |
| [Maven PlantUML plugin][34]                             | [Apache License
                Version 2.0, January 2004][35] |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][36] | [ASL2][37]                                                     |
| [Maven Surefire Plugin][38]                             | [Apache-2.0][21]                                               |
| [Versions Maven Plugin][39]                             | [Apache License, Version 2.0][21]                              |
| [duplicate-finder-maven-plugin Maven Mojo][40]          | [Apache License 2.0][41]                                       |
| [Apache Maven Artifact Plugin][42]                      | [Apache-2.0][21]                                               |
| [Maven Failsafe Plugin][43]                             | [Apache-2.0][21]                                               |
| [JaCoCo :: Maven Plugin][44]                            | [EPL-2.0][45]                                                  |
| [Quality Summarizer Maven Plugin][46]                   | [MIT License][47]                                              |
| [Exec Maven Plugin][48]                                 | [Apache License 2][21]                                         |
| [OpenFastTrace Maven Plugin][49]                        | [GNU General Public License v3.0][50]                          |
| [Build Helper Maven Plugin][51]                         | [The MIT License][52]                                          |
| [error-code-crawler-maven-plugin][53]                   | [MIT License][54]                                              |
| [Git Commit Id Maven Plugin][55]                        | [GNU Lesser General Public License 3.0][56]                    |

## Extension

### Compile Dependencies

| Dependency                                | License |
| ----------------------------------------- | ------- |
| [@exasol/extension-manager-interface][57] | MIT     |

[0]: http://www.exasol.com/
[1]: https://repo1.maven.org/maven2/com/exasol/exasol-jdbc/25.2.2/exasol-jdbc-25.2.2-license.txt
[2]: https://github.com/exasol/exasol-testcontainers/
[3]: https://github.com/exasol/exasol-testcontainers/blob/main/LICENSE
[4]: https://java.testcontainers.org
[5]: http://opensource.org/licenses/MIT
[6]: http://hamcrest.org/JavaHamcrest/
[7]: https://raw.githubusercontent.com/hamcrest/JavaHamcrest/master/LICENSE
[8]: https://github.com/exasol/hamcrest-resultset-matcher/
[9]: https://github.com/exasol/hamcrest-resultset-matcher/blob/main/LICENSE
[10]: https://junit.org/junit5/
[11]: https://www.eclipse.org/legal/epl-v20.html
[12]: http://www.slf4j.org
[13]: https://opensource.org/license/mit
[14]: https://github.com/exasol/test-db-builder-java/
[15]: https://github.com/exasol/test-db-builder-java/blob/main/LICENSE
[16]: https://github.com/exasol/maven-project-version-getter/
[17]: https://github.com/exasol/maven-project-version-getter/blob/main/LICENSE
[18]: https://github.com/exasol/extension-manager/
[19]: https://github.com/exasol/extension-manager/blob/main/LICENSE
[20]: https://maven.apache.org/plugins/maven-clean-plugin/
[21]: https://www.apache.org/licenses/LICENSE-2.0.txt
[22]: https://maven.apache.org/plugins/maven-install-plugin/
[23]: https://maven.apache.org/plugins/maven-resources-plugin/
[24]: https://maven.apache.org/plugins/maven-site-plugin/
[25]: http://docs.sonarqube.org/display/PLUG/Plugin+Library/sonar-scanner-maven/sonar-maven-plugin
[26]: http://www.gnu.org/licenses/lgpl.txt
[27]: https://maven.apache.org/plugins/maven-toolchains-plugin/
[28]: https://github.com/exasol/project-keeper/
[29]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[30]: https://maven.apache.org/plugins/maven-compiler-plugin/
[31]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[32]: https://www.mojohaus.org/flatten-maven-plugin/
[33]: https://maven.apache.org/plugins/maven-jar-plugin/
[34]: https://github.com/Huluvu424242/plantuml-maven-plugin
[35]: https://www.apache.org/licenses/LICENSE-2.0
[36]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[37]: http://www.apache.org/licenses/LICENSE-2.0.txt
[38]: https://maven.apache.org/surefire/maven-surefire-plugin/
[39]: https://www.mojohaus.org/versions/versions-maven-plugin/
[40]: https://basepom.github.io/duplicate-finder-maven-plugin
[41]: http://www.apache.org/licenses/LICENSE-2.0.html
[42]: https://maven.apache.org/plugins/maven-artifact-plugin/
[43]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[44]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[45]: https://www.eclipse.org/legal/epl-2.0/
[46]: https://github.com/exasol/quality-summarizer-maven-plugin/
[47]: https://github.com/exasol/quality-summarizer-maven-plugin/blob/main/LICENSE
[48]: https://www.mojohaus.org/exec-maven-plugin
[49]: https://github.com/itsallcode/openfasttrace-maven-plugin
[50]: https://www.gnu.org/licenses/gpl-3.0.html
[51]: https://www.mojohaus.org/build-helper-maven-plugin/
[52]: https://spdx.org/licenses/MIT.txt
[53]: https://github.com/exasol/error-code-crawler-maven-plugin/
[54]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[55]: https://github.com/git-commit-id/git-commit-id-maven-plugin
[56]: http://www.gnu.org/licenses/lgpl-3.0.txt
[57]: https://registry.npmjs.org/@exasol/extension-manager-interface/-/extension-manager-interface-0.5.0.tgz
