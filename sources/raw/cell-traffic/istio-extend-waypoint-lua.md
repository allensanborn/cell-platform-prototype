---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/usage/extend-waypoint-lua/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed 6ea76ed45deb 2026-05-12)"
---


<!-- istio.io/content/en/docs/ambient/usage/extend-waypoint-lua/index.md lines 1,16 -->

---
title: Extend waypoints with Lua scripts
description: Describes how to extend ambient mode waypoint proxies using inline Lua scripts.
weight: 56
keywords: [extensibility,Lua,TrafficExtension,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to extend waypoint proxies using inline [Lua](https://www.lua.org/) scripts
via the [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/) API.
In ambient mode, `TrafficExtension` resources must be attached to a waypoint proxy using `targetRefs`.

