---
type: source
title: "Cell traffic docs (Nov 2026): Gateway API, network-policy-api, Cilium, Istio ambient, Calico, Linkerd, Envoy Gateway, OpenChoreo code"
description: "Sixteen primary-doc captures (2026-11-13, verbatim from each project's docs source repo) behind the cell NSEW traffic analysis: ListenerSet and ReferenceGrant to v1 in Gateway API v1.5.0, GAMMA, GEP-4894 Backend (Experimental egress); ClusterNetworkPolicy v1beta1 in network-policy-api v0.3.0 (listed as not implemented by Cilium; superseded: Cilium 1.20 implements it behind a flag, see cell-traffic-gaps-2026-11); Cilium toFQDNs, deny precedence, Egress Gateway (incompatible with ClusterMesh); Istio ambient waypoints as destination and egress gateways and their bypass caveats, ambient multicluster limits; Calico tiers and Enterprise-only egress gateway; Linkerd multicluster; Envoy Gateway local rate limit; OpenChoreo v1.3.3 network-policy code."
resource: https://gateway-api.sigs.k8s.io/
tags: [gateway-api, kubernetes-network-policy, cilium, istio, ambient-mesh, calico, linkerd, envoy-gateway, openchoreo, egress, cell-based-architecture]
timestamp: 2026-11-16T00:00:00Z
fetch_note: "gh api raw from each project's docs source repo, 2026-11-13; per-file provenance in each raw file's fetch_note and ../../sources/raw/cell-traffic/README.md. Versions current at fetch: Gateway API v1.7.0, network-policy-api v0.3.0, Cilium v1.20.4, Istio 1.32.0, OpenChoreo v1.3.3."
---

# Cell traffic docs (Nov 2026)

Captured for [cell-traffic-nsew-tooling](../cell-traffic-nsew-tooling.md). Index: `../../sources/raw/cell-traffic/README.md`. Each section names its raw file(s).

## Gateway API

Raw files: `gateway-api-security-multins-listenerset.md`, `gateway-api-gep-1713-listenerset.md`, `gateway-api-release-notes-v1.5-v1.7.md`, `gateway-api-gamma-mesh.md`, `gateway-api-gep-4894-backend.md`.

- **Shared Gateways take routes from other namespaces only by opt-in.** "The Gateway owner must explicitly allow Routes to bind from additional namespaces… configuring allowedRoutes." Hostname conflicts "usually work on a first-come, first-served basis".
- **v1.5.0 (2026-02-27):** "TLSRoute and ListenerSet have graduated to the Standard channel as `v1`", and ReferenceGrant is moving to `v1`.
  - "By default, a Gateway does not allow ListenerSets to be attached"; the default is `allowedListeners: {from: None}`.
  - v1.6.0 adds conformance for "a ListenerSet only allows routes in its own namespace by default".
- **GAMMA** (mesh routes with a Service parentRef) has been Standard since v1.1.0.
  - Producer routes: "requests that do not match at least one of the Routes will be rejected".
  - Consumer routes "only affect requests from workloads in the same Namespace", and you can't define "distinct consumer routes for multiple consumers in the same Namespace".
- **GEP-4894 Backend** is Experimental. It adds `ExternalHostname` for egress ("call external APIs (like OpenAI) with specific TLS settings and authentication").

## network-policy-api

Raw file: `network-policy-api-clusternetworkpolicy.md`.

- **v0.2.0 (2026-04-21)** "combines the previously separate AdminNetworkPolicy and BaselineAdminNetworkPolicy resources into a single CRD with a `tier` field".
- **v0.3.0 (2026-11-06)** "graduates `ClusterNetworkPolicy` (CNP) to the `v1beta1` API version", which is now the storage version.
- **Admin tier:** "a developer CANNOT override these rules by creating NetworkPolicies".
- **Implementations, as of 2026-04-21:** Calico v3.32, kube-network-policies and Kube-OVN. Cilium is listed as a "tracking issue" only. **Stale:** Cilium 1.20 ships it behind a flag ([cell-traffic-gaps-2026-11](cell-traffic-gaps-2026-11.md)).
- **NPEP-133** (an FQDN selector) is "Implementable".

## Cilium (v1.20.4)

Raw files: `cilium-dns-and-layer3-policy.md`, `cilium-egress-gateway.md`, `cilium-clusterwide-deny-clustermesh.md`.

- **DNS-aware egress:** `toFQDNs` policies are "very useful for controlling access to services running outside the Kubernetes cluster". They depend on an in-agent DNS proxy; the HA standalone proxy is alpha.
- **Cluster-wide policy:** a CiliumClusterwideNetworkPolicy is a CiliumNetworkPolicy that is "not namespaced".
- **Deny precedence:** "Deny policies take precedence over allow policies, regardless of whether they are a Cilium Network Policy, a Clusterwide Cilium Network Policy or even a Kubernetes Network Policy."
- **Egress Gateway:**
  - needs BPF masquerading and kube-proxy replacement;
  - new pods leave unmasked briefly before policy applies;
  - "Egress gateway is not compatible with the Cluster Mesh feature."
- **ClusterMesh:** "Pod-to-pod connectivity between clusters within a flat IP address space" with cluster-aware policy.

## Istio (1.32.0)

Raw files: `istio-ambient-waypoint-policy-egress.md`, `istio-ambient-multicluster-and-authz.md`, `istio-sidecar-egress-control-gateway.md`.

- **Waypoints sit on the destination side.** `istio.io/use-waypoint` "governs **east-west** traffic", sending requests to the labelled namespace through the destination's waypoint. On its own it "does not guarantee" traversal. A selector policy allowing only the waypoint's identity is "enforced at Layer 4 by ztunnel" and closes both bypass cases.
- **Egress:** "a waypoint proxy naturally acts as an egress gateway" when ServiceEntries sit in a waypoint-enrolled namespace, which "concentrates TLS credential management at the gateway".
- **Authorization order:** policies are evaluated "`CUSTOM`, `DENY`, and then `ALLOW`", and root-namespace policies apply mesh-wide.
- **Ambient multicluster** is beta for multi-network only:
  - "Multicluster single-network configurations are untested, and may be broken";
  - primary-remote is not supported;
  - waypoints must be "identically named" and synced across clusters.
- **Sidecar mode:** "Istio *cannot securely enforce* that all egress traffic actually flows through the egress gateways… Mechanisms external to Istio must enforce this requirement."

## Calico, Linkerd, Envoy Gateway

Raw files: `calico-egress-gateway-and-tiers.md`, `linkerd-multicluster.md`, `envoy-gateway-local-rate-limit.md`.

- **Calico:**
  - Admin-tier ClusterNetworkPolicies live in a `kube-admin` tier evaluated before the developer tier.
  - The egress gateway pages exist only under Calico Enterprise and Cloud. Those gateways "perform an SNAT on the traffic passing through them".
- **Linkerd multicluster** has three modes: hierarchical (gateway), flat pod-to-pod (since 2.14) and federated services.
- **Envoy Gateway's `BackendTrafficPolicy` local rate limit** applies per replica: "each replica will allow 10 requests/second".

## OpenChoreo (docs + v1.3.3 code)

Raw file: `openchoreo-runtime-gateways-networkpolicy.md`.

The docs describe four directional gateways and "Cilium for network policy enforcement and kgateway for ingress traffic management". The code and chart show:

- **One shared ingress gateway.** A kgateway `gateway-default` at DataPlane level with `allowedRoutes: from: All`.
- **An optional shared internal gateway**, `gateway-internal`.
- **Direct calls between projects.** At `namespace` visibility, cross-project calls go pod-to-pod via a generated NetworkPolicy rule.
- **Open egress.** `MakeComponentPolicies` "returns a policy for a component with ingress rules based on declared endpoint visibility. Egress is unrestricted."
- **No default-deny.** The shipped `default` ClusterProjectType provisions "only the cell namespace".

The contradiction between the docs and the code is flagged on [cell-traffic-nsew-tooling](../cell-traffic-nsew-tooling.md) and openchoreo docs.

Related: [cell-traffic-nsew-tooling](../cell-traffic-nsew-tooling.md), gateway api, kubernetes network policy, cilium, istio, service mesh, kgateway, cell based architecture.
