---
resource: https://github.com/submariner-io/submariner/issues/4247
fetched: 2026-11-16
fetch_note: "gh api repos/submariner-io/submariner/issues/4247 + /comments (full thread, bodies verbatim)"
---

# #4247 Cilium: pod traffic to remote clusters is SNATed to the vx-submariner address by BPF masquerading

state: open () | created 2026-10-15T01:22:57Z | closed - | updated 2026-11-03T11:59:07Z | milestone: none | labels: 

## kurtyoon 2026-10-15T01:22:57Z

**What happened**:

On clusters running Cilium with kube-proxy replacement and BPF masquerading (the Cilium defaults for a
kube-proxy-free install), inter-cluster traffic from pods on non-gateway nodes fails. Cilium picks up
`vx-submariner` as one of its native devices as soon as the route agent creates it, and BPF masquerading
then rewrites the pod source address to the node's `vx-submariner` address (240.x). The gateway has no
IPsec policy for that source and answers with ICMP host unreachable.

`cilium status` on every node, a few seconds after Submariner is joined (no agent restart):

```
KubeProxyReplacement:   True   [eth0 172.19.0.5 ... (Direct Routing), vx-submariner 240.19.0.5 fe80::acff:fe13:5]
Routing:                Network: Tunnel [vxlan]   Host: BPF
Masquerading:           BPF   [eth0, vx-submariner]   10.2.1.0/24  [IPv4: Enabled, IPv6: Disabled]
```

BPF NAT entry on the client's (non-gateway) node:

```
TCP OUT 10.2.0.202:58936 -> 10.1.0.74:80 XLATE_SRC 240.19.0.4:58936
```

What arrives on the gateway's `vx-submariner`:

```
IP 240.19.0.4.45940 > 10.1.0.74.80: Flags [S]
IP 240.19.0.5 > 240.19.0.4: ICMP host 10.1.0.74 unreachable
```

Pods on gateway nodes take a different path and are not affected by this, which matches what was reported
in #3159 (traffic only working when both pods run on gateway nodes).

**What you expected to happen**:

The pod source address is preserved and the connection succeeds, as on netfilter-based CNIs.

**How to reproduce it (as minimally and precisely as possible)**:

1. Two kind clusters with non-overlapping CIDRs, `kubeProxyMode: none`, default CNI disabled.
2. Cilium 1.20.2 via Helm: `kubeProxyReplacement=true`, `bpf.masquerade=true`, `routingMode=tunnel`,
   `tunnelProtocol=vxlan`, `ipam.mode=kubernetes`. `devices` left unset.
3. `subctl deploy-broker`, `subctl join` both clusters (v0.24.2, libreswan, no Globalnet).
4. From a pod on a non-gateway node, curl a pod on a non-gateway node in the other cluster.

`subctl verify --only basic-connectivity` fails on "pod not on a gateway to remote pod not on a gateway".

**Anything else we need to know?**:

Cilium's device auto-detection has no exclusion for vxlan devices and accepts addresses in 240.0.0.0/4
(`pkg/datapath/linux/devices_controller.go`, `isSelectedDevice`), so `vx-submariner` qualifies through its
connected `240.0.0.0/8` route. Either of these restores pod-to-pod connectivity in the same setup:

- pin Cilium's devices to the uplink, e.g. `devices: "eth+"`, so no Cilium program is attached to
  `vx-submariner`;
- enable Cilium's ip-masq-agent with a `nonMasqueradeCIDRs` list that contains the remote cluster CIDRs.
  Enabling it without a ConfigMap also works for this path, but it applies Cilium's built-in list (all of
  RFC 1918) and stopped pod traffic to the broker API server from being masqueraded in my setup.

Remote ClusterIP services and pods on gateway nodes still fail after either fix; those have separate
causes and I'll describe them in the Cilium proposal that follows up on #3168 and #4105.

**Environment**:

- Diagnose and gather output: I no longer have the clusters up, but I can rebuild them and attach both if useful
- Cloud provider or hardware configuration: kind v0.33.0 (node v1.37.0) on Docker, arm64, kernel 6.8.0
- Install tools: subctl v0.24.2 (release-0.24 images)
- Others: Cilium 1.20.2, cable driver libreswan, no Globalnet


## yboaron 2026-11-03T11:51:22Z

Thanks for the detailed explanation, @kurtyoon. 

Yep, this is a known limitation: Cilium's IPv4 masquerading conflicts with Submariner's source IP preservation requirement (see this reference guide: [https://medium.com/@yboaron/connecting-k8s-cilium-cluster-and-k8s-calico-cluster-using-submariner-d56d7c39f0cb](https://medium.com/@yboaron/connecting-k8s-cilium-cluster-and-k8s-calico-cluster-using-submariner-d56d7c39f0cb)).

Also note that Submariner is not fully supported with Cilium, contributions to improve Cilium support are always welcome 


## kurtyoon 2026-11-03T11:59:07Z

@yboaron Thanks for the clarification!

I actually have a few ideas for improving Cilium support in Submariner, and I’m currently working on an SEP to propose them.

I’ll try to submit it by the end of this week. Looking forward to hearing your thoughts!

