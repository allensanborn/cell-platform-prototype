---
resource: https://github.com/istio/istio/issues/54391
fetched: 2026-11-16
fetch_note: "gh api repos/istio/istio/issues/54391 + /comments (full thread, bodies verbatim)"
---

# #54391 Rate Limit on Istio ambient mode

state: closed (completed) | created 2024-12-18T13:17:29Z | closed 2025-08-13T05:02:45Z | updated 2025-08-13T05:02:47Z | milestone: none | labels: kind/enhancement, lifecycle/stale, lifecycle/automatically-closed, area/ambient

## arshianrz 2024-12-18T13:17:29Z

### Is this the right place to submit this?

- [X] This is not a security vulnerability or a crashing bug
- [X] This is not a question about how to use Istio

### Bug Description

Dear @howardjohn , I am currently working on implementing global rate limiting for east-to-west traffic in an Istio mesh running in Ambient Mode. Since the traditional approach often relies on the ingress gateway (and I don't have one.) to enforce rate limits, I am facing challenges adapting this to the sidecar-less architecture of Ambient Mode. Specifically, I am looking for guidance or recommendations on how to configure a global rate limit service (Have no idea how to configure waypoint to act as rate limit service). Any insights, examples, or best practices for achieving this functionality in the Ambient Mode context would be greatly appreciated.

### Version

```Text
$ istioctl version
client version: 1.24.0
control plane version: 1.24.0
data plane version: 1.24.0 (10 proxies)
---
$ kubectl version
Client Version: v1.30.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.30.0
```


### Additional Information

_No response_


## hzxuzhonghu 2024-12-19T01:42:38Z

Ewaypoint xds configuration is a little different from sidecar, but can apply the ratelimit filter accordingly


## waynewong-ascenda 2025-01-28T05:31:00Z

Hi all, I tried to implement istio rate limiting with envoyfilter as [this extensibilty for waypoint proxy](https://github.com/istio/istio/issues/42223#issuecomment-1353589154) but it didnt work. Any idea? @howardjohn 


## howardjohn 2025-01-28T16:29:19Z

Envoyfilter is very very limited support in ambient. I doubt it can work but maybe @hzxuzhonghu has managed to make it so.


## howardjohn 2025-01-30T00:04:22Z

EF support is tracked in https://github.com/istio/istio/issues/43720 btw


## istio-policy-bot 2025-08-13T05:02:46Z

🚧 This issue or pull request has been closed due to not having had activity from an Istio team member since 2025-01-30. If you feel this issue or pull request deserves attention, please reopen the issue. Please see [this wiki page](https://github.com/istio/istio/wiki/Issue-and-Pull-Request-Lifecycle-Manager) for more information. Thank you for your contributions.


_Created by the issue and PR lifecycle manager_.

