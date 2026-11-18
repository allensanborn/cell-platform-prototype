---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/architecture/data-plane/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed 0c2acee6e401 2024-05-15)"
---


<!-- istio.io/content/en/docs/ambient/architecture/data-plane/index.md lines 22,47 -->

requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also added in the mesh, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will be forwarded to that waypoint for L7 policy enforcement.

Note that in the case of a request to a `Service`, if the service *has* a waypoint, the request will be sent to its waypoint to apply L7 policies to the traffic.
Similarly, in the case of a request to a `Pod` IP, if the pod *has* a waypoint, the request will be sent to its waypoint to apply L7 policies to the traffic.
Since it is possible to vary the labels associated with pods in a `Deployment` it is technically possible for
some pods to use a waypoint while others do not. Users are generally recommended to avoid this advanced use case.

### Inbound

When a pod in an ambient mesh receives an inbound request, it will be [transparently redirected](/docs/ambient/architecture/traffic-redirection) to the node-local ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request passes these checks.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Requests from sources out of mesh will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, if the source is in ambient mesh, the source's ztunnel ensures the request **will** go through
the waypoint where policy is enforced. However, a workload outside of the mesh doesn't know anything about waypoint proxies therefore it sends
requests directly to the destination without going through any waypoint proxy even if the destination is waypoint enabled.
Currently, traffic from sidecars and gateways won't go through any waypoint proxy either and they will be made aware of waypoint proxies
in a future release.
