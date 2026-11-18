# raw/cell-traffic

Primary-doc captures for the question "which tools implement each WSO2 cell traffic direction (north/south/west/east) on Kubernetes". Fetched 2026-11-13, all via `gh api .../contents/<path> -H 'Accept: application/vnd.github.raw'` from each project's docs source repo (no HTML scraping). Each file's `fetch_note` names the exact repo paths and ref.

| File | Origin (repo @ ref → path) | Rendered URL |
|---|---|---|
| `gateway-api-security-multins-listenerset.md` | kubernetes-sigs/gateway-api @ main → site/content/en/docs/concepts/security.md, guides/user-guides/multiple-ns.md, guides/user-guides/listener-set.md | https://gateway-api.sigs.k8s.io/docs/concepts/security/ |
| `gateway-api-gep-1713-listenerset.md` | kubernetes-sigs/gateway-api @ main → geps/gep-1713/{metadata.yaml,index.md} | https://gateway-api.sigs.k8s.io/geps/gep-1713/ |
| `gateway-api-gep-4894-backend.md` | kubernetes-sigs/gateway-api @ main → geps/gep-4894/{metadata.yaml,index.md} | https://gateway-api.sigs.k8s.io/geps/gep-4894/ |
| `gateway-api-gamma-mesh.md` | kubernetes-sigs/gateway-api @ main → site/content/en/docs/mesh/{mesh-overview.md,gamma.md} | https://gateway-api.sigs.k8s.io/docs/mesh/ |
| `gateway-api-release-notes-v1.5-v1.7.md` | GitHub releases v1.5.0 (2026-02-27), v1.7.0 (2026-10-29) | https://github.com/kubernetes-sigs/gateway-api/releases |
| `network-policy-api-clusternetworkpolicy.md` | kubernetes-sigs/network-policy-api @ main → site-src/api-overview.md, implementations.md, npeps/npep-133-fqdn-egress-selector.md + releases v0.2.0, v0.3.0 | https://network-policy-api.sigs.k8s.io/api-overview/ |
| `cilium-dns-and-layer3-policy.md` | cilium/cilium @ v1.20.4 → Documentation/security/dns.rst, security/policy/layer3.rst | https://docs.cilium.io/en/stable/security/dns/ |
| `cilium-egress-gateway.md` | cilium/cilium @ v1.20.4 → Documentation/network/egress-gateway/egress-gateway.rst | https://docs.cilium.io/en/stable/network/egress-gateway/egress-gateway/ |
| `cilium-clusterwide-deny-clustermesh.md` | cilium/cilium @ v1.20.4 → Documentation/security/policy/{intro,kubernetes,deny}.rst, network/clustermesh/intro.rst | https://docs.cilium.io/en/stable/security/policy/kubernetes/ |
| `istio-ambient-waypoint-policy-egress.md` | istio/istio.io @ master → content/en/docs/ambient/usage/{waypoint,l4-policy,l7-features,networkpolicy,egress-gateway}/index.md | https://istio.io/latest/docs/ambient/usage/waypoint/ |
| `istio-sidecar-egress-control-gateway.md` | istio/istio.io @ master → content/en/docs/tasks/traffic-management/egress/{egress-control,egress-gateway}/index.md | https://istio.io/latest/docs/tasks/traffic-management/egress/egress-control/ |
| `istio-ambient-multicluster-and-authz.md` | istio/istio.io @ master → content/en/docs/ambient/install/multicluster/{_index.md,before-you-begin/index.md}, concepts/security/index.md | https://istio.io/latest/docs/ambient/install/multicluster/ |
| `openchoreo-runtime-gateways-networkpolicy.md` | openchoreo/openchoreo.github.io @ HEAD → docs/concepts/runtime-model.md, docs/platform-engineer-guide/api-gateway/topology.md; openchoreo/openchoreo @ main → internal/networkpolicy/networkpolicy.go, install/helm/openchoreo-data-plane/templates/gateway/gateway.yaml, test/e2e/k3d/internal-gateway.yaml, samples/getting-started/cluster-project-types/default.yaml, api/v1alpha1/workload_types.go (excerpt) | https://openchoreo.dev/docs/platform-engineer-guide/api-gateway/topology/ |
| `calico-egress-gateway-and-tiers.md` | tigera/docs @ main → calico-enterprise/networking/egress/egress-gateway-on-prem.mdx, calico/network-policy/policy-tiers/tiered-policy.mdx | https://docs.tigera.io/calico-enterprise/latest/networking/egress/egress-gateway-on-prem |
| `linkerd-multicluster.md` | linkerd/website @ main → linkerd.io/content/2-edge/features/multicluster.md | https://linkerd.io/2-edge/features/multicluster/ |
| `envoy-gateway-local-rate-limit.md` | envoyproxy/gateway @ main → site/content/en/latest/tasks/traffic/local-rate-limit.md | https://gateway.envoyproxy.io/latest/tasks/traffic/local-rate-limit/ |

Not captured (named UNVERIFIED in the findings): Submariner, Skupper, kgateway's own rate-limit/egress docs, kubernetes.io NetworkPolicy page.

## Follow-up captures (2026-11-16)

25 more files from a second research pass, summarised in `docs/sources/cell-traffic-gaps-2026-11.md`: `cilium-23380`, `cilium-kcnp-doc-v1.20.4`, `istio-*` (api mesh config, pilot outbound, egress control, ambient waypoint / data plane / egress gateway / l7 features / serviceentry visibility / lua, rate-limit task, issues 43720 and 54391), `ztunnel-outbound-passthrough`, `kgateway-*` (3), `submariner-*` (3), `cncf-landscape-submariner`, `skupper-*` (3). Each carries `resource`, `fetched` and `fetch_note` with the pinned SHA.
