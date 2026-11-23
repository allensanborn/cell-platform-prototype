# 3. The platform can suspend a cell

Status: proposed, 2026-11-23. Not built.

## Context

Every fence is owned by the platform in a place tenants cannot write. There is still no way to stop one cell. During an incident the choices are to delete the Cell, which removes its namespaces, or to hand-write deny policies under pressure.

OpenAI's reference architecture for supervised investigations (2026-11-09, [excerpts](../../sources/raw/openai-daybreak-red/supervision-controls.md)) treats this as a precondition for running an AI agent at all: the operator must be able to stop the agent or cut its access from outside it, and must have verified that before the first run.

## Decision (proposed)

- The `Cell` schema gains `spec.suspended` (boolean, default false).
- When true, the Composition renders deny rules in all four directions for that cell: no ListenerSet attachment (north), a waypoint policy that admits nobody (west), and a cluster-scoped deny of all egress from the cell's namespaces except DNS (east and south).
- Namespaces, workloads, data stores and the cell's other objects are left in place.
- The platform sets the field in Git like any other Cell change. On the cluster, the local Crossplane applies it.

## Alternatives considered

- **Delete the Cell.** Destroys state and the evidence.
- **Scale the tenant's workloads to zero.** The tenant owns its workloads and can scale them back.
- **A separate `CellSuspension` resource.** A second object to keep consistent with the first. One field is enough.

## Consequences

- Suspension takes one Git commit plus one Argo CD sync plus one reconcile. The local repair time measured in round 5 was about 10 seconds; the sync interval is the slow part. An emergency path that sets the field directly on the cluster will be overwritten by the next sync unless Git follows.
- A suspended cell still holds its cloud resources and still costs money.
- Sidecar-mode workloads bypass the ambient waypoint (tested, round 3), so the cluster-scoped egress deny is what stops them, not the waypoint policy.
- Proof, in the conformance suite: suspend a probe cell; all four meant paths are dropped while a second cell's still succeed; clear the field; they succeed again.
