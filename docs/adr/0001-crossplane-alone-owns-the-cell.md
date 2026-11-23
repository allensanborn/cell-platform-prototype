# 1. Crossplane alone owns the cell

Status: accepted, 2026-11-17. Recorded here on 2026-11-23 from `docs/decision-memo.md` and `docs/recommendation.md`, which remain the full argument.

## Context

On a platform whose contract with each service is one versioned Helm chart, a platform change reaches a running service only when that team merges a chart bump. The question was which tool should own the cell so that a platform change reaches every cell at once, in a staged order, with fences a tenant cannot weaken.

## Decision

- A cluster-scoped `Cell` composite resource in Crossplane is the contract. The platform writes it; tenants do not.
- The existing Argo CD hub ships each `Cell` to every workload cluster, and the Crossplane on that cluster renders it.
- Each environment's cells select a Composition revision by `channel` label: `dev` in dev, `stable` elsewhere.
- Data stores in team accounts are XRDs in the same Crossplane.
- The Helm chart stays the workload contract for now.

## Alternatives considered

Kratix, Radius, OpenChoreo, mutating admission, and one control cluster composing remotely. Each was tested or read against primary sources; the reasons are in the decision memo's "Rejected options".

## Consequences

- Composition functions become platform code to own.
- Revision pins live on the XR. That is safe only while the platform is the sole writer of Cell XRs.
- **Open:** the tested Crossplane composition renders a Namespace and the east fence only. West and north were rendered by the Kratix Promise. The full cell in Crossplane is the first item of `docs/plans/2026-11-extension-plan.md`.
