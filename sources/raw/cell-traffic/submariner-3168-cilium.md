---
resource: https://github.com/submariner-io/submariner/issues/3168
fetched: 2026-11-16
fetch_note: "gh api repos/submariner-io/submariner/issues/3168 + /comments (full thread, bodies verbatim)"
---

# #3168 Add support for Cilium CNI

state: open () | created 2024-09-24T10:02:56Z | closed - | updated 2026-07-22T14:46:31Z | milestone: none | labels: enhancement, help wanted, cilium

## yboaron 2024-09-24T10:02:56Z

<!-- Please only use this template for submitting enhancement requests -->

**What would you like to be added**:

I am creating this issue to track Submariner support for Cilium CNI.

Currently, Cilium CNI is recognized as a generic CNI by Submariner, and subctl verify e2e tests [seem to fail](https://github.com/submariner-io/submariner/issues/3159#issuecomment-2352351748) on clusters with Cilium CNI.


**Why is this needed**:

Enable multi-cluster networking using Submariner on clusters with Cilium CNI.

**Other Info**:

In order to support new CNI in Submariner there is a need to update the following functions:


- [CNI network discovery](https://github.com/submariner-io/submariner-operator/blob/devel/pkg/discovery/network/network.go#L71) - responsible for pod,service CIDRs and CNI plugin name auto-discovery.
- Submariner RouteAgent handlers (optional) - used to apply configuration specific for CNI, check [Calico ippool handler](https://github.com/submariner-io/submariner/blob/devel/pkg/routeagent_driver/handlers/calico/ippool_handler.go) for example.


## dfarrell07 2024-09-24T18:07:13Z

@gk-fschubert agreed to help with this one in https://github.com/submariner-io/submariner/issues/3159#issuecomment-2371940830. Thanks! You can assign yourself here (I'd do it, but can't due to GitHub anti-spam restrictions).


## yboaron 2024-11-14T08:57:45Z

This [post](https://medium.com/@yboaron/d56d7c39f0cb) covers Submariner deployment on K8S-Kind/Cilium and K8S-Kind/Calico clusters


## github-actions[bot] 2025-03-15T00:16:20Z

This issue has been automatically marked as stale because it has not had recent activity. It will be closed if no further
activity occurs. Thank you for your contributions.


## github-actions[bot] 2025-07-17T00:20:06Z

This issue has been automatically marked as stale because it has not had recent activity. It will be closed if no further
activity occurs. Thank you for your contributions.


## github-actions[bot] 2025-11-20T00:18:23Z

This issue has been automatically marked as stale because it has not had recent activity. It will be closed if no further
activity occurs. Thank you for your contributions.


## dfarrell07 2025-11-25T14:05:25Z

We're looking for contributors to work on Cilium tasks for SubM if anyone is willing to step up.


## jdaln 2026-03-20T10:51:06Z

Is there anything new on this front or is it mostly waiting for someone to implement nftables to eBPF?
\+ of course what what @yboaron points out


## yboaron 2026-03-23T11:30:48Z

>Is there anything new on this front

Not much; we're still looking for a contributor to lead Cilium implementation for Submariner,  we’d love to see some community contributions on this task.


## github-actions[bot] 2026-07-22T00:31:49Z

This issue has been automatically marked as stale because it has not had recent activity. It will be closed if no further
activity occurs. Thank you for your contributions.


## jdaln 2026-07-22T09:11:11Z

If plans don't change, I should be looking into it in September. Happy to have people reach out if they have the same need.

