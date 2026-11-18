---
resource: https://github.com/submariner-io/submariner-website/tree/48be461510784fe41e718dd4e597ecc1fd3e415c/src/content
fetched: 2026-11-16
fetch_note: "git clone --depth 1 submariner-io/submariner-website@48be461510784fe41e718dd4e597ecc1fd3e415c (2026-11-03)"
---


<!-- submariner-website/src/content/getting-started/architecture/_index.en.md lines 6,18 -->

<!-- markdownlint-disable line-length -->
Submariner connects multiple Kubernetes clusters in a way that is secure and performant. Submariner flattens the networks between the
connected clusters, and enables IP reachability between Pods and Services. Submariner also provides, via Lighthouse, service discovery
capabilities. The service discovery model is built using the proposed
[Kubernetes Multi Cluster Services](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api).
<!-- markdownlint-enable line-length -->
Submariner consists of several main components that work in conjunction to securely connect workloads across multiple Kubernetes clusters,
both on-premises and on public clouds:

* [Gateway Engine](./gateway-engine/): manages the secure tunnels to other clusters.
* [Route Agent](./route-agent/): routes cross-cluster traffic from nodes to the active Gateway Engine.
* [Broker](./broker/): facilitates the exchange of metadata between Gateway Engines enabling them to discover one another.
* [Service Discovery](./service-discovery/): provides DNS discovery of Services across clusters.

<!-- submariner-website/src/content/getting-started/architecture/gateway-engine/_index.en.md lines 8,16 -->


The Gateway Engine has a pluggable architecture for the cable engine component
that maintains the tunnels. The following implementations are available:

* an IPsec implementation using [Libreswan](https://libreswan.org/). This is currently the default.
* an implementation for [WireGuard](https://www.wireguard.com/) (via the [wgctrl](https://github.com/WireGuard/wgctrl-go) library).
* an un-encrypted tunnel implementation using VXLAN.

The cable driver can be specified via the `--cable-driver` flag while joining a cluster using `subctl`. For more information, please refer

<!-- submariner-website/src/content/getting-started/_index.en.md lines 170,182 -->

## Support Matrix

Submariner is designed to be cloud provider agnostic, and should run in any standard Kubernetes cluster. Submariner has been tested with the
following network (CNI) Plugins:

* [OpenShift-SDN](https://github.com/openshift/sdn)
* [Weave](https://github.com/weaveworks/weave)
* [Flannel](https://github.com/coreos/flannel)
* [Canal](https://docs.tigera.io/calico/latest/getting-started/kubernetes/flannel/install-for-flannel)
* [Calico](https://www.projectcalico.org/) (see the [Calico-specific deployment instructions](../operations/deployment/calico/))
* [OVN](https://github.com/ovn-org/ovn-kubernetes) - Requires OVN NorthBound DB version 6.1.0+

Submariner supports all currently-supported Kubernetes versions, as determined by [the Kubernetes release policy](https://kubernetes.io/releases/).

<!-- submariner-website/src/content/community/role-ecosystem/_index.en.md lines 13,58 -->

This page highlights Submariner’s role within the ecosystem and touches on how it compares to some of these other projects.

## Submariner

**Networking Focus**: Submariner is primarily focused on providing network connectivity at layer 3. It establishes tunnels between clusters
to facilitate direct communication between pods and services. Submariner operates at layer 3 of the OSI model, which means it can support
communication for any type of application data or protocol. However, setting up Submariner does require some administrative overhead,
particularly in configuring firewall rules in the underlying infrastructure.

**Service Discovery**: Submariner provides an implementation of the Multi-cluster Services API (MCS API), an initiative within the
Kubernetes ecosystem aimed at standardizing the management of services across multiple Kubernetes clusters, and follows its core principal
of “namespace sameness” whereby Kubernetes namespaces behave consistently and seamlessly across interconnected clusters.

**Use Cases**: It is well-suited for scenarios where you need to create a unified permanent network across geographically distributed
clusters, ensuring seamless pod-to-pod communication and service discovery.

**Connectivity Domain**: Submariner primarily focuses on interconnecting Kubernetes clusters. However, Submariner also provides an
experimental feature that allows access to external applications or endpoints that exist outside of the cluster, in non-Kubernetes
environments. It's important to note that while this [experimental feature](../../getting-started/quickstart/external/) exists, it might not
be as mature or stable as Submariner's core functionalities. Users interested in leveraging Submariner for accessing external applications
should consider testing and evaluating this feature in their specific use cases.

**Integration**: Submariner integrates with various networking solutions and can work alongside existing CNI
(Container Network Interface) plug-ins like Calico, Flannel, etc., ensuring compatibility with different Kubernetes environments.

**Security**: Provides secure communication between clusters using IPsec tunnels by default, which encrypt traffic between clusters.

## Comparison Summary

- **Submariner** focuses on establishing a unified network between Kubernetes clusters, ensuring secure pod-to-pod communication and service
discovery.

- **Skupper** leverages messaging functionalities to facilitate flexible communication across end-points. While Skupper provides support for
linking namespaces across different Kubernetes clusters, it can also be used to support non-Kubernetes environments, including bare-metal,
VMs or services running as Docker or Podman containers. It’s important to note that Skupper utilizes a layer 7-based mechanism for
establishing connectivity. This approach supports selected application protocols today, including HTTP/1.1, HTTP/2, gRPC, and TCP
communication.

- **Istio** provides a robust service mesh with advanced traffic management, policy and security features primarily designed for
intra-cluster communication but can be extended to manage communication across clusters with additional setup.

- Projects like **Calico** and **Cilium**, which integrate with Kubernetes using the Container Network Interface (CNI), require that the
same CNI plug-in is configured consistently across all interconnected clusters for multi-cluster connectivity solutions to work effectively.

Choosing between these solutions would depend on your specific use case requirements regarding network connectivity, service discovery,
security needs, and integration preferences within a multi-cluster environment.
