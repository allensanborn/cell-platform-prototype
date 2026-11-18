---
type: source
resource: https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.0
title: "Gateway API release notes v1.5.0 and v1.7.0 (full bodies)"
source_kind: webpage
tags: [gateway-api, release-notes, listenerset, referencegrant]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/kubernetes-sigs/gateway-api/releases/tags/{v1.5.0,v1.7.0} --jq .body, 2026-11-13. v1.5.0 published 2026-02-27; v1.7.0 published 2026-10-29. Full bodies saved verbatim (no excerpting despite title)."
---

# v1.5.0 (published 2026-02-27)
**Warning**: The Experimental channel CRDs are too large for a standard `kubectl apply`. To work around this please use `kubectl apply --server-side=true` instead -- or, even better, use [`kuberc`](https://kubernetes.io/docs/reference/kubectl/kuberc/) to make server-side apply the default.

# Gateway API v1.5.0

## Major Changes Since v1.4.1

### Breaking Changes

#### TLSRoute `v1alpha2` and XListenerSet

TLSRoute and ListenerSet have graduated to the Standard channel as `v1`. In 1.5.0, TLSRoute `v1alpha2` is present only in the Experimental channel; in 1.6, it will be removed from the Experimental channel too.

Additionally, note that TLSRoute's CEL validation requires Kubernetes 1.31 or higher.

#### Upgrades and ValidatingAdmissionPolicy

Gateway API 1.5 introduces a validating admission policy (VAP) called `safe-upgrades.gateway.networking.k8s.io` to guard against two specific concerns:

* It prevents installing Experimental CRDs once you've installed Standard CRDs.
* It prevents downgrading to a version prior to 1.5 after you've installed Gateway API 1.5.

These actions can't be known to be safe without detailed knowledge about your application and users. If you need to perform them, delete the `safe-upgrades.gateway.networking.k8s.io` VAP first.

### New Features

In this release, the following major features are moving to the `Standard` channel and are now considered generally available:

* Gateway Client Certificate validation ([GEP-91], [GEP-3567])
* Certificate selection for Gateway TLS origination ([GEP-3155])
* ListenerSet support ([GEP-1713])
* HTTPRoute CORS filter ([GEP-1767])
* TLSRoute `v1` ([GEP-2643])

Additionally, the ReferenceGrant resource is moving to `v1`.

[GEP-91]: https://gateway-api.sigs.k8s.io/geps/gep-91/
[GEP-1713]: https://gateway-api.sigs.k8s.io/geps/gep-1713/
[GEP-1767]: https://gateway-api.sigs.k8s.io/geps/gep-1767/
[GEP-2643]: https://gateway-api.sigs.k8s.io/geps/gep-2643/
[GEP-3155]: https://gateway-api.sigs.k8s.io/geps/gep-3155/
[GEP-3567]: https://gateway-api.sigs.k8s.io/geps/gep-3567/

## Experimental

* Gateway/HTTPRoute level authentication ([GEP-1494])

[GEP-1494]: https://gateway-api.sigs.k8s.io/geps/gep-1494/

## Full Changelog

**Full Changelog**: https://github.com/kubernetes-sigs/gateway-api/compare/v1.4.1...v1.5.0

## Dependencies

### Added
- github.com/Masterminds/semver/v3: [v3.4.0](https://github.com/Masterminds/semver/tree/v3.4.0)
- github.com/chzyer/readline: [v1.5.1](https://github.com/chzyer/readline/tree/v1.5.1)
- github.com/gkampitakis/ciinfo: [v0.3.2](https://github.com/gkampitakis/ciinfo/tree/v0.3.2)
- github.com/gkampitakis/go-diff: [v1.3.2](https://github.com/gkampitakis/go-diff/tree/v1.3.2)
- github.com/gkampitakis/go-snaps: [v0.5.15](https://github.com/gkampitakis/go-snaps/tree/v0.5.15)
- github.com/ianlancetaylor/demangle: [f615e6b](https://github.com/ianlancetaylor/demangle/tree/f615e6b)
- github.com/joshdk/go-junit: [v1.0.0](https://github.com/joshdk/go-junit/tree/v1.0.0)
- github.com/maruel/natural: [v1.1.1](https://github.com/maruel/natural/tree/v1.1.1)
- github.com/mfridman/tparse: [v0.18.0](https://github.com/mfridman/tparse/tree/v0.18.0)
- github.com/tidwall/gjson: [v1.18.0](https://github.com/tidwall/gjson/tree/v1.18.0)
- github.com/tidwall/match: [v1.1.1](https://github.com/tidwall/match/tree/v1.1.1)
- github.com/tidwall/pretty: [v1.2.1](https://github.com/tidwall/pretty/tree/v1.2.1)
- github.com/tidwall/sjson: [v1.2.5](https://github.com/tidwall/sjson/tree/v1.2.5)

### Changed
- cloud.google.com/go/compute/metadata: v0.7.0 → v0.9.0
- github.com/GoogleCloudPlatform/opentelemetry-operations-go/detectors/gcp: [v1.29.0 → v1.30.0](https://github.com/GoogleCloudPlatform/opentelemetry-operations-go/compare/detectors/gcp/v1.29.0...detectors/gcp/v1.30.0)
- github.com/cncf/xds/go: [2ac532f → 0feb691](https://github.com/cncf/xds/compare/2ac532f...0feb691)
- github.com/envoyproxy/go-control-plane/envoy: [v1.32.4 → v1.35.0](https://github.com/envoyproxy/go-control-plane/compare/envoy/v1.32.4...envoy/v1.35.0)
- github.com/envoyproxy/go-control-plane: [v0.13.4 → 75eaa19](https://github.com/envoyproxy/go-control-plane/compare/v0.13.4...75eaa19)
- github.com/go-jose/go-jose/v4: [v4.1.1 → v4.1.3](https://github.com/go-jose/go-jose/compare/v4.1.1...v4.1.3)
- github.com/google/pprof: [d1b30fe → 294ebfa](https://github.com/google/pprof/compare/d1b30fe...294ebfa)
- github.com/mailru/easyjson: [v0.9.0 → v0.9.1](https://github.com/mailru/easyjson/compare/v0.9.0...v0.9.1)
- github.com/miekg/dns: [v1.1.68 → v1.1.72](https://github.com/miekg/dns/compare/v1.1.68...v1.1.72)
- github.com/onsi/ginkgo/v2: [v2.22.0 → v2.28.0](https://github.com/onsi/ginkgo/compare/v2.22.0...v2.28.0)
- github.com/onsi/gomega: [v1.38.1 → v1.39.1](https://github.com/onsi/gomega/compare/v1.38.1...v1.39.1)
- github.com/prometheus/client_golang: [v1.23.0 → v1.23.2](https://github.com/prometheus/client_golang/compare/v1.23.0...v1.23.2)
- github.com/prometheus/common: [v0.65.0 → v0.66.1](https://github.com/prometheus/common/compare/v0.65.0...v0.66.1)
- github.com/prometheus/procfs: [v0.17.0 → v0.19.2](https://github.com/prometheus/procfs/compare/v0.17.0...v0.19.2)
- github.com/rogpeppe/go-internal: [v1.13.1 → v1.14.1](https://github.com/rogpeppe/go-internal/compare/v1.13.1...v1.14.1)
- github.com/spf13/cobra: [v1.9.1 → v1.10.2](https://github.com/spf13/cobra/compare/v1.9.1...v1.10.2)
- github.com/spf13/pflag: [v1.0.7 → v1.0.10](https://github.com/spf13/pflag/compare/v1.0.7...v1.0.10)
- github.com/spiffe/go-spiffe/v2: [v2.5.0 → v2.6.0](https://github.com/spiffe/go-spiffe/compare/v2.5.0...v2.6.0)
- github.com/stretchr/testify: [v1.11.0 → v1.11.1](https://github.com/stretchr/testify/compare/v1.11.0...v1.11.1)
- go.etcd.io/bbolt: v1.4.2 → v1.4.3
- go.etcd.io/etcd/api/v3: v3.6.4 → v3.6.5
- go.etcd.io/etcd/client/pkg/v3: v3.6.4 → v3.6.5
- go.etcd.io/etcd/client/v3: v3.6.4 → v3.6.5
- go.etcd.io/etcd/pkg/v3: v3.6.4 → v3.6.5
- go.etcd.io/etcd/server/v3: v3.6.4 → v3.6.5
- go.opentelemetry.io/auto/sdk: v1.1.0 → v1.2.1
- go.opentelemetry.io/contrib/detectors/gcp: v1.36.0 → v1.38.0
- go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp: v0.58.0 → v0.61.0
- go.opentelemetry.io/otel/metric: v1.37.0 → v1.38.0
- go.opentelemetry.io/otel/sdk/metric: v1.37.0 → v1.38.0
- go.opentelemetry.io/otel/sdk: v1.37.0 → v1.38.0
- go.opentelemetry.io/otel/trace: v1.37.0 → v1.38.0
- go.opentelemetry.io/otel: v1.37.0 → v1.38.0
- go.opentelemetry.io/proto/otlp: v1.5.0 → v1.7.0
- go.uber.org/zap: v1.27.0 → v1.27.1
- go.yaml.in/yaml/v2: v2.4.2 → v2.4.3
- golang.org/x/crypto: v0.41.0 → v0.47.0
- golang.org/x/mod: v0.27.0 → v0.32.0
- golang.org/x/net: v0.43.0 → v0.49.0
- golang.org/x/oauth2: v0.30.0 → v0.34.0
- golang.org/x/sync: v0.16.0 → v0.19.0
- golang.org/x/sys: v0.35.0 → v0.40.0
- golang.org/x/telemetry: 1a19826 → bd525da
- golang.org/x/term: v0.34.0 → v0.39.0
- golang.org/x/text: v0.28.0 → v0.33.0
- golang.org/x/time: v0.12.0 → v0.14.0
- golang.org/x/tools: v0.36.0 → v0.41.0
- google.golang.org/genproto/googleapis/api: 8d1bb00 → ab9386a
- google.golang.org/genproto/googleapis/rpc: ef028d9 → ab9386a
- google.golang.org/grpc: v1.75.1 → v1.78.0
- google.golang.org/protobuf: v1.36.8 → v1.36.11
- k8s.io/api: v0.34.1 → v0.35.1
- k8s.io/apiextensions-apiserver: v0.34.1 → v0.35.1
- k8s.io/apimachinery: v0.34.1 → v0.35.1
- k8s.io/apiserver: v0.34.1 → v0.35.1
- k8s.io/client-go: v0.34.1 → v0.35.1
- k8s.io/code-generator: v0.34.1 → v0.35.1
- k8s.io/component-base: v0.34.1 → v0.35.1
- k8s.io/gengo/v2: c297c0c → ec3ebc5
- k8s.io/kms: v0.34.1 → v0.35.1
- k8s.io/kube-openapi: d7b6acb → 589584f
- k8s.io/utils: 0af2bda → 914a6e7
- sigs.k8s.io/controller-runtime: v0.22.1 → v0.23.1
- sigs.k8s.io/controller-tools: v0.19.0 → v0.20.1
- sigs.k8s.io/structured-merge-diff/v6: v6.3.0 → v6.3.2

### Removed
- github.com/kisielk/errcheck: [v1.5.0](https://github.com/kisielk/errcheck/tree/v1.5.0)
- github.com/kisielk/gotool: [v1.0.0](https://github.com/kisielk/gotool/tree/v1.0.0)
- github.com/pkg/errors: [v0.9.1](https://github.com/pkg/errors/tree/v0.9.1)
- github.com/zeebo/errs: [v1.4.0](https://github.com/zeebo/errs/tree/v1.4.0)
- golang.org/x/xerrors: 5ec99f8


# v1.7.0 (published 2026-10-29)
## Major Themes

### Graduating to Standard

*   **HTTPRoute Retries ([GEP-1731](https://gateway-api.sigs.k8s.io/geps/gep-1731/))**: the `retry` configuration of an HTTPRoute rule (`codes`, `attempts` and `backoff`) is promoted to the Standard channel, together with the `HTTPRouteRetryCodes` and `HTTPRouteRetryConnectionError` conformance features. The `backoff` field is implementation-specific because backoff behavior, especially jitter, varies between implementations. ([#5357](https://github.com/kubernetes-sigs/gateway-api/pull/5357), [@snorwin](https://github.com/snorwin), [#5359](https://github.com/kubernetes-sigs/gateway-api/pull/5359), [@mikemorris](https://github.com/mikemorris))

### New in Experimental

*   **Gateway Address Routability ([GEP-5093](https://gateway-api.sigs.k8s.io/geps/gep-5093/))**: routability is expressed per Gateway address, so a single Gateway can serve addresses of different scopes. Valid values are empty (implementation default), `Cluster`, or a domain-prefixed implementation-specific value. ([#5304](https://github.com/kubernetes-sigs/gateway-api/pull/5304), [@rikatz](https://github.com/rikatz))
*   **Standardized Attribute Dictionary ([GEP-5253](https://gateway-api.sigs.k8s.io/geps/gep-5253/))**: a shared, vendor-neutral set of traffic attributes, based on OpenTelemetry semantic conventions, for use by features such as `XTelemetryPolicy`. ([#5256](https://github.com/kubernetes-sigs/gateway-api/pull/5256), [@gkhom](https://github.com/gkhom))
*   **Session Persistence on Backend ([GEP-1619](https://gateway-api.sigs.k8s.io/geps/gep-1619/) and [GEP-4894](https://gateway-api.sigs.k8s.io/geps/gep-4894/))**: session persistence is configured on the `XBackend` resource, and the route-inline and `BackendTrafficPolicy` attachment points are deprecated. ([#4876](https://github.com/kubernetes-sigs/gateway-api/pull/4876), [#5298](https://github.com/kubernetes-sigs/gateway-api/pull/5298), [@gcs278](https://github.com/gcs278))
*   **Pre-routing Filters ([GEP-5224](https://gateway-api.sigs.k8s.io/geps/gep-5224/))**: listener filters that run before routing decisions, for use cases such as external authentication and payload processing, with the new `GatewayListenerFilters` feature. Filters can be set on both Gateway and `ListenerSet` listeners. ([#5315](https://github.com/kubernetes-sigs/gateway-api/pull/5315), [@jaellio](https://github.com/jaellio), [#5370](https://github.com/kubernetes-sigs/gateway-api/pull/5370), [@snorwin](https://github.com/snorwin))
*   **ClusterTrustBundle in `caCertificateRefs` ([GEP-5075](https://gateway-api.sigs.k8s.io/geps/gep-5075/))**: `BackendTLSPolicy` and Gateway frontend TLS validation can reference a `ClusterTrustBundle` through the existing `caCertificateRefs` field, instead of copying CA bundles into every namespace. ([#5272](https://github.com/kubernetes-sigs/gateway-api/pull/5272), [#5356](https://github.com/kubernetes-sigs/gateway-api/pull/5356), [@davidesalerno](https://github.com/davidesalerno))
*   **TelemetryPolicy for Distributed Tracing ([GEP-4768](https://gateway-api.sigs.k8s.io/geps/gep-4768/))**: the `XTelemetryPolicy` API standardizes tracing configuration for Gateways without vendor-specific CRDs. Metrics and access logs are not covered yet. ([#5323](https://github.com/kubernetes-sigs/gateway-api/pull/5323), [@gkhom](https://github.com/gkhom))

## Major Changes Since v1.6.3

### Breaking Changes

*   **Experimental API changes (no effect on the Standard channel):**
    *   SessionPersistence API: `sessionName` moved to `cookie.name` (Extended, optional) and `header.name` (Core, required), `cookieConfig` renamed to `cookie`, and `HeaderConfig` added. ([#4873](https://github.com/kubernetes-sigs/gateway-api/pull/4873), [@gcs278](https://github.com/gcs278))
    *   SessionPersistence API: the cookie `Path` now defaults to `/` instead of being computed from route matches, and the new `cookie.path` field (Extended) allows explicit path configuration. ([#5046](https://github.com/kubernetes-sigs/gateway-api/pull/5046), [@gcs278](https://github.com/gcs278))
    *   SessionPersistence: route-inline and `BackendTrafficPolicy` session persistence are deprecated in favor of the Backend resource. ([#4876](https://github.com/kubernetes-sigs/gateway-api/pull/4876), [@gcs278](https://github.com/gcs278))
    *   `XBackend`: `spec.port.port` was renamed to `spec.port.number`, `spec.port.name` was removed, and `backendRef.port` is now prohibited when referencing an `XBackend`. ([#5287](https://github.com/kubernetes-sigs/gateway-api/pull/5287), [@gcs278](https://github.com/gcs278))
*   **Go types:**
    *   `BackendAncestorStatus.AncestorRef` was renamed in the generated Go types for consistency with docs and JSON/YAML serialization. ([#5187](https://github.com/kubernetes-sigs/gateway-api/pull/5187), [@Stevenjin8](https://github.com/Stevenjin8))
    *   `ForwardBodyConfig.MaxSize` changed type from `uint16` to `int32`. ([#5099](https://github.com/kubernetes-sigs/gateway-api/pull/5099), [@arjunxplorer](https://github.com/arjunxplorer))
*   **Conformance features:**
    *   The `HTTPRouteRetry` and `HTTPRouteRetryBackendTimeout` features were removed. `HTTPRouteRetryCodes` was added and `HTTPRouteRetryConnectionError` is retained. ([#5167](https://github.com/kubernetes-sigs/gateway-api/pull/5167), [@snorwin](https://github.com/snorwin))
    *   The `HTTPRouteBackendRequestRedirect` feature and its test were removed. ([#5279](https://github.com/kubernetes-sigs/gateway-api/pull/5279), [@snorwin](https://github.com/snorwin))
*   Go was upgraded to 1.27 (`go 1.27.0` directive in `go.mod` and `conformance/go.mod`) and Kubernetes dependencies to v0.37. ([#5297](https://github.com/kubernetes-sigs/gateway-api/pull/5297), [@snorwin](https://github.com/snorwin), [#5232](https://github.com/kubernetes-sigs/gateway-api/pull/5232), [@snorwin](https://github.com/snorwin), [#5388](https://github.com/kubernetes-sigs/gateway-api/pull/5388), [@howardjohn](https://github.com/howardjohn))

### GEP & API Graduation

*   **GEP Status Updates:**
    *   [GEP-4768](https://gateway-api.sigs.k8s.io/geps/gep-4768/) (TelemetryPolicy): add the proposal, then the experimental `XTelemetryPolicy` API ([#4872](https://github.com/kubernetes-sigs/gateway-api/pull/4872), [@gkhom](https://github.com/gkhom), [#5323](https://github.com/kubernetes-sigs/gateway-api/pull/5323), [#5345](https://github.com/kubernetes-sigs/gateway-api/pull/5345), [@robscott](https://github.com/robscott))
    *   [GEP-5093](https://gateway-api.sigs.k8s.io/geps/gep-5093/) (Gateway Address Routability): add as Provisional, move to Implementable, then to Experimental. ([#5094](https://github.com/kubernetes-sigs/gateway-api/pull/5094), [@usize](https://github.com/usize), [#5263](https://github.com/kubernetes-sigs/gateway-api/pull/5263), [@rikatz](https://github.com/rikatz), [#5304](https://github.com/kubernetes-sigs/gateway-api/pull/5304), [@rikatz](https://github.com/rikatz))
    *   [GEP-5224](https://gateway-api.sigs.k8s.io/geps/gep-5224/) (Pre-routing filters): add as Provisional, move to Implementable, then to Experimental. ([#5235](https://github.com/kubernetes-sigs/gateway-api/pull/5235), [@jaellio](https://github.com/jaellio), [#5271](https://github.com/kubernetes-sigs/gateway-api/pull/5271), [@jaellio](https://github.com/jaellio), [#5315](https://github.com/kubernetes-sigs/gateway-api/pull/5315), [@jaellio](https://github.com/jaellio))
    *   [GEP-5075](https://gateway-api.sigs.k8s.io/geps/gep-5075/) (ClusterTrustBundle `caCertificateRef`): add as Provisional, move to Experimental, then use `caCertificateRefs` instead of a dedicated reference type. ([#5259](https://github.com/kubernetes-sigs/gateway-api/pull/5259), [@davidesalerno](https://github.com/davidesalerno), [#5272](https://github.com/kubernetes-sigs/gateway-api/pull/5272), [@davidesalerno](https://github.com/davidesalerno), [#5356](https://github.com/kubernetes-sigs/gateway-api/pull/5356), [@davidesalerno](https://github.com/davidesalerno))
    *   [GEP-5253](https://gateway-api.sigs.k8s.io/geps/gep-5253/): Standardized Attribute Dictionary. ([#5256](https://github.com/kubernetes-sigs/gateway-api/pull/5256), [@gkhom](https://github.com/gkhom))
    *   [GEP-4359](https://gateway-api.sigs.k8s.io/geps/gep-4359/): Gateway API Regex. ([#4764](https://github.com/kubernetes-sigs/gateway-api/pull/4764), [@Stevenjin8](https://github.com/Stevenjin8))
    *   [GEP-4360](https://gateway-api.sigs.k8s.io/geps/gep-4360/): Regex-based Path Rewrites. ([#4695](https://github.com/kubernetes-sigs/gateway-api/pull/4695), [@Stevenjin8](https://github.com/Stevenjin8))
    *   [GEP-1619](https://gateway-api.sigs.k8s.io/geps/gep-1619/) (Session Persistence): synced with API updates and made the Backend the attachment point. ([#4870](https://github.com/kubernetes-sigs/gateway-api/pull/4870), [#4876](https://github.com/kubernetes-sigs/gateway-api/pull/4876), [@gcs278](https://github.com/gcs278))
    *   [GEP-1731](https://gateway-api.sigs.k8s.io/geps/gep-1731/) (HTTPRoute Retries): aligned retry semantics with implementations, then loosened the `backoff` definition so it no longer requires an exponential strategy, and promoted the retry configuration, including `backoff`, to the Standard channel. ([#5167](https://github.com/kubernetes-sigs/gateway-api/pull/5167), [@snorwin](https://github.com/snorwin), [#5359](https://github.com/kubernetes-sigs/gateway-api/pull/5359), [@mikemorris](https://github.com/mikemorris))
    *   [GEP-4894](https://gateway-api.sigs.k8s.io/geps/gep-4894/) (Backend): deferred `SelectorRef` in favor of the `Selector` field. ([#5158](https://github.com/kubernetes-sigs/gateway-api/pull/5158), [@gcs278](https://github.com/gcs278))
*   **Graduations to Standard:**
    *   HTTPRoute retry configuration (`retry.codes` and `retry.attempts`) is promoted to the Standard channel, and the `HTTPRouteRetryCodes` and `HTTPRouteRetryConnectionError` features are now Standard. `retry.backoff` (implementation-specific) is promoted with them. ([#5357](https://github.com/kubernetes-sigs/gateway-api/pull/5357), [@snorwin](https://github.com/snorwin))
    *   HTTPRoute and GRPCRoute rule `name` uniqueness validation is now enforced in the Standard channel. ([#5009](https://github.com/kubernetes-sigs/gateway-api/pull/5009), [@snorwin](https://github.com/snorwin))
    *   BackendTLSPolicy SANs and TLS options are now marked as Standard channel. ([#4999](https://github.com/kubernetes-sigs/gateway-api/pull/4999), [@Suvink](https://github.com/Suvink))
    *   The `TLSRouteMixedMode` feature is now Standard channel. ([#5412](https://github.com/kubernetes-sigs/gateway-api/pull/5412), [@rikatz](https://github.com/rikatz))

### Feature

*   **New Experimental APIs and Fields:**
    *   Experimental `XTelemetryPolicy` API ([GEP-4768](https://gateway-api.sigs.k8s.io/geps/gep-4768/)). ([#5323](https://github.com/kubernetes-sigs/gateway-api/pull/5323), [@gkhom](https://github.com/gkhom), [#5345](https://github.com/kubernetes-sigs/gateway-api/pull/5345), [@robscott](https://github.com/robscott))
    *   `XBackend` supports a new `EndpointSelector` type that routes to in-cluster pods selected by label. ([#5255](https://github.com/kubernetes-sigs/gateway-api/pull/5255), [@gcs278](https://github.com/gcs278))
    *   `XBackend` supports session persistence for the `EndpointSelector` type. ([#5298](https://github.com/kubernetes-sigs/gateway-api/pull/5298), [@gcs278](https://github.com/gcs278))
    *   `XBackend` TLS mode was refactored and its CEL validation fixed. ([#5316](https://github.com/kubernetes-sigs/gateway-api/pull/5316), [@snorwin](https://github.com/snorwin))
    *   Gateway address `routability` ([GEP-5093](https://gateway-api.sigs.k8s.io/geps/gep-5093/)), including the `GatewayAddressRoutability` and `GatewayAddressRoutabilityCluster` features. ([#5304](https://github.com/kubernetes-sigs/gateway-api/pull/5304), [@rikatz](https://github.com/rikatz))
    *   Pre-routing listener filters ([GEP-5224](https://gateway-api.sigs.k8s.io/geps/gep-5224/)), with the new `GatewayListenerFilters` feature. ([#5315](https://github.com/kubernetes-sigs/gateway-api/pull/5315), [@jaellio](https://github.com/jaellio))
    *   Pre-routing listener filters (`filters`) were added to `ListenerSet`. ([#5370](https://github.com/kubernetes-sigs/gateway-api/pull/5370), [@snorwin](https://github.com/snorwin))
    *   `ClusterTrustBundle` can be referenced through `caCertificateRefs` in `BackendTLSPolicy` and Gateway frontend TLS validation, with the new `ClusterTrustBundle` feature. ([#5272](https://github.com/kubernetes-sigs/gateway-api/pull/5272), [@davidesalerno](https://github.com/davidesalerno), [#5356](https://github.com/kubernetes-sigs/gateway-api/pull/5356), [@davidesalerno](https://github.com/davidesalerno))
*   **API & Validation Enhancements:**
    *   `HTTPRouteRetry.Attempts` now defaults to `1`, and its minimum was lowered from `1` to `0` so retries can be disabled per rule. ([#5269](https://github.com/kubernetes-sigs/gateway-api/pull/5269), [@snorwin](https://github.com/snorwin), [#5387](https://github.com/kubernetes-sigs/gateway-api/pull/5387), [@mikemorris](https://github.com/mikemorris))
    *   Added CEL validation enforcing that TLS is disabled for H2C and enabled for HTTP2. Added a new `WSS` protocol value for WebSockets over TLS. ([#5312](https://github.com/kubernetes-sigs/gateway-api/pull/5312), [@snorwin](https://github.com/snorwin))
    *   Added the `GatewayRouteHostnameIntersectionPrecedence` feature so implementations can opt in to resolving *Route precedence using the original Route hostnames instead of the calculated Listener/Route intersection. ([#5212](https://github.com/kubernetes-sigs/gateway-api/pull/5212), [@rostislavbobo](https://github.com/rostislavbobo))
    *   Replaced immutable CEL validation rules with the `+k8s:immutable` marker. ([#4902](https://github.com/kubernetes-sigs/gateway-api/pull/4902), [@chinmaychahar](https://github.com/chinmaychahar))
*   **Release Artifacts:**
    *   Releases now contain OpenAPIv2 schema definitions. ([#4686](https://github.com/kubernetes-sigs/gateway-api/pull/4686), [@Rycieos](https://github.com/Rycieos))

### Documentation

*   **New and Updated Documentation:**
    *   Added documentation for `XBackend`. ([#4931](https://github.com/kubernetes-sigs/gateway-api/pull/4931), [@keithmattix](https://github.com/keithmattix))
    *   Added TCP and UDP examples and documentation. ([#4932](https://github.com/kubernetes-sigs/gateway-api/pull/4932), [@zac-nixon](https://github.com/zac-nixon))
    *   Added `ListenerSet` to the SectionName interpretation table. ([#4880](https://github.com/kubernetes-sigs/gateway-api/pull/4880), [@apkatsikas](https://github.com/apkatsikas))
    *   Stopped referring to `ListenerSet` as experimental. ([#5228](https://github.com/kubernetes-sigs/gateway-api/pull/5228), [@linuzctl](https://github.com/linuzctl))
    *   Aligned the GRPCRoute hostname cross-serving godoc with the relaxed site docs. ([#5176](https://github.com/kubernetes-sigs/gateway-api/pull/5176), [@lexfrei](https://github.com/lexfrei))
    *   Clarified that implementations should only retry HTTPRoute requests on connection errors when it is safe to do so, and that `backoff` specifies the base interval of a backoff strategy rather than the minimum interval. The precise backoff curve and jitter are implementation-specific, and implementations that retry immediately with no backoff must not advertise support for `backoff`. ([#5269](https://github.com/kubernetes-sigs/gateway-api/pull/5269), [@snorwin](https://github.com/snorwin), [#5359](https://github.com/kubernetes-sigs/gateway-api/pull/5359), [@mikemorris](https://github.com/mikemorris))
    *   Marked Upstream TLS (BackendTLSPolicy) as Standard channel since v1.4.0. ([#4965](https://github.com/kubernetes-sigs/gateway-api/pull/4965), [@anneheartrecord](https://github.com/anneheartrecord))
    *   Corrected API groups in the [GEP-709](https://gateway-api.sigs.k8s.io/geps/gep-709/) ReferenceGrant example. ([#5310](https://github.com/kubernetes-sigs/gateway-api/pull/5310), [@deepujain](https://github.com/deepujain))
    *   Corrected conformance feature selection guidance. ([#5175](https://github.com/kubernetes-sigs/gateway-api/pull/5175), [@immanuwell](https://github.com/immanuwell))
    *   Updated the API reference format for readability. ([#5156](https://github.com/kubernetes-sigs/gateway-api/pull/5156), [@youngnick](https://github.com/youngnick))
*   **Site & Project:**
    *   Removed the old MkDocs and Python environments. ([#5165](https://github.com/kubernetes-sigs/gateway-api/pull/5165), [@rikatz](https://github.com/rikatz))
    *   Added dark mode image support. ([#5203](https://github.com/kubernetes-sigs/gateway-api/pull/5203), [@robscott](https://github.com/robscott))
    *   Added a GitHub repository link to the site navbar. ([#5305](https://github.com/kubernetes-sigs/gateway-api/pull/5305), [@yashrajshuklaaa](https://github.com/yashrajshuklaaa))
    *   Added an AI Policy document and AI disclosure to the pull request template. ([#5151](https://github.com/kubernetes-sigs/gateway-api/pull/5151), [@youngnick](https://github.com/youngnick), [#5208](https://github.com/kubernetes-sigs/gateway-api/pull/5208), [@youngnick](https://github.com/youngnick))
*   **Implementations & Conformance Reports:**
    *   Added or updated conformance reports for Agentgateway, Airlock Microgateway, AWS Load Balancer Controller, Calico, Cilium, Cloudflare Tunnel Gateway Controller, GKE Gateway, Gravitee, Higress, Istio, Kgateway, Kong Operator, Linkerd, NGINX Gateway Fabric, Traefik Proxy and WSO2 Gateway.
    *   Envoy Gateway moved to Conformant. ([#5186](https://github.com/kubernetes-sigs/gateway-api/pull/5186), [@zirain](https://github.com/zirain))
    *   HAProxy Ingress was renamed to N42 Gateway. ([#5268](https://github.com/kubernetes-sigs/gateway-api/pull/5268), [@jcmoraisjr](https://github.com/jcmoraisjr))

### Bug or Regression

*   Fixed the generator so that inline references are supported on experimental validation, and fixed generator tag recognition for experimental markers. ([#5288](https://github.com/kubernetes-sigs/gateway-api/pull/5288), [#5303](https://github.com/kubernetes-sigs/gateway-api/pull/5303), [@rikatz](https://github.com/rikatz))
*   Fixed the backend port name CEL expression and added a unit test. ([#5193](https://github.com/kubernetes-sigs/gateway-api/pull/5193), [@snorwin](https://github.com/snorwin))
*   Fixed an always-true scheme check in conformance redirect port validation. ([#5201](https://github.com/kubernetes-sigs/gateway-api/pull/5201), [@immanuwell](https://github.com/immanuwell))
*   Added CEL validation for `LabelKey` in `XBackend`'s `endpointSelector.matchLabels`. ([#5397](https://github.com/kubernetes-sigs/gateway-api/pull/5397), [@snorwin](https://github.com/snorwin))

### Test & Conformance

*   **New Conformance Tests:**
    *   Added a conformance test for `GRPCRouteFilterRequestHeaderModifier` (new `GRPCRouteRequestHeaderModifier` feature). ([#4060](https://github.com/kubernetes-sigs/gateway-api/pull/4060), [@salonichf5](https://github.com/salonichf5))
    *   Added a `BackendTLSPolicy` conformance test for GRPCRoute. ([#4882](https://github.com/kubernetes-sigs/gateway-api/pull/4882), [@Thealisyed](https://github.com/Thealisyed))
    *   Added a `BackendTLSPolicy` with TLSRoute Terminate conformance test. ([#4875](https://github.com/kubernetes-sigs/gateway-api/pull/4875), [@davidesalerno](https://github.com/davidesalerno))
    *   Added a Gateway maximum name length conformance test. ([#5035](https://github.com/kubernetes-sigs/gateway-api/pull/5035), [@arjunexplorer](https://github.com/arjunexplorer))
    *   Added an HTTPRoute rule precedence conformance test. ([#5128](https://github.com/kubernetes-sigs/gateway-api/pull/5128), [@thorn3r](https://github.com/thorn3r))
    *   Added a conformance test covering shared and dedicated routes across multiple Gateways for GRPCRoute. ([#5281](https://github.com/kubernetes-sigs/gateway-api/pull/5281), [@snorwin](https://github.com/snorwin))
    *   Added conformance tests validating that Gateway resolves HTTPRoute precedence using original route hostname specificity rather than the calculated listener/route hostname intersection. ([#5124](https://github.com/kubernetes-sigs/gateway-api/pull/5124), [@rostislavbobo](https://github.com/rostislavbobo))
    *   Added conformance tests validating that Gateway resolves GRPCRoute precedence using original route hostname specificity rather than the calculated listener/route hostname intersection. ([#5346](https://github.com/kubernetes-sigs/gateway-api/pull/5346), [@rostislavbobo](https://github.com/rostislavbobo))
    *   Added conformance tests validating that Gateway resolves TLSRoute precedence using original route hostname specificity rather than the calculated listener/route hostname intersection. ([#5361](https://github.com/kubernetes-sigs/gateway-api/pull/5361), [@rostislavbobo](https://github.com/rostislavbobo))
    *   Extended the HTTPRoute same-hostname intersection conformance test to cover path prefix and header matching across multiple attached Routes. ([#5410](https://github.com/kubernetes-sigs/gateway-api/pull/5410), [@rostislavbobo](https://github.com/rostislavbobo))
    *   Added conformance tests for `URLRewrite` filters at HTTPBackendRef level (`HTTPRouteBackendURLRewrite`). ([#4823](https://github.com/kubernetes-sigs/gateway-api/pull/4823), [@Srujan-rai](https://github.com/Srujan-rai))
    *   Added unit tests for the echo response parser. ([#4635](https://github.com/kubernetes-sigs/gateway-api/pull/4635), [@archy-rock3t-cloud](https://github.com/archy-rock3t-cloud))
*   **Test Machinery & Framework Updates:**
    *   The conformance suite now supports an injectable WebSocket dialer (`ConformanceOptions.WebSocketDialer`). It defaults to the previous `websocket.Dial` behavior when unset. ([#4936](https://github.com/kubernetes-sigs/gateway-api/pull/4936), [@lexfrei](https://github.com/lexfrei))
    *   The conformance gRPC `DefaultClient` is now safe for concurrent `SendRPC` and reusable after `Close`. ([#4946](https://github.com/kubernetes-sigs/gateway-api/pull/4946), [@lexfrei](https://github.com/lexfrei))
    *   Base-resource cleanup now waits for deletion to complete, so the suite can be re-run in a single process (`go test -count>1`). ([#4948](https://github.com/kubernetes-sigs/gateway-api/pull/4948), [@lexfrei](https://github.com/lexfrei))
    *   `RouteMustHaveParents` now runs the `observedGeneration` check against the status it just read. Implementations whose status lags the Route generation may now fail where they previously passed. ([#5206](https://github.com/kubernetes-sigs/gateway-api/pull/5206), [@lexfrei](https://github.com/lexfrei))
    *   Report an error when a conformance manifest is missing from every configured filesystem. ([#5216](https://github.com/kubernetes-sigs/gateway-api/pull/5216), [@immanuwell](https://github.com/immanuwell))
    *   Conformance report `Implementation.URL` is now validated as a well-formed http(s) URL. ([#5209](https://github.com/kubernetes-sigs/gateway-api/pull/5209), [@yashrajshuklaaa](https://github.com/yashrajshuklaaa))
    *   The conformance echo server images moved to a dedicated repository (`kubernetes-sigs/gateway-api-conformance-images`). ([#5090](https://github.com/kubernetes-sigs/gateway-api/pull/5090), [@snorwin](https://github.com/snorwin))
    *   Use the timeout config more consistently. ([#5150](https://github.com/kubernetes-sigs/gateway-api/pull/5150), [@howardjohn](https://github.com/howardjohn))
    *   Preserve `=` in conformance key-value flags. ([#5034](https://github.com/kubernetes-sigs/gateway-api/pull/5034), [@immanuwell](https://github.com/immanuwell))
*   **Updates & Fixes to Existing Tests:**
    *   Expect `RefNotPermitted` for a cross-namespace `certificateRef` to a nonexistent secret. ([#5306](https://github.com/kubernetes-sigs/gateway-api/pull/5306), [@PetrMc](https://github.com/PetrMc))
    *   Wait for mesh weighted routes to be programmed. ([#5214](https://github.com/kubernetes-sigs/gateway-api/pull/5214), [@Automaat](https://github.com/Automaat))
    *   Retry the failure-path assertion in the client certificate validation test. ([#5097](https://github.com/kubernetes-sigs/gateway-api/pull/5097), [@yashrajshuklaaa](https://github.com/yashrajshuklaaa))
    *   Added `containerPort`s to the echo pod in the mesh conformance manifest. ([#5055](https://github.com/kubernetes-sigs/gateway-api/pull/5055), [@AnirbanNandi](https://github.com/AnirbanNandi))
    *   Foreign status entries on HTTPRoutes, BackendTLSPolicy and Gateway are now preserved by conformance tests. ([#5206](https://github.com/kubernetes-sigs/gateway-api/pull/5206), [@lexfrei](https://github.com/lexfrei))
    *   Removed the HTTPRoute retry tests that required unsafe retries and added a retry-with-backend-timeout case. ([#5339](https://github.com/kubernetes-sigs/gateway-api/pull/5339), [@snorwin](https://github.com/snorwin))
    *   Fixed a nil `Group` pointer dereference panic in `gatewayListenersMatch` and `listenerSetListenersMatch` when the actual `SupportedKinds` list is empty. ([#5411](https://github.com/kubernetes-sigs/gateway-api/pull/5411), [@Ujjwaljain16](https://github.com/Ujjwaljain16))
    *   Fixed `parentRefToString` in the conformance helpers printing a pointer address instead of the namespace name. ([#5399](https://github.com/kubernetes-sigs/gateway-api/pull/5399), [@Ujjwaljain16](https://github.com/Ujjwaljain16))
    *   Replaced `coredns` with `echo-basic` in the UDPRoute conformance tests and base manifests. ([#5408](https://github.com/kubernetes-sigs/gateway-api/pull/5408), [@linolayani](https://github.com/linolayani))
    *   Updated `TCPRoute` conformance test manifests and helpers from `v1alpha2` to `v1`. ([#5365](https://github.com/kubernetes-sigs/gateway-api/pull/5365), [@davidjumani](https://github.com/davidjumani))
    *   Removed remaining references to removed alpha APIs from conformance and CEL/CRD/VAP tests. ([#5368](https://github.com/kubernetes-sigs/gateway-api/pull/5368), [@rikatz](https://github.com/rikatz))

### Other (Cleanup or Flake)

*   Mark `HTTPRouteBackendURLRewrite` tests as provisional. ([#5270](https://github.com/kubernetes-sigs/gateway-api/pull/5270), [@snorwin](https://github.com/snorwin))
*   Removed the provisional flag from conformance tests that are now stable. ([#5254](https://github.com/kubernetes-sigs/gateway-api/pull/5254), [@rikatz](https://github.com/rikatz))
*   Added a `make lint` target. ([#5198](https://github.com/kubernetes-sigs/gateway-api/pull/5198), [@youngnick](https://github.com/youngnick))
*   Added a new `implist` tool. ([#5191](https://github.com/kubernetes-sigs/gateway-api/pull/5191), [@youngnick](https://github.com/youngnick))
*   Fixed the package declared as `main` so that it can be imported as `utils`. ([#5275](https://github.com/kubernetes-sigs/gateway-api/pull/5275), [@yashrajshuklaaa](https://github.com/yashrajshuklaaa))
*   Bumped the Go toolchain to 1.26.8 to fix stdlib CVEs. ([#5280](https://github.com/kubernetes-sigs/gateway-api/pull/5280), [@yashrajshuklaaa](https://github.com/yashrajshuklaaa))
*   Marked generated OpenAPI files as generated in PRs. ([#5261](https://github.com/kubernetes-sigs/gateway-api/pull/5261), [@youngnick](https://github.com/youngnick))

## Full Changelog

**Full Changelog**: https://github.com/kubernetes-sigs/gateway-api/compare/v1.6.3...v1.7.0

***

## Dependencies

Only changes to modules directly required by the root, `conformance`, `tests` and `tools` modules are listed below.

### Added
*   github.com/spf13/cobra: v1.10.2
*   sigs.k8s.io/gateway-api-conformance-images: v0.2.0

### Changed
*   github.com/stretchr/testify: v1.11.1 → v1.12.1
*   golang.org/x/mod: v0.36.0 → v0.42.0
*   golang.org/x/net: v0.55.0 → v0.61.0
*   golang.org/x/sync: v0.20.0 → v0.24.0
*   golang.org/x/tools: v0.45.0 → v0.52.0
*   google.golang.org/grpc: v1.81.1 → v1.84.0
*   k8s.io/api: v0.36.1 → v0.37.1
*   k8s.io/apiextensions-apiserver: v0.36.1 → v0.37.1
*   k8s.io/apimachinery: v0.36.1 → v0.37.1
*   k8s.io/client-go: v0.36.1 → v0.37.1
*   k8s.io/code-generator: v0.36.1 → v0.37.1
*   k8s.io/kube-openapi: 927ab1f → d427ff9
*   k8s.io/utils: 28399d8 → be93311
*   sigs.k8s.io/controller-runtime: v0.24.1 → v0.25.2
*   sigs.k8s.io/controller-tools: v0.21.0 → v0.22.0
*   sigs.k8s.io/structured-merge-diff/v6: v6.4.0 → v6.4.2

### Removed
*   github.com/miekg/dns: v1.1.72

