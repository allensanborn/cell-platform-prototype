---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/usage/waypoint/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed bc969197f9e4 2026-09-17)"
---


<!-- istio.io/content/en/docs/ambient/usage/waypoint/index.md lines 16,30 -->

A waypoint, or set of waypoints, can be shared between applications with a similar security boundary. This might be all the instances of a particular workload, or all the workloads in a namespace.

As opposed to {{< gloss >}}sidecar{{< /gloss >}} mode, in ambient mode policies are enforced by the **destination** waypoint. In many ways, the waypoint acts as a gateway to a resource (a namespace, service or pod). Istio enforces that all traffic coming into the resource goes through the waypoint, which then enforces all policies for that resource.

## Do you need a waypoint proxy?

The layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure L4 overlay, to full L7 processing.

Most of the features of ambient mode are provided by the ztunnel node proxy. Ztunnel is scoped to only process traffic at Layer 4 (L4), so that it can safely operate as a shared component.

When you configure redirection to a waypoint, traffic will be forwarded by ztunnel to that waypoint. If your applications require any of the following L7 mesh functions, you will need to use a waypoint proxy:

* **Traffic management**: HTTP routing & load balancing, circuit breaking, rate limiting, fault injection, retries, timeouts
* **Security**: Rich authorization policies based on L7 primitives such as request type or HTTP header
* **Observability**: HTTP metrics, access logging, tracing

<!-- istio.io/content/en/docs/ambient/usage/waypoint/index.md lines 152,158 -->

### Ingress gateways and waypoints {#ingress-and-waypoints}

The `istio.io/use-waypoint` label governs **east-west** traffic: requests from other pods in the mesh to the labeled namespace, service, or workload are sent through the destination waypoint for Layer 7 policy and telemetry.

Traffic from an **Istio ingress gateway** to that `Service` is modeled separately. By default, ingress-originated traffic will **not** use the destination service waypoint, even when `istio.io/use-waypoint` is set on the service or namespace.

To direct ingress traffic through the same waypoint as mesh traffic, set **`istio.io/ingress-use-waypoint`** to `true` on the Kubernetes `Service`, or on the `Namespace` to apply to all services in that namespace (supported starting with Istio 1.25). See the [resource labels](/docs/reference/config/labels/#IoIstioIngressUseWaypoint) reference for supported resource types.

<!-- istio.io/content/en/docs/ambient/usage/waypoint/index.md lines 216,226 -->

### Require traffic to traverse the waypoint {#require-waypoint}

The `istio.io/use-waypoint` label records your intent to send traffic through a waypoint, but on its own it does not guarantee that this happens. ztunnel routes traffic directly to the destination, rather than failing the request, when:

* the named waypoint does not exist or has no address; or
* the traffic type does not match the traffic the waypoint handles; for example, a request sent directly to a workload (a pod or VM IP) when the waypoint only handles service traffic, which is the [default](#waypoint-traffic-types).

In either case, any Layer 7 policy that the waypoint would have enforced never takes effect, and traffic flows as though no waypoint were configured.

If enforcing a waypoint's Layer 7 policies is a security requirement, make the waypoint mandatory with an `AuthorizationPolicy` that allows only the waypoint's identity. A waypoint uses the service account named after its `Gateway`, so a policy on the destination workloads that allows only that identity denies any client that reaches them without first passing through the waypoint. Continuing with the `reviews-svc-waypoint` waypoint from above:

