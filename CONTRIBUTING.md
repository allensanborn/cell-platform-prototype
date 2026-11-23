# Contributing

Contributions are welcome: corrections to a write-up, a failed reproduction, a new test round.

## Ask a question or report a defect

Open a [GitHub issue](https://github.com/allensanborn/cell-platform-prototype/issues). Issues are the public place to discuss a proposed change or a problem using the repo. For a defect, say which file or test round, what you ran, what you expected and what happened. Report a security problem privately instead; see [SECURITY.md](SECURITY.md).

## Propose a change

1. Fork the repository and create a branch.
2. Make the change. Keep one topic per pull request.
3. Sign off every commit (see below) and open a pull request against `main`.
4. CI must pass. The maintainer reviews and merges.

Direct pushes to `main` are blocked for everyone, the maintainer included.

## What an acceptable contribution looks like

- Every commit has a `Signed-off-by` line.
- CI passes: shellcheck, gitleaks, Trivy.
- A claim taken from documentation links to a verbatim capture under `sources/raw/`, and the capture records where it came from.
- A claim from a test comes with the manifest or script under `prototype/` that reproduces it. A major change to a manifest or script adds or updates the script that tests it and records the output under `prototype/results/`.
- No secrets, and no binaries or generated artifacts.
- A scanner finding is fixed, or suppressed with a written reason as [SECURITY.md](SECURITY.md) describes.

## Sign your work

This project uses the [Developer Certificate of Origin](https://developercertificate.org/). By signing off you certify that you wrote the change or have the right to submit it under the project's license. Add the line with `git commit -s`:

```
Signed-off-by: Your Name <you@example.com>
```

CI rejects a pull request that contains a commit without it.

## Build and test

There is nothing to compile. [prototype/README.md](prototype/README.md) lists the tools each test round needs and the order to run it in.

The automated checks run in CI on every pull request ([.github/workflows/ci.yml](.github/workflows/ci.yml)). To run them locally from the repository root:

```sh
git ls-files -z '*.sh' | xargs -0 shellcheck -S warning
gitleaks git --no-banner --redact .
trivy fs --scanners vuln,secret,misconfig --ignorefile .trivyignore.yaml --exit-code 1 --severity HIGH,CRITICAL .
```

The cluster test rounds in `prototype/` need local clusters and are run by hand. Their recorded output is in `prototype/results/`.

## Dependencies

The repository has no package manifest, because it ships no application code. Its dependencies are the tools and container images that the manifests and scripts name. Each is chosen because a test round needs it and is named in the manifest or script that uses it. [prototype/README.md](prototype/README.md) records the version each round was run with. A new manifest or script names an explicit version, not `latest`. CI tools are pinned by image digest or commit SHA in the workflow file.
