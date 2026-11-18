---
resource: https://github.com/crossplane-contrib/provider-kubernetes/releases/tag/v1.4.0
fetched: 2026-11-16
fetch_note: gh api releases/tags/v1.4.0 + issues/{n} bodies (first ~1800 chars) and #561 comments; fetched 2026-11-16
---

# Release v1.4.0 published 2026-10-07T11:28:26Z

# v1.4.0

> [!CAUTION]
> Release v1.4.0 contains a regression in Azure authentication. If you're using provider-kubernetes with AKS please update directly to v1.4.1

> [!IMPORTANT]
> This release changes some defaults. Review these before upgrading:
> - **Watches are enabled by default** ([#569](https://github.com/crossplane-contrib/provider-kubernetes/pull/569)): `--enable-watches` now defaults to `true`, which increases the provider's resource consumption. Set `--enable-watches=false` through a `DeploymentRuntimeConfig` to keep the previous behavior.
> - **Startup requires readable ProviderConfigs** ([#560](https://github.com/crossplane-contrib/provider-kubernetes/pull/560)): the provider sizes its client cache from the cluster at startup and fails to start if its ProviderConfigs and their credentials cannot be read within 300 seconds.
> - **Client-side rate limiting is disabled for target cluster clients** ([#543](https://github.com/crossplane-contrib/provider-kubernetes/pull/543)): a cached client is shared by all concurrent reconciles of its credential set. Load on target clusters is bounded by `--max-reconcile-rate` and the API server's Priority and Fairness.

## Performance

This release removes most of the provider's memory and API server overhead on large clusters. Target cluster clients are built once per credential set instead of once per reconcile ([#543](https://github.com/crossplane-contrib/provider-kubernetes/pull/543)), the client cache sizes itself and reports metrics ([#560](https://github.com/crossplane-contrib/provider-kubernetes/pull/560)), CRD schemas no longer sit in the provider's informer cache and the Secret informer can be turned off ([#549](https://github.com/crossplane-contrib/provider-kubernetes/pull/549)), and the CRD gate ignores CRDs of other providers ([#574](https://github.com/crossplane-contrib/provider-kubernetes/pull/574)). Measured with a reconcile load test on a kind cluster carrying the provider-upjet-aws CRD set (~2,000 CRDs) and 3,000 Secrets, with 300 `Object`s each managing a ConfigMap and publishing a connection Secret, averaged over three update rounds:

| | v1.3.0 | Client cache only | Client cache, CRD schema strip, `--enable-secret-cache=false` |
|---|---:|---:|---:|
| Aggregated discovery requests per round | hundreds | single digits | single digits |
| Peak heap in use | 1.5-1.9 GiB | 450 MiB | 72 MiB |
| Allocation per round | ~2.2 GiB | ~240 MiB | ~250 MiB |

By default v1.4.0 runs the client cache and the CRD schema strip with the Secret informer on, so it lands between the last two columns. Disabling the Secret cache through a `DeploymentRuntimeConfig` trades roughly 200 live Secret reads per round for the remaining memory. There is nothing to size by hand: a sustained `provider_kubernetes_client_cache_events_total{event="evict"}` rate is the signal that more credential sets appeared than the cache was sized for at startup.

## New Features

- **Watches promoted to beta and enabled by default** ([#569](https://github.com/crossplane-contrib/provider-kubernetes/pull/569)): The Watches feature graduates from alpha to beta (feature flag `EnableAlphaWatches` is now `EnableBetaWatches`) and `--enable-watches` now defaults to `true`, so `Object`s with `spec.watch: true` react to changes of their managed and referenced resources without extra configuration.

- **Automatic client cache sizing and cache metrics** ([#560](https://github.com/crossplane-contrib/provider-kubernetes/pull/560)): At startup the provider lists its `ProviderConfig` and `ClusterProviderConfig` objects, counts the distinct credential sets and sizes the target cluster client cache to that count plus headroom (10% or 4 entries, whichever is larger, never below 8). The computed size is logged at startup, and the cache exposes `provider_kubernetes_client_cache_size`, `provider_kubernetes_client_cache_entries` and `provider_kubernetes_client_cache_events_total{event="hit|miss|evict"}`. Cache hits no longer re-run the cloud identity wrappers (GKE, AWS, Azure, Nebius, Upbound).

- **CEL optional field selection in readiness queries** ([#575](https://github.com/crossplane-contrib/provider-kubernetes/pull/575)): The `DeriveFromCelQuery` readiness policy now supports `.?` and `orValue()`, so queries no longer need a `has()` guard on every level, e.g. `object.?status.?conditions.orValue([]).exists(c, c.type == "Complete" && c.status == "True")`. Existing queries are unaffected.

- **Leaner caches with crossplane-runtime v2.4.0** ([#549](https://github.com/crossplane-contrib/provider-kubernetes/pull/549)): CRD schemas are stripped from cached CRD objects, reducing the provider's baseline memory. A new `--enable-secret-cache` flag (default `true`, matching prior behavior) lets you serve Secrets with direct API calls instead of an informer cache. Also shipped in v1.3.1.

- **Gate controller only considers provider CRDs** ([#574](https://github.com/crossplane-contrib/provider-kubernetes/pull/574)): The CRD Gate controller now filters on the provider's own API groups and ignores all other CRDs in the cluster.

- **ProviderConfigs protected while managed resources terminate** ([#565](https://github.com/crossplane-contrib/provider-kubernetes/pull/565)): Consumes [crossplane-runtime#1113](https://github.com/crossplane/crossplane-runtime/pull/1113), which adds a finalizer to `ProviderConfigUsage` so a `ProviderConfig` cannot be deleted while an `Object` that uses it is still terminating.

- **Configurable TLS certs directory and working `make run`** ([#532](https://github.com/crossplane-contrib/provider-kubernetes/pull/532)): A new `--certs-dir` flag (`CERTS_DIR` env) sets the TLS certificate directory; setting it to an empty string disables the conversion webhook. `make run` now strips the partial conversion stanza from the CRDs and runs without TLS certificates, fixing out-of-cluster development ([#343](https://github.com/crossplane-contrib/provider-kubernetes/issues/343), [#249](https://github.com/crossplane-contrib/provider-kubernetes/issues/249)).

# Issue #430: [Perf][IdentityAwareBuilder] Client connection pooling for ProviderConfig identities
state: closed completed created: 2026-03-05T19:15:27Z closed: 2026-09-11T09:26:12Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/430

## Problem
Currently, IdentityAwareBuilder.KubeForProviderConfig() creates a new Kubernetes client on every reconcile, even when the same ProviderConfig (and identity) was used previously. 
This causes:
Connection churn – repeated TCP/TLS handshakes to the same remote cluster
Memory pressure – short-lived clients accumulate before GC
Token refresh overhead – OAuth tokens are re-fetched 

## Solution
Add a thread-safe client cache to IdentityAwareBuilder with TTL-based expiration:

Cache key generation – derive a stable key from the ProviderConfig's identity source 
Cache lookup – before creating a client, check for a valid (non-expired) cached entry
TTL expiration – cached clients expire after 30 minutes (configurable) to ensure credential rotation is respected
Lazy cleanup – expired entries are evicted on next access rather than requiring a background goroutine

# Issue #541: Memory/CPU regression under watch load: full aggregated discovery runs on every reconcile
state: closed completed created: 2026-08-18T07:02:44Z closed: 2026-09-02T10:50:45Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/541

**Summary:** On a cluster with a large CRD population, `provider-kubernetes` `main`
uses roughly **2.8x the steady memory and ~5x the CPU** of `v1.2.1` under the same
`watch: true` load. It looks like a leak but is not one: it is a **transient ~2 GiB
heap spike per reconcile round** that Go returns to the OS lazily (`MADV_FREE`), so
the working set decays slowly and *looks* retained. The provider builds a **fresh
controller-runtime client (and therefore a fresh `RESTMapper`) on every `Connect`**,
and controller-runtime `>= v0.20.0` primes that mapper with **full aggregated
discovery** - one `GET /api` + `GET /apis` returning *every* CRD in the cluster - on
each build. `v1.2.1` ships controller-runtime `v0.19.0`, which fetched discovery
**lazily, per requested group/version**. The behavior flip is upstream
controller-runtime [#2901][cr2901] (issue [#2897][cr2897]), first released in
`controller-runtime v0.20.0`.

## Environment

- Provider: `crossplane-contrib/provider-kubernetes` `main` vs `v1.2.1` (release).
- controller-runtime: **`v0.23.1`** on `main` vs **`v0.19.0`** on `v1.2.1` - this
  bump is the pivot. The relevant behavior change landed in `v0.20.0`.
- Crossplane: UXP with the external package runtime; `kind` cluster.
- Kubernetes: aggregated discovery is beta/default since `1.27`, so any reasonably
  modern apiserver takes the aggregated path.
- Cluster shape that makes it visible: **~1000 CRDs**, 300 `Object`s with `watch: true`, a `ClusterProviderConfig` with credential
  `source: Secret` (kubeconfig) so every reconcile reads credentials. **Invisible on
  a bare cluster** - a large CRD population is required to trigger it.

## What happens

1. Each `Object` reconcile calls `Connect`, which builds a new controller-runtime
   client for the target cluster via 

# Issue #559: client cache: size the LRU from the cluster's credential sets at startup, and expose cache metrics
state: closed completed created: 2026-09-02T14:01:46Z closed: 2026-09-09T10:48:13Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/559

## Context

#543 (merged `9a1e83cb`, unreleased as of `v1.3.1`) bounds `IdentityAwareBuilder`'s per-credential-set client cache with `--client-cache-size` ([`cmd/provider/main.go:100`](https://github.com/crossplane-contrib/provider-kubernetes/blob/9a1e83cb2dc312df2dc08e6af033a598222e41eb/cmd/provider/main.go#L100)), default [`DefaultClientCacheSize = 8`](https://github.com/crossplane-contrib/provider-kubernetes/blob/9a1e83cb2dc312df2dc08e6af033a598222e41eb/pkg/kube/client/client.go#L78), LRU-evicted. The review ([r3813958630](https://github.com/crossplane-contrib/provider-kubernetes/pull/543#discussion_r3813958630) → [r3913268493](https://github.com/crossplane-contrib/provider-kubernetes/pull/543#discussion_r3913268493)) agreed the flag is an escape hatch rather than something a provider admin can reason about, and that a follow-up should make the size come from the cluster instead of from a guess. This issue tracks that follow-up, in two parts.

## Why a static default cannot be right for everyone

- **A bound that is too small is silent and expensive.** The overflow set rebuilds a client and re-runs aggregated discovery on every reconcile - exactly the #541 regression - and the only signal is a `Debug` log on eviction ([`client.go:136-137`](https://github.com/crossplane-contrib/provider-kubernetes/blob/9a1e83cb2dc312df2dc08e6af033a598222e41eb/pkg/kube/client/client.go#L136-L137)). @bobh66 runs control planes managing 1 cluster each *and* 20+ with plans to double or triple ([r3814188755](https://github.com/crossplane-contrib/provider-kubernetes/pull/543#discussion_r3814188755)).
- **A bound that is too large keeps rotated-out clients alive.** **Measured (kind, 2026-08-19):** one primed controller-runtime client retains ~0.4 MiB on a 30-CRD cluster and **~6 MiB on a 153

# Issue #561: add an option to skip periodic poll for stable resources (SuccessfulCreate + ResourceUpToDate)
state: closed completed created: 2026-09-02T20:38:55Z closed: 2026-09-03T19:39:19Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/561

<!--
Thank you for helping to improve Crossplane!

Please be sure to search for open issues before raising a new one. We use issues
for bug reports and feature requests. Please find us at https://slack.crossplane.io
for questions, support, and discussion.
-->

### What problem are you facing?
In large fleets, provider-kubernetes generates a continuous stream of reconcile events even for resources that have been stable since creation. Every resource is requeued after each poll interval and `Observe()` contacts the remote cluster regardless of whether the resource has ever drifted.

For resources with `readiness.policy: SuccessfulCreate`, the provider already knows after the first successful create that the resource is ready. On every subsequent poll, `Observe()` returns ResourceUpToDate: true unconditionally (no drift is ever detected), yet the resource is still requeued at the configured --poll interval. That makes sense when you want to ensure the resource is still there, but **there should be some sort of fire-and-forget mechanism that can be enabled after the resource is ready at least once** .

At scale this is significant. We have seen a case, for example, with ~8k Object resources × 1 poll/30min ≈ 4 unnecessary remote Kubernetes API calls per second, sustained indefinitely, generating noise in both the control plane cluster (Crossplane events) and the remote clusters (API server load).

Notice this isn't the same as setting `crossplane.io/paused: "true"`. When paused is set, it will also stop receiving updates, meaning any change in the object won't be propagated. What we actually need is an option that stops the `Observe()` calls for resources with `readiness.policy: SuccessfulCreate` once they become ready.

### How could Crossplane help solve your problem?
Intr

# Issue #598: Watches stop receiving events once a static kubeconfig token expires
state: closed completed created: 2026-10-26T22:17:46Z closed: 2026-10-28T09:24:02Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/598

### What happened?

An Object with `watch: true` stops receiving watch events about 15 minutes after its watch starts, when its ProviderConfig's kubeconfig contains a short-lived token. After that the Object only picks up changes to the remote resource when it's polled, every 10 minutes by default. Nothing at the default log level says the watch has stopped working.

I hit this with EKS. The ProviderConfig reads a kubeconfig that provider-aws-eks's `ClusterAuth` writes. Its token expires after 15 minutes (`X-Amz-Expires=900`), and `ClusterAuth` writes a fresh one every 10 minutes. From one Object watching a custom resource on the EKS cluster:

- 19:10:39: `Starting resource watch` for the remote GVK. The secret contained a token dated about 19:00:4x. It rotated to one dated 19:10:42 three seconds later.
- 19:15:33: the last `Enqueueing Object because referenced resource changed` for the Object.
- 19:16:55: the remote resource's status changed. There was no event, and the Object's `status.atProvider.manifest` still showed the old status at 19:20.
- 19:25:20: the Object picked the change up on its next poll.

A second watch on the same cluster, started at 19:15:23 with the 19:10:42 token, stopped the same way after that token expired.

### How can we reproduce it?

1. Provision an EKS cluster with provider-aws-eks, including a `ClusterAuth` that writes a kubeconfig to a secret.
2. Create a provider-kubernetes ProviderConfig that reads that secret.
3. Create an Object with `watch: true` that manages a ConfigMap on the EKS cluster.
4. Wait 20 minutes, then edit the ConfigMap on the EKS cluster directly.
5. The Object isn't enqueued (no `Enqueueing Object because referenced resource changed` log), and its `status.atProvider.manifest` doesn't change until its next poll.

### 

# Issue #563: Support AWS AssumeRole chains for EKS authentication
state: open  created: 2026-09-05T03:32:10Z closed: -
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/563

<!--
Thank you for helping to improve Crossplane!

Please be sure to search for open issues before raising a new one. We use issues
for bug reports and feature requests. Please find us at https://slack.crossplane.io
for questions, support, and discussion.
-->

### What problem are you facing?
<!--
Please tell us a little about your use case - it's okay if it's hypothetical!
Leading with this context helps frame the feature request so we can ensure we
implement it sensibly.
--->

When `AWSWebIdentityCredentials` is used, provider-kubernetes creates EKS tokens with the AWS credentials injected into its pod. A `ProviderConfig` cannot ask it to assume a different IAM role first.

This is a problem when an EKS cluster grants access to a dedicated IAM role. The pod role may be allowed to assume that role, but the EKS token is still signed as the pod role. Users must then grant the pod role direct access to every cluster or maintain a separate kubeconfig credential path.

### How could Crossplane help solve your problem?
<!--
Let us know how you think Crossplane could help with your use case. 
-->

Add optional provider-specific configuration under `identity`. This would be the first cloud-specific configuration in the shared identity API. Grouping it under an AWS field keeps `type` and `source` separate from AWS settings.

One option is a short `aws` field:

```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: target-eks
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: target-eks-kubeconfig
      key: kubeconfig
  identity:
    type: AWSWebIdentityCredentials
    source: InjectedIdentity
    aws:
      assumeRoleChain:
        - roleARN: arn:aws:iam::123456789012:role/target-eks-acces

# Issue #421: Reconciliation generates watch events on Objects with no changes
state: open  created: 2026-01-13T02:08:29Z closed: -
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/421

### What happened?
We noticed that there are a large number of no-change update watch events happening in deployments that contain a large number of Object resources.

We are seeing two watch events for every Object in every reconciliation cycle, even when there are no changes
being applied to the objects.  The first watch event is triggered by a status update from the provider:

```json
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata","auditID":"3b346756-ad1f-42f5-ae0f-62d273f40402","stage":"ResponseComplete","requestURI":"/apis/kubernetes.crossplane.io/v1alpha2/objects/bobncom-ngsjm-8f6f35d00355/status","verb":"update","user":{"username":"system:serviceaccount:crossplane-system:provider-kubernetes","uid":"b81295bd-4f57-4fae-9c8e-a280ae7145ae","groups":["system:serviceaccounts","system:serviceaccounts:crossplane-system","system:authenticated"],"extra":{"authentication.kubernetes.io/credential-id":["JTI=3a085658-fd97-41df-8c4b-e0a1ee20edda"],"authentication.kubernetes.io/node-name":["ip-10-254-0-45.ec2.internal"],"authentication.kubernetes.io/node-uid":["8a56b5dc-c208-477f-8ae4-422bbfd832e4"],"authentication.kubernetes.io/pod-name":["provider-kubernetes-75f7657d8d-pdpcr"],"authentication.kubernetes.io/pod-uid":["b715f9ea-5c3a-4b7a-9d3f-a23003a7bf26"]}},"sourceIPs":["10.254.14.242"],"userAgent":"crossplane-kubernetes-provider/v0.0.0 (linux/amd64) kubernetes/$Format","objectRef":{"resource":"objects","name":"bobncom-ngsjm-8f6f35d00355","uid":"b6b2664a-925d-495c-934f-9daa7930e180","apiGroup":"kubernetes.crossplane.io","apiVersion":"v1alpha2","resourceVersion":"4345770","subresource":"status"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"2026-01-12T23:43:02.299010Z","stageTimestamp":"2026-01-12T23:43:02.324430Z","annotations":{"au

# Issue #89: ServiceAccount as CredentialsSource
state: open  created: 2023-01-05T12:29:26Z closed: -
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/89

### What problem are you facing?

I want to enable users to provide their own `ProviderConfig` using their namespaced `ServiceAccount`.
Currently, the only way of doing that is by providing a `kubeconfig` inside a `secret`. Then use that secret in the `ProviderConfig`.
This works but would be amazing to have another simpler mechanism to provide inner kubernetes credentials per team.

### How could Crossplane help solve your problem?
Adding a new `CredentialsSource` option: `ServiceAccount` to the `ProviderConfig`

# Issue #297: Remote Object creation not working for Kubernetes-provider
state: closed completed created: 2024-10-02T22:40:18Z closed: 2026-08-04T14:25:22Z
url: https://github.com/crossplane-contrib/provider-kubernetes/issues/297

<!--
Thank you for helping to improve Crossplane!

Please be sure to search for open issues before raising a new one. We use issues
for bug reports and feature requests. Please find us at https://slack.crossplane.io
for questions, support, and discussion.
-->

### What happened?

Following error message I am getting when trying to create object into remote openshift cluster, its working perfectly with in-cluster provider config but not with remote cluster.

message: 'connect failed: cannot build kube client for provider config: cannot
  get REST config for provider: cannot create new REST config using provider secret:
  currentContext not set in kubeconfig'


### How can we reproduce it?
This is the defination of simple object to create Namespace to remoe cluster.

kind: Object
metadata:
name: sample-namespace
spec:
forProvider:
manifest:
apiVersion: v1
kind: Namespace
metadata:
# name in manifest is optional and defaults to Object name
# name: some-other-name
labels:
provisioned-by: "crossplane"
providerConfigRef:
name: providerconfig-shared-nonprod

Defination of Providerconfig

apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
name: providerconfig-shared-nonprod
spec:
credentials:
source: Secret
secretRef:
namespace: crossplane-system
name: shared-nonprod-kubeconfig
key: kubeconfig

I created a secret into conplane-system namespace where crossplae and provider is installed.

apiVersion: v1
data:
value.yaml: <base64 encoded value of kubeconfig for remote cluster>
kind: Secret
metadata:
name: shared-nonprod-kubeconfig
namespace: crossplane-system
type: Opaque



Anythig I am missing ? need help please.
Or do we have any hints how to use providerconfig with secret ref. as kubeconf

# Issue #561 comments

> bobh66 2026-09-02T21:20:14Z: @pedromartinssouza if I understand correctly you want to ignore potential drift of the resource (any external changes or deletion would not be reverted unless the `spec` was updated). This is basically the equivalent of `managementPolicies: ['Create', 'Update', 'Delete', 'LateInitialize']`, which is not a valid combination today.

Can you accomplish something similar by using a very long poll interval, maybe 24h?

> pedromartinssouza 2026-09-03T02:50:00Z: @bobh66 we considered it, but my understanding is that this would then apply to all resources. We still want some of them (around 40%) being properly monitored every few minutes for their statuses, but some others don't need it.

What I was thinking of is more similar to what I pushed in https://github.com/crossplane-contrib/provider-kubernetes/pull/562. Could you have a look and lmk if it's feasible?

> jonasz-lasut 2026-09-03T05:53:49Z: I'm with @bobh66 on this one, the described behavior is against Crossplane management policy convention, which does not allow full lifecycle without Observe

On the topic of the poll interval, crossplane-runtime >=v2.3.0 supports per resource poll interval customization via annotations (crossplane.io/poll-interval). Provider-kubernetes release v1.3.1 uses crossplane-runtime version which supports this feature

> pedromartinssouza 2026-09-03T19:39:19Z: @jonasz-lasut thanks for the suggestion! While not 100% what we desired, it should be good enough to solve our issue.

Will try it out 😄 
