---
resource: https://github.com/cilium/cilium/issues/23380
fetched: 2026-11-16
fetch_note: "gh api repos/cilium/cilium/issues/23380 + /comments (full thread, bodies verbatim)"
---

# #23380 CFP: Support ClusterNetworkPolicy 

state: closed (completed) | created 2023-01-26T11:44:42Z | closed 2026-09-09T20:16:15Z | updated 2026-09-10T14:08:06Z | milestone: none | labels: area/datapath, kind/feature, sig/policy, pinned, area/agent, kind/cfp

## sathieu 2023-01-26T11:44:42Z

## Cilium Feature Proposal
**Is your feature request related to a problem?**

No

**Describe the feature you'd like**

Support for AdminNetworkPolicy, as described in https://github.com/kubernetes/enhancements/issues/2091




## pchaigno 2023-02-08T22:35:08Z

FYI, the difficult part here is the priority-based policies. It's generally difficult to build packet classification algorithms that take priorities into account while being efficient at scale.


## sathieu 2023-02-11T11:22:58Z

@pchaigno Thanks for the info. I don't know if Cilium was involved in defining the specs, and maybe something was missed at that time. I see that AdminNetworkPolicy (with BaselineAdminNetworkPolicy) is half of the future NPv2, the other being developper-focused policies (mabe by using current NetworkPolicies).

As cluster admins, we need cluster-scoped firewall rules (both baseline rules, overrridable ; and  non-overridable rules). Current [CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumclusterwidenetworkpolicy) lacks some of our needs:

- rules are overridable by namespace-scoped resources
- when a pod is matched by a rule, the pod goes to default deny

Also we prefer to use non vendor-specific CRDs.

AdminNetworkPolicy (with BaselineAdminNetworkPolicy) match our needs, but the priority field is a very complex way to fulfill our needs (as mentioned [here](https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/2091-admin-network-policy#risks-and-mitigation)).


## ysksuzuki 2023-04-07T05:23:21Z

I'm interested in the AdminNetworkPolicy support because we see the potential to make our policy setup simple and easy to maintain. I'm wondering if it would be possible to interpret the AdminNetworkPolicy manifests on the agent side and put the data in the policy map with the current data structure(or with some tweaks). Obviously, it's not that easy though. I think it's worth trying it.




## tssurya 2023-04-20T13:58:49Z

/cc

I work on the upstream ANP/BANP API: https://github.com/kubernetes-sigs/network-policy-api 
I am interested in this issue as we are looking to unify the way CNIs do the NP API's to align with the upstream one. Let us know if there are any major "can't implement or translate this x part of the API in our plugin" kind of roadblocks and please feel free to give us feedback on use cases we might not have considered. We are currently on the alphav1 version and want to understand the challenges implementors are running into before graduation.

I can see there is a note https://github.com/cilium/cilium/issues/23380#issuecomment-1423328510 on the difficultly of implementing the "priority" field.. Is that only from a point of view of efficiency or other aspects as well? Priority is actually a powerful way to classify the rules for the API specially since the scope is cluster-wide..


## github-actions[bot] 2023-06-20T01:56:35Z

This issue has been automatically marked as stale because it has not
had recent activity. It will be closed if no further activity occurs.


## sathieu 2023-06-20T05:28:54Z

not stale

NB: we are able to workaround the feature by using [`always`  Policy Enforcement Mode](https://docs.cilium.io/en/stable/security/policy/intro/#policy-enforcement-modes) and [Deny policies](https://docs.cilium.io/en/stable/security/policy/language/#id8). However, this is Cilium-specific.


## aojea 2023-06-22T19:06:04Z

/cc


## danehans 2023-07-18T16:37:37Z

/cc


## pchaigno 2023-07-18T17:00:28Z

Hi everyone,
This is the official GitHub "cc" button :smile_cat: :point_down: 
<img src="https://github.com/cilium/cilium/assets/1764210/63bd8434-dc97-496d-b84d-25329779f4cc" width="500">


## oblazek 2024-01-25T14:33:06Z

> NB: we are able to workaround the feature by using [always Policy Enforcement Mode](https://docs.cilium.io/en/stable/security/policy/intro/#policy-enforcement-modes) and [Deny policies](https://docs.cilium.io/en/stable/security/policy/language/#id8). However, this is Cilium-specific.

agree, we are forced to do the same via CCNPs and letting our users to create only CNPs


## squeed 2024-05-03T10:32:59Z

We are definitely looking in to this; the tricky bit is determining exactly how to implement ordering within the `toMapState()` empire. Specifically, the precedence logic within [denyPreferredInsert](https://github.com/cilium/cilium/blob/f1925b59247739ab3beb5ed3b395025d887c2825/pkg/policy/mapstate.go#L767) will need to be ordering-aware.

It will probably not happen for v1.16, but we are laying the ground work as part of port-range support. Hopefully we will be ready to go for v1.17


## danehans 2024-05-13T16:31:38Z

> It will probably not happen for v1.16, but we are laying the ground work as part of port-range support.

@squeed do you have a link to any issues/PRs related for this work?


## bowei 2024-11-13T18:25:04Z

I'm interested in helping out on this one.

I'm curious about the efficiency issue -- the use of priorities does (naively) require a chained implementation. I'm assuming g(enerally speaking), Cilium is looking for an O(1) implementation in the datapath?


## hemanthmalla 2024-11-13T18:30:56Z

@bowei Yes, thats my understanding based on some discussions in previous sig-policy meetings. 


## pchaigno 2024-11-14T11:40:50Z

We used to have an O(1), hashmap-based implementation for the policy lookups (not including the identity resolution). But [it changed somewhat recently](https://github.com/cilium/cilium/pull/23885) and now uses LPM map lookups.


## tamilmani1989 2024-11-18T19:42:27Z

is there any design doc or proposal started for this feature?


## bowei 2024-12-03T06:51:11Z

I'm starting to collect info for a design doc.


## bowei 2025-01-24T23:10:38Z

For reference, I've started putting together some sketches to get the idea collection going. Would appreciate any suggestions/comments:

https://docs.google.com/document/d/1oO8K4deI4dHjpKWd0ICj0htUklT-2C0krBKjcGcR-CM/edit?tab=t.0

Happy to discuss this on `sig-policy` channel on Cilium Slack


## sathieu 2026-08-28T09:31:00Z

I've renamed this issue to ClusterNetworkPolicy.

It's supported in Cilium 1.20 ([ref](https://isovalent.com/blog/post/cilium-1-20/#kubernetes-clusternetworkpolicy-kcnp-support)), but [behind a feature-flag](https://docs.cilium.io/en/v1.20/network/kubernetes/policy/#kubernetes-clusternetworkpolicy) `--enable-k8s-cluster-network-policy`.

I don't know if this should be closed now, or once the flag is enabled by default.


## TheBeeZee 2026-09-09T20:17:36Z

I think it's fine to close this as completed. The main reason we didn't enable it by default in 1.20 is because it is an alpha API. The k8s sig-network-policy is hoping to release a v1beta1 of the API (with no actual API changes) soon-ish and I think that would be a good opportunity to make the feature enabled by default.


## squeed 2026-09-10T09:08:59Z

@TheBeeZee seems reasonable. Are you satisfied with the state of kCNP CI? Should we make a follow-up issue to update CI when v1beta1 cuts?


## TheBeeZee 2026-09-10T14:08:06Z

> [@TheBeeZee](https://github.com/TheBeeZee) seems reasonable. Are you satisfied with the state of kCNP CI? Should we make a follow-up issue to update CI when v1beta1 cuts?

There is still a number of things I want to complete:
* Implement flags for enabling FQDN policy (in progress)
* Add the ability to auto-install the CRD
* Improve CI
* Enable KCNP by default
* Update to v1beta1 (when released)

Unless you disagree, this CFP is likely not the right issue to track this.

