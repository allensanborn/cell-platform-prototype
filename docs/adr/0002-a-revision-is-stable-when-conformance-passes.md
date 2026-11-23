# 2. A revision becomes `stable` when conformance passes on dev

Status: proposed, 2026-11-23. Not built.

## Context

Cells move by channel: a Composition revision is labelled `dev`, then `stable` after a soak (ADR 0001). The decision memo leaves open how long the soak is. A duration alone says nothing about whether the revision kept the fences: in the tests, a missing west policy let three bypasses return 200, and Argo CD showed Healthy while an XR was not Ready until a custom health check was added. A revision can sit in dev for a week, look healthy, and have an open fence.

## Decision (proposed)

- `conformance.sh <cell>` checks each of the four directions with a pair: the meant path succeeds and the bypass is dropped. It exits non-zero on any miss, including an allow that fails.
- `promote.sh` is the only thing that labels a revision `stable`. It runs conformance against every dev-channel cell, requires a minimum soak since the revision was created, then changes the label in Git and pushes.
- A person may still relabel by hand. That is a Git commit with their name on it.

## Alternatives considered

- **A fixed soak time only.** Measures patience, not fences.
- **Argo CD health as the gate.** Health means the objects exist and report Ready. It does not mean traffic is dropped.
- **A progressive-delivery controller.** More machinery than one label change needs. Revisit if there are more than two channels.

## Consequences

- The soak question becomes two smaller ones: the minimum time, and which cells count as the dev sample.
- Conformance needs probe workloads in every dev cell, or a dedicated probe cell per cluster. A probe cell is simpler and tests the template, not each tenant's instance of it.
- The promotion script holds push rights to the platform repository. It runs in CI, not on a laptop.
- Proof: a revision whose template omits the west policy fails `promote.sh` and stays `dev`, beside a correct revision that is promoted.
