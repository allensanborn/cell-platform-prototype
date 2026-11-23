# Governance

This is a single-maintainer project.

## Who has access

| Person | GitHub | Role | Access to sensitive resources |
|---|---|---|---|
| Allen Sanborn | [@allensanborn](https://github.com/allensanborn) | Maintainer | Repository admin: settings, branch rules, CI configuration, merges, security advisories |

No one else has write access.

## Roles

- **Maintainer.** Reviews and merges pull requests, triages issues, answers security reports within the times in [SECURITY.md](SECURITY.md), and owns the repository settings.
- **Contributor.** Anyone who opens an issue or a pull request. Contributors work from forks and have no write access. [CONTRIBUTING.md](CONTRIBUTING.md) describes the process.

## Granting access

Before anyone is given write or admin access, the maintainer reviews them: they have a history of merged contributions here, and their GitHub account uses two-factor authentication. Access starts at the lowest role that does the job (triage, then write), and the change to this file lands in a pull request before the permission is granted.

## Codebases

The project is this one repository. It has no subprojects.

## Known gap

A second person does not approve changes before merge, because the project has one maintainer. Every change still goes through a pull request with passing CI. This gap closes when a second maintainer joins.
