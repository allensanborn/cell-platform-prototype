---
type: source
title: "Release propagation in OpenChoreo v1.3.3 and Radius v0.62 (docs + code, Nov 2026)"
description: "36 captures (2026-11-16) answering whether a platform template change reaches deployed workloads without a tenant change. OpenChoreo: ComponentRelease freezes ComponentType/Trait specs, but the Component controller watches them and with autoDeploy cuts a new release for the first environment; Flux is the default GitOps module; ResourceTypes can wrap Crossplane claims. Radius: Recipe Pack changes affect only subsequent deployments; its aggregated API means kube-apiserver webhooks see rendered objects, not Radius resources."
resource: https://github.com/openchoreo/openchoreo/tree/5336791f421b3efb79603b09b8ce0c98e8ef077d
tags: [openchoreo, radius, release-train, gitops, flux, admission-control, crossplane, platform-orchestration]
timestamp: 2026-11-16T00:00:00Z
fetch_note: "git clone --depth 1 at tags openchoreo/openchoreo v1.3.3 (5336791f), radius-project/radius v0.62.0 (37a8cbd3), plus the openchoreo docs v1.3.x and radius-project/docs trees, by a research agent 2026-11-16. Per-file provenance in each raw header; index ../../sources/raw/release-propagation/README.md. Load-bearing quotes re-checked against the raw files by the maintainer."
---

# Release propagation: OpenChoreo and Radius (Nov 2026)

Captured for the release-train question in [openchoreo-cells-radius-crossplane](../openchoreo-cells-radius-crossplane.md) and [radius-in-nyt-dvsp](../radius-in-nyt-dvsp.md): when the platform changes the implementation template, do already-deployed workloads pick it up with no tenant change? Raw files live in `../../sources/raw/release-propagation/`.

## OpenChoreo v1.3.3

- **Releases are frozen.** `oc-componentrelease-types.md`: `spec.componentType`, `spec.traits`, `spec.componentProfile` and `spec.owner` each carry `+kubebuilder:validation:XValidation:rule="self == oldSelf"` ("… is immutable"). `oc-releasebinding-render-from-release.md`: the binding renders from the release's copy.
- **The Component controller watches templates.** `oc-component-controller-watch.md`: `Watches(&openchoreov1alpha1.ComponentType{}…)`, plus ClusterComponentType, Trait, ClusterTrait, Workflow and ClusterWorkflow.
- **autoDeploy cuts a release for the first environment.** `oc-component-controller-autodeploy.md`: "It computes the hash of the current release spec and creates/updates ComponentRelease and ReleaseBinding if the hash has changed"; the binding name is `fmt.Sprintf("%s-%s", comp.Name, firstEnv)`. `oc-component-autodeploy-field.md`: `autoDeploy` defaults to `false`.
- **GitOps.** The modules overview lists Argo CD under "Community modules"; `oc-community-modules-tree.md` contains only `gitops-flux-cd`. The workflow-plane chart's Argo is Argo Workflows (CI).
- **ResourceTypes** can template Crossplane claims (`ocdocs-v1.3.x-platform-engineer-guide-resource-types.md`); Terraform appears only as a Workflow sample.

## Radius v0.62.0

- **Recipe Pack updates are a plain save.** `rad-createorupdaterecipepack.md` is the synchronous frontend controller; recipe execution lives in each resource's PUT (`rad-portable-createorupdateresource.md`, `rad-recipe-engine.md`, `rad-dynamicrp-putrecipe.md`).
- **Docs agree.** `raddocs-management-recipe-packs.md`: "The change affects subsequent deployments of that Resource Type in those Environments." `raddocs-management-environments.md`: Environment changes "affect subsequent deployments that target it."
- **Aggregated API.** `rad-chart-apiservice.md` registers the UCP APIService. `k8s-configure-aggregation-layer.md` shows that for proxied mutating requests "the aggregated apiserver runs admission checks". The conclusion that kube-apiserver webhooks skip Radius resource writes was inference from that flow; it was confirmed live on 2026-11-16 ([prototype-results](../prototype-results.md)). Rendered Kubernetes objects go through ordinary apply (`rad-kubernetes-handler-put.md`).

## Caveats

This page is docs and code only. Both conclusions (OpenChoreo autoDeploy, Radius admission) were confirmed live on 2026-11-16 in [prototype-results](../prototype-results.md). The research agent's own findings file was not written (harness refusal), so this page was rebuilt from its report and the raw files.

Related: openchoreo, radius, openchoreo docs, [kratix-in-nyt-dvsp](../kratix-in-nyt-dvsp.md), [prototype-results](../prototype-results.md), kubernetes admission control, flux.
