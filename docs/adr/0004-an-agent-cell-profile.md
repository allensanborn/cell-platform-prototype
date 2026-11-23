# 4. A cell profile for AI agent workloads

Status: proposed, 2026-11-23. Not built. Blocked on a scope decision: this repo is an outside assessment of one published platform, and this ADR goes beyond that.

## Context

A cell gives a tenant a boundary it cannot change and a declared way in and out. That is most of what OpenAI's reference architecture for supervised investigations (2026-11-09, [excerpts](../../sources/raw/openai-daybreak-red/supervision-controls.md)) calls an isolated investigation environment. The guide asks for two more things that a plain cell does not have:

- a log store outside the agent's control, holding what the agent did and which requests reached its targets;
- a preflight that proves each fence with one allowed and one forbidden attempt before work starts.

An agent workload also differs from a service in one way that matters to the fences: its outbound calls are chosen by a model at run time, so a declared-dependency list is a weaker description of what it will try.

## Decision (proposed)

`spec.profile: agent` on a Cell changes what the Composition renders:

- **South:** egress only to a named model gateway. No ServiceEntry for any third party is granted to the cell directly; third-party calls go through the gateway, which holds the credentials (the kgateway `secretRef` injection in `docs/prototype-results.md`, "kgateway egress credential injection", is the same pattern).
- **Telemetry:** waypoint access logs and policy-drop counters for the cell are written to a platform namespace. The tenant has no write or delete on that store.
- **Conformance on a schedule:** the cell's fence probes (ADR 0002) run periodically, and a failed or stale probe suspends the cell (ADR 0003).

The default profile is unchanged.

## Alternatives considered

- **No profile; agents are ordinary tenants.** True for network fences. It leaves telemetry in the tenant's reach and the fences proven only at promotion.
- **A separate `AgentCell` kind.** Two compositions to keep in step. A profile is one branch in one template.
- **Sandbox runtime per profile** (gVisor or a microVM runtime class). A real control, but it is a node concern, not a cell one. Leave it to the cluster.

## Consequences

- The platform now runs a log store and is responsible for its retention.
- Automatic suspension on a stale probe can take a healthy cell down when the probe itself breaks. Start with an alert only, and turn on suspension after the probe has been quiet for a soak.
- Nothing about this has been tested. It needs the full Crossplane cell (plan Phase 1), conformance (Phase 2) and suspension (Phase 3) first.
