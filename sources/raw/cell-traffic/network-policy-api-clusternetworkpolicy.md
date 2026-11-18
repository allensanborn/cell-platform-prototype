---
type: source
resource: https://network-policy-api.sigs.k8s.io/api-overview/
title: "Network Policy API — ClusterNetworkPolicy overview, implementations, release notes v0.2.0/v0.3.0"
source_kind: webpage
tags: [network-policy-api, clusternetworkpolicy, adminnetworkpolicy, kubernetes, multi-tenancy]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/kubernetes-sigs/network-policy-api/contents/site-src/{api-overview.md,implementations.md,npeps/npep-133-fqdn-egress-selector.md} raw (main, 2026-11-13) + gh api releases/tags/{v0.2.0,v0.3.0} --jq .body. All verbatim, concatenated."
---

<!-- ===== site-src/api-overview.md ===== -->
# API Object Overview

Prior to the Network Policy API the original NetworkPolicy V1 Resource was the only
way for k8s users to apply security rules to their kubernetes workloads. One of the
main drawbacks to this API was that it was designed exclusively for use by the
Application Developer, although in reality it is used by many different cluster
personas, sometimes creating a complex web of objects to be maintained. In
contrast, each resource in the Network Policy API is designed to be used by a
specific persona.

With the advent of the ClusterNetworkPolicy resource Cluster Admins will now have
the ability to apply policy globally with only a few simple policy objects.

## Roles and personas

In this documentation we refer to three primary personas:

- Application Developer
- Namespace Administrator
- Cluster Administrator

## Resource Model

!!! note
    Network Policy API resources are in the `policy.networking.k8s.io` API group as
    Custom Resource Definitions (CRDs). Unqualified resource names below will
    implicitly be in this API group.

Currently, there is one main object in the Network Policy API resource model:

- **ClusterNetworkPolicy (CNP)**

The diagram below demonstrates how these new API objects interact with
each-other and existing NetworkPolicy Objects:

<img src="/images/CNP.drawio.svg" width="541" alt="Cluster Network Policy API model">

## General Notes

- Any well-defined ClusterNetworkPolicy rules should
be read as-is, i.e. there will not be any implicit isolation effects for the Pods
selected by the ClusterNetworkPolicy, as opposed to what NetworkPolicy rules imply.

- We now have multiple API versions, see the [ClusterNetworkPolicy blog post](blog/posts/ClusterNetworkPolicy.md) for more details

### Hairpin Traffic Semantics

ClusterNetworkPolicy is logically enforced outside the Pod network namespace. This determines how policy applies to "hairpin" traffic that a Pod sends to itself:
- A Pod connecting directly to its own Pod IP is never subject to ClusterNetworkPolicy enforcement.
- For a Pod connecting to a Service IP that load-balances back to itself, the **preferred behavior** is that such traffic is subject to ClusterNetworkPolicy enforcement.
- To accommodate existing dataplanes (e.g., socket-level load balancers), service hairpin enforcement is **not required for conformance in Beta**. The API reserves the right to mandate this behavior in a future release.

## The ClusterNetworkPolicy Resource

The ClusterNetworkPolicy (CNP) resource will help administrators set cluster-wide security
rules for the cluster, which are evaluated before or after the NetworkPolicies defined by the
namespace owners.

### Tiers

Tier is used as the top-level grouping for network policy prioritization.

Policy tiers are evaluated in the following order:

* `Admin` tier
* NetworkPolicy tier
* `Baseline` tier

ClusterNetworkPolicy can use 2 of these tiers: `Admin` and `Baseline`.

The `Admin` tier will help administrators set strict security rules for the cluster,
i.e. a developer CANNOT override these rules by creating NetworkPolicies that apply
to the same workloads as the ClusterNetworkPolicy.

The `Baseline` tier will allow administrators to set baseline security rules that
describe default connectivity for cluster workloads, which CAN be overridden by
developer NetworkPolicies if needed.
The major use case for `Baseline` tier is the ability to flip the [default security stance of the
cluster](user-stories.md#story-5-cluster-wide-default-guardrails).

### Actions

Unlike the NetworkPolicy resource in which each rule represents an allowed
traffic, ClusterNetworkPolicy will enable administrators to set `Pass`,
`Deny` or `Accept` as the action of each rule. ClusterNetworkPolicy rules should
be read as-is, i.e. there will not be any implicit isolation effects for the Pods
selected by the ClusterNetworkPolicy, as opposed to implicit deny NetworkPolicy rules imply.

- **Accept**: Accepts the selected traffic, including replies to that
  traffic and related ICMP traffic (e.g. ICMP errors such as
  "destination unreachable" or "packet too big"). No further
  ClusterNetworkPolicy or NetworkPolicy rules will be processed.

- **Deny**: Drops the selected traffic. No further
  ClusterNetworkPolicy or NetworkPolicy rules will be
  processed.

- **Pass**: Skips all further ClusterNetworkPolicy rules in the
  current tier for the selected traffic, and passes
  evaluation to the next tier.

ClusterNetworkPolicy `Deny` rules are useful for administrators to explicitly
block traffic with malicious in-cluster clients, or workloads that pose security risks.
Those traffic restrictions can only be lifted once the `Deny` rules are deleted,
modified by the admin, or overridden by a higher priority rule.

On the other hand, the `Accept` rules can be used to call out traffic in the cluster
that needs to be allowed for certain components to work as expected (egress to
CoreDNS for example). This traffic should not be blocked when developers apply
NetworkPolicy to their Namespaces which isolates the workloads.

ClusterNetworkPolicy `Pass` rules in the `Admin` tier allow an admin to delegate security posture for
certain traffic to the Namespace owners by overriding any lower precedence Accept
or Deny rules. For example, intra-namespace traffic management can be delegated to namespace
admins explicitly with the use of `Pass` rules. More specifically traffic selected by a `Pass` rule
will skip any lower precedence `Admin` tier rules and proceed to be evaluated by `NetworkPolicy` and
`Baseline` tier policies. When the `Pass` action is matched at the `Admin` tier, `NetworkPolicy` will
apply next or if there is no `NetworkPolicy` match, `Baseline` policies will be evaluated.

### Priorities

Integer priority values were added to the ClusterNetworkPolicy API to allow Cluster
Admins to express direct and intentional ordering between various CNP Objects.
The `Priority` field in the CNP spec is defined as a non-negative integer value
where rules with lower priority values have higher precedence, and are checked
before policies with higher priority values in the same tier.

### Rules

Each CNP should define at least one `Ingress` or `Egress` relevant in-cluster traffic flow
along with the associated Action that should occur. In each rule the user
should *at a minimum* define an `Action`, and at least one peer (`To` or `From` entry).
Optionally the user may also define select `Protocols` to filter traffic on and also
a name for each rule to make management and reporting easier for Admins.

Within the `Protocols` array, `TCP`, `UDP`, or `SCTP` protocols can be specified, each with an
optional `destinationPort`. The `destinationPort` can be a single `number` or a `range`
with a `start` and `end`. If `destinationPort` is omitted, all ports for the specified
protocol match.

Alternatively, `DestinationNamedPort` can be used to target a port by name. A named port is
defined directly within the ports section of the `Pod` or `Deployment` container spec by assigning
a string to the name field alongside the containerPort. Existing named ports can be located by
inspecting the resource's YAML under `spec.containers[].ports` or by running `kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].ports[*].name}'`. Using a name instead of a number allows the ClusterNetworkPolicy to remain valid even
if the container’s underlying port number is updated.

### Status

For `v1alpha2` of this API the CNP status field is simply defined as a list of
[`metav1.condition`](https://github.com/kubernetes/apimachinery/blob/v0.25.0/pkg/apis/meta/v1/types.go#L1464)s. Currently there are no rules as to what these conditions should display,
and it is up to each implementation to report what they see fit. For further
API iterations the community may consider standardizing these conditions based on
the usefulness they provide for various implementors.

<!-- ===== site-src/implementations.md ===== -->
# Implementations

This document tracks downstream(actual and planned) implementations of
Network Policy API resources and provides status and resource references for them.

Implementors of Network Policy API resources are encouraged to update this document with status information about their
implementations, the versions they cover, and documentation to help users get started.

Implementations are also strongly encouraged to substantiate their entries by
submitting a [conformance report](https://github.com/kubernetes-sigs/network-policy-api/tree/main/conformance/reports)
— a machine-generated record of exactly which profiles and features were
tested and passed, with a link to the CI run that produced it. See the
[reports README](https://github.com/kubernetes-sigs/network-policy-api/blob/main/conformance/reports/README.md)
for how to generate and submit one.

## ClusterNetworkPolicy

Updated: 21-April-2026

- [Kube-network-policies](https://github.com/kubernetes-sigs/kube-network-policies) ([conformance report](https://github.com/kubernetes-sigs/network-policy-api/blob/main/conformance/reports/v0.2.0/kube-network-policies.yaml))
- [Kube-OVN CNI](https://github.com/kubeovn/kube-ovn) (Experimental support)
- [Calico CNI](https://github.com/projectcalico/calico) (Standard support in Calico v3.32)

## AdminNetworkPolicy and BaseLineAdminNetworkPolicy (v1alpha1)

Updated: 21-April-2026

- [Kube-network-policies](https://github.com/kubernetes-sigs/kube-network-policies/tree/v0.8.1)
- [OVN-Kubernetes CNI](https://github.com/ovn-org/ovn-kubernetes/) (Has implemented standard fields of the API + Nodes/Networks in Experimental)
- [Antrea CNI](https://github.com/antrea-io/antrea/) (Has implemented standard fields of the API)
- [Kube-OVN CNI](https://github.com/kubeovn/kube-ovn) (Has implemented standard fields of the API)
- [Calico CNI](https://github.com/projectcalico/calico) (Has implemented standard fields of the API + Networks peer in experimental in Calico v3.29, v3.30, and v3.31)
- [Cilium CNI](https://github.com/cilium/cilium/issues/23380) (tracking issue)

<!-- ===== release v0.2.0 (2026-04-21) ===== -->
API Version: v1alpha2

This is a minor release of the network-policy-api that introduces v1alpha2 version of the API with
a single unified resource for cluster administrators:

- ClusterNetworkPolicy (CNP)

ClusterNetworkPolicy combines the previously separate AdminNetworkPolicy and
BaselineAdminNetworkPolicy resources into a single CRD with a `tier` field
(Admin or Baseline) to control policy precedence. See [NPEP-285](https://network-policy-api.sigs.k8s.io/npeps/npep-285-combine-crds) for more details.

The new aspects of the API being released here that are worth highlighting include:

- The `Allow` action has been renamed to `Accept`.
- **NPEP-187: Ports and Protocols** - The `ports` field has been replaced with
  a new `protocols` field that provides explicit per-protocol matching for TCP,
  UDP, and SCTP with clearer semantics.
- Reduced MaxItems from 100 to 25 for rules and peers

## What's Changed
* npep-285: Combine ANP and BANP by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/289
* ClusterNetworkPolicy: implementation and clients by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/306
* [CRD doc] replace "lower priority" with "lower precedence". by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/310
* Allow => Accept by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/318
* Remove dependency on perl (for awk) in the update codegen script by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/327
* use latest version of kube-network-policies for testing by @aojea in https://github.com/kubernetes-sigs/network-policy-api/pull/322
* Bump 1.34 by @aojea in https://github.com/kubernetes-sigs/network-policy-api/pull/323
* Update the Makefile help text to include all of the targets by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/325
* CNP update tests by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/307
* Update OWNERS by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/334
* Update the user stories to ClusterNetworkPolicy by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/321
* Change MaxItems from 100 to 25 by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/329
* Fix `make conformance` to select only the requested tests by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/336
* Some fixes to codegen by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/337
* Update comment to match validation rules (100 => 25) by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/338
* Adds unit test to test CRDs by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/331
* CNP: update docs to use CNP instead of ANP and BANP by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/333
* [conformance] Make host network ports configurable. by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/345
* npep-187: More protocols support by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/297
* Implements option #3 (npep-187: More protocols support) by @bowei in https://github.com/kubernetes-sigs/network-policy-api/pull/347
* Fix typo 'continguous'. by @fasaxc in https://github.com/kubernetes-sigs/network-policy-api/pull/356
* Update conformance test for new protocol/port schema by @TheBeeZee in https://github.com/kubernetes-sigs/network-policy-api/pull/357
* Conformance: Improve test reliability by @mazdakn in https://github.com/kubernetes-sigs/network-policy-api/pull/353
* [conformance] increase test timeout due to the added retries by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/362
* Bump k8s dependencies to 1.35.2 and lint v2 by @tssurya in https://github.com/kubernetes-sigs/network-policy-api/pull/373
* Run make docs by @tssurya in https://github.com/kubernetes-sigs/network-policy-api/pull/367
* Update docs to match port/protocol schema changes in v1alpha2 by @TheBeeZee in https://github.com/kubernetes-sigs/network-policy-api/pull/363
* chore(docs): add cnp support in kube-ovn by @SkalaNetworks in https://github.com/kubernetes-sigs/network-policy-api/pull/354
* Add a simple dependabot config by @npinaeva in https://github.com/kubernetes-sigs/network-policy-api/pull/377
* Bump golang from 1.15 to 1.26 by @dependabot[bot] in https://github.com/kubernetes-sigs/network-policy-api/pull/378
* Cut release v0.2.0 by @tssurya in https://github.com/kubernetes-sigs/network-policy-api/pull/369

## New Contributors
* @bowei made their first contribution in https://github.com/kubernetes-sigs/network-policy-api/pull/318
* @TheBeeZee made their first contribution in https://github.com/kubernetes-sigs/network-policy-api/pull/357
* @mazdakn made their first contribution in https://github.com/kubernetes-sigs/network-policy-api/pull/353
* @SkalaNetworks made their first contribution in https://github.com/kubernetes-sigs/network-policy-api/pull/354
* @dependabot[bot] made their first contribution in https://github.com/kubernetes-sigs/network-policy-api/pull/378

**Full Changelog**: https://github.com/kubernetes-sigs/network-policy-api/compare/v0.1.7...v0.2.0

<!-- ===== release v0.3.0 (2026-11-06) ===== -->
# API Version: v1beta1

This is a minor release of the network-policy-api that graduates
`ClusterNetworkPolicy` (CNP) to the `v1beta1` API version:

- ClusterNetworkPolicy (CNP)

`v1beta1` is now the **storage version** and is served alongside `v1alpha2`,
which remains served for backward compatibility. The `v1beta1` and `v1alpha2`
schemas are identical, so no conversion webhook is required and existing
`v1alpha2` objects are readable and writable through `v1beta1`.

# The key changes since v0.2.1 include:

- **ClusterNetworkPolicy graduated to v1beta1** - Both the standard and
  experimental channel CRDs now serve `v1alpha2` and `v1beta1`, with `v1beta1`
  as the storage version. There are no changes to the shape of the API.
  Deprecation of `v1alpha2` is deferred to a future release once `v1beta1` has
  soaked.
- Conformance tests and manifests migrated to the `v1beta1` API.

Please check out the [network-policy-api website](https://network-policy-api.sigs.k8s.io/) for more information.


**Full Changelog**: https://github.com/kubernetes-sigs/network-policy-api/compare/v0.2.1...v0.3.0

<!-- ===== site-src/npeps/npep-133-fqdn-egress-selector.md ===== -->

# NPEP-133: FQDN Selector for Egress Traffic

* Issue:
  [#133](https://github.com/kubernetes-sigs/network-policy-api/issues/133)
* Status: Implementable

## TLDR

This enhancement proposes adding a new optional selector to specify egress peers
using [Fully Qualified Domain
Names](https://www.wikipedia.org/wiki/Fully_qualified_domain_name) (FQDNs).

## Goals

* Provide a selector to specify egress peers using a Fully Qualified Domain Name
  (for example `kubernetes.io`).
* Support basic wildcard matching capabilities when specifying FQDNs (for
  example `*.cloud-provider.io`)
* Currently only `Accept` type rules are proposed.
  * Safely enforcing `Deny` rules based on FQDN selectors is difficult as there
    is no guarantee a Network Policy plugin is aware of all IPs backing a FQDN
    policy. If a Network Policy plugin has incomplete information, it may
    accidentally allow traffic to an IP belonging to a denied domain. This would
    constitute a security breach.
    
    By contrast, `Accept` rules, which may also have an incomplete list of IPs,
    would not create a security breach. In case of incomplete information, valid
    traffic would be dropped as the plugin believes the destination IP does not
    belong to the domain. While this is definitely undesirable, it is at least
    not an unsafe failure.

* DomainNames may only be used with Accept action (not Pass or Deny).
  * The rationale for excluding Deny is described above.
  * Pass is excluded for now because no existing implementations support
    DomainNames with Pass and there is no strong use case for it. This
    restriction may be relaxed in the future.

## Non-Goals

* This enhancement does not include a FQDN selector for allowing ingress
  traffic.
* This enhancement only describes enhancements to the existing L4 filtering as
  provided by ClusterNetworkPolicy. It does not propose any new L7 matching or
  filtering capabilities, like matching HTTP traffic or URL paths.
  * This selector should not control what DNS records are resolvable from a
    particular workload.
  * This selector provides no capability to detect traffic destined for
    different domains backed by the same IP (e.g. CDN or load balancers).
* This enhancement does not add any new mechanisms for specifying how traffic is
  routed to a destination (egress gateways, alternative SNAT IPs, etc). It just
  adds a new way of specifying packets to be allowed or dropped on the normal
  egress data path.
* This enhancement does not require any mechanism for securing DNS resolution
  (e.g. DNSSEC or DNS-over-TLS). Unsecured DNS requests are expected to be
  sufficient for looking up FQDNs.

## Introduction

FQDN-based egress controls are a common enterprise security practice.
Administrators often prefer to write security policies using DNS names such as
“www.kubernetes.io” instead of capturing all the IP addresses the DNS name might
resolve to. Keeping up with changing IP addresses is a maintenance burden, and
hampers the readability of the network policies.

## User Stories

* As a cluster admin, I want to allow all Pods in the cluster to send traffic to
  an external service specified by a well-known domain name. For example, all
  Pods must be able to talk to `my-service.com`.

* As a cluster admin, I want to allow Pods in the "monitoring" namespace to be
  able to send traffic to a logs-sink, hosted at `logs-storage.com`

* As a cluster admin, I want to allow all Pods in the cluster to send traffic to
  any of the managed services provided by my Cloud Provider. Since the cloud
  provider has a well known parent domain, I want to allow Pods to send traffic
  to all sub-domains using a wild-card selector -- `*.my-cloud-provider.com`

* As a cluster admin, I want to allow Pods in the cluster to send traffic to a
  entire tree of domains. For example, our CDN has domains of the format
  `<session>.<random>.<region>.my-app.cdn.com`. I want to be able to use a
  wild-card selector to allow the full tree of subdomains below
  `*.my-app.cdn.com`.

### Future User Stories

These are some user stories we want to keep in mind, but due to limitations of
the existing Network Policy API, cannot be implemented currently. The design
goal in this case is to ensure we do not make these unimplementable down the
line.

* As a cluster admin, I want to switch the default disposition of the cluster to
  be default deny. This is enforced using a Baseline-tier
  `ClusterNetworkPolicy`. I also want individual namespace owners to be able to
  specify their egress peers. Namespace admins would then use a FQDN selector
  in the Kubernetes `NetworkPolicy` objects to allow `my-service.com`.
  
## API

This NPEP proposes adding a `DomainNames` field to
`ClusterNetworkPolicyEgressPeer` which allows specifying domain names as
egress peers. DomainNames is only available with Accept rules.

This restriction is enforced via CEL validation on
`ClusterNetworkPolicyEgressRule`:

```go
// +kubebuilder:validation:XValidation:rule="self.action != 'Accept' ? !self.to.exists(peer, has(peer.domainNames)) : true",message="domainNames may only be used with Accept action"
type ClusterNetworkPolicyEgressRule struct { ... }
```

```golang

// DomainName describes one or more domain names to be used as a peer.
//
// DomainName can be an exact match, or use the wildcard specifier '*' to match
// one or more labels.
//
// '*', the wildcard specifier, matches one or more entire labels. It does not
// support partial matches. '*' may only be specified as a prefix.
// 
//  Examples:
//    - `kubernetes.io` matches only `kubernetes.io`.
//      It does not match "www.kubernetes.io", "blog.kubernetes.io",
//      "my-kubernetes.io", or "wikipedia.org".
//    - `blog.kubernetes.io` matches only "blog.kubernetes.io".
//      It does not match "www.kubernetes.io" or "kubernetes.io".
//    - `*.kubernetes.io` matches subdomains of kubernetes.io.
//      "www.kubernetes.io", "blog.kubernetes.io", and
//      "latest.blog.kubernetes.io" match, however "kubernetes.io", and
//      "wikipedia.org" do not.
//
// +kubebuilder:validation:Pattern=`^(\*\.)?([a-zA-z0-9]([-a-zA-Z0-9_]*[a-zA-Z0-9])?\.)+[a-zA-z0-9]([-a-zA-Z0-9_]*[a-zA-Z0-9])?\.?$`
type DomainName string

type ClusterNetworkPolicyEgressPeer struct {
    <snipped>
    // DomainNames provides a way to specify domain names as peers.
    //
    // DomainNames is only supported for Accept rules.
    // In order to control access, DomainNames Accept rules should be used
    // with a lower precedence egress deny -- this allows the admin to
    // maintain an explicit "allowlist" of reachable domains.
    // 
    // Support: Extended
    //
    // <network-policy-api:experimental>
    // +optional
    // +listType=set
    // +kubebuilder:validation:MinItems=1
    // +kubebuilder:validation:MaxItems=25
    DomainNames []DomainName `json:"domainNames,omitempty"`
}
```

### Examples

#### Pods in `monitoring` namespace can talk to `my-service.com` and `*.cloud-provider.io`

```yaml
apiVersion: policy.networking.k8s.io/v1alpha2
kind: ClusterNetworkPolicy
metadata:
  name: allow-my-service-egress
spec:
  tier: Admin
  priority: 55
  tier: Admin
  subject:
    namespaces:
      matchLabels:
        kubernetes.io/metadata.name: "monitoring"
  egress:
  - name: "allow-to-my-service"
    action: "Accept"
    to:
    - domainNames:
      - "my-service.com"
      - "*.cloud-provider.io"
    protocols:
    - tcp:
        destinationPort:
          number: 443
```

#### Maintaining an allowlist of domains

There are a couple ways to maintain an allowlist:

This example includes the Deny rule in the same ClusterNetworkPolicy object.
It's also possible to use another ClusterNetworkPolicy object with a lower
priority (e.g. `100` in this example):
```yaml
apiVersion: policy.networking.k8s.io/v1alpha2
kind: ClusterNetworkPolicy
metadata:
  name: allow-my-service-egress
spec:
  tier: Admin
  priority: 55
  tier: Admin
  subject:
    namespaces:
      matchLabels:
        kubernetes.io/metadata.name: "monitoring"
  egress:
  - name: "allow-to-my-service"
    action: "Accept"
    to:
    - domainNames:
      - "my-service.com"
      - "*.cloud-provider.io"
    protocols:
    - tcp:
        destinationPort:
          number: 443
  - name: "default-deny"
    action: "Deny"
    to:
    - networks:
      - "0.0.0.0/0"
      - "::/0"
```

This example uses a Baseline-tier default-deny ClusterNetworkPolicy to create
the allowlist:
```yaml
apiVersion: policy.networking.k8s.io/v1alpha2
kind: ClusterNetworkPolicy
metadata:
  name: allow-my-service-egress
spec:
  tier: Admin
  priority: 55
  tier: Admin
  subject:
    namespaces:
      matchLabels:
        kubernetes.io/metadata.name: "monitoring"
  egress:
  - name: "allow-to-my-service"
    action: "Accept"
    to:
    - domainNames:
      - "my-service.com"
      - "*.cloud-provider.io"
    protocols:
    - tcp:
        destinationPort:
          number: 443
---
apiVersion: policy.networking.k8s.io/v1alpha2
kind: ClusterNetworkPolicy
metadata:
  name: default-deny
spec:
  tier: Baseline
  priority: 0
  subject:
    namespaces: {}
  egress:
  - name: "default-deny"
    action: "Deny"
    to:
    - networks:
      - "0.0.0.0/0"
      - "::/0"
```

### Expected Behavior

1. A FQDN egress policy does not grant the workload permission to communicate
   with any in-cluster DNS services (like `kube-dns`). A separate rule needs to
   be configured to allow traffic to any DNS servers. FQDN policies are not
   expected to work if the pod cannot reach DNS.
1. FQDN policies should not affect the ability of workloads to resolve domains,
   only their ability to communicate with the IP backing them. Put another way,
   FQDN policies should not result in any form of DNS filtering.
   *  For example, if a policy allows traffic to `kubernetes.io`, any selected
      Pods can still resolve `wikipedia.org` or
      `my-services.default.svc.cluster.local`, but can not send traffic to them
      unless allowed by a different rule.
1. Each implementation will provide guidance on which DNS name-server is
   considered authoritative for resolving domain names. This could be the
   `kube-dns` Service or potentially some other DNS provider specified in the
   implementation's configuration.
1. Pods are expected to use the DNS configuration provided via `resolv.conf`
   (i.e. the canonical cluster DNS server). If a pod uses a different DNS
   server (e.g. hardcoded `8.8.8.8`), FQDN rule processing is not guaranteed
   to work.
1. DNS record querying and lifetimes:
   *  Pods are expected to make a DNS query for a domain before sending traffic
      to it. If the Pod fails to send a DNS request and instead just sends
      traffic to the IP (either because of caching or a static config), traffic
      is not guaranteed to flow.
   *  Pods should respect the TTL of DNS records they receive. Trying to
      establish new connection using DNS records that are expired is not
      guaranteed to work.
   *  When the TTL for a DNS record expires, the implementor should stop
      allowing new connections to that IP. Existing connections will still be
      allowed (that's consistent with NetworkPolicy behavior on long-running
      connections).
   *  If a DNS record is refreshed before the TTL expires (e.g., due to a new
      DNS query from the workload), the TTL timer should be reset based on the
      new response.
1. Implementations must support at least 100 unique IPs (either IPv4 or IPv6)
   for each domain. This is true for both explicitly specified domains, as well
   as for each domain selected by a wild-card rule. For example, the rule
   `*.kubernetes.io` supports 100 IPs each for both `docs.kubernetes.io` and
   `blog.kubernetes.io`.
1. PTR records are not required to properly configure a FQDN selector. For
   example, as long as an A record exists mapping `my-hostname` to `1.2.3.4`,
   the Network Policy implementation should allow traffic to `1.2.3.4`. There is
   no requirement that a PTR record for `1.2.3.4.in-addr.arpa` exist or that it
   points to `my-hostname` (it is allowed to point to `other-host`).
1. Targeting in-cluster endpoints with FQDN selector is not recommended. There
   are other selectors which can more precisely capture intent. However, if
   in-cluster endpoints are selected:
   *  ✅︎ Supported:
      *  Selecting Pods using their [generated DNS
         record](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pods)
         (for example `pod-ip-address.my-namespace.pod.cluster.local`). This is
         analogous to selecting the Pod by its IP address using the Network
         selector.
      * Headless Services can be selected using their [generated DNS
        record](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#services)
        because the generated DNS records contain a list of all the Pod IPs that
        back the service.
   *  ❌ Not Supported:
      * ClusterIP Services can not be selected using their [generated DNS
        record](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#services)
        (for example `my-svc.my-namespace.svc.cluster.local`). This is
        consistent with the behavior when selecting the Service VIP using the
        Network selector.
      * ExternalName Services return a `CNAME` record. See the entry below
        about CNAME support.
      * Any record which points to the IPs used for `LoadBalancer` type
        services. This includes the `externalIPs` and the
        `.status.loadBalancer.ingress` fields
1. If the specified domain in a FQDN selector resolves to a [CNAME
   record](#cname-records) the behavior of the implementor depends on the
   returned response.

   If the upstream resolver used [CNAME chasing](#cname-chasing) to fully
   resolve the domain to a A/AAAA record and returns the resulting chain, the
   implementor can use this information to allow traffic to the specified IPs.
   However the implementor does not need to perform their own CNAME chasing or
   to understand resolutions across multiple DNS requests.

   For example, if the FQDN selector is allowing traffic to `www.kubernetes.io`:
     *  If a DNS query to the upstream resolver returns *a single response* with
        the following records:
        ```
        www.kubernetes.io  --  CNAME to kubernetes.io
        kubernetes.io      --  A     to 1.2.3.4
        ```
        The implementor can use this response to allow traffic to `1.2.3.4`
     *  If DNS query only responds with a CNAME record, the resolver is not
        required to allow traffic even if subsequent requests resolve the full
        chain:
        ```
        # REQUEST 1

        www.kubernetes.io  --  CNAME to kubernetes.io
        
        # REQUEST 2

        kubernetes.io      --  A     to 1.2.3.4
        ```
        The implementer can still deny traffic to `1.2.3.4` because no single
        response contained the full chain required to resolve the domain.

### Recommended Behavior

The following recommendations are based on operational experience from existing
implementations and feedback gathered during KubeCon Atlanta 2025.

1. Pods should only make DNS requests to the canonical DNS server, because
   FQDN rules for a pod are only guaranteed to work after that pod makes an
   appropriate DNS request to the canonical DNS server (see [Expected
   Behavior](#expected-behavior)). If a pod queries an alternate DNS server
   (e.g. hardcoded `8.8.8.8`), the implementation may not observe the DNS
   response, and the FQDN Accept rule will simply not take effect. This is
   a functionality issue, not a security breach -- the pod's traffic is
   denied, not accidentally allowed. For example, when a pod queries the
   canonical DNS server for `my-service.com` and receives `1.2.3.4`, the
   implementation observes that response and learns that `my-service.com`
   maps to `1.2.3.4`. It can then enforce the FQDN Accept rule by allowing
   traffic to `1.2.3.4`. If the pod instead queries `8.8.8.8`, the
   implementation never sees the response and has no IP to allow -- the rule
   simply doesn't take effect.
1. Administrators should create a high-precedence Admin-tier rule allowing
   egress DNS traffic to the canonical DNS server (e.g. `kube-dns` in
   `kube-system`), to ensure that DNS is not blocked by other deny rules.
   For example:
   ```yaml
   apiVersion: policy.networking.k8s.io/v1alpha2
   kind: ClusterNetworkPolicy
   metadata:
     name: allow-dns
   spec:
     tier: Admin
     priority: 50
     subject:
       namespaces:
         matchLabels:
           requires-fqdn-policy: "true"
     egress:
     - name: "allow-dns"
       action: "Accept"
       to:
       - namespaces:
           matchLabels:
             kubernetes.io/metadata.name: "kube-system"
       protocols:
       - udp:
           destinationPort:
             number: 53
       - tcp:
           destinationPort:
             number: 53
   ```
1. Implementations that operate by snooping DNS responses on the wire MUST
   only trust responses originating from the canonical DNS server. Trusting
   responses from arbitrary sources is a security concern: a malicious actor
   could forge DNS responses to trick the implementation into allowing
   traffic to unintended IPs.
1. Implementations MAY provide a configurable grace period beyond the TTL to
   accommodate DNS propagation delays and client-side caching.
1. Although securing DNS resolution is a non-goal of this NPEP, implementations
   are recommended to consider mitigations for DNS cache poisoning (e.g.,
   DNSSEC validation by the canonical DNS server) when documenting their trust
   model.

## Connection Lifecycle on Policy Updates

When FQDN policies change, implementations must handle in-flight connections
gracefully. See the [Expected Behavior](#expected-behavior) section for DNS
record updates.

* **Policy addition**: New connections matching the FQDN are allowed once DNS
  resolution for the domain has been observed. Connections to IPs that haven't
  been observed via DNS are not guaranteed to be allowed.

## Alternatives

### IP Block Selector

IP blocks are an important tool for specifying Network Policies. However, they
do not address all user needs and have a few short-comings when compared to FQDN
selectors:

* IP-based selectors can become verbose if a single logical service has numerous
  IPs backing it.
* IP-based selectors pose an ongoing maintenance burden for administrators, who
  need to be aware of changing IPs.
* IP-based selectors can result in policies that are difficult to read and
  audit.

### L4 Proxy

Users can also configure a L4 Proxy (e.g. using SOCKS) to inspect their traffic
and implement egress firewalls. They present a few trade-ofs when compared to a
FQDN selector:

* Additional configuration and maintenance burden of the proxy application
  itself
* Configuring new routes to direct traffic leaving the application to the L4
  proxy.  

### L7 Policy

Another alternative is to provide a L7 selector, similar to the policies
provided by Service Mesh providers. While L7 selectors can offer more
expressivity, they often come trade-offs that are not suitable for all users:

* L7 selectors necessarily support a select set of protocols. Users may be
  using a custom protocol for application-level communication, but still want
  the ability to specify endpoints using DNS.
* L7 selectors often require proxies to perform deep packet inspection and
  enforce the policies. These proxies can introduce un-desireable latencies in
  the datapath of applications.

## References

* [NPEP #126](https://github.com/kubernetes-sigs/network-policy-api/issues/126):
  Egress Control in ANP

### Implementations

* [Antrea](https://antrea.io/docs/main/docs/antrea-network-policy/#fqdn-based-filtering)
* [Calico](https://docs.tigera.io/calico-enterprise/latest/network-policy/domain-based-policy)
* [Cilium](https://docs.cilium.io/en/latest/security/policy/language/#dns-based)
* [OpenShift](https://docs.openshift.com/container-platform/latest/networking/openshift_sdn/configuring-egress-firewall.html)

The following is a best-effort breakdown of capabilities of different
NetworkPolicy providers, as of 2023-09-25. This information may be out-of-date,
or inaccurate.

|                | Antrea                         | Calico       | Cilium       | OpenShift <br/> (current) | OpenShift <br/> (future) |
| -------------- | ------------------------------ | ------------ | ------------ | ------------------------- | ------------------------ |
| Implementation | DNS Snooping <br/> + Async DNS | DNS Snooping | DNS Snooping | Async DNS                 | DNS Snooping             |
| Wildcards      | ✅︎                              | ️✅︎           | ✅︎            | ❌                         | ✅︎                        |
| Egress Rules   | ✅︎                              | ️✅︎           | ✅︎            | ✅︎                         | ✅︎                        |
| Ingress Rules  | ❌                              | ️❌           | ❌            | ❌                         | ❌                        |
| Allow Rules    | ✅︎                              | ️✅︎           | ✅︎            | ✅︎                         | ✅︎                        |
| Deny Rules     | ✅︎                              | ️❌(?)        | ❌            | ✅︎                         | ❌(?)                     |

## Appendix

### CNAME Records

CNAME records are a type of DNS record (like a `A` or `AAAA`) that direct the
resolver to query another name to retrieve actual A/AAAA records.

For example:
```
$ dig www.kubernetes.io

... Omitted output ...

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.kubernetes.io.		IN	A

;; ANSWER SECTION:
www.kubernetes.io.	3600	IN	CNAME	kubernetes.io.
kubernetes.io.		3600	IN	A	147.75.40.148

... Omitted Output ...
```
### CNAME Chasing

CNAME chasing refers to an optional behavior for DNS resolvers whereby they
perform subsequent lookups to resolve CNAMEs returned for a particular query. In
the above example, querying for `www.kubernetes.io.` returned a CNAME record for
`kubernetes.io.`. When CNAME chasing is enabled, the DNS server will
automatically resolve `kubernetes.io.` and return both records as the DNS
response.
