---
type: source
resource: https://openchoreo.dev/docs/platform-engineer-guide/api-gateway/topology/
title: "OpenChoreo — runtime model, gateway topology, and the code that implements cell networking"
source_kind: webpage
tags: [openchoreo, cell-based-architecture, kgateway, gateway-api, network-policy, cilium]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api raw, 2026-11-13: openchoreo/openchoreo.github.io HEAD docs/concepts/runtime-model.md + docs/platform-engineer-guide/api-gateway/topology.md; openchoreo/openchoreo main (latest release v1.3.3, 2026-10-29) internal/networkpolicy/networkpolicy.go (full), install/helm/openchoreo-data-plane/templates/gateway/gateway.yaml, test/e2e/k3d/internal-gateway.yaml, api/v1alpha1/workload_types.go lines 98-115 (EndpointVisibility enum only), samples/getting-started/cluster-project-types/default.yaml. Each verbatim under its own heading."
---


<!-- ===== openchoreo.github.io: ocd-runtime-model.md ===== -->

---
title: Runtime Model
description: Runtime execution and deployment model
---

# Runtime Model

The runtime model describes how OpenChoreo's abstractions transform into running systems. When developers declare
projects and components, the platform orchestrates a sophisticated runtime environment that provides isolation,
security, and observability. Understanding this transformation from declaration to execution helps teams design better
applications and troubleshoot issues effectively.

## Cell Architecture

At runtime, each **Project** transforms into a **Cell** - a secure, isolated runtime boundary that encapsulates all
components of an application domain. This transformation represents a fundamental principle of OpenChoreo:
organizational boundaries in code become physical boundaries in infrastructure.

Cells provide complete isolation between different application domains. Each cell operates as an independent unit with
its own namespace, network policies, and security boundaries. Components within a cell can communicate freely using
cluster-local networking, but all communication across cell boundaries must flow through well-defined gateways. This
architecture ensures that failures, security breaches, or performance issues in one cell cannot directly impact others.

The cell's namespace and its baseline resources have an explicit owner: the **ProjectReleaseBinding** for that project
and environment. The binding renders the project's ProjectType (which must declare the namespace itself as a template
entry), creates the namespace on the data plane, and seeds it with the shared infrastructure the type defines, such as
default-deny network policies and resource quotas. Component and resource deployments into the environment wait for
this namespace to exist, so the cell's boundary is established before anything runs inside it, and its lifecycle is
tied to the project and environment rather than to whichever component deployed first.

The cell model aligns with microservices best practices and Domain-Driven Design principles. By mapping bounded contexts
to isolated runtime units, OpenChoreo ensures that architectural boundaries are enforced by infrastructure. This
alignment reduces the cognitive load on developers - the same mental model used for designing applications applies to
their runtime behavior.

## Traffic Flow Patterns

OpenChoreo implements a structured approach to network traffic through directional gateways, each serving a specific
purpose in the overall communication architecture. These patterns provide clarity about how data flows through the
system while enabling sophisticated security and routing policies.

### Northbound Ingress

Northbound ingress handles traffic entering cells from the public internet. This gateway serves as the entry point for
external users, customers, and third-party integrations accessing public APIs and web applications. The platform
automatically configures load balancing and TLS termination at this boundary.

The northbound gateway translates friendly DNS names into internal service endpoints, handles HTTP routing based on
hostnames and paths, and enforces public-facing API policies. This abstraction means developers can focus on application
logic while the platform manages the complexities of internet-facing services.

### Southbound Egress

Southbound egress manages traffic leaving cells to reach external services on the internet. This gateway provides
controlled access to third-party APIs, cloud services, and external databases. By channeling all outbound traffic
through a managed gateway, the platform can enforce security policies, manage credentials, and provide observability for
external dependencies.

The southbound gateway enables capabilities like egress filtering to prevent data exfiltration, credential injection for
authenticated external services, and circuit breaking for unreliable external dependencies. This controlled approach to
external communication reduces security risks while improving reliability.

### Westbound Ingress

Westbound ingress handles traffic from other parts of the organization entering the cell. This gateway manages internal
API consumption, service-to-service communication across projects, and administrative access. Unlike public northbound
traffic, westbound traffic comes from trusted sources within the organization but still requires authentication and
authorization.

The westbound gateway enables internal service discovery, allowing components in other cells to locate and communicate
with services using logical names. It enforces organization-wide policies while allowing more permissive communication
than public interfaces. This balance enables productive development while maintaining security boundaries.

### Eastbound Egress

Eastbound egress manages traffic leaving the cell to reach other cells or internal services within the organization.
This gateway handles inter-project dependencies, shared service consumption, and platform service integration. By
managing internal outbound traffic, the platform can track dependencies, enforce quotas, and provide circuit breaking
between internal services.

The eastbound gateway makes internal service dependencies explicit and observable. Teams can understand which other
projects they depend on, platform engineers can track usage patterns across the organization, and the system can prevent
cascading failures through circuit breaking and retry policies.

## Network Security

OpenChoreo manages network security through the cell architecture and gateway pattern. Communication within a cell is
allowed between components of the same project, while all cross-cell communication must flow through the defined
gateways. This provides security boundaries between different application domains.

The platform uses Cilium for network policy enforcement and kgateway for ingress traffic management. Developers
declare their components' endpoints and dependencies in the workload specification, and the platform handles the
underlying network configuration.

## Workload Execution

When components deploy to a runtime environment, OpenChoreo orchestrates a complex series of transformations. The
abstract component definition combines with workload specifications, environment configurations, and platform policies
to produce concrete Kubernetes resources.

The platform manages the complete lifecycle of these resources. It creates deployments with appropriate resource limits
and scaling parameters, configures services for network access and load balancing, injects configuration and secrets
from secure stores, and establishes health checks and readiness probes. This orchestration happens transparently -
developers see their components running while the platform manages the underlying complexity.

Workload execution is environment-aware. The same component might run with different resource allocations, replica
counts, or configuration values in different environments. The platform manages these variations through the binding
system, where environment-specific bindings override default values from ComponentTypes, Traits, and workload specifications.

Resources follow the same render-and-apply path. Each ResourceReleaseBinding renders its ResourceType template with
the combined Resource parameters and environment overrides, produces a RenderedRelease, and applies the resulting
manifests to the data plane. The provisioned outputs are resolved back to the binding so consuming components can read
them at pod-start. The render gate on the consuming Component waits for its declared Resource dependencies to be
Ready before producing its own RenderedRelease, so a component is not deployed until the infrastructure it depends on
is healthy.

## Service Discovery and Load Balancing

Service discovery uses standard Kubernetes DNS, allowing services to communicate using service names. Within a cell,
components can discover each other using simple service names. Across cells, services require routing through the
appropriate gateways.

## Observability

The runtime model includes centralized logs, metrics, and traces collected through the Observability Plane. Logs from all containers flow through the platform's collection pipeline configured in the Observability Plane, enriched with metadata about the source component, project, and environment. This enrichment enables queries across the entire platform while maintaining clear attribution of log entries to their sources.

The Observer API provides access to these logs, metrics, and traces, allowing developers to search and analyze application behavior across environments. This centralized observability approach ensures that debugging information is always available without requiring additional configuration from developers.

The platform also provides a centralized alerting and RCA (Root Cause Analysis) system through the Observability Plane. Developers can define alert rules in their components' traits, and the platform will automatically create alert rules in the Observability Plane. When an alert fires, incident creation and AI RCA can be triggered if they are enabled for that rule.

<!-- ===== openchoreo.github.io: ocd-topology.md ===== -->

---
title: Gateway Topology
description: Understand how OpenChoreo provisions and manages API Gateway resources using the Kubernetes Gateway API.
sidebar_position: 2
---

# API Gateway Topology

OpenChoreo has a well-architected API Gateway topology designed to cater to a wide range of API Gateway use cases. The topology is built on top of three main principles:

1. **Traffic Direction** — Whether traffic flows into the cluster (Ingress) or out of it (Egress)
2. **Networking Configuration** — Whether the gateway is exposed externally to the internet or internally within the cluster network / VPC
3. **Granularity** — Whether the gateway is shared at the DataPlane level or dedicated to a specific Environment

These three dimensions can be combined to describe any gateway in an OpenChoreo deployment.

## Default Gateway

By default, OpenChoreo installs one gateway at the DataPlane level:

| Gateway                  | Traffic Direction | Networking | Granularity |
| ------------------------ | ----------------- | ---------- | ----------- |
| Ingress External Gateway | Ingress           | External   | DataPlane   |

With this default configuration, APIs and routes deployed across all environments are hosted as unique virtual hosts on the shared DataPlane level gateway. This keeps infrastructure costs low and is well suited for basic use cases where environments do not have strict isolation requirements.

## Internal Gateway

By default, the DataPlane gateway is internet-facing (external). For traffic that should not be exposed to the public internet — such as service-to-service communication or traffic restricted to a private VPC subnet — you can add an **internal gateway**.

An internal gateway can be configured in two ways depending on your environment:

- **`ClusterIP`** — accessible only within the cluster, suitable for pure in-cluster service-to-service traffic
- **`LoadBalancer`** — accessible within the VPC/private network but not the public internet, suitable when services span multiple nodes or clusters within a private network (using cloud provider annotations such as `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`)

```
External Gateway (LoadBalancer)     Internal Gateway (ClusterIP or internal LB)
───────────────────────────────     ──────────────────────────────────────────
  Accessible from the internet        Not accessible from the public internet
  ├── dev virtual host                ├── dev virtual host
  ├── staging virtual host            ├── staging virtual host
  └── production virtual host         └── production virtual host
```

:::note
The configuration steps below are based on the default **kgateway** API gateway module. If you are using a different API gateway module, refer to that module's documentation instead. Available gateway modules are listed in the [modules](/modules) page.
:::

### Configuring an Internal Gateway

**Step 1: Create GatewayParameters**

Create a `GatewayParameters` resource to configure the underlying service type. The example below uses `ClusterIP` for in-cluster-only access:

```yaml
apiVersion: gateway.kgateway.dev/v1alpha1
kind: GatewayParameters
metadata:
  name: internal-gateway-params
  namespace: openchoreo-data-plane
spec:
  kube:
    service:
      type: ClusterIP
      extraLabels:
        gateway: internal
```

To use a VPC-internal LoadBalancer instead, set `type: LoadBalancer` and add the appropriate cloud provider annotation. For example, on AWS:

```yaml
spec:
  kube:
    service:
      type: LoadBalancer
      extraAnnotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
      extraLabels:
        gateway: internal
```

**Step 2: Create the Internal Gateway**

Reference the `GatewayParameters` via the `infrastructure.parametersRef` field:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-internal
  namespace: openchoreo-data-plane
  labels:
    app.kubernetes.io/component: gateway
    app.kubernetes.io/part-of: openchoreo
spec:
  gatewayClassName: kgateway
  infrastructure:
    labels:
      openchoreo.dev/system-component: gateway
    parametersRef:
      name: internal-gateway-params
      group: gateway.kgateway.dev
      kind: GatewayParameters
  listeners:
    - name: http
      port: 9080
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
```

**Step 3: Register on the DataPlane**

Register the internal gateway on the `DataPlane` resource so OpenChoreo routes internal traffic through it:

```bash
kubectl patch dataplane default -n default --type merge -p '{
  "spec": {
    "gateway": {
      "ingress": {
        "internal": {
          "name": "gateway-internal",
          "namespace": "openchoreo-data-plane",
          "http": {
            "host": "gateway-internal.openchoreo-data-plane",
            "listenerName": "http",
            "port": 9080
          }
        }
      }
    }
  }
}'
```

Alternatively, you can update this configuration from the Backstage portal. Navigate to **Catalog** > **Dataplane**, select the relevant Dataplane, go to the **Definition** tab, and update the YAML definition.

<img
src={require("./dataplane.png").default}
alt="Backstage Dataplane Definition tab"
/>

For a `ClusterIP` gateway, set `host` to the in-cluster DNS name of the gateway service: `<service-name>.<namespace>`.

For an internal `LoadBalancer` gateway, the host depends on your DNS setup. Your cloud provider will assign a private hostname or IP to the load balancer (for example, an internal ELB DNS name on AWS). You can use that hostname directly, or create a DNS record in your private hosted zone pointing to it. If you use [external-dns](https://github.com/kubernetes-sigs/external-dns), it can manage these records automatically when configured with the appropriate annotation filters for internal services.

## Environment Gateway

OpenChoreo supports environment-level gateways for advanced use cases where a dedicated gateway is required for a specific environment — such as a production environment that demands traffic isolation, independent scaling, or separate TLS termination.

```
DataPlane Level Gateway          Environment Level Gateway
───────────────────────          ─────────────────────────
  ├── development traffic                  └── production traffic
  └── staging traffic
```

This allows you to start with the cost-efficient default topology and progressively introduce dedicated gateways for environments that require stricter isolation or higher availability guarantees.

### Configuring an Environment Gateway

**Step 1: Create the Gateway**

Create a new `Gateway` resource in the `openchoreo-data-plane` namespace:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-production
  namespace: openchoreo-data-plane
  labels:
    app.kubernetes.io/component: gateway
    app.kubernetes.io/part-of: openchoreo
spec:
  gatewayClassName: kgateway
  infrastructure:
    labels:
      openchoreo.dev/system-component: gateway
  listeners:
    - name: http
      port: 19081
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
```

:::tip k3d users
If you are running k3d locally, add a port mapping to the load balancer node before creating the gateway:

```bash
k3d node edit k3d-openchoreo-serverlb --port-add 19081:19081/tcp
```

:::

**Step 2: Register on the Environment**

Patch the target `Environment` CR to override the gateway for that environment:

```bash
kubectl patch environment production -n default --type merge -p '{
  "spec": {
    "gateway": {
      "ingress": {
        "external": {
          "name": "gateway-production",
          "namespace": "openchoreo-data-plane",
          "http": {
            "host": "openchoreoapis.localhost",
            "listenerName": "http",
            "port": 19081
          }
        }
      }
    }
  }
}'
```

Alternatively, you can update this configuration from the Backstage portal. Navigate to **Catalog** > **Environment**, select the relevant Environment, go to the **Definition** tab, and update the YAML definition.

<img
src={require("./environment.png").default}
alt="Backstage Environment Definition tab"
/>

OpenChoreo will then route all APIs and routes belonging to that environment through the dedicated gateway instead of the shared Dataplane level gateway.

<!-- ===== openchoreo/openchoreo: install/helm/openchoreo-data-plane/templates/gateway/gateway.yaml ===== -->
```yaml
{{- if .Values.gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-default
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "openchoreo-data-plane.componentLabels" (dict "context" . "component" "gateway") | nindent 4 }}
  {{- with .Values.gateway.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  gatewayClassName: {{ .Values.gateway.gatewayClassName | default "kgateway" }}
  {{- /*
  kgateway renders the proxy pods from this Gateway, so chart label helpers never
  reach them - platform identity has to travel via spec.infrastructure.labels.
  Platform identity labels win over values-supplied ones.
  */}}
  {{- $infra := .Values.gateway.infrastructure | default dict }}
  infrastructure:
    {{- with omit $infra "labels" }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    labels:
      {{- include "openchoreo-data-plane.gatewayInfrastructureLabels" . | nindent 6 }}
  listeners:
    - name: http
      protocol: HTTP
      port: {{ .Values.gateway.httpPort | default 80 }}
      allowedRoutes:
        namespaces:
          from: All
{{- if .Values.gateway.tls.enabled }}
    - name: https
      protocol: HTTPS
      port: {{ .Values.gateway.httpsPort | default 443 }}
      {{- if .Values.gateway.tls.hostname }}
      hostname: {{ .Values.gateway.tls.hostname | quote }}
      {{- end }}
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          {{- range .Values.gateway.tls.certificateRefs }}
          - kind: {{ .kind | default "Secret" }}
            name: {{ .name }}
            {{- with .namespace }}
            namespace: {{ . }}
            {{- end }}
          {{- end }}
{{- end }}
{{- if .Values.gateway.tlsPassthrough.enabled }}
    - name: tls-passthrough
      protocol: TLS
      port: {{ .Values.gateway.tlsPassthrough.port | default 8443 }}
      {{- if .Values.gateway.tlsPassthrough.hostname }}
      hostname: {{ .Values.gateway.tlsPassthrough.hostname | quote }}
      {{- end }}
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Passthrough
{{- end }}
{{- end }}
```

<!-- ===== openchoreo/openchoreo: test/e2e/k3d/internal-gateway.yaml ===== -->
```yaml
# Internal Gateway for e2e testing
# Provides an internal ingress gateway for internal-visibility endpoints.
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-internal
  namespace: openchoreo-data-plane
spec:
  gatewayClassName: kgateway
  infrastructure:
    labels:
      openchoreo.dev/system-component: gateway
  listeners:
    - name: http
      protocol: HTTP
      port: 18080
      allowedRoutes:
        namespaces:
          from: All
```

<!-- ===== openchoreo/openchoreo: samples/getting-started/cluster-project-types/default.yaml ===== -->
```yaml
apiVersion: openchoreo.dev/v1alpha1
kind: ClusterProjectType
metadata:
  name: default
  annotations:
    openchoreo.dev/display-name: Default Project Type
    openchoreo.dev/description: >-
      Minimal project type that provisions only the cell namespace per
      environment. Per-environment labels and annotations can be added
      to the namespace via ProjectReleaseBinding.spec.environmentConfigs
      (namespaceLabels, namespaceAnnotations). Use as the starting
      template when no additional shared infrastructure (NetworkPolicies,
      ResourceQuotas, baseline RBAC) is needed.
  labels:
    openchoreo.dev/name: default
spec:
  environmentConfigs:
    openAPIV3Schema:
      type: object
      properties:
        namespaceLabels:
          type: object
          additionalProperties:
            type: string
          default: {}
        namespaceAnnotations:
          type: object
          additionalProperties:
            type: string
          default: {}
  resources:
    - id: cell-namespace
      template:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: ${metadata.namespace}
          labels: ${oc_merge(metadata.labels, environmentConfigs.namespaceLabels)}
          annotations: ${environmentConfigs.namespaceAnnotations}
```

<!-- ===== openchoreo/openchoreo: api/v1alpha1/workload_types.go L98-115 ===== -->
```go
// EndpointVisibility defines the visibility scope for an endpoint.
// It determines which components can access the endpoint and how that access is enforced at runtime.
// +kubebuilder:validation:Enum=project;namespace;internal;external
type EndpointVisibility string

const (
	// EndpointVisibilityProject makes the endpoint accessible only within the same project and environment.
	EndpointVisibilityProject EndpointVisibility = "project"

	// EndpointVisibilityNamespace makes the endpoint accessible across all projects in the same namespace and environment.
	EndpointVisibilityNamespace EndpointVisibility = "namespace"

	// EndpointVisibilityInternal makes the endpoint accessible across all namespaces in the deployment (intranet).
	EndpointVisibilityInternal EndpointVisibility = "internal"

	// EndpointVisibilityExternal makes the endpoint accessible from outside the deployment, including public internet.
	EndpointVisibilityExternal EndpointVisibility = "external"
)
```

<!-- ===== openchoreo/openchoreo: internal/networkpolicy/networkpolicy.go ===== -->
```go
// Copyright 2025 The OpenChoreo Authors
// SPDX-License-Identifier: Apache-2.0

package networkpolicy

import (
	"fmt"
	"sort"
	"strconv"

	openchoreov1alpha1 "github.com/openchoreo/openchoreo/api/v1alpha1"
	dpkubernetes "github.com/openchoreo/openchoreo/internal/dataplane/kubernetes"
	"github.com/openchoreo/openchoreo/internal/labels"
)

// Provider selects which network policy API to use when generating component policies.
type Provider string

const (
	// ProviderKubernetes generates standard Kubernetes NetworkPolicy objects (default).
	ProviderKubernetes Provider = "kubernetes"
	// ProviderCilium generates CiliumNetworkPolicy objects with L7 HTTP rules for
	// HTTP-proxied endpoints, enabling Hubble flow metrics via Envoy.
	ProviderCilium Provider = "cilium"

	// ProviderAnnotation on a DataPlane or ClusterDataPlane selects the
	// network policy provider for everything rendered onto it.
	ProviderAnnotation = "openchoreo.dev/networkpolicyprovider"

	// KubernetesNamespaceKey is the key for Kubernetes namespace
	// used in CiliumNetworkPolicy to allow rules based on namespace.
	KubernetesNamespaceKey = "k8s:io.kubernetes.pod.namespace"
)

// ComponentPolicyParams holds parameters for generating per-component NetworkPolicies
// with ingress rules based on endpoint visibility.
type ComponentPolicyParams struct {
	Namespace     string                                         // data plane namespace name
	CPNamespace   string                                         // control plane namespace name
	Environment   string                                         // environment name (e.g., "development")
	ComponentName string                                         // for naming the policy
	PodSelectors  map[string]string                              // platform pod selectors
	Endpoints     map[string]openchoreov1alpha1.WorkloadEndpoint // from workload spec
	Provider      Provider                                       // network policy provider
}

// EndpointPolicyParams holds parameters for the policy an Endpoint renders for
// one of its backends. It admits the Endpoint's visibility to the backend's
// pods on the backend's port, alongside the backend component's own policy:
// policies are additive, so the component's policy keeps its project scope and
// whatever its deprecated workload visibility requests.
type EndpointPolicyParams struct {
	Name         string                                  // policy name
	Namespace    string                                  // data plane namespace name
	CPNamespace  string                                  // control plane namespace name
	Environment  string                                  // environment name (e.g., "development")
	PodSelectors map[string]string                       // the backend's pod selectors
	Port         int32                                   // the backend's container port
	Protocol     openchoreov1alpha1.EndpointProtocol     // the backend's protocol
	Visibility   []openchoreov1alpha1.EndpointVisibility // the Endpoint's visibility
	Provider     Provider                                // network policy provider
}

// MakeComponentPolicies returns a policy for a component with ingress rules based on
// declared endpoint visibility. Egress is unrestricted.
// When Provider is ProviderCilium a CiliumNetworkPolicy is returned with L7 HTTP rules
// for HTTP-proxied endpoints; otherwise a standard Kubernetes NetworkPolicy is returned.
func MakeComponentPolicies(params ComponentPolicyParams) []map[string]any {
	if params.Provider == ProviderCilium {
		return makeCiliumComponentPolicies(params)
	}

	// Build ingress rules from endpoints
	ingressRules := makeIngressRules(params)

	// Generate a policy name, truncated to k8s limits
	policyName := fmt.Sprintf("openchoreo-%s", params.ComponentName)
	if len(policyName) > dpkubernetes.MaxResourceNameLength {
		policyName = dpkubernetes.GenerateK8sNameWithLengthLimit(
			dpkubernetes.MaxResourceNameLength,
			"openchoreo", params.ComponentName,
		)
	}

	spec := map[string]any{
		"podSelector": map[string]any{
			"matchLabels": toAnyMap(params.PodSelectors),
		},
		"policyTypes": []any{"Ingress"},
	}
	if len(ingressRules) > 0 {
		spec["ingress"] = ingressRules
	}

	policy := map[string]any{
		"apiVersion": "networking.k8s.io/v1",
		"kind":       "NetworkPolicy",
		"metadata": map[string]any{
			"name":      policyName,
			"namespace": params.Namespace,
		},
		"spec": spec,
	}

	return []map[string]any{policy}
}

// makeIngressRules builds ingress rules from component endpoints.
func makeIngressRules(params ComponentPolicyParams) []any {
	if len(params.Endpoints) == 0 {
		return nil
	}

	// Collect endpoints into a slice and sort by name to ensure deterministic
	// output. Without this, map iteration order causes the serialized
	// NetworkPolicy to differ between reconcile cycles, triggering unnecessary
	// updates.
	type epEntry struct {
		name       string
		port       map[string]any
		visibility []openchoreov1alpha1.EndpointVisibility
	}
	entries := make([]epEntry, 0, len(params.Endpoints))
	for name, ep := range params.Endpoints {
		entries = append(entries, epEntry{
			name: name,
			port: map[string]any{
				"protocol": l4Protocol(ep.EffectiveProtocol()),
				"port":     int64(ep.Port),
			},
			visibility: ep.Visibility, //nolint:staticcheck // deprecated field still supported for backward compatibility
		})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].name < entries[j].name
	})

	// Group ports by visibility level.
	// Every endpoint implicitly has project visibility (intra-namespace).
	// We collect additional visibility levels to build extra ingress rules.
	projectPorts := make([]any, 0, len(entries))
	var namespacePorts []any
	var broadAccessPorts []any

	for _, e := range entries {
		projectPorts = append(projectPorts, e.port)

		for _, vis := range e.visibility {
			switch vis {
			case openchoreov1alpha1.EndpointVisibilityNamespace:
				namespacePorts = append(namespacePorts, e.port)
			case openchoreov1alpha1.EndpointVisibilityInternal, openchoreov1alpha1.EndpointVisibilityExternal:
				broadAccessPorts = append(broadAccessPorts, e.port)
			}
		}
	}

	var ingressRules []any

	// Rule 1: intra-namespace (project visibility) — all declared ports
	if len(projectPorts) > 0 {
		ingressRules = append(ingressRules, map[string]any{
			"from": []any{
				map[string]any{
					"podSelector": map[string]any{},
				},
			},
			"ports": projectPorts,
		})
	}

	// Rule 2: cross-project, same CP namespace and same environment (namespace visibility)
	if len(namespacePorts) > 0 {
		ingressRules = append(ingressRules, namespaceIngressRule(params.CPNamespace, params.Environment, namespacePorts))
	}

	// Rule 3: system components (e.g., gateway) from any namespace (internal or external visibility)
	if len(broadAccessPorts) > 0 {
		ingressRules = append(ingressRules, systemComponentIngressRule(broadAccessPorts))
	}

	return ingressRules
}

// namespaceIngressRule admits pods of other projects in the same control plane
// namespace and environment (namespace visibility).
func namespaceIngressRule(cpNamespace, environment string, ports []any) map[string]any {
	return map[string]any{
		"from": []any{
			map[string]any{
				"namespaceSelector": map[string]any{
					"matchLabels": map[string]any{
						labels.LabelKeyNamespaceName:   cpNamespace,
						labels.LabelKeyEnvironmentName: environment,
					},
				},
			},
		},
		"ports": ports,
	}
}

// systemComponentIngressRule admits system components such as the gateways,
// from any namespace (internal or external visibility).
func systemComponentIngressRule(ports []any) map[string]any {
	return map[string]any{
		"from": []any{
			map[string]any{
				"namespaceSelector": map[string]any{},
				"podSelector": map[string]any{
					"matchExpressions": []any{
						map[string]any{
							"key":      labels.LabelKeySystemComponent,
							"operator": "Exists",
						},
					},
				},
			},
		},
		"ports": ports,
	}
}

// ciliumPortEntry holds per-endpoint data for Cilium CNP generation.
type ciliumPortEntry struct {
	port       string
	proto      string
	isL7       bool
	visibility []openchoreov1alpha1.EndpointVisibility
}

// makeCiliumComponentPolicies returns a CiliumNetworkPolicy for a component.
// HTTP-proxied endpoint types (HTTP, GraphQL, Websocket, gRPC) get L7 HTTP rules
// so Cilium redirects traffic through Envoy and Hubble emits flow metrics.
// Non-proxied types (TCP, UDP) get L4-only rules.
func makeCiliumComponentPolicies(params ComponentPolicyParams) []map[string]any {
	entries := make([]ciliumPortEntry, 0, len(params.Endpoints))
	for _, ep := range params.Endpoints {
		entries = append(entries, ciliumPortEntry{
			port:       strconv.Itoa(int(ep.Port)),
			proto:      l4Protocol(ep.EffectiveProtocol()),
			isL7:       isL7Proxied(ep.EffectiveProtocol()),
			visibility: ep.Visibility, //nolint:staticcheck // deprecated field still supported for backward compatibility
		})
	}
	// Sort by port for deterministic output.
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].port < entries[j].port
	})

	projectPorts := make([]ciliumPortEntry, 0, len(entries))
	var namespacePorts, broadPorts []ciliumPortEntry
	for _, e := range entries {
		projectPorts = append(projectPorts, e)
		for _, vis := range e.visibility {
			switch vis {
			case openchoreov1alpha1.EndpointVisibilityNamespace:
				namespacePorts = append(namespacePorts, e)
			case openchoreov1alpha1.EndpointVisibilityInternal, openchoreov1alpha1.EndpointVisibilityExternal:
				broadPorts = append(broadPorts, e)
			}
		}
	}

	ingressRules := make([]any, 0)

	// Rule 1: intra-namespace (project visibility) — all pods in the data-plane namespace
	if len(projectPorts) > 0 {
		ingressRules = append(ingressRules, map[string]any{
			"fromEndpoints": []any{
				map[string]any{},
			},
			"toPorts": ciliumToPorts(projectPorts),
		})
	}

	// Rule 2: cross-project, same CP namespace and environment (namespace visibility)
	if len(namespacePorts) > 0 {
		ingressRules = append(ingressRules, ciliumNamespaceIngressRule(params.CPNamespace, params.Environment, namespacePorts))
	}

	// Rule 3: system components (e.g., gateway) from any namespace (internal or external visibility)
	if len(broadPorts) > 0 {
		ingressRules = append(ingressRules, ciliumSystemComponentIngressRule(broadPorts))
	}

	// No endpoints: emit a single empty ingress rule. Cilium rejects a rule with
	// no ingress/egress sections, while an empty rule enables ingress default-deny
	// without allowing anything, matching the Kubernetes provider's deny-all.
	if len(ingressRules) == 0 {
		ingressRules = append(ingressRules, map[string]any{})
	}

	policyName := fmt.Sprintf("openchoreo-%s", params.ComponentName)
	if len(policyName) > dpkubernetes.MaxResourceNameLength {
		policyName = dpkubernetes.GenerateK8sNameWithLengthLimit(
			dpkubernetes.MaxResourceNameLength,
			"openchoreo", params.ComponentName,
		)
	}

	spec := map[string]any{
		"endpointSelector": map[string]any{
			"matchLabels": toAnyMap(params.PodSelectors),
		},
		"ingress": ingressRules,
	}

	return []map[string]any{{
		"apiVersion": "cilium.io/v2",
		"kind":       "CiliumNetworkPolicy",
		"metadata": map[string]any{
			"name":      policyName,
			"namespace": params.Namespace,
		},
		"spec": spec,
	}}
}

// ciliumNamespaceIngressRule is namespaceIngressRule for Cilium.
func ciliumNamespaceIngressRule(cpNamespace, environment string, entries []ciliumPortEntry) map[string]any {
	return map[string]any{
		"fromEndpoints": []any{
			map[string]any{
				"matchLabels": map[string]any{
					labels.LabelKeyNamespaceName:   cpNamespace,
					labels.LabelKeyEnvironmentName: environment,
				},
				"matchExpressions": []any{
					map[string]any{ // Explicitly allow from any namespace
						"key":      KubernetesNamespaceKey,
						"operator": "Exists",
					},
				},
			},
		},
		"toPorts": ciliumToPorts(entries),
	}
}

// ciliumSystemComponentIngressRule is systemComponentIngressRule for Cilium.
func ciliumSystemComponentIngressRule(entries []ciliumPortEntry) map[string]any {
	return map[string]any{
		"fromEndpoints": []any{
			map[string]any{"matchExpressions": []any{
				map[string]any{
					"key":      labels.LabelKeySystemComponent,
					"operator": "Exists",
				},
				map[string]any{ // Explicitly allow from any namespace
					"key":      KubernetesNamespaceKey,
					"operator": "Exists",
				},
			}},
		},
		"toPorts": ciliumToPorts(entries),
	}
}

// MakeEndpointPolicy returns the policy admitting an Endpoint's visibility to
// one backend's pods on the backend's port: namespace visibility admits the
// other projects of the namespace and environment, internal and external admit
// the gateways. It returns nil when the visibility admits nothing beyond the
// project scope the backend component's own policy already admits.
func MakeEndpointPolicy(params EndpointPolicyParams) map[string]any {
	var namespaceScope, broadScope bool
	for _, vis := range params.Visibility {
		switch vis {
		case openchoreov1alpha1.EndpointVisibilityNamespace:
			namespaceScope = true
		case openchoreov1alpha1.EndpointVisibilityInternal, openchoreov1alpha1.EndpointVisibilityExternal:
			broadScope = true
		}
	}
	if !namespaceScope && !broadScope {
		return nil
	}

	proto := l4Protocol(params.Protocol)

	if params.Provider == ProviderCilium {
		entries := []ciliumPortEntry{{port: strconv.Itoa(int(params.Port)), proto: proto, isL7: isL7Proxied(params.Protocol)}}
		var ingressRules []any
		if namespaceScope {
			ingressRules = append(ingressRules, ciliumNamespaceIngressRule(params.CPNamespace, params.Environment, entries))
		}
		if broadScope {
			ingressRules = append(ingressRules, ciliumSystemComponentIngressRule(entries))
		}
		return map[string]any{
			"apiVersion": "cilium.io/v2",
			"kind":       "CiliumNetworkPolicy",
			"metadata": map[string]any{
				"name":      params.Name,
				"namespace": params.Namespace,
			},
			"spec": map[string]any{
				"endpointSelector": map[string]any{
					"matchLabels": toAnyMap(params.PodSelectors),
				},
				"ingress": ingressRules,
			},
		}
	}

	ports := []any{map[string]any{"protocol": proto, "port": int64(params.Port)}}
	var ingressRules []any
	if namespaceScope {
		ingressRules = append(ingressRules, namespaceIngressRule(params.CPNamespace, params.Environment, ports))
	}
	if broadScope {
		ingressRules = append(ingressRules, systemComponentIngressRule(ports))
	}
	return map[string]any{
		"apiVersion": "networking.k8s.io/v1",
		"kind":       "NetworkPolicy",
		"metadata": map[string]any{
			"name":      params.Name,
			"namespace": params.Namespace,
		},
		"spec": map[string]any{
			"podSelector": map[string]any{
				"matchLabels": toAnyMap(params.PodSelectors),
			},
			"policyTypes": []any{"Ingress"},
			"ingress":     ingressRules,
		},
	}
}

// ProviderFromAnnotations returns the provider a data plane's
// "openchoreo.dev/networkpolicyprovider" annotation selects, defaulting to
// ProviderKubernetes.
func ProviderFromAnnotations(annotations map[string]string) Provider {
	if annotations[ProviderAnnotation] == string(ProviderCilium) {
		return ProviderCilium
	}
	return ProviderKubernetes
}

// ciliumToPorts builds the toPorts slice for a CNP ingress rule, grouping L7-proxied
// ports (with rules.http) separately from L4-only ports.
func ciliumToPorts(entries []ciliumPortEntry) []any {
	var l7Ports, l4Ports []any
	for _, e := range entries {
		p := map[string]any{"port": e.port, "protocol": e.proto}
		if e.isL7 {
			l7Ports = append(l7Ports, p)
		} else {
			l4Ports = append(l4Ports, p)
		}
	}
	var toPorts []any
	if len(l7Ports) > 0 {
		toPorts = append(toPorts, map[string]any{
			"ports": l7Ports,
			"rules": map[string]any{"http": []any{
				map[string]any{},
			}},
		})
	}
	if len(l4Ports) > 0 {
		toPorts = append(toPorts, map[string]any{"ports": l4Ports})
	}
	return toPorts
}

// l4Protocol returns the transport protocol a policy port uses for an
// endpoint protocol: UDP for UDP endpoints, TCP for everything else.
func l4Protocol(p openchoreov1alpha1.EndpointProtocol) string {
	if p == openchoreov1alpha1.EndpointProtocolUDP {
		return "UDP"
	}
	return "TCP"
}

// isL7Proxied reports whether the endpoint type is proxied through Envoy for L7 inspection.
func isL7Proxied(t openchoreov1alpha1.EndpointProtocol) bool {
	switch t {
	case openchoreov1alpha1.EndpointProtocolHTTP,
		openchoreov1alpha1.EndpointProtocolGraphQL,
		openchoreov1alpha1.EndpointProtocolWebsocket,
		openchoreov1alpha1.EndpointProtocolGRPC:
		return true
	}
	return false
}

// toAnyMap converts map[string]string to map[string]any for use in unstructured maps.
func toAnyMap(m map[string]string) map[string]any {
	result := make(map[string]any, len(m))
	for k, v := range m {
		result[k] = v
	}
	return result
}
```
