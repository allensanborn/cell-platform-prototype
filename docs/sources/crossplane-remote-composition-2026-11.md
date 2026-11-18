---
type: source
title: "Crossplane remote composition with provider-kubernetes v1.4.1 (Nov 2026)"
description: "Captures (2026-11-16) on one control cluster composing objects into remote workload clusters: provider-kubernetes v1.4.1 ProviderConfig credential sources and identities, namespaced vs legacy Object MRs in Crossplane v2, poll/watch drift behaviour, scale limits from GitHub issues, the provider's own 'remote clusters' framing, and what happens when the control cluster is down."
resource: https://github.com/crossplane-contrib/provider-kubernetes/tree/v1.4.1
tags: [crossplane, provider-kubernetes, multi-cluster, platform-engineering, cell-based-architecture]
timestamp: 2026-11-16T00:00:00Z
fetch_note: "gh api / clone by a research agent 2026-11-16: crossplane-contrib/provider-kubernetes@v1.4.1 (9a27a441d3f8), crossplane/docs@6c4f7f95 content/v2.4. Per-file headers in ../../sources/raw/crossplane-remote-composition/. Key quotes spot-checked by the maintainer. The agent's findings file wasn't written (harness refusal); this page was rebuilt from its report and the raw files."
---

# Crossplane remote composition (Nov 2026)

Captured for the owner decision in [recommendation](../recommendation.md): should Crossplane run on every workload cluster (tested in [prototype-results](../prototype-results.md), round 5), or should one control cluster compose cells into remote clusters? Raw files are in `../../sources/raw/crossplane-remote-composition/`.

- **Remote is the provider's main use case.** `provider-kubernetes-enhanced-doc.md`: "The major usage scenario of Provider Kubernetes is to provision and manage Kubernetes objects on Kubernetes clusters, especially on remote clusters." The caveat: "it is always your responsibility to feed the proper kubeconfig … properly configured RBAC". An example composes a GKE cluster, then a ProviderConfig, then Objects on it (`provider-kubernetes-v1.4.1-examples.md`).
- **Targeting.** A ProviderConfig takes `spec.credentials.source` (`None|Secret|InjectedIdentity|Environment|Filesystem`) with a kubeconfig `secretRef`. An optional `spec.identity` covers GCP, Azure, Upbound and `AWSWebIdentityCredentials` (EKS IRSA). AssumeRole chains aren't supported yet (#563, open).
- **v2 composition reaches only the local cluster natively.** No XR or Composition field selects a cluster; the agent's inference, not stated by the docs (**UNVERIFIED**). Remote objects are composed as `Object` managed resources: namespaced `kubernetes.m.crossplane.io/v1alpha1` or legacy cluster-scoped `kubernetes.crossplane.io/v1alpha2`. Every cell resource becomes a wrapped manifest, the indirection v2 removed for local composition.
- **Drift.**
  - `--poll` defaults to 10 minutes, or 30 s while an Object isn't Ready, adjustable with a per-resource `crossplane.io/poll-interval` annotation.
  - Watches are beta and on by default since v1.4.0, but only for Objects with `spec.watch: true`. They go silent when a static kubeconfig token expires (#598).
  - A remote edit is reverted, and a remote delete is recreated.
- **Scale.**
  - The provider keeps one cached client per credential set (#559/#560) and "does not start if its ProviderConfigs … cannot be read within 300 seconds".
  - Polling load at about 8k Objects was reported in #561, with the advice to use the poll annotation.
- **Control cluster down.** Remote objects are plain resources and persist; finalizers are local only. Namespaced `Object` has no `deletionPolicy`, so to orphan remote objects, drop `Delete` from `managementPolicies`.

**Bearing on the recommendation.** Remote composition trades Crossplane-per-cluster for wrapped `Object` manifests, poll-based drift on the fence objects by default (10 minutes, compared with about 10 s for a local re-render in the test), per-cluster credentials and a single control point. For fences, whose repair latency is the point, per-cluster Crossplane is the better default. Remote composition fits fleets too small to justify a controller per cluster.

Related: crossplane, [recommendation](../recommendation.md), [prototype-results](../prototype-results.md), cluster api.
