---
resource: https://github.com/kgateway-dev/kgateway/blob/74f2e098d85f1b3d6825b3a12bbacab82e606cb3/api/v1alpha1/shared/shared_types.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 kgateway-dev/kgateway@74f2e098d85f1b3d6825b3a12bbacab82e606cb3; secretRef present at tag v2.5.2 (verified via gh api contents ?ref=v2.5.2); introduced f58d20800b 2026-05-11 (#13880, EP-2027)"
---


<!-- kgateway/api/v1alpha1/shared/shared_types.go lines 173,195 -->

// HeaderModifiers can be used to define the policy to modify request and response headers.
// +kubebuilder:validation:AtLeastOneOf=request;response
type HeaderModifiers struct {
	// Request modifies request headers.
	// +optional
	Request *HTTPHeaderFilter `json:"request,omitempty"`

	// Response modifies response headers.
	// +optional
	Response *HTTPHeaderFilter `json:"response,omitempty"`
}

// HTTPHeaderFilter defines a filter that modifies the headers of an HTTP request or response.
// Configuration to set or add multiple values for a header must use RFC 7230 header value
// formatting, separating each value with a comma.
// Multiple actions may name the same header. They are applied in the order add, set, remove, so
// a set overwrites any value contributed by add, and a remove drops the header altogether.
// Unlike the Gateway API HTTPHeaderFilter, each entry also supports sourcing the value from a
// Kubernetes Secret via secretRef.
// +kubebuilder:validation:AtLeastOneOf=set;add;remove
type HTTPHeaderFilter struct {
	// Set overwrites the request with the given header (name, value) before the action.
	//

<!-- kgateway/api/v1alpha1/shared/shared_types.go lines 255,300 -->

	Remove []string `json:"remove,omitempty"`
}

// HTTPHeader represents a single header name/value pair. Exactly one of value or secretRef must
// be set. When using secretRef, name and key interact as follows:
//   - Both present: name is the header name, key is the Secret data key.
//   - name absent, key present: the key is also used as the header name.
//   - name present, key absent: the name is also used as the Secret data key.
//   - Both absent: every entry in the Secret is injected as a header (data key -> header name).
//
// +kubebuilder:validation:ExactlyOneOf=value;secretRef
// +kubebuilder:validation:XValidation:rule="has(self.value) ? has(self.name) : true",message="name is required when using an inline value"
type HTTPHeader struct {
	// Name is the HTTP header field name. Name matching is case-insensitive.
	// (See https://tools.ietf.org/html/rfc7230#section-3.2.)
	// Required when value is set. When secretRef is used, if omitted the Secret data key is
	// used as the header name; if both name and key are omitted every Secret entry is injected
	// as a header.
	// +optional
	Name *gwv1.HTTPHeaderName `json:"name,omitempty"`

	// Value is an inline string value for the header. Mutually exclusive with secretRef.
	// Must consist of printable US-ASCII characters. (See https://tools.ietf.org/html/rfc7230#section-3.2.)
	// +optional
	// +kubebuilder:validation:MinLength=1
	// +kubebuilder:validation:MaxLength=4096
	// +kubebuilder:validation:Pattern=`^[!-~]+([\t ]?[!-~]+)*$`
	Value *string `json:"value,omitempty"`

	// SecretRef sources the header value from a key in a Kubernetes Secret.
	// Mutually exclusive with value.
	// +optional
	SecretRef *SecretRefWithKey `json:"secretRef,omitempty"`
}

// SecretRefWithKey identifies a Kubernetes Secret and optionally a specific key within it.
type SecretRefWithKey struct {
	// Name is the name of the Kubernetes Secret.
	// +required
	Name gwv1.ObjectName `json:"name"`

	// Key is the key within the Secret's data map to use as the header value. When omitted and
	// the parent HTTPHeader.name is set, that name is used as the key. When both key and name are
	// omitted, all entries in the Secret are injected as headers.
	// +optional
	// +kubebuilder:validation:MinLength=1

<!-- kgateway/api/v1alpha1/kgateway/backend_config_policy_types.go lines 275,298 -->

// Tunnel configures HTTP CONNECT tunneling through a forward proxy.
type Tunnel struct {
	// Proxy identifies the forward proxy that establishes the tunnel.
	// +required
	Proxy TunnelProxy `json:"proxy"`

	// Headers are sent only on CONNECT requests. Each requires a name and
	// exactly one of value or secretRef.
	// +optional
	// +listType=atomic
	// +kubebuilder:validation:MaxItems=16
	// +kubebuilder:validation:XValidation:rule="self.all(h, has(h.name))",message="tunnel headers require a name"
	// +kubebuilder:validation:XValidation:rule="self.all(h, !has(h.name) || h.name.lowerAscii() != 'host')",message="tunnel headers cannot set Host"
	Headers []shared.HTTPHeader `json:"headers,omitempty"`
}

// TunnelProxy identifies the forward proxy for a tunnel.
type TunnelProxy struct {
	// BackendRef references the proxy Service or Backend. CONNECT uses that
	// backend's HTTP protocol.
	// +required
	// +kubebuilder:validation:XValidation:rule="(self.group == '' && self.kind == 'Service') || (self.group == 'gateway.kgateway.dev' && self.kind == 'Backend')",message="proxy backendRef must reference a Service or a Backend"
	BackendRef gwv1.BackendObjectReference `json:"backendRef"`
}
