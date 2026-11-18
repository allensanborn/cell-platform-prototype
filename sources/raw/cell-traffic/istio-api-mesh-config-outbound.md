---
resource: https://github.com/istio/api/blob/590ccfb34743af8f52b76e75d25d8df72287fc01/mesh/v1alpha1/config.proto
fetched: 2026-11-16
fetch_note: "gh api contents istio/api@590ccfb34743af8f52b76e75d25d8df72287fc01 (file last changed e0d275e5684d 2026-09-24)"
---


<!-- api-config.proto lines 173,211 -->

  // `OutboundTrafficPolicy` sets the default behavior of the sidecar for
  // handling unknown outbound traffic from the application.
  message OutboundTrafficPolicy {
    enum Mode {
      // In `REGISTRY_ONLY` mode, unknown outbound traffic will be dropped.
      // Traffic destinations must be explicitly declared into the service registry through `ServiceEntry` configurations.
      //
      // Note: Istio [does not offer an outbound traffic security policy](https://istio.io/latest/docs/ops/best-practices/security/#understand-traffic-capture-limitations).
      // This option does not act as one, or as any form of an outbound firewall.
      // Instead, this option exists primarily to offer users a way to detect missing `ServiceEntry` configurations by explicitly failing.
      REGISTRY_ONLY = 0;
      // In `ALLOW_ANY` mode, any traffic to unknown destinations will be allowed.
      // Unknown destination traffic will have limited functionality, however, such as reduced observability.
      // This mode allows users that do not have all possible egress destinations registered through `ServiceEntry` configurations to still connect
      // to arbitrary destinations.
      ALLOW_ANY = 1;
      // In `ALLOW_ANY_DYNAMIC_DNS` mode, traffic to unknown destinations will be allowed via dynamic DNS resolution.
      // This mode allows users that do not have all possible egress destinations registered through `ServiceEntry` configurations to still connect
      // to arbitrary destinations. Client TLS settings can be configured for connections to such destinations.
      // This mode cannot be used at the Sidecar level.
      ALLOW_ANY_DYNAMIC_DNS = 3;

      reserved 2;
      reserved "VIRTUAL_SERVICE_ONLY";
    }
    Mode mode = 1;

    // TLS settings for client connections to unknown destinations. Applicable only when mode is set to `ALLOW_ANY_DYNAMIC_DNS`.
    istio.networking.v1alpha3.ClientTLSSettings tls = 2;
  }

  // Set the default behavior of the sidecar for handling outbound
  // traffic from the application. This does not apply to gateways.
  //
  // Can be overridden at a Sidecar level by setting the `OutboundTrafficPolicy` in the
  // [Sidecar API](https://istio.io/docs/reference/config/networking/sidecar/#OutboundTrafficPolicy).
  //
  // Default mode is `ALLOW_ANY`, which means outbound traffic to unknown destinations will be allowed.
  OutboundTrafficPolicy outbound_traffic_policy = 17;
