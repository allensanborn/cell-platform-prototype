---
type: source
resource: https://docs.cilium.io/en/stable/security/policy/kubernetes/
title: "Cilium — Policy intro, Kubernetes/clusterwide policies, deny policies, Cluster Mesh intro"
source_kind: webpage
tags: [cilium, ciliumclusterwidenetworkpolicy, deny-policy, clustermesh, multi-cluster]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/cilium/cilium/contents/Documentation/{security/policy/intro.rst,security/policy/kubernetes.rst,security/policy/deny.rst,network/clustermesh/intro.rst}?ref=v1.20.4 raw, 2026-11-13. RST verbatim, concatenated."
---


<!-- ===== cilium-security-policy-intro.rst ===== -->

.. only:: not (epub or latex or html)

    WARNING: You are looking at unreleased Cilium documentation.
    Please use the official rendered version released here:
    https://docs.cilium.io

.. _policy_guide:

.. _policy_enforcement_modes:

Policy Enforcement Modes
========================

The configuration of the Cilium agent and the Cilium Network Policy determines whether an endpoint accepts traffic from a source or not. The agent can be put into the following three policy enforcement modes:

default
  This is the default behavior for policy enforcement. In this mode, endpoints
  have unrestricted network access until selected by policy. Upon being selected by
  a policy, the endpoint permits only allowed traffic. This state is per-direction
  and can be adjusted on a per-policy basis. For more details, :ref:`see the dedicated section on default mode<policy_mode_default>`.

always
  With always mode, policy enforcement is enabled on all endpoints even if no
  rules select specific endpoints.

  If you want to configure health entity to check cluster-wide connectivity when 
  you start cilium-agent with ``enable-policy: always``, you will likely want to
  enable communications to and from the health endpoint. See :ref:`health_endpoint`.

never
  With never mode, policy enforcement is disabled on all endpoints, even if
  rules do select specific endpoints. In other words, all traffic is allowed
  from any source (on ingress) or destination (on egress).

To :ref:`configure <k8s_configuration>` the policy enforcement mode, adjust the Helm value
``policyEnforcementMode`` or the corresponding configuration flag ``enable-policy``.

.. _policy_mode_default:

Endpoint default policy
-----------------------

By default, all egress and ingress traffic is allowed for all endpoints. When
an endpoint is selected by a network policy, it transitions to a default-deny
state, where only **explicitly allowed** traffic is permitted. This state is
per-direction:

* If any rule selects an :ref:`endpoint` and the rule has an ingress
  section, the endpoint goes into default deny-mode for ingress.
* If any rule selects an :ref:`endpoint` and the rule has an egress section, the
  endpoint goes into default-deny mode for egress.

This means that endpoints start without any restrictions, and the first
policy will switch the endpoint's default enforcement mode (per direction).

It is possible to create policies that do not enable the default-deny mode for selected
endpoints. The field ``EnableDefaultDeny`` configures this. Rules with ``EnableDefaultDeny``
disabled are ignored when determining the default mode.

For example, this policy causes all DNS traffic to be intercepted, but does not
block any traffic, even if it is the first policy to apply to an endpoint. An
administrator can safely apply this policy cluster-wide, without the risk that
it transitions an endpoint in to default-deny and causes legitimate traffic to be dropped.

.. warning::
  ``EnableDefaultDeny`` does not apply to :ref:`layer-7 policy <l7_policy>`.
  Adding a layer-7 rule that does not include a layer-7 allow-all will cause drops,
  even when default-deny is explicitly disabled.

.. code-block:: yaml

  apiVersion: cilium.io/v2
  kind: CiliumClusterwideNetworkPolicy
  metadata:
    name: intercept-all-dns
  spec:
    endpointSelector:
      matchExpressions:
        - key: "io.kubernetes.pod.namespace"
          operator: "NotIn"
          values:
          - "kube-system"
        - key: "k8s-app"
          operator: "NotIn"
          values:
          - kube-dns
    enableDefaultDeny:
      egress: false
      ingress: false
    egress:
      - toEndpoints:
          - matchLabels:
              io.kubernetes.pod.namespace: kube-system
              k8s-app: kube-dns
        toPorts:
          - ports:
            - port: "53"
              protocol: TCP
            - port: "53"
              protocol: UDP
            rules:
              dns:
                - matchPattern: "*"

Policy Deny Response Handling
==============================

By default, when network policy denies egress traffic from a pod, Cilium silently drops the packets.
This means applications experience connection timeouts rather than immediate connection failures when attempting to reach forbidden destinations.

However, some applications may benefit from receiving explicit rejection notifications instead of experiencing connection timeouts.
This can provide faster feedback to applications and improve user experience by reducing wait times.

This behavior can be configured with the ``--policy-deny-response`` option:

**none** (default)
  Silently drop denied packets. Applications will experience connection timeouts when policy denies traffic.

**icmp** (experimental)
  Send an ICMP Destination Unreachable response back to the source pod when egress traffic is denied by policy.
  This provides immediate feedback to applications that the connection was rejected.

.. note::
   This is an experimental feature and only applies to ipv4 and ipv6 egress pod traffic denied by network policy.
   Ingress traffic denial behavior is not supported currently. Check :gh-issue:`41859` for updates

.. warning::
   When using ``--policy-deny-response=icmp``, ensure that ICMP ingress traffic is allowed by your network policies. 
   If ICMP traffic is blocked by ingress policies, applications will not receive 
   the rejection notifications and will still experience connection timeouts.

.. _policy_rule:

Rule Basics
===========

All policy rules are based upon a whitelist model, that is, each rule in the
policy allows traffic that matches the rule. If two rules exist, and one
would match a broader set of traffic, then all traffic matching the broader
rule will be allowed. If there is an intersection between two or more rules,
then traffic matching the union of those rules will be allowed. Finally, if
traffic does not match any of the rules, it will be dropped pursuant to the
`policy_enforcement_modes`.

Policy rules share a common base type which specifies which endpoints the
rule applies to and common metadata to identify the rule. Each rule is split
into an ingress section and an egress section. The ingress section contains
the rules which must be applied to traffic entering the endpoint, and the
egress section contains rules applied to traffic coming from the endpoint
matching the endpoint selector. Either ingress, egress, or both can be
provided. If both ingress and egress are omitted, the rule has no effect.

.. code-block:: go

        type Rule struct {
                // EndpointSelector selects all endpoints which should be subject to
                // this rule. EndpointSelector and NodeSelector cannot be both empty and
                // are mutually exclusive.
                //
                // +optional
                EndpointSelector EndpointSelector `json:"endpointSelector,omitempty"`

                // NodeSelector selects all nodes which should be subject to this rule.
                // EndpointSelector and NodeSelector cannot be both empty and are mutually
                // exclusive. Can only be used in CiliumClusterwideNetworkPolicies.
                //
                // +optional
                NodeSelector EndpointSelector `json:"nodeSelector,omitempty"`

                // Ingress is a list of IngressRule which are enforced at ingress.
                // If omitted or empty, this rule does not apply at ingress.
                //
                // +optional
                Ingress []IngressRule `json:"ingress,omitempty"`

                // Egress is a list of EgressRule which are enforced at egress.
                // If omitted or empty, this rule does not apply at egress.
                //
                // +optional
                Egress []EgressRule `json:"egress,omitempty"`

                // Labels is a list of optional strings which can be used to
                // re-identify the rule or to store metadata. It is possible to lookup
                // or delete strings based on labels. Labels are not required to be
                // unique, multiple rules can have overlapping or identical labels.
                //
                // +optional
                Labels labels.LabelArray `json:"labels,omitempty"`

                // Description is a free form string, it can be used by the creator of
                // the rule to store human readable explanation of the purpose of this
                // rule. Rules cannot be identified by comment.
                //
                // +optional
                Description string `json:"description,omitempty"`
        }

----

endpointSelector / nodeSelector
  Selects the endpoints or nodes which the policy rules apply to. The policy
  rules will be applied to all endpoints which match the labels specified in
  the selector. For additional details, see the :ref:`EndpointSelector` and
  :ref:`NodeSelector` sections.

ingress
  List of rules which must apply at ingress of the endpoint, i.e. to all
  network packets which are entering the endpoint.

egress
  List of rules which must apply at egress of the endpoint, i.e. to all network
  packets which are leaving the endpoint.

labels
  Labels are used to identify the rule. Rules can be listed and deleted by
  labels. Policy rules which are imported via :ref:`kubernetes<k8s_policy>`
  automatically get the label ``io.cilium.k8s.policy.name=NAME`` assigned where
  ``NAME`` corresponds to the name specified in the `NetworkPolicy` or
  `CiliumNetworkPolicy` resource.

description
  Description is a string which is not interpreted by Cilium. It can be used to
  describe the intent and scope of the rule in a human readable form.

.. _EndpointSelector:

Endpoint Selector
-----------------

The Endpoint Selector is based on the `Kubernetes LabelSelector`_. It is called
Endpoint Selector because it only applies to labels associated with an
:ref:`Endpoint <endpoint>`.

.. _NodeSelector:

Node Selector
-------------

Like the :ref:`Endpoint Selector <EndpointSelector>`, the Node Selector is
based on the `Kubernetes LabelSelector`_, although rather than
matching on labels associated with Endpoints, it applies to labels associated
with :ref:`Nodes <node>` in the cluster.

Node Selectors can only be used in :ref:`CiliumClusterwideNetworkPolicies
<CiliumClusterwideNetworkPolicy>`. For details on the scope of node-level
policies, see :ref:`HostPolicies`.

.. _Kubernetes LabelSelector: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors

<!-- ===== cilium-security-policy-kubernetes.rst ===== -->

.. only:: not (epub or latex or html)

    WARNING: You are looking at unreleased Cilium documentation.
    Please use the official rendered version released here:
    https://docs.cilium.io

Using Kubernetes Constructs In Policy
=====================================

This section covers Kubernetes specific network policy aspects.

.. _k8s_namespaces:

Namespaces
----------

`Namespaces <https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>`_
are used to create virtual clusters within a Kubernetes cluster. All Kubernetes objects
including `NetworkPolicy` and `CiliumNetworkPolicy` belong to a particular
namespace.

Known Pitfalls
--------------

This section covers known pitfalls when using Kubernetes constructs in policy.

Considerations Of Namespace Boundaries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Depending on how a policy is defined and created, Kubernetes namespaces are automatically taken into account.

Network policies imported directly with the :ref:`api_ref` apply to all
namespaces unless a namespace selector is specified as described in
:ref:`example_cnp_ns_boundaries`.

.. _example_cnp_ns_boundaries:

Example
^^^^^^^

This example demonstrates how to enforce Kubernetes namespace-based boundaries
for the namespaces ``ns1`` and ``ns2`` by enabling default-deny on all pods of
either namespace and then allowing communication from all pods within the same
namespace.

.. note:: The example locks down ingress of the pods in ``ns1`` and ``ns2``.
	  This means that the pods can still communicate egress to anywhere
	  unless the destination is in either ``ns1`` or ``ns2`` in which case
	  both source and destination have to be in the same namespace. In
	  order to enforce namespace boundaries at egress, the same example can
	  be used by specifying the rules at egress in addition to ingress.

.. literalinclude:: ../../../examples/policies/kubernetes/namespace/isolate-namespaces.yaml
  :language: yaml

Policies Only Apply Within The Namespace
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Network policies created and imported as `CiliumNetworkPolicy` CRD and
`NetworkPolicy` apply within the namespace. In other words, the policy **only** applies
to pods within that namespace. It's possible, however, to grant access to and
from pods in other namespaces as described in :ref:`example_cnp_across_ns`.

.. _example_cnp_across_ns:

Example
^^^^^^^

The following example exposes all pods with the label ``name=leia`` in the
namespace ``ns1`` to all pods with the label ``name=luke`` in the namespace
``ns2``.

Refer to the :git-tree:`example YAML files <examples/policies/kubernetes/namespace/demo-pods.yaml>`
for a fully functional example including pods deployed to different namespaces.

.. literalinclude:: ../../../examples/policies/kubernetes/namespace/namespace-policy.yaml
  :language: yaml

Specifying Namespace In EndpointSelector, FromEndpoints, ToEndpoints
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Specifying the namespace by way of the label
``k8s:io.kubernetes.pod.namespace`` in the ``fromEndpoints`` and
``toEndpoints`` fields is supported as described in 
:ref:`example_cnp_egress_to_kube_system`.
However, Kubernetes prohibits specifying the namespace in the ``endpointSelector``,
as it would violate the namespace isolation principle of Kubernetes. The
``endpointSelector`` always applies to pods in the namespace 
associated with the `CiliumNetworkPolicy` resource itself.

.. _example_cnp_egress_to_kube_system:

Example
^^^^^^^

The following example allows all pods in the ``public`` namespace in which the
policy is created to communicate with kube-dns on port 53/UDP in the ``kube-system``
namespace.

.. literalinclude:: ../../../examples/policies/kubernetes/namespace/kubedns-policy.yaml
  :language: yaml

Namespace Specific Information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Namespace-specific information such as ``io.cilium.k8s.namespace.labels``
can be used within ``fromEndpoints`` and ``toEndpoints`` in both
:ref:`CiliumNetworkPolicy` and :ref:`CiliumClusterwideNetworkPolicy` resources
to match pods based on the labels of the namespace they belong to.

The label format is ``io.cilium.k8s.namespace.labels.<label-key>``, where
``<label-key>`` corresponds to a label on the Kubernetes namespace.

When namespace labels are specified in a ``fromEndpoints`` or ``toEndpoints``
selector within a :ref:`CiliumNetworkPolicy`, the selector is not implicitly
restricted to the policy's own namespace. This allows matching pods across
namespaces based on namespace labels.

.. note:: The ``endpointSelector`` always applies to pods in the namespace
          associated with the :ref:`CiliumNetworkPolicy` resource itself, regardless
          of any namespace labels used in ``fromEndpoints`` or ``toEndpoints``.

.. _example_cnp_namespace_labels:

Example
^^^^^^^

The following example restricts ``rebel-base`` pods to only communicate with
pods in namespaces labeled ``faction: alliance``. As the Rebel Alliance
operates across multiple namespaces, namespace labels allow this policy to
apply to all Alliance namespaces without listing each one by name.

.. literalinclude:: ../../../examples/policies/kubernetes/namespace/namespace-labels-policy.yaml
  :language: yaml

Match Expressions
~~~~~~~~~~~~~~~~~

When using ``matchExpressions`` in a :ref:`CiliumNetworkPolicy` or a
:ref:`CiliumClusterwideNetworkPolicy`, the list values are
treated as a logical AND. If you want to match multiple keys
with a logical OR, you must use multiple ``matchExpressions``.

.. _example_multiple_match_expressions:

Example
^^^^^^^

This example demonstrates how to enforce a policy with multiple ``matchExpressions``
that achieves a logical OR between the keys and its values.

.. literalinclude:: ../../../examples/policies/l3/match-expressions/or-statement.yaml
  :language: yaml

The following example shows a logical AND using a single ``matchExpression``.

.. literalinclude:: ../../../examples/policies/l3/match-expressions/and-statement.yaml
  :language: yaml

ServiceAccounts
~~~~~~~~~~~~~~~

Kubernetes `Service Accounts
<https://kubernetes.io/docs/concepts/security/service-accounts/>`_ are used
to associate an identity to a pod or process managed by Kubernetes and grant
identities access to Kubernetes resources and secrets. Cilium supports the
specification of network security policies based on the service account
identity of a pod.

The service account of a pod is either defined via the `service account
admission controller
<https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount>`_
or can be directly specified in the Pod, Deployment, ReplicationController
resource like this:

.. code-block:: yaml

        apiVersion: v1
        kind: Pod
        metadata:
          name: my-pod
        spec:
          serviceAccountName: leia
          # ...

Example
^^^^^^^

The following example grants any pod running under the service account of
"luke" to issue a ``HTTP GET /public`` request on TCP port 80 to all pods
running associated to the service account of "leia".

Refer to the :git-tree:`example YAML files <examples/policies/kubernetes/serviceaccount/demo-pods.yaml>`
for a fully functional example including deployment and service account
resources.


.. literalinclude:: ../../../examples/policies/kubernetes/serviceaccount/serviceaccount-policy.yaml
  :language: yaml

Multi-Cluster
~~~~~~~~~~~~~

When operating multiple cluster with cluster mesh, the cluster name is exposed
via the label ``io.cilium.k8s.policy.cluster`` and can be used to restrict
policies to a particular cluster.

.. literalinclude:: ../../../examples/policies/kubernetes/clustermesh/cross-cluster-policy.yaml
  :language: yaml

Note the ``io.kubernetes.pod.namespace: default`` in the policy
rule. It makes sure the policy applies to ``rebel-base`` in the
``default`` namespace of ``cluster2`` regardless of the namespace in
``cluster1`` where ``x-wing`` is deployed in.

If the namespace label of policy rules is omitted it defaults to the same namespace
where the policy itself is applied in, which may be not what is wanted when deploying
cross-cluster policies. To allow access from/to any namespace, use ``matchExpressions``
combined with an ``Exists`` operator.

.. literalinclude:: ../../../examples/policies/kubernetes/clustermesh/cross-cluster-any-namespace-policy.yaml
  :language: yaml

Clusterwide Policies
~~~~~~~~~~~~~~~~~~~~

`CiliumNetworkPolicy` only allows to bind a policy restricted to a particular namespace. There can be situations
where one wants to have a cluster-scoped effect of the policy, which can be done using Cilium's
`CiliumClusterwideNetworkPolicy` Kubernetes custom resource. The specification of the policy is same as that
of `CiliumNetworkPolicy` except that it is not namespaced.

In the cluster, this policy will allow ingress traffic from pods matching the label ``name=luke`` from any
namespace to pods matching the labels ``name=leia`` in any namespace.

.. literalinclude:: ../../../examples/policies/kubernetes/clusterwide/clusterscope-policy.yaml
  :language: yaml

Allow All Cilium Managed Endpoints To Communicate With Kube-dns
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following example allows all Cilium managed endpoints in the cluster to communicate
with kube-dns on port 53/UDP in the ``kube-system`` namespace.

.. literalinclude:: ../../../examples/policies/kubernetes/clusterwide/wildcard-from-endpoints.yaml
  :language: yaml

.. _health_endpoint: 

Example: Add Health Endpoint
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following example adds the health entity to all Cilium managed endpoints in order to check
cluster connectivity health.

.. literalinclude:: ../../../examples/policies/kubernetes/clusterwide/health.yaml
  :language: yaml

<!-- ===== cilium-security-policy-deny.rst ===== -->

.. only:: not (epub or latex or html)

    WARNING: You are looking at unreleased Cilium documentation.
    Please use the official rendered version released here:
    https://docs.cilium.io

.. _deny_policies:

Deny Policies
=============

Deny policies, available and enabled by default since Cilium 1.9, allows to
explicitly restrict certain traffic to and from a Pod.

Deny policies take precedence over allow policies, regardless of whether they
are a Cilium Network Policy, a Clusterwide Cilium Network Policy or even a
Kubernetes Network Policy.

Similarly to "allow" policies, Pods will enter default-deny mode as soon a
single policy selects it.

If multiple allow and deny policies are applied to the same pod, the following
table represents the expected enforcement for that Pod:

+--------------------------------------------------------------------------------------------+
| **Set of Ingress Policies Deployed to Server Pod**                                         |
+---------------------+-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 7 (HTTP)        | ✓       | ✓       | ✓      | ✓      |        |
|                     +-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 4 (80/TCP)      | ✓       | ✓       | ✓      | ✓      |        |
| **Allow Policies**  +-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 4 (81/TCP)      | ✓       | ✓       | ✓      | ✓      |        |
|                     +-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 3 (Pod: Client) | ✓       | ✓       | ✓      | ✓      |        |
+---------------------+-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 4 (80/TCP)      |         | ✓       |        | ✓      | ✓      |
| **Deny Policies**   +-----------------------+---------+---------+--------+--------+--------+
|                     | Layer 3 (Pod: Client) |         |         | ✓      | ✓      |        |
+---------------------+-----------------------+---------+---------+--------+--------+--------+
| **Result for Traffic Connections (Allowed / Denied)**                                      |
+---------------------+-----------------------+---------+---------+--------+--------+--------+
|                     | curl server:81        | Allowed | Allowed | Denied | Denied | Denied |
|                     +-----------------------+---------+---------+--------+--------+--------+
| **Client → Server** | curl server:80        | Allowed | Denied  | Denied | Denied | Denied |
|                     +-----------------------+---------+---------+--------+--------+--------+
|                     | ping server           | Allowed | Allowed | Denied | Denied | Denied |
+---------------------+-----------------------+---------+---------+--------+--------+--------+

If we pick the second column in the above table, the bottom section shows the
forwarding behaviour for a policy that selects curl or ping traffic between the
client and server:

* Curl to port 81 is allowed because there is an allow policy on port 81, and
  no deny policy on that port;
* Curl to port 80 is denied because there is a deny policy on that port;
* Ping to the server is allowed because there is a Layer 3 allow policy and no deny.

The following policy will deny ingress from "world" on all namespaces on all
Pods managed by Cilium. Existing inter-cluster policies will still be allowed
as this policy is allowing traffic from everywhere except from "world".

.. literalinclude:: ../../../examples/policies/l3/entities/from_world_deny.yaml
  :language: yaml

Deny policies do not support: policy enforcement at L7, i.e., specifically
denying an URL and ``toFQDNs``, i.e., specifically denying traffic to a specific
domain name.

<!-- ===== cilium-network-clustermesh-intro.rst ===== -->

.. only:: not (epub or latex or html)

    WARNING: You are looking at unreleased Cilium documentation.
    Please use the official rendered version released here:
    https://docs.cilium.io

.. _Cluster Mesh:

############################
Multi-Cluster (Cluster Mesh)
############################

Multi-cluster Kubernetes setups are often adopted for reasons like fault
isolation, scalability, and geographical distribution. This approach can lead
to networking complexity. With such multi-cluster setups, traditional networking
models struggle with service discovery, network segmentation, policy enforcement,
and load-balancing across clusters. Cluster Mesh addresses these challenges by
extending Cilium networking across multiple Kubernetes clusters and provides:

* Pod-to-pod connectivity between clusters within a flat IP address space
* Cluster-aware :ref:`network policy enforcement <gs_clustermesh_network_policy>`
* Cross-cluster :ref:`service discovery and load-balancing <gs_clustermesh_load_balancing>`
* :ref:`Service affinity <gs_clustermesh_service_affinity>` controls to
  prefer local or remote backends

See :ref:`gs_clustermesh` for instructions on how to set up Cluster Mesh.

Architecture
============

Cluster Mesh is built around a per-cluster control plane hosted by
``clustermesh-apiserver`` pods. These pods expose the local cluster state to
remote clusters and synchronize remote cluster state into the local cluster.

Cilium agents use local Kubernetes API server state and remote Cluster Mesh
state in a similar way to program the local datapath. Pod-to-pod traffic is
forwarded directly between nodes, including across cluster boundaries, without
requiring any additional proxy or gateway.

The following diagram shows the main Cluster Mesh components and how two
clusters exchange state:


.. image:: images/clustermesh-architecture.svg
   :align: center

.. The image source can be found at images/clustermesh-architecture.excalidraw

A ``clustermesh-apiserver`` pod typically contains the following containers:

* ``etcd``: Stores the local cluster state that is exposed to remote clusters
  over mTLS, typically through a LoadBalancer or NodePort service. This embedded
  etcd is simple to operate because it is a single instance and does not require
  persistent storage as the entire state is rebuilt from kube-apiserver on startup.
* ``apiserver``: Synchronizes local Cilium and Kubernetes state into the local
  etcd instance.
* ``kvstoremesh``: Synchronizes remote cluster state from other clusters into
  the local cluster.

Cluster Mesh reuses several concepts from :ref:`kvstore mode <kvstore>` to
exchange state between clusters. When Cilium is already running in kvstore mode,
Cluster Mesh extends the existing kvstore etcd instance instead of
deploying an additional embedded etcd instance.

Security
========

.. _clustermesh_security_model:

All clusters connected in a Cluster Mesh form a single trust domain.

While Cilium performs various sanity checks on information received from remote
clusters, these checks cannot fully prevent a compromised cluster's Cilium
control plane from propagating malicious information to other clusters.

Only connect clusters that are mutually trusted and have equivalent security
postures.
