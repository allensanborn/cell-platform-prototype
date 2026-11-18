---
type: source
resource: https://istio.io/latest/docs/ambient/usage/waypoint/
title: "Istio ambient — waypoints, L4 policy (ztunnel), L7 features, NetworkPolicy, egress gateway via waypoint"
source_kind: webpage
tags: [istio, ambient, waypoint, ztunnel, authorizationpolicy, egress, use-waypoint]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/istio/istio.io/contents/content/en/docs/ambient/usage/{waypoint,l4-policy,l7-features,networkpolicy,egress-gateway}/index.md raw, master branch, 2026-11-13 (latest Istio release 1.32.0, 2026-11-09). Hugo source verbatim, concatenated; snippets/shortcodes unexpanded."
---


<!-- ===== istio-ambient-usage-waypoint.md ===== -->

---
title: Configure waypoint proxies
description: Gain the full set of Istio features with optional Layer 7 proxies.
weight: 30
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: yes
---

A **waypoint proxy** is an optional deployment of the Envoy-based proxy to add Layer 7 (L7) processing to a defined set of workloads.

Waypoint proxies are installed, upgraded and scaled independently from applications; an application owner should be unaware of their existence. Compared to the sidecar {{< gloss >}}data plane{{< /gloss >}} mode, which runs an instance of the Envoy proxy alongside each workload, the number of proxies required can be substantially reduced.

A waypoint, or set of waypoints, can be shared between applications with a similar security boundary. This might be all the instances of a particular workload, or all the workloads in a namespace.

As opposed to {{< gloss >}}sidecar{{< /gloss >}} mode, in ambient mode policies are enforced by the **destination** waypoint. In many ways, the waypoint acts as a gateway to a resource (a namespace, service or pod). Istio enforces that all traffic coming into the resource goes through the waypoint, which then enforces all policies for that resource.

## Do you need a waypoint proxy?

The layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure L4 overlay, to full L7 processing.

Most of the features of ambient mode are provided by the ztunnel node proxy. Ztunnel is scoped to only process traffic at Layer 4 (L4), so that it can safely operate as a shared component.

When you configure redirection to a waypoint, traffic will be forwarded by ztunnel to that waypoint. If your applications require any of the following L7 mesh functions, you will need to use a waypoint proxy:

* **Traffic management**: HTTP routing & load balancing, circuit breaking, rate limiting, fault injection, retries, timeouts
* **Security**: Rich authorization policies based on L7 primitives such as request type or HTTP header
* **Observability**: HTTP metrics, access logging, tracing

## Deploy a waypoint proxy

Waypoint proxies are deployed using Kubernetes Gateway resources.

{{< boilerplate gateway-api-install-crds >}}

You can use istioctl waypoint subcommands to generate, apply or list these resources.

After the waypoint is deployed, the entire namespace (or whichever services or pods you choose) must be [enrolled](#useawaypoint) to use it.

Before you deploy a waypoint proxy for a specific namespace, confirm the namespace is labeled with `istio.io/dataplane-mode: ambient`:

{{< text syntax=bash snip_id=check_ns_label >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

`istioctl` can generate a Kubernetes Gateway resource for a waypoint proxy. For example, to generate a waypoint proxy named `waypoint` for the `default` namespace that can process traffic for services in the namespace:

{{< text syntax=bash snip_id=gen_waypoint_resource >}}
$ istioctl waypoint generate --for service -n default
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Note the Gateway resource has a `gatewayClassName` of `istio-waypoint`, which instantiates an Istio-managed waypoint. The Gateway resource is labeled with `istio.io/waypoint-for: service`, indicating the waypoint can process traffic for services, which is the default.

To deploy a waypoint proxy directly, use `apply` instead of `generate`:

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

Or, you can deploy the generated Gateway resource:

{{< text syntax=bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

After the Gateway resource is applied, Istiod will monitor the resource, deploy and manage the corresponding waypoint deployment and service for users automatically.

### Waypoint traffic types

By default, a waypoint will only handle traffic destined for **services** in its namespaces. This choice was made because traffic directed at a pod alone is rare, and often used for internal purposes such as Prometheus scraping, and the extra overhead of L7 processing may not be desired.

It is also possible for the waypoint to handle all traffic, only handle traffic sent directly to **workloads** (pods or VMs) in the cluster, or no traffic at all. The types of traffic that will be redirected to the waypoint are determined by the `istio.io/waypoint-for` label on the `Gateway` object.

Use the `--for` argument to `istioctl waypoint apply` to change the types of traffic that can be redirected to the waypoint:

| `waypoint-for` value | Original destination type |
| -------------------- | ------------ |
| `service`            | Kubernetes services |
| `workload`           | Pod IPs or VM IPs |
| `all`                | Both service and workload traffic |
| `none`               | No traffic (useful for testing) |

Waypoint selection occurs based on the destination type, `service` or `workload`, to which traffic was _originally addressed_. If traffic is addressed to a service which does not have a waypoint, a waypoint will not be transited: even if the eventual workload it reaches _does_ have an attached waypoint.

## Use a waypoint proxy {#useawaypoint}

When a waypoint proxy is deployed, it is not used by any resources until you explicitly configure those resources to use it.

To enable a namespace, service or Pod to use a waypoint, add the `istio.io/use-waypoint` label with a value of the waypoint name.

{{< tip >}}
Most users will want to apply a waypoint to an entire namespace, and we recommend you start with this approach.
{{< /tip >}}

If you use `istioctl` to deploy your namespace waypoint, you can use the `--enroll-namespace` parameter to automatically label a namespace:

{{< text syntax=bash snip_id=enroll_ns_waypoint >}}
$ istioctl waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Alternatively, you may add the `istio.io/use-waypoint: waypoint` label to the `default` namespace using `kubectl`:

{{< text syntax=bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

After a namespace is enrolled to use a waypoint, any requests from any pods using the ambient data plane mode, to any service running in that namespace, will be routed through the waypoint for L7 processing and policy enforcement.

If you prefer more granularity than using a waypoint for an entire namespace, you can enroll only a specific service or pod to use a waypoint. This may be useful if you only need L7 features for some services in a namespace, if you only want an extension like a `WasmPlugin` to apply to a specific service, or if you are calling a Kubernetes
[headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) by its pod IP address.

{{< tip >}}
If the `istio.io/use-waypoint` label exists on both a namespace and a service, the service waypoint takes precedence over the namespace waypoint as long as the service waypoint can handle `service` or `all` traffic. Similarly, a label on a pod will take precedence over a namespace label.
{{< /tip >}}

### Ingress gateways and waypoints {#ingress-and-waypoints}

The `istio.io/use-waypoint` label governs **east-west** traffic: requests from other pods in the mesh to the labeled namespace, service, or workload are sent through the destination waypoint for Layer 7 policy and telemetry.

Traffic from an **Istio ingress gateway** to that `Service` is modeled separately. By default, ingress-originated traffic will **not** use the destination service waypoint, even when `istio.io/use-waypoint` is set on the service or namespace.

To direct ingress traffic through the same waypoint as mesh traffic, set **`istio.io/ingress-use-waypoint`** to `true` on the Kubernetes `Service`, or on the `Namespace` to apply to all services in that namespace (supported starting with Istio 1.25). See the [resource labels](/docs/reference/config/labels/#IoIstioIngressUseWaypoint) reference for supported resource types.

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/ingress-use-waypoint=true
service/reviews labeled
{{< /text >}}

{{< tip >}}
Enabling this path results in **Layer 7 processing at both the ingress gateway and the waypoint** (a two-tier gateway pattern). Consider authorization rules, latency, and metrics for both hops.
{{< /tip >}}

The control plane only applies this behavior when **`ENABLE_INGRESS_WAYPOINT_ROUTING`** is enabled for istiod; it defaults to `false`. See [`ENABLE_INGRESS_WAYPOINT_ROUTING`](/docs/reference/commands/pilot-discovery/#enable-ingress-waypoint-routing) in the pilot-discovery environment reference.

### Configure a service to use a specific waypoint

Using the services from the sample [bookinfo application](/docs/examples/bookinfo/), we can deploy a waypoint called `reviews-svc-waypoint` for the `reviews` service:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Label the `reviews` service to use the `reviews-svc-waypoint` waypoint:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

Any requests from pods in the mesh to the `reviews` service will now be routed through the `reviews-svc-waypoint` waypoint.

### Configure a pod to use a specific waypoint

Deploy a waypoint called `reviews-v2-pod-waypoint` for the `reviews-v2` pod.

{{< tip >}}
Recall the default for waypoints is to target services; as we explicitly want to target a pod, we need to use the `istio.io/waypoint-for: workload` label, which we can generate by using the `--for workload` parameter to istioctl.
{{< /tip >}}

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Label the `reviews-v2` pod to use the `reviews-v2-pod-waypoint` waypoint:

{{< text syntax=bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

Any requests from pods in the ambient mesh to the `reviews-v2` pod IP will now be routed through the `reviews-v2-pod-waypoint` waypoint for L7 processing and policy enforcement.

{{< tip >}}
The original destination type of the traffic is used to determine if a service or workload waypoint will be used. By using the original destination type the ambient mesh avoids having traffic transit waypoint twice, even if both service and workload have attached waypoints.
For instance, traffic which is addressed to a service, even though ultimately resolved to a pod IP, is always treated by the ambient mesh as to-service and would use a service-attached waypoint.
{{< /tip >}}

### Require traffic to traverse the waypoint {#require-waypoint}

The `istio.io/use-waypoint` label records your intent to send traffic through a waypoint, but on its own it does not guarantee that this happens. ztunnel routes traffic directly to the destination, rather than failing the request, when:

* the named waypoint does not exist or has no address; or
* the traffic type does not match the traffic the waypoint handles; for example, a request sent directly to a workload (a pod or VM IP) when the waypoint only handles service traffic, which is the [default](#waypoint-traffic-types).

In either case, any Layer 7 policy that the waypoint would have enforced never takes effect, and traffic flows as though no waypoint were configured.

If enforcing a waypoint's Layer 7 policies is a security requirement, make the waypoint mandatory with an `AuthorizationPolicy` that allows only the waypoint's identity. A waypoint uses the service account named after its `Gateway`, so a policy on the destination workloads that allows only that identity denies any client that reaches them without first passing through the waypoint. Continuing with the `reviews-svc-waypoint` waypoint from above:

{{< text syntax=yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-waypoint
  namespace: default
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/reviews-svc-waypoint
{{< /text >}}

This policy uses a workload `selector` rather than a `targetRef`, so it is enforced at Layer 4 by ztunnel. It therefore takes effect in both bypass cases: when the waypoint is unavailable, and when a client dials the workload directly.

### Shift traffic between waypoints {#waypoint-canary}

{{< warning >}}
Shifting traffic between waypoints is supported starting with Istio 1.31 and is considered [Alpha](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md). The labels, annotation, and behavior may change in future releases.
{{< /warning >}}

Changing the `istio.io/use-waypoint` label on a service moves all of its traffic to the new waypoint at once. To move a service between two waypoints gradually, for example to validate a new waypoint revision during an upgrade, name a second *canary* waypoint alongside the primary and give it a share of the service's traffic. The configuration lives entirely on the destination service: clients are unaware of it, and no second `Service` is required.

| Name | Kind | Purpose |
| --- | --- | --- |
| [`istio.io/use-waypoint-canary`](/docs/reference/config/labels/#IoIstioUseWaypointCanary) | label | Name of the canary waypoint `Gateway`. |
| [`istio.io/use-waypoint-canary-namespace`](/docs/reference/config/labels/#IoIstioUseWaypointCanaryNamespace) | label | Namespace of the canary waypoint, if it is not the namespace of the service. |
| [`istio.io/use-waypoint-canary-weight`](/docs/reference/config/annotations/#IoIstioUseWaypointCanaryWeight) | annotation | Share of traffic sent to the canary, as an integer from 0 to 100. The primary waypoint receives the remainder. Defaults to 0. |

Continuing with the `reviews` service from above, deploy a second waypoint and send 5% of the service's traffic to it, leaving the remaining 95% on `reviews-svc-waypoint`:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint-v2
waypoint default/reviews-svc-waypoint-v2 applied
{{< /text >}}

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint-canary=reviews-svc-waypoint-v2
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight=5
{{< /text >}}

Raise the weight as you gain confidence in the canary. Once the canary is carrying all of the traffic, promote it by making it the primary waypoint and removing the canary configuration:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint-v2 --overwrite
$ kubectl label service reviews istio.io/use-waypoint-canary-
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight-
{{< /text >}}

To roll back at any point, remove the canary label. The service returns to sending all of its traffic through the primary waypoint.

#### Supported resources

The canary labels and annotation are supported on `Service`, `ServiceEntry`, and `Namespace`. Unlike `istio.io/use-waypoint`, they are **not** supported on `Pod` or `WorkloadEntry`: the split is defined at the service level so that it behaves the same for mesh and ingress traffic.

A canary configured on a namespace only applies to services that also inherit their primary waypoint from that namespace. If a service sets its own `istio.io/use-waypoint`, it must set its own canary configuration too; the namespace's canary labels are ignored for that service.

Both waypoints must be able to front the service. Each must be ready, must allow attachment from the service's namespace, and must handle `service` or `all` traffic.

#### What the weight applies to

* **Mesh traffic** is split by {{< gloss >}}ztunnel{{< /gloss >}} **per connection**: the weight is the share of *new* connections that select the canary. Established connections are never moved, so a service whose clients hold long-lived connections will approach the configured weight only as those clients reconnect. For the same reason, the observed split is approximate, and is only meaningful over a large number of connections.
* **Ingress traffic** is split by the ingress gateway **per request**, and only for services that opt in with `istio.io/ingress-use-waypoint` as described in [Ingress gateways and waypoints](#ingress-and-waypoints). Without that opt-in, ingress traffic continues to bypass both waypoints.

The mesh split requires a ztunnel from Istio 1.31 or later. While the data plane is being upgraded, nodes still running an older ztunnel send all of their connections to the primary waypoint, so the split across the mesh lags the configured weight until every node is upgraded. The ingress split does not depend on ztunnel.

#### Configuration attached to the waypoint

Both waypoints serve the same service, so any configuration that must remain in effect during the shift has to apply at both. Policies and routes that target the `Service`, such as an `AuthorizationPolicy` or an `HTTPRoute` with the service as its `parentRef`, are enforced by whichever waypoint handles the traffic and need no duplication.

Configuration attached to a waypoint `Gateway` itself is a different matter. A `WasmPlugin` selecting the waypoint, or a policy whose `targetRef` names the `Gateway`, applies only to that waypoint. Replicate it on the canary before shifting traffic, otherwise the share of traffic going through the canary is handled with a different set of policies.

#### Invalid configuration

An unusable canary is not fatal. The service keeps using its primary waypoint alone, and the reason is reported in the `istio.io/WaypointBound` condition on the service:

{{< text syntax=bash >}}
$ kubectl get service reviews -o jsonpath='{.status.conditions}'
{{< /text >}}

This fallback applies when the canary waypoint does not exist, is not ready, does not allow attachment from the service's namespace, or cannot handle service traffic; when the weight is not an integer between 0 and 100 (`CanaryInvalidWeight`); and when the canary names the same waypoint as the primary (`CanarySameAsPrimary`).

## Cross-namespace waypoint use {#usewaypointnamespace}

Straight out of the box, a waypoint proxy is usable by resources within the same namespace. Beginning with Istio 1.23, it is possible to use waypoints in different namespaces. In this section, we will examine
the gateway configuration required to enable cross-namespace use and how to configure your resources to use a waypoint from a different namespace.

### Configure a waypoint for cross-namespace use

In order to enable cross-namespace use of a waypoint, the `Gateway` should be configured to [allow routes](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.AllowedRoutes) from other namespaces.

{{< tip >}}
The keyword `All` may be specified as the value for `allowedRoutes.namespaces.from` in order to allow routes from any namespace.
{{< /tip >}}

The following `Gateway` would allow resources in a namespace called "cross-namespace-waypoint-consumer" to use this `egress-gateway`. For a complete step-by-step guide of using a waypoint as an egress gateway, see [Egress gateways](/docs/ambient/usage/egress-gateway/).

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: egress-gateway
  namespace: common-infrastructure
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: cross-namespace-waypoint-consumer
{{< /text >}}

### Configure resources to use a cross-namespace waypoint proxy

By default, the Istio control plane will look for a waypoint specified using the `istio.io/use-waypoint` label in the same namespace as the resource which the label is applied to. It is possible to use
a waypoint in another namespace by adding a new label, `istio.io/use-waypoint-namespace`. `istio.io/use-waypoint-namespace` works for all resources which support the `istio.io/use-waypoint` label.
Together, the two labels specify the name and namespace of your waypoint respectively. For example, to configure a `ServiceEntry` named `istio-site` to use a waypoint named `egress-gateway` in the namespace
named `common-infrastructure`, you could use the following commands:

{{< text syntax=bash >}}
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint=egress-gateway
serviceentries.networking.istio.io/istio-site labeled
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint-namespace=common-infrastructure
serviceentries.networking.istio.io/istio-site labeled
{{< /text >}}

### Cleaning up

You can remove all waypoints from a namespace by doing the following:

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}

<!-- ===== istio-ambient-usage-l4-policy.md ===== -->

---
title: Use Layer 4 security policy
description: Supported security features when only using the secure L4 overlay.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

The Layer 4 (L4) features of Istio's [security policies](/docs/concepts/security) are supported by {{< gloss >}}ztunnel{{< /gloss >}}, and are available in {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) also continue to work if your cluster has a {{< gloss >}}CNI{{< /gloss >}} plugin that supports them, and can be used to provide defense-in-depth.

The layering of ztunnel and {{< gloss "waypoint" >}}waypoint proxies{{< /gloss >}} gives you a choice as to whether or not you want to enable Layer 7 (L7) processing for a given workload. To use L7 policies, and Istio's traffic routing features, you can [deploy a waypoint](/docs/ambient/usage/waypoint) for your workloads. Because policy can now be enforced in two places, there are [considerations](#considerations) that need to be understood.

## Policy enforcement using ztunnel

The ztunnel proxy can perform authorization policy enforcement when a workload is enrolled in {{< gloss "Secure L4 Overlay" >}}secure overlay mode{{< /gloss >}}. The enforcement point is the receiving (server-side) ztunnel proxy in the path of a connection.

A basic L4 authorization policy looks like this:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
{{< /text >}}

This policy can be used in both {{< gloss "sidecar" >}}sidecar mode{{< /gloss >}} and ambient mode.

The L4 (TCP) features of the Istio `AuthorizationPolicy` API have the same functional behavior in ambient mode as in sidecar mode. When there is no authorization policy provisioned,  the default action is `ALLOW`. Once a policy is provisioned, pods targeted by the policy only permit traffic which is explicitly allowed. In the above example, pods with the label `app: httpbin` only permit traffic from sources with an identity principal of `cluster.local/ns/ambient-demo/sa/curl`. Traffic from all other sources will be denied.

## Targeting policies

Sidecar mode and L4 policies in ambient are *targeted* in the same fashion: they are scoped by the namespace in which the policy object resides, and an optional `selector` in the `spec`. If the policy is in the Istio root namespace (traditionally `istio-system`), then it will target all namespaces.  If it is in any other namespace, it will target only that namespace.

L7 policies in ambient mode are enforced by waypoints, which are configured with the {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}. They are *attached* using the `targetRef` field.

## Allowed policy attributes

Authorization policy rules can contain [source](/docs/reference/config/security/authorization-policy/#Source) (`from`), [operation](/docs/reference/config/security/authorization-policy/#Operation) (`to`), and [condition](/docs/reference/config/security/authorization-policy/#Condition) (`when`) clauses.

This list of attributes determines whether a policy is considered L4-only:

| Type | Attribute | Positive match | Negative match |
| --- | --- | --- | --- |
| Source | Peer identity | `principals` | `notPrincipals` |
| Source | Namespace | `namespaces` | `notNamespaces` |
| Source | IP block | `ipBlocks` | `notIpBlocks` |
| Operation | Destination port | `ports` | `notPorts` |
| Condition | Source IP | `source.ip` | n/a |
| Condition | Source namespace | `source.namespace` | n/a |
| Condition | Source identity | `source.principal` | n/a |
| Condition | Remote IP | `destination.ip` | n/a |
| Condition | Remote port | `destination.port` | n/a |

### Policies with Layer 7 conditions

The ztunnel cannot enforce L7 policies. If a policy with rules matching L7 attributes (i.e. those not listed in the table above) is targeted such that it will be enforced by a receiving ztunnel, the ztunnel cannot evaluate those rules and skips them. The outcome depends on the policy action:

| Policy | Behavior in ztunnel | Result |
|--------|---------------------|--------|
| `ALLOW` with L7 attributes | The rule is skipped, so no `ALLOW` rule ever matches | Traffic is denied |
| `DENY` with only L7 attributes | The rule is skipped, so no `DENY` rule ever matches | Traffic is **allowed** |
| `DENY` with L4 and L7 attributes in the same `source`, `operation` or `when` entry | Only the L4 attributes are enforced; the L7 attributes are ignored | Traffic matching the L4 attributes is denied, which is broader than intended |
| `DENY` with L4 and L7 attributes in different entries, such as `from.source.principals` and `to.operation.methods` | The entry with L7 attributes is skipped, so the rule never matches | Traffic is **allowed** |

{{< warning >}}
A `DENY` policy whose rules contain only L7 attributes, such as `notRequestPrincipals`, `paths` or `methods`, is not enforced by ztunnel and does not block any traffic. This is the case for the common "require authentication" policy using `notRequestPrincipals: ["*"]`. The status message saying the policy is "more restrictive than requested" applies only to `DENY` rules where the L4 and L7 attributes are in the same entry. To enforce L7 only `DENY` policies, [deploy a waypoint proxy](/docs/ambient/usage/waypoint/) and attach the policy to it.
{{< /warning >}}

This example adds a check for the HTTP GET method:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
   to:
   - operation:
       methods: ["GET"]
{{< /text >}}

Even if the identity of the client pod is correct, the presence of a L7 attribute causes the ztunnel to deny the connection:

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## Choosing enforcement points when waypoints are introduced {#considerations}

When a waypoint proxy is added to a workload, you now have two possible places where you can enforce L4 policy. (L7 policy can only be enforced at the waypoint proxy.)

With only the secure overlay, traffic appears at the destination ztunnel with the identity of the *source* workload.

Waypoint proxies do not impersonate the identity of the source workload. Once you have introduced a waypoint to the traffic path, the destination ztunnel will see traffic with the *waypoint's* identity, not the source identity.

This means that when you have a waypoint installed, **the ideal place to enforce policy shifts**. Even if you only wish to enforce policy against L4 attributes, if you are dependent on the source identity, you should attach your policy to your waypoint proxy. A second policy may be targeted at your workload to make its ztunnel enforce policies like "in-mesh traffic must come from my waypoint in order to reach my application".

## Peer authentication

Istio's [peer authentication policies](/docs/concepts/security/#peer-authentication), which configure mutual TLS (mTLS) modes, are supported by ztunnel.

The default policy for ambient mode is `PERMISSIVE`, which allows pods to accept both mTLS-encrypted traffic (from within the mesh) and plain text traffic (from without). Enabling `STRICT` mode means that pods will only accept mTLS-encrypted traffic.

As ztunnel and {{< gloss >}}HBONE{{< /gloss >}} implies the use of mTLS, it is not possible to use the `DISABLE` mode in a policy. Such policies will be ignored.

<!-- ===== istio-ambient-usage-l7-features.md ===== -->

---
title: Use Layer 7 features
description: Supported features when using a L7 waypoint proxy.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

By adding a waypoint proxy to your traffic flow you can enable more of [Istio's features](/docs/concepts). Waypoints are configured using the {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}.

{{< warning >}}
Usage of VirtualService with the ambient data plane mode is considered Alpha. Mixing with Gateway API configuration is not supported, and will lead to undefined behavior.
{{< /warning >}}

{{< warning >}}
`EnvoyFilter` is Istio's break-glass API for advanced configuration of Envoy proxies. Please note that *`EnvoyFilter` is not currently supported for any existing Istio version with waypoint proxies*. While it may be possible to use `EnvoyFilter` with waypoints in limited scenarios, its use is not supported, and is actively discouraged by the maintainers. The alpha API may break in future releases as it evolves. We expect official support will be provided at a later date.
{{< /warning >}}

## Route and policy attachment

The Gateway API defines the relationship between objects (such as routes and gateways) in terms of *attachment*.

* Route objects (such as [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)) include a way to reference the **parent** resources it wants to attach to.
* Policy objects are considered [*metaresources*](https://gateway-api.sigs.k8s.io/geps/gep-713/): objects that augments the behavior of a **target** object in a standard way.

The tables below show the type of attachment that is configured for each object.

## Traffic routing

With a waypoint proxy deployed, you can use the following traffic route types:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Beta | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha | `parentRefs` |

Refer to the [traffic management](/docs/tasks/traffic-management/) documentation to see the range of features that can be implemented using these routes.

## Security

Without a waypoint installed, you can only use [Layer 4 security policies](/docs/ambient/usage/l4-policy/). By adding a waypoint, you gain access to the following policies:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (including L7 features) | Beta | `targetRefs` |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### Considerations for authorization policies {#considerations}

In ambient mode, authorization policies can either be *targeted* (for ztunnel enforcement) or *attached* (for waypoint enforcement). For an authorization policy to be attached to a waypoint it must have a `targetRef` which refers to the waypoint, or a Service which uses that waypoint.

The ztunnel cannot enforce L7 policies. If a policy with rules matching L7 attributes is targeted with a workload selector (rather than attached with a `targetRef`), such that it is enforced by a ztunnel, it will fail safe by becoming a `DENY` policy.

A policy attached to a waypoint is only enforced for traffic that actually reaches the waypoint. Traffic can bypass the waypoint, and its Layer 7 policies, when the waypoint does not exist or has no address, or when the traffic type does not match the traffic the waypoint handles (see [Waypoint traffic types](/docs/ambient/usage/waypoint/#waypoint-traffic-types)). To require that traffic traverses the waypoint, pair the waypoint policy with an `AuthorizationPolicy` enforced by ztunnel that allows only the waypoint's identity. See [Require traffic to traverse the waypoint](/docs/ambient/usage/waypoint/#require-waypoint).

See [the L4 policy guide](/docs/ambient/usage/l4-policy/) for more information, including when to attach policies to waypoints for TCP-only use cases.

## Observability

The [full set of Istio traffic metrics](/docs/reference/config/metrics/) are exported by a waypoint proxy.

## Extension

As the waypoint proxy is a deployment of {{< gloss >}}Envoy{{< /gloss >}}, some of the extension mechanisms that are available for Envoy in {{< gloss "sidecar">}}sidecar mode{{< /gloss >}} are also available to waypoint proxies.

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| `TrafficExtension` ‡ | Alpha | `targetRefs` |
| `WasmPlugin` † | Alpha | `targetRefs` |

‡ [Read more on how to extend waypoints with Lua scripts](/docs/ambient/usage/extend-waypoint-lua/).
† [Read more on how to extend waypoints with WebAssembly plugins](/docs/ambient/usage/extend-waypoint-wasm/).

Extension configurations are considered policy by the Gateway API definition.

## Scoping routes or policies

A route or policy can be scoped to apply to all traffic traversing a waypoint proxy, or only specific services.

### Attach to the entire waypoint proxy

To attach a route or a policy to the entire waypoint — so that it applies to all traffic enrolled to use it — set `Gateway` as the `parentRefs` or `targetRefs` value, depending on the type.

To scope an `AuthorizationPolicy` policy to apply to the waypoint named `default` for the `default` namespace:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: view-only
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: default
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

### Attach to a specific service

You can also attach a route to one or more specific services within the waypoint. Set `Service` as the `parentRefs` or `targetRefs` value, as appropriate.

To apply the `reviews` HTTPRoute to the `reviews` service in the `default` namespace:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: default
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

<!-- ===== istio-ambient-usage-networkpolicy.md ===== -->

---
title: Ambient and Kubernetes NetworkPolicy
description: Understanding how CNI-enforced L4 Kubernetes NetworkPolicy interacts with Istio's ambient mode.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Kubernetes [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) allows you to control how layer 4 traffic reaches your pods.

`NetworkPolicy` is typically enforced by the {{< gloss >}}CNI{{< /gloss >}} installed in your cluster. Istio is not a CNI, and does not enforce or manage `NetworkPolicy`, and in all cases respects it - ambient does not and will never bypass Kubernetes `NetworkPolicy` enforcement.

An implication of this is that it is possible to create a Kubernetes `NetworkPolicy` that will block Istio traffic, or otherwise impede Istio functionality, so when using `NetworkPolicy` and ambient together, there are some things to keep in mind.

## Ambient traffic overlay and Kubernetes NetworkPolicy

Once you have added applications to the ambient mesh, ambient's secure L4 overlay will tunnel traffic between your pods over port 15008. Once secured traffic enters the target pod with a destination port of 15008, the traffic will be proxied back to the original destination port.

However, `NetworkPolicy` is enforced on the host, outside the pod. This means that if you have preexisting `NetworkPolicy` in place that, for example, will deny list inbound traffic to an ambient pod on every port but 443, you will have to add an exception to that `NetworkPolicy` for port 15008. Sidecar workloads receiving traffic will also need to allow inbound traffic on port 15008 to allow ambient workloads to communicate with them.

For example, the following `NetworkPolicy` will block incoming {{< gloss >}}HBONE{{< /gloss >}} traffic to `my-app` on port 15008:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
{{< /text >}}

and should be changed to

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
    - port: 15008
      protocol: TCP
{{< /text >}}

if `my-app` is added to the mesh.

## Ambient, health probes, and Kubernetes NetworkPolicy

Kubernetes health check probes present a problem and create a special case for Kubernetes traffic policy in general. They originate from the kubelet running as a process on the node, and not some other pod in the cluster. They are plaintext and unsecured. Neither the kubelet or the Kubernetes node typically have their own cryptographic identity, so access control isn't possible. It's not enough to simply allow all traffic through on the health probe port, as malicious traffic could use that port just as easily as the kubelet could. In addition, many apps use the same port for health probes and legitimate application traffic, so simple port-based allows are unacceptable.

Various CNI implementations solve this in different ways and seek to either work around the problem by silently excluding kubelet health probes from normal policy enforcement, or configuring policy exceptions for them.

In Istio ambient, this problem is solved by using a combination of iptables rules and source network address translation (SNAT) to rewrite only packets that provably originate from the local node with a fixed link-local IP, so that they can be explicitly ignored by Istio policy enforcement as unsecured health probe traffic. A link-local IP was chosen as the default since they are typically ignored for ingress-egress controls, and [by IETF standard](https://datatracker.ietf.org/doc/html/rfc3927) are not routable outside of the local subnetwork.

This behavior is transparently enabled when you add pods to the ambient mesh, and by default ambient uses the link-local addresses `169.254.7.127` (IPv4) and `fd16:9254:7127:1337:ffff:ffff:ffff:ffff` (IPv6) to identify and correctly allow kubelet health probe packets.

Note: If your workload, namespace, or cluster enforces Kubernetes `NetworkPolicy`, you must allow both the IPv4 and IPv6 addresses used by ambient mode. Depending on your CNI, packets with these addresses may otherwise be blocked, which will cause application pod health probes to fail once they join the ambient mesh.

For instance, applying the following `NetworkPolicy` in a namespace would block all traffic (Istio or otherwise) to the `my-app` pod, **including** kubelet health probes. Depending on your CNI, kubelet probes and link-local addresses may be ignored by this policy, or be blocked by it:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
  - Ingress
{{< /text >}}

Once the pod is enrolled in the ambient mesh, health probe packets will begin to be assigned a link local address via SNAT, which means health probes may begin to be blocked by your CNI's `NetworkPolicy` implementation. To allow ambient health probes to bypass `NetworkPolicy`, explicitly allow traffic from the host node to your pod by allow-listing the link-local addresses ambient uses for this traffic:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
{{< /text >}}

Note: If you are using a dual-stack cluster or an IPv6-only cluster, make sure to update your `NetworkPolicy` with the IPv6 ipBlock (`fd16:9254:7127:1337:ffff:ffff:ffff:ffff/128`) in addition to, or instead of, the IPv4 entry.

<!-- ===== istio-ambient-usage-egress-gateway.md ===== -->

---
title: Egress gateways
description: Control and observe traffic leaving the mesh using a waypoint as an egress gateway.
weight: 45
keywords: [ambient,egress,gateway,serviceentry,waypoint]
owner: istio/wg-networking-maintainers
test: yes
---

An egress gateway is a dedicated proxy that all outbound traffic to external services must pass through. It provides a single, verifiable exit point for traffic leaving the mesh, where you can apply authorization policies, enable observability, and originate TLS.

In {{< gloss "sidecar" >}}sidecar mode{{< /gloss >}}, configuring an egress gateway for a single host requires coordinating five separate objects: a `ServiceEntry`, a `Gateway`, two `HTTPRoute` resources (one to steer mesh traffic into the gateway, one to forward traffic from the gateway to the destination), and a `DestinationRule`. Each new external host repeats most of that work.

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} naturally acts as an egress gateway. Ztunnel automatically routes traffic to a service's waypoint before forwarding it to the destination. If you place a [`ServiceEntry`](/docs/reference/config/networking/service-entry/) in a namespace enrolled to use a waypoint, all mesh traffic to that external host passes through the waypoint automatically, with no extra routing rules required.

## Before you begin

- Install Istio with [ambient mode enabled](/docs/ambient/install/).
- Deploy a workload to use as a traffic source. The [curl]({{< github_tree >}}/samples/curl) sample works well:

    {{< text syntax=bash snip_id=deploy_curl >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

- Label the workload's namespace for ambient mode so ztunnel intercepts its traffic:

    {{< text syntax=bash snip_id=label_default_ambient >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    {{< /text >}}

## Set up the egress namespace

Create a dedicated namespace for egress resources. Isolating external service definitions and their policies from application namespaces simplifies administration and reduces the blast radius of misconfigurations.

{{< text syntax=bash snip_id=create_egress_ns >}}
$ kubectl create namespace istio-egress
$ kubectl label namespace istio-egress istio.io/dataplane-mode=ambient
{{< /text >}}

## Deploy the egress waypoint

Deploy a waypoint proxy in the egress namespace and enroll the namespace to use it. The `--enroll-namespace` flag adds the `istio.io/use-waypoint` label to the namespace, so every service defined there, including those backed by `ServiceEntry`, will be routed through the waypoint.

{{< boilerplate gateway-api-install-crds >}}

{{< text syntax=bash snip_id=apply_egress_waypoint >}}
$ istioctl waypoint apply --for service --enroll-namespace --namespace istio-egress
✅ waypoint istio-egress/waypoint applied
✅ namespace istio-egress labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Confirm the waypoint is ready:

{{< text syntax=bash snip_id=wait_egress_waypoint >}}
$ istioctl waypoint list -n istio-egress
NAME       REVISION  TRAFFIC TYPE  PROGRAMMED
waypoint   default   service       True
{{< /text >}}

## Define an external service

Create a `ServiceEntry` in the egress namespace to represent the external host. Because the namespace is enrolled to use the waypoint, ztunnel routes all mesh traffic to this host through the waypoint automatically. The `ServiceEntry` is visible cluster-wide by default (`exportTo: *`), so ztunnel on every node resolves `httpbin.org` to the `istio-egress` waypoint without any additional configuration.

{{< text syntax=bash snip_id=apply_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

## Verify traffic routes through the egress waypoint

Send a request from the curl pod to the external host and confirm it reaches the destination:

{{< text syntax=bash snip_id=verify_egress_traffic >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

To confirm traffic traversed the waypoint, check the waypoint's Envoy stats:

{{< text syntax=bash snip_id=check_waypoint_logs >}}
$ kubectl exec -n istio-egress deploy/waypoint -c istio-proxy -- pilot-agent request GET stats | grep upstream_rq_total
{{< /text >}}

A non-zero `upstream_rq_total` count (the number of requests the waypoint forwarded upstream) confirms the waypoint is acting as the egress gateway.

{{< warning >}}
Enrolling a namespace routes traffic through the waypoint but does not prevent direct paths if the waypoint is unavailable. If egress control is a security requirement, add an `AuthorizationPolicy` that allows only the waypoint's identity, enforced at L4 by ztunnel. See [Require traffic to traverse the waypoint](/docs/ambient/usage/waypoint/#require-waypoint).
{{< /warning >}}

## Enforce access policies

Because traffic passes through the waypoint, you can attach Layer 7 authorization policies directly to the `ServiceEntry`. The policy below allows any source to issue `GET` requests to `/get` only:

{{< text syntax=bash snip_id=apply_authz_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  targetRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-org
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get"]
EOF
{{< /text >}}

After applying the policy, verify that allowed requests succeed:

{{< text syntax=bash snip_id=verify_allowed_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

Confirm that a disallowed request is rejected:

{{< text syntax=bash snip_id=verify_denied_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" -X POST http://httpbin.org/post
403
{{< /text >}}

## Originate TLS at the egress gateway

Application pods can send plaintext HTTP to the egress gateway; the gateway upgrades to HTTPS before forwarding to the external host. This concentrates TLS credential management at the gateway and avoids distributing certificates to each application pod.

Update the `ServiceEntry` to map the plaintext port to the TLS port, and add a `DestinationRule` to originate the TLS connection:

{{< text syntax=bash snip_id=apply_tls_origination >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: httpbin-org-tls
  namespace: istio-egress
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
EOF
{{< /text >}}

Verify that the application still receives a response, now sent over HTTPS by the gateway:

{{< text syntax=bash snip_id=verify_tls_origination >}}
$ kubectl exec deploy/curl -- curl -s http://httpbin.org/get | head -5
{{< /text >}}

{{< tip >}}
ztunnel provides mTLS between the application pod and the egress waypoint automatically. The `DestinationRule` here controls only the outbound TLS from the waypoint to the external host.
{{< /tip >}}

## Add an external service without TLS origination

To expose additional external hosts through the same egress waypoint, create another `ServiceEntry` in the same namespace. No additional waypoint configuration is needed because the namespace is already enrolled:

{{< text syntax=bash snip_id=apply_second_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: example-com
  namespace: istio-egress
spec:
  hosts:
  - example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Verify that traffic to the new host also routes through the waypoint:

{{< text syntax=bash snip_id=verify_second_serviceentry >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://example.com
200
{{< /text >}}

Each `ServiceEntry` in the namespace is automatically routed through the waypoint and can carry its own `AuthorizationPolicy`.

## Cleanup

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete namespace istio-egress
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

## See also

- [Configure waypoint proxies](/docs/ambient/usage/waypoint/): general waypoint deployment and enrollment
- [Require traffic to traverse the waypoint](/docs/ambient/usage/waypoint/#require-waypoint): enforce that egress traffic cannot bypass the waypoint
- [ServiceEntry visibility](/docs/ambient/usage/serviceentry-visibility/): control which namespaces can discover each `ServiceEntry`
- [Use Layer 7 features](/docs/ambient/usage/l7-features/): full list of L7 policies and routes available at a waypoint
- [Egress gateways (sidecar mode)](/docs/tasks/traffic-management/egress/egress-gateway/): the equivalent sidecar-mode configuration for comparison
