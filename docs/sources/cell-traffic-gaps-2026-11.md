---
type: source
title: "Cell traffic follow-ups (Nov 2026): ambient REGISTRY_ONLY, waypoint rate limits, kgateway, Cilium ClusterNetworkPolicy, Submariner, Skupper"
description: "25 primary captures (2026-11-16) closing the open questions on the cell traffic page: REGISTRY_ONLY is sidecar-only; waypoints have no supported rate-limit API (EnvoyFilter unsupported, istio#43720 open); kgateway v2.5.2 has local/global rate limits and Secret-sourced header injection; Cilium 1.20 implements ClusterNetworkPolicy behind a flag (cilium#23380 closed 2026-09-09), correcting this write-up; no source-side waypoint is documented; Submariner conflicts with Cilium masquerading, Skupper is an L7 router network outside CNCF."
resource: https://github.com/cilium/cilium/issues/23380
tags: [istio, ambient-mesh, cilium, kubernetes-network-policy, kgateway, rate-limiting, submariner, skupper, multicluster, egress, cell-based-architecture]
timestamp: 2026-11-16T00:00:00Z
fetch_note: "gh api / shallow clones by a research agent 2026-11-16, pinned: istio/istio.io@167b0ad6, istio/istio@4689491e, istio/ztunnel@6a0f4878, istio/api@590ccfb3, kgateway-dev/kgateway v2.5.2@078f23da, kgateway-dev/kgateway.dev@e1acca81, cilium/cilium v1.20.4@6660d6ea, submariner-io/submariner-website@48be4615, skupperproject/skupper-docs@5d7a092b, cncf/landscape@6d334eb5. Per-file headers in ../../sources/raw/cell-traffic/. Load-bearing quotes re-checked by the maintainer; the Cilium ClusterNetworkPolicy claim was also tested on kind."
---

# Cell traffic follow-ups (Nov 2026)

Closes the open questions of [cell-traffic-nsew-tooling](../cell-traffic-nsew-tooling.md) as of 2026-11-13. Raw files are in `../../sources/raw/cell-traffic/` alongside the first capture set (file names below).

## Correction: Cilium does implement ClusterNetworkPolicy

`cilium-23380.md`: the issue closed as completed 2026-09-09, no milestone; a maintainer explains it isn't on by default in 1.20 "because it is an alpha API". `cilium-kcnp-doc-v1.20.4.md`: "Support for the Kubernetes ClusterNetworkPolicy (KCNP) is available starting with Cilium 1.20", enabled by `--enable-k8s-cluster-network-policy` or Helm `k8sClusterNetworkPolicy.enabled=true`, with the CRD from network-policy-api `release-0.2`. This supersedes the "tracking issue" status in [cell-traffic-docs-2026-11](cell-traffic-docs-2026-11.md), which came from the upstream implementations page dated 2026-04-21. Verified on kind in [prototype-results](../prototype-results.md).

## Istio ambient

- **REGISTRY_ONLY** (`istio-api-mesh-config-outbound.md`, `istio-pilot-virtual-outbound.md`, `ztunnel-outbound-passthrough.md`, `istio-egress-control.md`): the mesh config describes "the default behavior of the sidecar… This does not apply to gateways", and "does not act as one, or as any form of an outbound firewall". ztunnel logs "built request as passthrough; no upstream found". The ambient docs never mention it.
- **Waypoint rate limiting** (`istio-ambient-l7-features.md`, `istio-rate-limit-task.md`, `istio-43720-envoyfilter-ambient.md`, `istio-54391-ratelimit-ambient.md`, `istio-extend-waypoint-lua.md`): EnvoyFilter "is not currently supported for any existing Istio version with waypoint proxies"; the rate-limit task is EnvoyFilter-only; #43720 is open, with a 2026-11-15 user report that `context: WAYPOINT` "fails silently".
- **Source-side waypoint** (`istio-ambient-waypoint.md`, `istio-ambient-data-plane.md`, `istio-ambient-egress-gateway.md`, `istio-serviceentry-visibility.md`): policies "are enforced by the **destination** waypoint"; nothing documents a caller-side one.

## kgateway v2.5.2

`kgateway-traffic-policy-ratelimit.md`, `kgateway-docs-ratelimit.md`, `kgateway-shared-httpheader-secretref.md`: `RateLimit{Local, Global}`; global needs a `GatewayExtension` and "you must bring your own rate limit service". `HTTPHeader` entries take `secretRef` ("Exactly one of value or secretRef must be set"). Since tested on kind ([prototype-results](../prototype-results.md)): injected, not forgeable, rotates live.

## Multi-cluster

- **Submariner** (`submariner-docs.md`, `cncf-landscape-submariner.md`, `submariner-3168-cilium.md`, `submariner-4247-cilium-masq.md`): v0.25.0, CNCF Sandbox; L3 tunnels; Cilium masquerading is a "known limitation".
- **Skupper** (`skupper-docs-overview.md`, `skupper-1331-cilium.md`, `skupper-818-istio.md`): 2.3.0; L7 routers; not in the CNCF landscape; one user report of working with OpenShift Service Mesh 2.4 (sidecar era).

## Caveats

The research agent's findings file was not written (harness refusal); this page was rebuilt from its report and the raw files. `REGISTRY_ONLY` was since tested ([prototype-results](../prototype-results.md)): ambient pods ignore it, and waypoints only see registered traffic. Submariner beside ClusterMesh remains UNVERIFIED.

Related: istio, cilium, kgateway, kubernetes network policy, service mesh, [cell-traffic-docs-2026-11](cell-traffic-docs-2026-11.md).
