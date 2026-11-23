# Security policy

## Report a vulnerability

Report a suspected vulnerability privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**, or go straight to <https://github.com/allensanborn/cell-platform-prototype/security/advisories/new>. Do not open a public issue for it.

The security contact is the maintainer, Allen Sanborn ([@allensanborn](https://github.com/allensanborn)). The private report form reaches the maintainer directly.

## What happens next

This is a single-maintainer project, so responses are best effort. The maintainer acknowledges a report when possible and gives no fixed time for a fix.

One time is fixed: a reported vulnerability is disclosed publicly no later than 90 days after the report, whether or not a fix exists. Disclosure is earlier when a fix is ready, or on a date agreed with you. Confirmed vulnerabilities are published as [GitHub Security Advisories](https://github.com/allensanborn/cell-platform-prototype/security/advisories) on this repository, with credit to the reporter unless you decline it.

## Supported versions

The project has made no release. Only the head of `main` is supported, and fixes land there. If the project starts making releases, this section will state how long each release is supported and when it stops receiving security updates.

## Scope

The manifests and scripts in `prototype/` build local test clusters (kind, k3d, floci). They are evidence for the write-ups in `docs/`, not a hardened deployment. A weakness that only exists because a test cluster is deliberately open is not a vulnerability. A committed credential, or a CI weakness, is.

## Secrets and credentials

- **Storage.** No real secret or credential is committed. The test clusters use throwaway values only: passwords that the scripts generate at run time, and placeholder keys (`test`) for the local AWS emulator. The repository has no GitHub Actions secrets.
- **Detection.** GitHub secret scanning and push protection are on. CI runs gitleaks over the full history and Trivy's secret scanner on every pull request.
- **Access.** Only the maintainer can read or change repository settings and secrets.
- **Rotation.** A credential that reaches a commit, a log or an issue is revoked at its issuer the same day. Removing it from history is not enough. Any long-lived credential added later is rotated at least once a year and recorded in this section.

## Dependency and static-analysis findings

CI evaluates every pull request and blocks the merge on a violation.

- **Dependencies (SCA).** Trivy scans for known-vulnerable dependencies. A HIGH or CRITICAL finding that has a fix blocks the merge. One found on `main` after the fact is fixed within 90 days, and before any release. A dependency must carry a license compatible with Apache-2.0.
- **Static analysis (SAST).** shellcheck (warnings and errors), Trivy's misconfiguration scanner and GitHub CodeQL (over the workflows) run on every pull request. A shellcheck warning, a HIGH or CRITICAL misconfiguration, or a CodeQL alert of high severity or above blocks the merge, and one found on `main` is fixed within 90 days.

## Findings that do not affect the project

A finding that is not exploitable here is suppressed in [`.trivyignore.yaml`](.trivyignore.yaml), scoped to the file it applies to, with a statement of why. A suppression without a statement is not accepted in review. If the project makes a release, those statements ship with it as an OpenVEX document.
