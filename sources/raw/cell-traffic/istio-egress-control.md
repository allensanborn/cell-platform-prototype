---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/tasks/traffic-management/egress/egress-control/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed 21a952b37e75 2026-11-09)"
---


<!-- istio.io/content/en/docs/tasks/traffic-management/egress/egress-control/index.md lines 56,66 -->

## Envoy passthrough to external services

Istio has an [installation option](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode),
`meshConfig.outboundTrafficPolicy.mode`, that configures the sidecar handling
of external services, that is, those services that are not defined in Istio's internal service registry.
If this option is set to `ALLOW_ANY`, the Istio proxy lets calls to unknown services pass through.
If the option is set to `REGISTRY_ONLY`, then the Istio proxy blocks any host without an HTTP service or
service entry defined within the mesh.
`ALLOW_ANY` is the default value, allowing you to start evaluating Istio quickly,
without controlling access to external services.
You can then decide to [configure access to external services](#controlled-access-to-external-services) later.
