---
resource: https://github.com/istio/istio/issues/43720
fetched: 2026-11-16
fetch_note: "gh api repos/istio/istio/issues/43720 + /comments (full thread, bodies verbatim)"
---

# #43720 Add support for EnvoyFilter in Ambient/Waypoints

state: open (reopened) | created 2023-03-02T15:18:25Z | closed - | updated 2026-11-15T11:24:06Z | milestone: none | labels: lifecycle/staleproof, area/ambient

## SirNexus 2023-03-02T15:18:25Z

### Bug Description

When running a waypoint proxy in Ambient and creating a VirtualService, the associated listener created for that VirtualService (in my case named `inbound-vip|9080||productpage.bookinfo.svc.cluster.local-http`) cannot be selected by EnvoyFilters specifying route configuration-related patches. I tested `HTTP_ROUTE`, and `VIRTUAL_HOST`. Both of these ARE able to modify the `direct-http` listener for routes not associated with a VirtualService.

### Version

```prose
$ ./out/darwin_arm64/istioctl version

client version: 1.18-dev
control plane version: 1.18-alpha.54a87be0b45d834e26da33224cad0770b342d3ab
data plane version:  (3 proxies), 1.18-alpha.54a87be0b45d834e26da33224cad0770b342d3ab (5 proxies)
```

Istioctl dev commit: 76c45169acca08dad4599171265a7ae0dab2ea40

```
$ kubectl version --short
Flag --short has been deprecated, and will be removed in the future. The --short output will become the default.
Client Version: v1.24.5
Kustomize Version: v4.5.4
Server Version: v1.24.9
```


### Additional Information

I did some digging into the code to ensure that I wasn't missing an aspect of the EnvoyFilter API to configure this to work, and came across: https://github.com/istio/istio/blob/7d1409ea406d0f1df7a4b8df7dd1e54e8ae31243/pilot/pkg/networking/core/v1alpha3/listener_waypoint.go#L445

It looks like we have two code paths for handling route configuration on this inbound direction. One for if the route is associated with a VirtualService (`buildSidecarInboundHTTPRouteConfig`) and one for if not (`lb.waypointInboundRoute`). It looks like only the former function actually respects ROUTE_CONFIGURATION (And therefore VIRTUAL_HOST and HTTP_ROUTE) EnvoyFilter patches.


## SirNexus 2023-03-02T15:20:50Z

Assuming the logic is sound, the location I specified in the `Additional Information` section is the culprit, and this is just a missing feature, I am happy to endeavor a PR to fix this issue.


## howardjohn 2023-03-02T16:04:29Z

Lets hold off on any envoyFilter changes for ambient currently, we are rapidly changing the XDS


## linsun 2023-06-27T14:32:29Z

Need an owner for this if anyone has time to help, probably a good time to pick up now that xDS API is more stable.


## howardjohn 2023-06-27T14:58:20Z

xDS api is not stable

On Tue, Jun 27, 2023 at 7:32 AM Lin Sun ***@***.***> wrote:

> Need an owner for this if anyone has time to help, probably a good time to
> pick up now that xDS API is more stable.
>
> —
> Reply to this email directly, view it on GitHub
> <https://github.com/istio/istio/issues/43720#issuecomment-1609631991>, or
> unsubscribe
> <https://github.com/notifications/unsubscribe-auth/AAEYGXPLY6TNJ5NRARHROHDXNLVITANCNFSM6AAAAAAVNQOD54>
> .
> You are receiving this because you commented.Message ID:
> ***@***.***>
>



## linsun 2023-06-27T16:21:09Z

Could you elaborate on what else is coming to xDS API, particularly for waypoint since this is EnvoyFilter?


## howardjohn 2023-06-27T16:31:52Z

Currently we put all Pod IPs and service IPs into one big listener, the
update frequency and cost is huge.

On Tue, Jun 27, 2023 at 9:21 AM Lin Sun ***@***.***> wrote:

> Could you elaborate on what else is coming to xDS API, particularly for
> waypoint since this is EnvoyFilter?
>
> —
> Reply to this email directly, view it on GitHub
> <https://github.com/istio/istio/issues/43720#issuecomment-1609846073>, or
> unsubscribe
> <https://github.com/notifications/unsubscribe-auth/AAEYGXL7KFMMKUM6FBMHTTLXNMCABANCNFSM6AAAAAAVNQOD54>
> .
> You are receiving this because you commented.Message ID:
> ***@***.***>
>



## kyessenov 2023-06-27T18:08:45Z

Listener filter ECDS is probably good enough to solve this if anyone is interested (it's good enough for a similar Google deployment), and ODS later for a really large scale.


## SirNexus 2023-08-10T14:51:37Z

Can you elaborate here @kyessenov? Interested in what use case was solved for you by listener filter ECDS. What I'm wanting to do is adjust the route being generated in the listener when a VirtualService is created. Don't see how I can do that via listener filter ECDS.

Perhaps I can manually create the route itself inside the listener filter chain, but I'd rather be able to select an existing route inside the `http_connection_manager` of the filter chain.


## kyessenov 2023-08-10T17:29:56Z

I was referring to the comment about the list of IPs in the listener - this list can be supplied via ECDS to reduce the size of the xDS update.


## SirNexus 2023-08-11T07:21:23Z

Got it, thanks for the quick response.


## linsun 2023-08-16T14:44:37Z

@kyessenov do you have any docs or examples you could share about using ECDS to dynamically update IPs for pods and services? We are interested in working on this.


## kyessenov 2023-08-16T16:31:40Z

My opinion is that we should not support HTTP_ROUTE or VIRTUAL_HOST for waypoint until we have a stable xDS. Grouping by port is not ideal for Waypoints and that's the expectation coming from sidecars.


## laiminhtrung1997 2024-08-05T14:22:52Z

any news on this? @howardjohn  @linsun 


## howardjohn 2024-08-05T14:56:06Z

No, this is not currently planned or in progress


## AndreiDoroftei 2024-10-29T15:47:46Z

Would love this feature to get implemented. 


## evenh 2025-03-20T08:05:01Z

Is there any update/timeline on supporting EnvoyFilter like it is supported in sidecar mode?


## laiminhtrung1997 2025-03-20T13:37:19Z

I have some EnvoyFilters on my cluster when I deploy Istio in sidecar mode. However, when I switch to ambient mode, I don’t know how to remove them without crashing my cluster. Currently, I have to deploy both modes in my cluster. Haizzzzzz.


## howardjohn 2025-03-20T15:11:58Z

In the recent TOC/Working Group meeting it was decided that this feature would not be implemented in waypoints.


## dprotaso 2025-03-28T13:51:00Z

> In the recent TOC/Working Group meeting it was decided that this feature would not be implemented in waypoints.

Given the ongoing interest in this from various end users - what does the TOC/WG need to see to revisit their decision?


## krissell 2025-05-05T17:26:01Z

Hi all, I read above where EnvoyFilter is not supported on Waypoints yet. Yet the doc talks about how to use this feature: https://istio.io/latest/docs/reference/config/networking/envoy-filter/#EnvoyFilter-targetRefs

Is the doc just plain wrong? Or is it supported in a limited manner?

Additionally, is the long term direction to add more EnvoyFilter support? Or to instead direct folks to WASM? I ask this since just above this thread is a link regarding extending waypoint with WASM, and I want to be sure we are developing in sync with the long-term direction of istio.

Thanks, Dan


## aavileli 2025-05-19T23:19:45Z

can the team have a look at Proxy-Wasm so that it can support EnvoyFilters https://github.com/proxy-wasm/proxy-wasm-rust-sdk/tree/main/examples/envoy_filter_metadata


## keithmattix 2025-05-19T23:23:26Z

Waypoints support proxy-WASM via WASMPlugin. This support is in alpha 


## craigbox 2025-06-04T02:22:22Z

> Is the doc just plain wrong? Or is it supported in a limited manner?

The doc is autogenerated, and hasn't been updated for the specifics of ambient mode.  (You can use the targetRefs attachment with Gateway API addressing in sidecar mode.)


## zirain 2025-06-04T02:41:21Z

> You can use the targetRefs attachment with Gateway API addressing in sidecar mode.

there's bug with targetRefs on EnvoyFilter, will be fixed by https://github.com/istio/istio/pull/56476.


## zirain 2025-06-18T08:09:34Z

Raise an new proposal for this: https://docs.google.com/document/d/1hnYJ1P3hYNBALR_2U2h03xJYhyKtcDHLzBAEVEl_pDc/edit?tab=t.0#heading=h.xw1gqgyqs5b

PTAL @istio/technical-oversight-committee 


## hzxuzhonghu 2025-08-30T09:03:44Z


@zirain what's the status now


## zirain 2025-08-30T09:56:55Z

> [@zirain](https://github.com/zirain) what's the status now

I think we need a formal discussion in WG meeting.


## acraigupgrade 2025-12-23T18:08:43Z

This would indeed be highly valuable


## zirain 2026-02-08T02:10:15Z

Anyone still insteresting in this, feel free to pick up https://github.com/istio/istio/pull/57971 and complete, I'm currently have no bandwidth for it.


## azagarelz 2026-09-05T15:23:16Z

Hey! Is there any plan to implement this? I would like to port some of the filters I was using with sidecars to a new ambient based setup and I'm currently stuck 


## puzzlermike 2026-10-08T06:19:18Z

Hi,

is there any ETA for the EnvoyFilter support ?
We would like to use the rate limiting capabilities in our Waypoint proxies.


## ejazzazeem 2026-11-15T11:24:06Z

I tested EnvoyFilter on an ambient waypoint with Istio 1.32.0. Sharing the result here because it may help others who are waiting on this issue.

**What works today**

An EnvoyFilter attached to the waypoint with `targetRefs` (Gateway), using `context: SIDECAR_INBOUND` and `listener.name: main_internal`, is applied to the waypoint. With a gzip compressor inserted before the router, the response is compressed (from 3,742 to 1,915 bytes).

**What does not work**

The same patch with `context: WAYPOINT` and a `match.waypoint` block is accepted by the API server, but it never reaches the waypoint config and nothing is compressed. I tried it with `targetRefs` to the Gateway and to the Service (the shape used in the test of #57971). istiod logged no warning or error after the filter was created, so it fails silently. This looks related to #62526. As far as I can tell, the only place in istio/istio master that refers to `EnvoyFilter_WAYPOINT` is the validation code.

**Question**

Is `SIDECAR_INBOUND` on a waypoint an intended path that users can rely on, and could it be documented? Or is it a side effect that may change?

**Limits of this test**

Single-node kind cluster, gzip only, `HTTP_FILTER` patches only, Istio 1.32.0 only. I did not test route or cluster patches.

The setup, results and the two EnvoyFilters are below. I can help with tests or docs if that is useful.

---

**Environment**

- Istio 1.32.0, `istioctl install --set profile=ambient` (images `1.32.0-distroless`)
- kind, single node, Kubernetes v1.36.4
- Gateway API v1.6.1, experimental channel
- Namespace `amb`: `istio.io/dataplane-mode: ambient`, `istio.io/use-waypoint: waypoint`
- Waypoint from `istioctl waypoint generate -n amb --for service` (class `istio-waypoint`, `proxyv2:1.32.0-distroless`)
- Backend `mccutchen/go-httpbin:v2.15.0`, client `curlimages/curl:8.16.0`, both in `amb`, no sidecars
- Request: `curl -H "Accept-Encoding: gzip" http://httpbin:8000/html` (3,742 bytes uncompressed)

**Results**

| EnvoyFilter | `targetRefs` | `match.context` | `envoy.filters.http.compressor` in waypoint listener config | Response |
|---|---|---|---|---|
| none | – | – | 0 | 3,742 bytes, no `content-encoding` |
| A | Gateway `waypoint` | `SIDECAR_INBOUND`, listener `main_internal` | 2 | `content-encoding: gzip`, 1,915 bytes |
| B | Gateway `waypoint` | `WAYPOINT` | 0 | 3,742 bytes, no `content-encoding` |
| B2 | Service `httpbin` | `WAYPOINT` | 0 | 3,742 bytes, no `content-encoding` |

- A, B and B2 were each measured twice, 66 to 103 seconds after the EnvoyFilter was created. One filter was applied at a time.
- With A, the compressor sits in `main_internal`, filter chains `inbound-vip|8000|http|httpbin.amb.svc.cluster.local` and `direct-http`, directly before `envoy.filters.http.router`.
- B and B2 were accepted by the API server, and istiod logged no warning or error after they were created.
- A request without `Accept-Encoding` was never compressed.
- Requests were confirmed to pass through the waypoint (`istio_requests_total{reporter="waypoint"}` increased).
- Config check: `istioctl proxy-config listener <waypoint-pod> -n amb -o json`, counting `"envoy.filters.http.compressor"`.

<details>
<summary>EnvoyFilter A (compresses on the waypoint)</summary>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: compress-waypoint-test-a
  namespace: amb
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: waypoint
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        name: main_internal
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: envoy.filters.http.router
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.compressor
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.compressor.v3.Compressor
          response_direction_config:
            common_config:
              min_content_length: 512
              content_type:
              - text/html
              - application/json
          compressor_library:
            name: gzip_text_optimized
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.compression.gzip.compressor.v3.Gzip
```

</details>

<details>
<summary>EnvoyFilter B2 (accepted, never reaches the waypoint)</summary>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: compress-waypoint-test-b2
  namespace: amb
spec:
  targetRefs:
  - kind: Service
    name: httpbin
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: WAYPOINT
      waypoint:
        filter:
          name: envoy.filters.network.http_connection_manager
          subFilter:
            name: envoy.filters.http.router
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.compressor
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.compressor.v3.Compressor
          response_direction_config:
            common_config:
              min_content_length: 512
              content_type:
              - text/html
              - application/json
          compressor_library:
            name: gzip_text_optimized
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.compression.gzip.compressor.v3.Gzip
```

</details>

B is B2 with `targetRefs` pointing at the waypoint Gateway (`group: gateway.networking.k8s.io`, `kind: Gateway`, `name: waypoint`).


