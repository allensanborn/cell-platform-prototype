---
resource: https://github.com/cilium/cilium/blob/v1.20.4/Documentation/network/kubernetes/policy.rst
fetched: 2026-11-16
fetch_note: "gh api contents cilium/cilium?ref=v1.20.4 (tag commit 6660d6eac7f93a2176ac039f03e7f2bf885bdb2e, released 2026-10-23)"
---


<!-- cilium-policy-v1.20.4.rst lines 55,83 -->

Kubernetes ClusterNetworkPolicy
===============================

Support for the Kubernetes ClusterNetworkPolicy (KCNP) is available starting with Cilium 1.20.
For more information, see the official `ClusterNetworkPolicy documentation
<https://network-policy-api.sigs.k8s.io/api-overview/>`_.

Enabling KCNP
-------------

Support must be enabled by setting the ``--enable-k8s-cluster-network-policy`` flag to ``true`` (or equivalent Helm value ``k8sClusterNetworkPolicy.enabled=true``). You also must install the Custom Resource Definition (CRD) from `sigs.k8s.io/network-policy-api <https://sigs.k8s.io/network-policy-api>`_:

.. code-block:: shell-session

    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/network-policy-api/release-0.2/config/crd/standard/policy.networking.k8s.io_clusternetworkpolicies.yaml

The KCNP API specifies that CIDR rules must also match pod and node IPs. For full conformance, set the :ref:`--policy-cidr-match-mode <cidr_select_nodes>` flag to ``pods,nodes``.

Tiers
-----

The KCNP API uses tiers as top-level groupings for policy evaluation. Policy rules are evaluated in the following order:

1. **Admin tier**: High-priority security rules set by cluster administrators.
2. **NetworkPolicy tier**: Workload and cluster rules, including standard `NetworkPolicy`, `CiliumNetworkPolicy`, and `CiliumClusterwideNetworkPolicy`.
3. **Baseline tier**: Default guardrails set by cluster administrators.

A Kubernetes ClusterNetworkPolicy can be assigned to either the Admin or Baseline tier. Rules in the Admin tier take precedence over all policies at the NetworkPolicy tier level, including CiliumClusterwideNetworkPolicy, CiliumNetworkPolicy, and standard NetworkPolicy resources and cannot be overridden by them. Keep this in mind when migrating from CiliumClusterwideNetworkPolicy to Kubernetes ClusterNetworkPolicy.

