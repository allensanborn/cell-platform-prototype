# Cell platform prototype

Hands-on evaluation, November 2026, of how a shared internal developer platform shaped like the New York Times' DVSP could stamp out *cells* (per-team namespaces, network fences, gateway attachment, data stores in team cloud accounts) without platform changes riding on tenant merges.

**Outcome:** Crossplane alone, not Kratix, Radius or OpenChoreo, delivered by an existing Argo CD hub with per-environment revision channels, plus a tenant-proof fence for each traffic direction. The reasoning is in [docs/recommendation.md](docs/recommendation.md) and every test is in [docs/prototype-results.md](docs/prototype-results.md).

## Layout

| Path | What |
|---|---|
| [docs/decision-memo.md](docs/decision-memo.md) | One-page decision memo: problem, decision, evidence, fence stack, rejected options, risks |
| [docs/recommendation.md](docs/recommendation.md) | The decision: Crossplane alone, the fence stack, rejected options, risks, owner decisions |
| [docs/prototype-results.md](docs/prototype-results.md) | Results of seven test rounds on kind, k3d and floci, with negative controls |
| [docs/](docs/) | The comparisons behind the decision: Kratix, Radius, OpenChoreo and Crossplane, and cell north/south/east/west traffic tooling |
| [docs/sources/](docs/sources/) | Summaries of the primary sources (project docs, code, GitHub issues) |
| [sources/raw/](sources/raw/) | Verbatim captures of those sources, each with `resource`, `fetched` and `fetch_note` provenance |
| [prototype/](prototype/) | Manifests and scripts to reproduce every test; [prototype/README.md](prototype/README.md) gives the order |
| [upstream/](upstream/) | Text of the bug report and fix PR filed against provider-upjet-aws |

## Reproducing

You need Docker, `kind`, `k3d`, `kubectl`, `helm`, `gh`, the AWS CLI and Go. Every test runs locally:

- kind with Cilium 1.20.4 and Istio 1.32.0 ambient;
- k3d for OpenChoreo v1.3.3 and as a second workload cluster;
- [floci](https://floci.io/) as the AWS emulator.

Start with [prototype/README.md](prototype/README.md). Two rules that cost time when skipped:

- **Fence provider egress before any Crossplane AWS test against an emulator** (`prototype/kind/provider-egress-fence.yaml`). provider-aws-rds v2.8.1 sent role-assumption STS calls to real AWS until that was fixed.
- **Turn on floci IAM enforcement** (`FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`) for any trust-policy test. Without it, an untrusted account can assume any role.

Round 6 uses only public, Apache-2.0 Terraform modules (Cloud Posse `terraform-aws-dynamodb` and `terraform-aws-modules/rds`). Both are referenced, not vendored.

## Upstream contributions

- Bug: [crossplane-contrib/provider-upjet-aws#2328](https://github.com/crossplane-contrib/provider-upjet-aws/issues/2328). `assumeRoleChain` (and WebIdentity) STS calls ignore `spec.endpoint` and go to the public STS endpoint.
- Fix: [crossplane-contrib/provider-upjet-aws#2329](https://github.com/crossplane-contrib/provider-upjet-aws/pull/2329), from branch `fix-assume-role-chain-endpoint` of [allensanborn/provider-upjet-aws](https://github.com/allensanborn/provider-upjet-aws). It installs the endpoint resolver before the role chain is built, carries it into each link, and applies it on the WebIdentity path. It adds `internal/clients/role_chain_endpoint_test.go`.
- Workaround until it ships: set `AWS_ENDPOINT_URL_STS` on the provider pod with a DeploymentRuntimeConfig (`prototype/kind/provider-sts-endpoint.yaml`).

## Provenance and limits

Primary sources were captured 2026-11-13 to 2026-11-17; versions are pinned in each capture's header. Nothing here ran at production scale or against real AWS. Claims that weren't confirmed are marked **UNVERIFIED**, and inferences are labelled.
