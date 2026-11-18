---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/ambient/usage/serviceentry-visibility/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed 66fd62313c04 2026-08-08)"
---


<!-- istio.io/content/en/docs/ambient/usage/serviceentry-visibility/index.md lines 10,16 -->

A [`ServiceEntry`](/docs/reference/config/networking/service-entry/) adds a service to Istio's internal service registry. By default, a `ServiceEntry` is visible to every workload in the mesh: anyone who can create a `ServiceEntry` in *any* namespace can define *any* hostname — for example `example.com` — and impact how the entire mesh resolves and routes to it.

The [`exportTo`](/docs/ops/configuration/mesh/configuration-scoping/) field does not protect against this, because it is declared by the author of the `ServiceEntry` itself: it lets a service owner scope what they publish, but places no firm constraint. Historically, a mesh administrator would need to constrain `ServiceEntry` creation with external admission control, such as a Kubernetes `ValidatingAdmissionPolicy` or webhook.

Beginning with Istio 1.31, the [`serviceEntryVisibility`](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) mesh configuration setting gives the mesh administrator that control, from a single place. The {{< gloss >}}ambient{{< /gloss >}} data plane ({{< gloss >}}ztunnel{{< /gloss >}} and {{< gloss "waypoint" >}}waypoints{{< /gloss >}}) honors visibility whenever it is configured; sidecars and gateways can [opt in](#extending-visibility-to-sidecars-and-gateways). The feature is inert unless configured: if `serviceEntryVisibility` is not set, nothing changes.

The design deliberately mirrors a familiar Kubernetes pattern: a `RoleBinding` has effect only within its own namespace, while creating cluster-wide effect with a `ClusterRoleBinding` is reserved for cluster administrators. `serviceEntryVisibility` lets the mesh administrator apply the same model to `ServiceEntry`: by setting `defaultVisibility: NAMESPACE`, an administrator makes every `ServiceEntry` behave like any other namespace-scoped resource, and visibility beyond a `ServiceEntry`'s own namespace becomes a capability the administrator explicitly grants.

<!-- istio.io/content/en/docs/ambient/usage/serviceentry-visibility/index.md lines 64,78 -->

## Visibility in ambient mode

When `serviceEntryVisibility` is configured, the ambient data plane always honors it. Istiod resolves the visibility of each `ServiceEntry` and distributes it with the service definition; ztunnel then applies it on the client side, based on the namespace of the workload making the request:

* A `PUBLIC` service behaves exactly as before.
* A `NAMESPACE` service can be discovered and resolved by workloads in its own namespace. For workloads in every other namespace, it is as if the `ServiceEntry` does not exist.
* A `NONE` service is never delivered to any data plane at all.

### Hidden means absent, not blocked

{{< warning >}}
Visibility hides a `ServiceEntry`; it does not block traffic. Clients outside the namespace do not receive `NXDOMAIN` responses or connection denials — they behave exactly as they would if the `ServiceEntry` had never been created.
{{< /warning >}}

This is deliberate: if ztunnel instead failed DNS queries for hidden hostnames, a `ServiceEntry` claiming `example.com` in one namespace would break `example.com` for the whole mesh — exactly the problem this feature exists to control. Concretely, for a client outside the `ServiceEntry`'s namespace:
