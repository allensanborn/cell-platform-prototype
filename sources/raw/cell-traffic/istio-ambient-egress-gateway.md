---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/usage/egress-gateway/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed bc969197f9e4 2026-09-17)"
---


<!-- istio.io/content/en/docs/ambient/usage/egress-gateway/index.md lines 8,16 -->

---

An egress gateway is a dedicated proxy that all outbound traffic to external services must pass through. It provides a single, verifiable exit point for traffic leaving the mesh, where you can apply authorization policies, enable observability, and originate TLS.

In {{< gloss "sidecar" >}}sidecar mode{{< /gloss >}}, configuring an egress gateway for a single host requires coordinating five separate objects: a `ServiceEntry`, a `Gateway`, two `HTTPRoute` resources (one to steer mesh traffic into the gateway, one to forward traffic from the gateway to the destination), and a `DestinationRule`. Each new external host repeats most of that work.

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} naturally acts as an egress gateway. Ztunnel automatically routes traffic to a service's waypoint before forwarding it to the destination. If you place a [`ServiceEntry`](/docs/reference/config/networking/service-entry/) in a namespace enrolled to use a waypoint, all mesh traffic to that external host passes through the waypoint automatically, with no extra routing rules required.

## Before you begin

<!-- istio.io/content/en/docs/ambient/usage/egress-gateway/index.md lines 60,63 -->

## Define an external service

Create a `ServiceEntry` in the egress namespace to represent the external host. Because the namespace is enrolled to use the waypoint, ztunnel routes all mesh traffic to this host through the waypoint automatically. The `ServiceEntry` is visible cluster-wide by default (`exportTo: *`), so ztunnel on every node resolves `httpbin.org` to the `istio-egress` waypoint without any additional configuration.

