---
resource: https://github.com/istio/istio/blob/4689491e2f46d1972fb416c327780eb474b63da3/pilot/pkg/networking/core/listener_builder.go
fetched: 2026-11-16
fetch_note: "sparse git clone istio/istio@4689491e2f46d1972fb416c327780eb474b63da3 (2026-11-16)"
---


<!-- istio/pilot/pkg/networking/core/listener_builder.go lines 298,316 -->

// See https://github.com/istio/istio/issues/21170
func (lb *ListenerBuilder) buildOutboundCatchAllNetworkFilterChains() []*listener.FilterChain {
	node := lb.node
	push := lb.push
	chains := []*listener.FilterChain{blackholeFilterChain(push, node)}

	if util.IsAllowAnyDynamicDNSOutbound(node) {
		// Plaintext HTTP: HTTP inspector detects HTTP traffic → HCM with DFP filter → AllowAnyDynamicDNSCluster.
		chains = append(chains, lb.buildAllowAnyDynamicDNSHTTPFilterChain())
	}
	// Everything else (TLS, plain TCP): PassthroughCluster (or EgressProxy) for ALLOW_ANY/ALLOW_ANY_DYNAMIC_DNS,
	// BlackHoleCluster for REGISTRY_ONLY.
	chains = append(chains, &listener.FilterChain{
		Name:    model.VirtualOutboundCatchAllTCPFilterChainName,
		Filters: buildOutboundCatchAllNetworkFiltersOnly(push, node),
	})

	return chains
}
