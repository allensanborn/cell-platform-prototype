---
type: comparison
title: "Kratix in a DVSP-shaped platform: release train, cells and Argo CD"
description: "Fit analysis of Syntasso Kratix (OSS rolling 'latest', SKE v0.63, Nov 2026) for an NYT-DVSP-shaped platform, alongside Radius, Crossplane and OpenChoreo. Floating Resource Bindings push a Promise change to every request with no tenant merge, which is the release-train fix NYT wants; staged rollout (UpgradePlan/UpgradeRun) is enterprise-only. Requests are plain CRDs, so Gatekeeper and kubectl explain work; Argo CD is documented but only single-cluster with no ordering. No cell or network Promises exist; a Cell Compound Promise is buildable."
tags: [kratix, syntasso, ske, platform-orchestration, golden-path, nytimes, cell-based-architecture, argo-cd, crossplane, radius, openchoreo, comparison, decision]
timestamp: 2026-11-16T00:00:00Z
---

# Kratix in a DVSP-shaped platform

Written 2026-11-13 in answer to: *research Syntasso Kratix for usage in this scenario*. The scenario is the one in [radius-in-nyt-dvsp](radius-in-nyt-dvsp.md) and [openchoreo-cells-radius-crossplane](openchoreo-cells-radius-crossplane.md): NYT's paved path is one versioned Helm chart, so "platform changes still ride on tenant merges", and this write-up is looking for a contract layer that can also stamp out cells ([cell-traffic-nsew-tooling](cell-traffic-nsew-tooling.md)). Evidence: [Kratix docs captured 2026-11-13](sources/kratix-docs-upgrades-gitops-tenancy.md) plus the earlier kratix sources. Verdicts are this page's assessment. Kratix was not installed for the original analysis; it was later tested on kind ([prototype-results](prototype-results.md)).

**OSS vs SKE matters throughout.** Open-source Kratix is Apache-2.0. **SKE** (Syntasso Kratix Enterprise) is the commercial distribution: "Syntasso Kratix Enterprise (SKE) is the enterprise distribution of Kratix."

## The release-train question: answered better than any option so far

- **Every request floats to the latest Promise by default.** "By default, Kratix associates new resource requests to the `latest` Promise Revision. When a new revision is created those resources will be automatically upgraded." Each request gets one **Resource Binding**, and the default strategy is `floating`. A resource configure workflow "runs when the Resource is created, updated or reconciled, or when the parent Promise is updated". **So a platform change reaches every existing request with no tenant PR.** That is the fix NYT's lesson asks for, and it is documented. Radius (no: next deploy only) and OpenChoreo (partial: autoDeploy to the first environment) were both answered on 2026-11-16.
- **Pinning is open source.** With `resourceBindingVersionStrategy: pinned`, "later Promise upgrades do not automatically flow through to the Resource". A request is moved by editing `ResourceBinding.spec.version`. "There is no field on the Resource Request itself to ask for a different version", so the version choice belongs to the platform, not the tenant.
- **Staged rollout is SKE.** `UpgradePlan` / `UpgradeRun` provide:
  - ordered groups selected by labels such as `env: dev` → staging → prod;
  - `maxConcurrent`, and stop on first failure ("the run stops and the remaining groups are not processed");
  - maintenance windows, cron schedules and dry-run;
  - health-check gating, from SKE v0.63.0 with the SKE Health Agent.

  This requires pinned bindings. In open source, the docs' own SKE upsell says: "Editing bindings one at a time works for a handful of Resources, but it does not scale to a fleet."
- **Dependencies always move.** "Destinations are always on the latest installed Promise Revision", so cluster-level dependencies a Promise installs can't be held back per environment. Only per-request output can be.
- **Two sharp edges:**
  - A Promise edited *without* bumping its version label updates that revision in place and re-runs every bound request immediately, **pinned or floating**. **Tested 2026-11-16** ([prototype-results](prototype-results.md)): three floating Cell requests re-ran within a second of the edit, with no new revision. Treat the version label as mandatory, or an edit becomes an unstaged fleet-wide rollout.
  - `latest` means most recently installed, not highest semver: "Kratix _does not take_ semantic versioning into account".

**What that means for NYT.** Floating bindings are the tenant-merge-free path. NYT's 2022 lesson, "opt-in resilience protects only the services that opt in", argues against floating for everything, though. Open-source pinning plus a platform-owned script that patches bindings by environment label rebuilds a minimal UpgradePlan. That script is the platform team's to write and own; buying SKE avoids it.

## Fit against NYT's stack

| Concern | Kratix | Notes |
|---|---|---|
| API surface | **Plain CRD.** A Promise's `spec.api` is an `apiextensions.k8s.io/v1` CRD; requests are namespaced CRs | Gatekeeper, Kyverno, `kubectl explain` and RBAC all apply. Kratix registers webhooks only for its own kinds, never for requests. Business rules run *after* admission, in pipelines |
| GitOps (tested 2026-11-16 with Argo CD v3.5.7 + Gitea over SSH: works; see the prototype page) | Kratix writes to a State Store (Git or bucket) under `<destination>/dependencies/` and `<destination>/resources/`; any agent reconciles | Flux guide has `dependsOn` ordering. **Argo CD guide is two plain Applications, single cluster, no ordering.** Hub-and-spoke with ApplicationSets (NYT's shape) would be built by the platform team; a Git-directory generator over `*/dependencies` and `*/resources` is the obvious design (inference) |
| Multi-cluster placement | Destinations with labels; `destinationSelectors` | First placement sticks: "If an update to a Resource changes its scheduling, the change will be **ignored**". Moving a request means recreating it |
| Implementation language | Any container in a pipeline | Pipelines can emit Crossplane claims, Terraform files for an external runner, or Helm output (`kratix init helm-promise` is "Preview… not supported under SLAs") |
| Status back to tenants | Pipeline writes `/kratix/metadata/status.yaml`; `ConfigureWorkflowCompleted` condition | The workflow finishes once files are written, so downstream apply failures (Terraform, Argo sync) don't show in the request unless something reports back. SKE has TF State Finder and the Health Agent |
| Portal | DIY in open source (pipeline writes Backstage catalog entities) | The supported Backstage/Port/Cortex integration is SKE |
| Drift | Reconcile every 10 h by default; per-Promise or per-revision override; `kratix.io/reconcile-resources` label forces a fleet-wide re-run | Unchanged outputs aren't re-written if deleted from Git (docs issue #254, earlier capture) |
| Maturity | Not a CNCF project (landscape listing only); 791 stars | **Open source ships a rolling `latest` release with no semver tag since v0.125.0 (2024-07-08).** There's nothing to pin the controller to; SKE is versioned (v0.63.0, 2026-10-29). No adopters list found |

## Kratix and cells

Kratix has no tenancy or cell concept of its own: "Kratix does not introduce a custom multi-tenancy layer." Its docs point to namespaces, ResourceQuotas, NetworkPolicies and RBAC.

- The marketplace has a bare `namespace` Promise (Namespace only), a ref-counted `namespace-claim` with a documented race, and an `istio` Promise that installs sidecar-mode Istio.
- **No Promise exists for network policy, gateways, quotas or cells.**

A **`Cell` Compound Promise** is the natural build (inference). Its pipeline would emit, per [cell-traffic-nsew-tooling](cell-traffic-nsew-tooling.md)'s mapping:

- Namespace + quota + LimitRange;
- ambient enrollment and a waypoint, plus a ztunnel "waypoint only" policy;
- a CCNP allow-list generated from the cell's declared dependencies;
- a ListenerSet or route admission label;
- egress ServiceEntry requests;
- an Argo CD AppProject;
- sub-requests to a `Postgres` or other data-store Promise in the team account.

Because the binding is floating or pinned per cell, tightening the egress baseline is a Promise version bump that reaches every cell, or a staged run in SKE. That is the release-train property applied to the network boundary. **Kratix's limit here:** a Promise generates objects; it does not enforce traffic. The fences in the traffic page still come from Cilium, Istio and Gatekeeper.

## Where Kratix sits among the options

| | Contract split | Platform change reaches running requests | Cells | Kubernetes-API native | Argo CD |
|---|---|---|---|---|---|
| Crossplane | XRD + Composition | Yes, `compositionUpdatePolicy: Automatic`; revisions and channels for staging (open source) | Build it | Yes | Yes |
| Radius | Resource Type + Recipe Pack | **No**: a pack change "affects subsequent deployments"; recipes run only on each resource's PUT (v0.62 code, 2026-11-16) | No | No (aggregated API) | Not yet |
| OpenChoreo | ComponentType/Trait | **Partial**: Releases freeze the template; with `autoDeploy: true` (default false) a template edit cuts a new Release and repoints only the first environment (v1.3.3 code, confirmed live on k3d) | Yes (Project → Cell, mostly policy) | Yes | Flux by default; external Argo CD tested, needs `ignoreDifferences` on `/spec/releaseName` |
| **Kratix** | Promise API + pipeline | **Yes, floating by default; staged rollout is SKE** | Build it (Compound Promise) | Yes | Documented, single-cluster example |

**Kratix vs Crossplane.** Kratix's own docs present them as complementary: "Kratix does not aim to compete with Crossplane on cloud orchestration". Kratix adds an imperative pipeline (scans, billing, approvals, generating many objects with logic), multi-cluster placement, and GitOps output. Crossplane adds continuous reconciliation of cloud resources and open-source staged rollout through Composition revision channels. A common pairing is a Kratix Promise whose pipeline emits Crossplane claims.

**Revised 2026-11-16 after testing both on kind** ([prototype-results](prototype-results.md)): Crossplane 2.4.2 matched Kratix on pushing a change to every XR, and beat it on open-source staged rollout (revision channels) and on safety (every edit is a new immutable revision, while Kratix re-ran every request on an unversioned edit). [recommendation](recommendation.md) now recommends **Crossplane alone for the cell and data stores**, keeping Kratix for a later Git-placed or procedural need. The original assessment follows.

**Assessment.** For the NYT problem, Kratix's floating bindings answer the release-train question most directly and with the clearest documentation. Its weaker points for an Argo CD hub-and-spoke shop are three:

- the GitOps wiring is DIY;
- open source has no versioned releases;
- staged rollout costs SKE or a home-grown binding-patcher.

Crossplane keeps staged rollout in open source but needs composition-function code for anything procedural. (Superseded the same day by the tested comparison above.) The original split was: **Crossplane for cloud resources in team accounts, Kratix Promises as the tenant-facing API (Cell, App, Database) that compose them.** Choose Kratix alone if the procedural pipeline is the main need, and Crossplane alone if the platform team wants one controller and open-source staging, which is what the tests favoured.

## Open questions

- ~~Does editing a Promise without a version bump re-run every request bound to that version?~~ Yes for floating bindings (tested 2026-11-16, [prototype-results](prototype-results.md)); pinned bindings re-run too (round 2 of the same test).
- ~~Does the Argo CD ordering gap matter in practice?~~ Tested with Argo CD v3.5.7 ([prototype-results](prototype-results.md)): with the dependencies app stalled, the resources app failed (`… not found`) and retried by itself, recovering about 30 s after the CRD landed. The gap is a delay, not a stuck app, on that version. Sync waves or an explicit `retry` policy make it deterministic.
- Is the `syntasso/helm-charts` chart (`v0.0.1`, last changed 2024-07) still a supported install path?
- Are there adopters or production references beyond Syntasso's own material?

Related: [recommendation](recommendation.md), [prototype-results](prototype-results.md), kratix, company syntasso, platform orchestration, crossplane, radius, golden path, argo cd, flux, cell based architecture, [cell-traffic-nsew-tooling](cell-traffic-nsew-tooling.md), [openchoreo-cells-radius-crossplane](openchoreo-cells-radius-crossplane.md), [radius-in-nyt-dvsp](radius-in-nyt-dvsp.md), [kratix-docs-upgrades-gitops-tenancy](sources/kratix-docs-upgrades-gitops-tenancy.md), [nytimes-dvsp-developer-platform](sources/nytimes-dvsp-developer-platform.md).
