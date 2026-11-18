# Cell Platform Decision

Nov 16, 2026 · Allen Sanborn

## Problem

On a DVSP-shaped platform, platform changes ride on tenant merges. The service contract is one versioned Helm chart, so a platform change reaches a running service only when its team merges a chart bump. NYT's ambient-mesh migration waited on exactly that, and Renovate shortens the wait without removing it.

This memo decides two things: which tool holds the platform-owned templates for the **cell** (a team's namespaces, network fences, gateway attachment and egress grants) and for **data stores**, and how each cell's four traffic directions are fenced. Workloads stay on the Helm chart for now. It is this write-up's assessment of NYT's published setup (Argo CD hub-and-spoke, Gatekeeper, Cilium, Istio ambient, a Kubebuilder Tenant Operator), not NYT's plan.

## Decision

Use **Crossplane alone** for the cell and data stores, and keep the Helm chart for workloads.

1. The platform writes a cluster-scoped `Cell` XR into Git on the account-created event, replacing the `Tenant` the Tenant Operator reconciles today.
2. Argo CD's existing hub ships Cell XRs to each workload cluster through an ApplicationSet. Crossplane on each cluster renders them.
3. Each environment's XRs follow a Composition revision channel: dev takes every revision; prod takes only revisions labelled `stable`. A template change reaches every cell with no tenant PR, in a staged order.
4. Data-store XRDs sit in the same Crossplane, provisioning into team accounts. Tested against a local AWS emulator: a platform-owned ProviderConfig per team namespace put each team's Postgres in its own account only, and existing public Terraform modules (Cloud Posse, terraform-aws-modules) ran behind the same pattern through provider-opentofu. The ProviderConfigs need no team keys: one platform identity assumes a role in each team account, whose trust policy names only the platform; an untrusted identity was refused (tested with the emulator's IAM enforcement on).
5. Workloads stay on the chart until revision channels have run for a quarter.

## Evidence

Crossplane 2.4.2 and Kratix (open-source `latest`) were tested on the same local clusters on 16 Nov 2026 (kind with Cilium 1.20.4 and Istio 1.32.0 ambient, plus a k3d cluster as a second workload cluster). Crossplane matched Kratix on the core need and beat it on staging and safety.

| Check | Kratix | Crossplane |
| --- | --- | --- |
| Template change reaches every tenant, no tenant PR | Yes | Yes (`Automatic`, the default) |
| Pin one tenant back | Yes (platform-owned binding) | Yes (`Manual` + revision ref on the XR) |
| Staged rollout in open source | No (paid SKE, or a script you write) | Yes: revision `channel` labels skipped `dev` and took the next `stable` |
| Edit without a version bump | Re-ran every request, pinned or floating, within 1 s | New immutable revision per edit; pins held |
| Release governance | Rolling `latest`, no semver since 2024; not CNCF | Semver releases; CNCF graduated |

**Hub and spoke.** One ApplicationSet shipped a Cell XR to two clusters. A Composition labelled `dev` moved only dev; relabelled `stable`, it then moved prod, all from Git. Both Argo CD apps stayed Synced and Healthy. A deleted fence object was recreated in about 10 s by the local Crossplane.

Full results: [prototype-results.md](prototype-results.md); manifests and rerun steps: [../prototype/](../prototype/).

## Fence stack

Every direction needs a path traffic is meant to take and a fence that drops traffic skipping it, placed where tenants can't write it. All four were tested with the fence removed as a control.

| Direction | Path | Fence | Tested result |
| --- | --- | --- | --- |
| North (internet → cell) | Shared regional gateway; one ListenerSet per public cell | Platform owns hostname allocation (Gatekeeper) | A duplicate hostname got `HostnameConflict`, first come first served |
| West (cells → cell) | The cell's ambient waypoint | ztunnel policy admitting only the waypoint; tenants get no write on Istio kinds | Without it, three bypasses returned 200 |
| East (cell → cells) | The destination's waypoint | Cluster-scoped Cilium allow-list per cell, from declared dependencies | A namespace admin couldn't delete it |
| South (cell → third parties) | Egress waypoint + ServiceEntries; kgateway injects API keys from a Secret | Admin-tier ClusterNetworkPolicy denying direct internet egress | Held after the tenant deleted its own policy |

Five settings the tests showed are required:

- `istio.io/ingress-use-waypoint` on public cells, or the west fence returns 503 to north traffic.
- `SkipDryRunOnMissingResource=true` on Cell XRs, or Argo CD's first sync to a fresh cluster fails.
- `ServerSideDiff=true` on Argo CD apps where Gatekeeper mutation overrides a Git-set field, or they stay OutOfSync and re-sync forever.
- `function-auto-ready` in every go-templating Composition, or cells and databases never report Ready.
- A custom Argo CD health check for the Cell and Database kinds; without one Argo showed Healthy while a cell was not Ready.

## Rejected options

| Option | Why not, here |
| --- | --- |
| Kratix | Crossplane matches its push-to-everyone and beats it on open-source staging, edit safety and releases. Revisit only for Git-placed output or container pipelines. |
| Radius | A Recipe Pack change reaches only later deployments, so a redeploy trigger remains. Admission never sees writes to its API (tested), and it is Flux-only. |
| OpenChoreo | It replaces the scaffolder, chart and Tenant Operator at once. External Argo CD fights its autoDeploy every 5 minutes unless told to ignore the binding's release name (tested). Its v1.3.3 code ships cells mostly as policy, with egress unrestricted. |
| Mutating admission as the release train | It fires only on create and update and creates nothing. It stays useful for small additions; overriding a Git-set field needs Argo CD server-side diff (tested). |
| One control cluster composing remotely | It works through provider-kubernetes, but it wraps every object and repairs drift by polling every 10 minutes by default, against about 10 s locally. |

## Risks and owner decisions

**Risks**

- Composition functions (go-templating, KCL or Go) become platform code to own; Crossplane's maintainers call complexity an adoption blocker.
- Revision pins live on the XR. That is safe while only the platform writes Cell XRs; if tenants ever author XRs, Gatekeeper must block edits to `spec.crossplane`.
- Cilium's ClusterNetworkPolicy is behind a flag, with no announced default-on date.
- Waypoints have no supported rate-limit API (istio#43720), so cross-cell quotas need per-replica limits or an external rate-limit service.
- Sidecar-mode workloads bypass the ambient egress waypoint (tested), so the Admin-tier deny is their only south fence.
- The AWS provider sends role-assumption calls to the public STS endpoint, ignoring its configured endpoint. In a local test this leaked rejected placeholder-key calls to real AWS. Set `AWS_ENDPOINT_URL_STS` where STS must go elsewhere, and fence provider egress in emulator tests.
- Nothing here ran at NYT scale.

**Decisions for the platform owner**

- How many revision channels, and how long a soak before a revision is labelled `stable`?
- Crossplane on every workload cluster (recommended), or one control cluster composing remotely?
- Is a cell a team (today's tenant) or a bounded context? That sets one Cell per tenant or several.
- Run Cilium's flag-gated ClusterNetworkPolicy in production now, or use cluster-wide Cilium deny rules until it is on by default?
