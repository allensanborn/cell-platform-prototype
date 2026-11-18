---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/usage/l7-features/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed f0b453114fe6 2026-08-11)"
---


<!-- istio.io/content/en/docs/ambient/usage/l7-features/index.md lines 9,18 -->

By adding a waypoint proxy to your traffic flow you can enable more of [Istio's features](/docs/concepts). Waypoints are configured using the {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}.

{{< warning >}}
Usage of VirtualService with the ambient data plane mode is considered Alpha. Mixing with Gateway API configuration is not supported, and will lead to undefined behavior.
{{< /warning >}}

{{< warning >}}
`EnvoyFilter` is Istio's break-glass API for advanced configuration of Envoy proxies. Please note that *`EnvoyFilter` is not currently supported for any existing Istio version with waypoint proxies*. While it may be possible to use `EnvoyFilter` with waypoints in limited scenarios, its use is not supported, and is actively discouraged by the maintainers. The alpha API may break in future releases as it evolves. We expect official support will be provided at a later date.
{{< /warning >}}


<!-- istio.io/content/en/docs/ambient/usage/l7-features/index.md lines 62,75 -->


## Extension

As the waypoint proxy is a deployment of {{< gloss >}}Envoy{{< /gloss >}}, some of the extension mechanisms that are available for Envoy in {{< gloss "sidecar">}}sidecar mode{{< /gloss >}} are also available to waypoint proxies.

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| `TrafficExtension` ‡ | Alpha | `targetRefs` |
| `WasmPlugin` † | Alpha | `targetRefs` |

‡ [Read more on how to extend waypoints with Lua scripts](/docs/ambient/usage/extend-waypoint-lua/).
† [Read more on how to extend waypoints with WebAssembly plugins](/docs/ambient/usage/extend-waypoint-wasm/).

Extension configurations are considered policy by the Gateway API definition.
