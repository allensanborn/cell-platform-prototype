---
resource: https://github.com/istio/ztunnel/blob/6a0f4878dbc7757a1893327657e3b5e128096393/src/proxy/outbound.rs
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/ztunnel@6a0f4878dbc7757a1893327657e3b5e128096393; grep -ri 'registry_only|outbound_traffic' src/ returned nothing"
---


<!-- ztunnel/src/proxy/outbound.rs lines 796,815 -->

            .await?
        else {
            if let Some(service) = service
                && service.
                load_balancer.
                as_ref().
                // If we are not a passthrough service, we should have an upstream
                map(|lb| lb.mode != LoadBalancerMode::Passthrough).
                // If the service had no lb, we should have an upstream
                unwrap_or(true)
            {
                return Err(Error::NoHealthyUpstream(target));
            }
            debug!("built request as passthrough; no upstream found");
            return Ok(Request {
                protocol: OutboundProtocol::TCP,
                source: source_workload,
                hbone_target_destination: None,
                actual_destination_workload: None,
                intended_destination_service: None,
