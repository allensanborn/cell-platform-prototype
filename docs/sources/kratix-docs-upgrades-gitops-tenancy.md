---
type: source
title: "Kratix docs (Nov 2026): Promise upgrades, resource workflows, GitOps agents, multi-tenancy, SKE"
description: "Thirteen Kratix pages captured 2026-11-13 from syntasso/kratix-docs main@169418223c15 (plus one marketplace README): Promise Revisions and Resource Bindings (floating by default, pinned optional), the SKE UpgradePlan/UpgradeRun staged rollout, resource configure workflows re-running on parent-Promise update, status reporting, the Argo CD and Flux agent guides, the 'no custom multi-tenancy layer' page, and SKE release notes."
resource: https://docs.kratix.io/main/reference/promises/promise-upgrade/promise-revisions
tags: [kratix, syntasso, ske, promise-revisions, resource-bindings, upgrades, gitops, argo-cd, flux, multi-tenancy]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "verbatim MDX source via gh api repos/syntasso/kratix-docs (main@169418223c15), 2026-11-13; each raw keeps the doc's own frontmatter under ours. Three resource URLs (resource-updates, multi-tenancy, config reference) are inferred from the docs path pattern, not opened as rendered pages."
---

# Kratix docs: upgrades, GitOps, tenancy (Nov 2026)

Captured 2026-11-13 for [kratix-in-nyt-dvsp](../kratix-in-nyt-dvsp.md); extends the earlier kratix sources (first Promise, Promise workflows, Destinations, Compound Promises). Raw files:

- `../../sources/raw/kratix/kratix-promise-revisions.md`
- `../../sources/raw/kratix/kratix-resource-bindings.md`
- `../../sources/raw/kratix/kratix-upgrading-a-promise-guide.md`
- `../../sources/raw/kratix/kratix-config-reference.md`
- `../../sources/raw/kratix/kratix-ske-promise-upgrades-guide.md`
- `../../sources/raw/kratix/kratix-resource-workflows-reference.md`
- `../../sources/raw/kratix/kratix-resource-updates.md`
- `../../sources/raw/kratix/kratix-resource-status.md`
- `../../sources/raw/kratix/kratix-gitops-argocd-guide.md`
- `../../sources/raw/kratix/kratix-gitops-flux-guide.md`
- `../../sources/raw/kratix/kratix-multi-tenancy.md`
- `../../sources/raw/kratix/kratix-ske-release-notes.md`
- `../../sources/raw/kratix/kratix-marketplace-namespace-claim.md`

## Promise Revisions and Resource Bindings (open source)

- A **Promise Revision** snapshots `promise.spec` (API, dependencies, workflows, selectors) at the version in the `kratix.io/promise-version` label. Re-applying the same version updates that revision in place: "If a Promise is updated, but the version already has a Promise Revision associated with it, the existing Promise Revision will be updated." `latest` is the most recently installed revision: "Kratix _does not take_ semantic versioning into account when applying the `latest` label."
- Each request gets one **Resource Binding**, created automatically "using `latest` as the Promise version". "There is no field on the Resource Request itself to ask for a different version"; pinning at creation means creating the Binding first, and creating both leaves "two Bindings for the same Resource, which is an error."
- Config: "`floating` (default): new Resource Bindings are set to `latest`." "`pinned`: … later Promise upgrades do not automatically flow through to the Resource."
- Guide: "By default, Kratix associates new resource requests to the `latest` Promise Revision. When a new revision is created those resources will be automatically upgraded." "Destinations are always on the latest installed Promise Revision." API changes: "Changes to the API are left to Kubernetes"; breaking ones need "a new API group and adding a conversion webhook".

## SKE staged upgrades

`UpgradePlan` and `UpgradeRun` (`platform.syntasso.io/v1alpha1`) roll a new Promise version out in ordered groups selected by labels copied onto bindings. They support `maxConcurrent`, maintenance windows, cron schedules, a `suspend: true` dry-run and (from SKE v0.63.0) health-check criteria. "This process only works when Resource Bindings are **pinned**"; "if any resource in a group fails to upgrade, the run stops and the remaining groups are not processed." SKE release notes: v0.63.0 on 2026-10-29, v0.62.0 on 2026-10-16.

## Resource workflows, updates and status

- "The `configure` workflow runs when the Resource is created, updated or reconciled, or when the parent Promise is updated." The default reconcile is 10 hours, overridable per Promise (`spec.workflows.config.reconciliationInterval`) or per revision (annotation, minimum `1m`).
- Updates: "Any files which are output by this workflow will replace all existing files associated with this Resource in the StateStore." "If an update to a Resource changes its scheduling, the change will be **ignored**." "This workflow runs against the Promise Revision the Resource is currently bound to."
- Status: pipelines "send information about the Resource back to the resource requester by writing information to `/kratix/metadata/status.yaml`"; a `ConfigureWorkflowCompleted` condition supports `kubectl wait`.

## GitOps agents

- **Argo CD:** "ArgoCD can be used as the GitOps agent for Kratix." It recommends two `Application`s, "one for the dependencies … and one for the resources", with automated sync, prune and self-heal, against `https://kubernetes.default.svc` in the `default` project. There is no ordering between the two and no multi-cluster or ApplicationSet guidance.
- **Flux:** a `GitRepository` or `Bucket` source and two `Kustomization`s; the resources one has `dependsOn: kratix-workload-dependencies`.

## Multi-tenancy and marketplace

- "Kratix does not introduce a custom multi-tenancy layer." Teams should "combine namespaces with Kubernetes features like ResourceQuotas and NetworkPolicies to enforce limits and isolation per team"; "Kratix Promises can create namespaced CRDs and therefore resource requests … will be namespaced."
- Marketplace `namespace-claim`: "many consumers request the *same* shared namespace, and the namespace is created once and deleted only when the **last** claim is gone"; "Recovery is not automatic".

## Read but not saved as raw (from the research agent's report)

- `kratix-and-crossplane`: "Kratix does not aim to compete with Crossplane on cloud orchestration".
- `kratix-and-terraform`: pipelines emit `.tf` for an external runner; outputs-to-status is SKE.
- Reconciliation labels (`kratix.io/reconcile-resources`).
- GitHub release metadata: OSS ships a rolling `latest` release; the last semver tag is v0.125.0 (2024-07-08).
- CNCF landscape entry with no `project:` field.

These are cited on [kratix-in-nyt-dvsp](../kratix-in-nyt-dvsp.md) with that caveat.

Related: kratix, company syntasso, [kratix-in-nyt-dvsp](../kratix-in-nyt-dvsp.md), platform orchestration, argo cd, flux, kubernetes multi tenancy.
