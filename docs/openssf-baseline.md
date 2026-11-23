# OpenSSF Baseline conformance

This page records how the repository meets the [Open Source Project Security Baseline, version 2026.08.28](https://baseline.openssf.org/versions/2026-08-28-checklist.md). It was last reviewed on 2026-11-23. Update it in the same pull request as any change to CI, repository settings or the policy files.

Status values: **Met**, **N/A** (the control's condition does not hold, with the reason), **Gap** (not met, with the reason).

The project has made no release, so every control that starts "when the project has made a release" is N/A today. Those controls apply from the first release.

## Level 1

| Control | Status | Evidence |
|---|---|---|
| AC-01.01 MFA for sensitive resources | Met | The maintainer's GitHub account uses two-factor authentication (confirmed by the maintainer on 2026-11-23), and it is the only account with write access ([GOVERNANCE.md](../GOVERNANCE.md)). |
| AC-02.01 Least privilege for new collaborators | Met | GitHub assigns a collaborator's role by hand. [GOVERNANCE.md](../GOVERNANCE.md) sets the lowest role as the starting point. |
| AC-03.01 No direct commits to the primary branch | Met | Repository ruleset `main`: changes need a pull request. No bypass actors. |
| AC-03.02 Primary branch cannot be deleted | Met | Ruleset `main`: deletion and force-push are blocked. |
| BR-01.01 Untrusted metadata is sanitized in CI | Met | [ci.yml](../.github/workflows/ci.yml) uses only commit SHAs from the event, passed through environment variables. |
| BR-01.03 Untrusted code gets no privileged credentials | Met | CI runs on `pull_request` with `contents: read`. The repository has no Actions secrets. |
| BR-03.01 Project channels are encrypted | Met | Every project URL is HTTPS on github.com. |
| BR-03.02 Distribution channels are authenticated | Met | The only distribution channel is this Git repository, over HTTPS or SSH. |
| BR-07.01 Secrets are kept out of version control | Met | GitHub secret scanning with push protection. gitleaks and Trivy in CI. |
| DO-01.01 User guides | N/A | No release. The [README](../README.md) and [prototype/README.md](../prototype/README.md) cover use. |
| DO-02.01 Defect reporting guide | N/A | No release. [CONTRIBUTING.md](../CONTRIBUTING.md) has the guide. |
| GV-02.01 Public discussion mechanism | Met | GitHub issues and pull requests. |
| GV-03.01 Contribution process | Met | [CONTRIBUTING.md](../CONTRIBUTING.md). |
| LE-02.01 Source license is OSI-approved | Met | Apache-2.0. |
| LE-02.02 Released-asset license is OSI-approved | Met | Apache-2.0. There are no released assets. |
| LE-03.01 License file in the repository | Met | [LICENSE](../LICENSE), with third-party captures scoped in [NOTICE](../NOTICE). |
| LE-03.02 License with released assets | Met | The same [LICENSE](../LICENSE). There are no released assets. |
| QA-01.01 Public repository at a static URL | Met | <https://github.com/allensanborn/cell-platform-prototype>. |
| QA-01.02 Public change history | Met | The Git history. |
| QA-02.01 Dependency list | N/A | The repository has no language package manager. [CONTRIBUTING.md](../CONTRIBUTING.md) describes the tool and image dependencies. |
| QA-04.01 List of codebases | N/A | One repository ([GOVERNANCE.md](../GOVERNANCE.md)). |
| QA-05.01 No generated executables | Met | The repository holds only text files. |
| QA-05.02 No unreviewable binaries | Met | The repository holds only text files. |
| VM-02.01 Security contacts | Met | [SECURITY.md](../SECURITY.md). |

## Level 2

| Control | Status | Evidence |
|---|---|---|
| AC-04.01 CI defaults to lowest permissions | Met | The repository's default workflow permission is read. The workflow also sets `contents: read`. |
| BR-02.01 Unique release version | N/A | No release. |
| BR-04.01 Release change log | N/A | No release. |
| BR-05.01 Standard dependency tooling | Met | CI pulls tools as digest-pinned container images and a SHA-pinned action. |
| BR-06.01 Signed releases | N/A | No release. |
| DO-06.01 Dependency management description | N/A | No release. [CONTRIBUTING.md](../CONTRIBUTING.md) has the description. |
| DO-07.01 Build instructions | Met | [prototype/README.md](../prototype/README.md) and [CONTRIBUTING.md](../CONTRIBUTING.md). |
| GV-01.01 Members with sensitive access | Met | [GOVERNANCE.md](../GOVERNANCE.md). |
| GV-01.02 Roles and responsibilities | Met | [GOVERNANCE.md](../GOVERNANCE.md). |
| GV-03.02 Requirements for contributions | Met | [CONTRIBUTING.md](../CONTRIBUTING.md). |
| LE-01.01 Contributors assert the right to contribute | Met | Developer Certificate of Origin. The required `dco` check rejects a commit without `Signed-off-by`, and web commits require sign-off. |
| QA-03.01 Status checks pass before merge | Met | Ruleset `main` requires the `check` and `dco` checks. |
| QA-06.01 CI runs a test suite before merge | Met | The `check` job: shellcheck, gitleaks, Trivy. |
| SA-01.01 Design documentation | N/A | No release. The [README](../README.md) diagrams the actors and flows. |
| SA-02.01 External interface documentation | N/A | No release. |
| SA-03.01 Security assessment | N/A | No release. |
| VM-01.01 Coordinated disclosure policy with timeframes | Met | [SECURITY.md](../SECURITY.md). |
| VM-03.01 Private vulnerability reporting | Met | GitHub private vulnerability reporting is on, linked from [SECURITY.md](../SECURITY.md). |
| VM-04.01 Published vulnerability data | Met | GitHub Security Advisories on this repository. None published to date. |

## Level 3

| Control | Status | Evidence |
|---|---|---|
| AC-04.02 Minimum job permissions | Met | Every job runs with `contents: read` only. |
| BR-01.04 Trusted input is sanitized in CI | Met | `workflow_dispatch` takes no inputs. |
| BR-02.02 Assets tied to a release identifier | N/A | No release. |
| BR-07.02 Secrets policy | Met | [SECURITY.md](../SECURITY.md), "Secrets and credentials". |
| DO-03.01 Verifying release integrity | N/A | No release. |
| DO-03.02 Verifying release author identity | N/A | No release. |
| DO-04.01 Support scope and duration | N/A | No release. [SECURITY.md](../SECURITY.md) states that only `main` is supported. |
| DO-05.01 End of security updates | N/A | No release. |
| GV-04.01 Review before granting access | Met | [GOVERNANCE.md](../GOVERNANCE.md), "Granting access". |
| QA-02.02 SBOM with compiled assets | N/A | No release and no compiled assets. |
| QA-04.02 Subprojects are as strict | N/A | No subprojects. |
| QA-06.02 When and how tests run | Met | [CONTRIBUTING.md](../CONTRIBUTING.md), "Build and test". |
| QA-06.03 Major changes update tests | Met | [CONTRIBUTING.md](../CONTRIBUTING.md), "What an acceptable contribution looks like". |
| QA-07.01 Non-author approval before merge | **Gap** | The project has one maintainer, so no second person can approve. Every change still needs a pull request and passing checks. Closes when a second maintainer joins ([GOVERNANCE.md](../GOVERNANCE.md)). |
| SA-03.02 Threat model | N/A | No release. |
| VM-04.02 VEX for non-affecting vulnerabilities | Met | Justified suppressions in [.trivyignore.yaml](../.trivyignore.yaml); policy in [SECURITY.md](../SECURITY.md). |
| VM-05.01 SCA remediation threshold | Met | [SECURITY.md](../SECURITY.md). |
| VM-05.02 SCA violations fixed before release | Met | [SECURITY.md](../SECURITY.md). |
| VM-05.03 Automated dependency evaluation blocks violations | Met | Trivy in the required `check` job. |
| VM-06.01 SAST remediation threshold | Met | [SECURITY.md](../SECURITY.md). |
| VM-06.02 Automated SAST blocks violations | Met | shellcheck and Trivy misconfiguration scanning in the required `check` job. CodeQL default setup scans the workflows, and ruleset `main` blocks a merge on a high-severity alert. |
