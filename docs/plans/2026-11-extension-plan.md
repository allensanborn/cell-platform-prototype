# Extension plan: from a decision to a platform that proves itself

Status: draft for review, 2026-11-23. Reviewed at `4cd516c`; the commits on `main` since then change policy and licence files only. Nothing here is built.

## Bottom line

The repo decided on Crossplane alone, and the evidence holds. But the recommended design has never run as one thing. The Crossplane composition that was tested renders a Namespace and the east fence only. The west and north objects were rendered by the Kratix Promise, which the repo then rejected. The first extension is to build the whole cell in Crossplane and rerun all four directions against it. The second is to turn the hand-run tests into a conformance suite, and use that suite as the rule for promoting a revision to `stable`. That answers one of the four owner decisions with a mechanism in place of a number.

Two decisions are yours and are listed at the end.

## What the review found

| Finding | Evidence |
|---|---|
| The Crossplane `XCell` composition renders a Namespace and a CiliumClusterwideNetworkPolicy. No waypoint, AuthorizationPolicy, ListenerSet or HTTPRoute appears in any Crossplane manifest | `prototype/kind/crossplane-xcell*.yaml`, `prototype/hub/repo/platform/xcell-np.yaml`; those kinds appear only in `prototype/kind/cell-promise-v2.yaml` |
| The tests are scripts plus steps done by hand. Negative controls were run by removing fences manually | `prototype/README.md` ("switched to SSH by hand", "Suspend the Kratix Flux Kustomization, delete…"), `prototype/results/control.txt` |
| Four things are recorded as not tested | `docs/prototype-results.md`, "Not tested": cross-cluster cells, SKE UpgradePlans, Argo CD sync waves, MutatingAdmissionPolicy |
| Adoption step 3, "fences in report-only mode first", has no test behind it | `docs/recommendation.md`, Adoption path |
| The Gatekeeper guard on `spec.crossplane` is named as a risk and not written | `docs/decision-memo.md`, Risks |
| The upstream fix is open and unreviewed: no review decision, no comments, last updated 2026-11-17 | `gh pr view 2329 --repo crossplane-contrib/provider-upjet-aws`, read 2026-11-23 |
| There is no `docs/adr/`. Decisions live in a memo and a recommendation | repository tree |

## Phase 1: the whole cell in Crossplane

**Outcome:** one `Cell` composition renders everything a cell needs, and `prototype/kind/test.sh` and `test-ns.sh` pass against a cluster that has no Kratix on it.

- Extend the `XCell` schema from `dependsOn` to the fields the Promise had: `dependsOn`, `hostname`, `public`.
- Render, per cell: the ambient Namespace, the waypoint Gateway, the ztunnel waypoint-only AuthorizationPolicy (west), the CCNP (east), and the ListenerSet and HTTPRoute for a public cell (north). South stays platform-wide.
- Carry over the settings the tests showed matter: `function-auto-ready`, an explicit ready annotation on kinds with no Ready condition, `istio.io/ingress-use-waypoint` on public cells.
- Rerun the four-direction matrix and the negative controls. Record the result as round 8.

**Risk this retires:** the recommendation rests on Crossplane being able to do what Kratix was shown doing. That is likely, since both tools apply the same objects, but it is an inference until round 8 exists.

ADR 0001 records the Crossplane decision so later ADRs have something to refer to.

## Phase 2: a conformance suite, and promotion by conformance

**Outcome:** `conformance.sh <cell>` proves every fence of one cell with a deny and an allow, removes nothing by hand, and exits non-zero on any miss. A revision is labelled `stable` only by a script that ran it.

- One probe pair per direction: the meant path returns 200 and the bypass is dropped. West has three known bypasses; keep all three.
- Negative controls become a mode, `--without <fence>`, run against a throwaway cell so a real cell's fence is never removed.
- `promote.sh`: run conformance on every dev-channel cell, wait out the soak, then change the revision's `channel` label in Git from `dev` to `stable` and push. ADR 0002.
- Add the Gatekeeper constraint that blocks tenant edits to `spec.crossplane`, with a deny test and an allow test.

## Phase 3: stop a cell

**Outcome:** `spec.suspended: true` on a Cell drops its traffic in all four directions within one reconcile, leaves its objects and data in place, and comes back when the field is cleared. ADR 0003.

This is the platform's stop switch. The need is general (an incident in one team's cell) and is sharpest for cells that run AI agents, where OpenAI's reference architecture for supervised investigations ([PDF](https://cdn.openai.com/pdf/49112a33-7dc9-4fa7-89ea-095a57552ed2/supervised-investigations-with-daybreak-red-a-reference-architecture.pdf), 2026-11-09; excerpts in [sources/raw](../../sources/raw/openai-daybreak-red/supervision-controls.md)) requires a stop the operator controls from outside the agent, verified before the first run.

## Phase 4: close the untested list

Small, independent probes. Each ends as a section in `docs/prototype-results.md`.

| Probe | Why |
|---|---|
| Fences in report-only mode: Cilium's policy audit mode and Istio's dry-run annotation on AuthorizationPolicy | Adoption step 3 depends on it. Whether each covers the kinds used here (CCNP, Admin-tier ClusterNetworkPolicy, ztunnel-enforced policy) is **unverified** |
| Argo CD sync waves for XRD before XR | Listed as not tested; `SkipDryRunOnMissingResource` is the current workaround |
| MutatingAdmissionPolicy with its feature gate on | Listed as not tested; Gatekeeper mutation stood in |
| Cross-cluster cells | Listed as not tested. Ambient multicluster is multi-network only, so this may end as a documented limit |
| Waypoint rate limiting with an external rate-limit service | The memo names it as a risk with no test |

SKE UpgradePlans stay untested. Kratix was rejected, and SKE is paid.

## Phase 5: upstream and real AWS

- Follow up on PR #2329. It has had no review since it was opened. Keep the `AWS_ENDPOINT_URL_STS` workaround until a release carries the fix, then delete `prototype/kind/provider-sts-endpoint.yaml` and rerun round 7.
- Rerun rounds 6 and 7 against real AWS accounts. The README's limit, "nothing here ran against real AWS", covers the cross-account trust policy, which is the part most likely to differ from the emulator. This costs money and needs two accounts; see decisions.

## Phase 6 (needs a scope decision): an agent cell profile

`spec.profile: agent` renders a stricter cell for AI agent workloads: south egress only to a model gateway, telemetry sent to a platform namespace the tenant cannot write, and suspension rehearsed by conformance. ADR 0004, proposed.

A cell is already the "isolated investigation environment" of the OpenAI guide: a boundary the tenant cannot change, with a declared way in and out. The profile adds the two controls a plain cell lacks, a log store outside the tenant's reach and a preflight.

This widens the repo. Today it is an outside assessment of one published platform. An agent profile makes it a general reference. Do not start it without decision 1 below.

## Considered and left out

- **An `App` XRD for workloads.** The recommendation says to revisit after channels have run for a quarter. A prototype cannot run for a quarter.
- **A second look at Kratix, Radius or OpenChoreo.** Nothing new since the captures of 2026-11-13 to 2026-11-17 was reviewed for this plan.
- **Scale testing.** One machine cannot say anything about hundreds of cells.

## Decisions for you

1. **Does this repo stay an assessment of a DVSP-shaped platform, or become a general reference cell platform?** Phases 1 to 5 fit either. Phase 6 fits only the second.
2. **Is real AWS in scope?** Phase 5's rerun needs two accounts and a budget.

The four platform-owner decisions in `docs/decision-memo.md` are unchanged, except that Phase 2 offers a mechanism for the soak question.

## What I did not check

- No cluster was started. Findings come from reading the README, `docs/decision-memo.md`, `docs/recommendation.md`, the "Not tested" and round 4 sections of `docs/prototype-results.md`, `prototype/README.md`, and the manifests named in the table.
- `docs/cell-traffic-nsew-tooling.md`, the Kratix, Radius and OpenChoreo comparisons, and `sources/raw/` were not reread.
- The report-only features in Phase 4 are named from general knowledge of Cilium and Istio, not from a capture in `sources/raw/`.
