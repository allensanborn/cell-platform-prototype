---
resource: https://github.com/kgateway-dev/kgateway/blob/74f2e098d85f1b3d6825b3a12bbacab82e606cb3/api/v1alpha1/kgateway/traffic_policy_types.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 kgateway-dev/kgateway@74f2e098d85f1b3d6825b3a12bbacab82e606cb3 (main 2026-11-13; latest release v2.5.2 tag 078f23da 2026-11-13)"
---


<!-- kgateway/api/v1alpha1/kgateway/traffic_policy_types.go lines 79,94 -->

	// RateLimit specifies the rate limiting configuration for the policy.
	// This controls the rate at which requests are allowed to be processed.
	// +optional
	RateLimit *RateLimit `json:"rateLimit,omitempty"`

	// Cors specifies the CORS configuration for the policy.
	// +optional
	Cors *CorsPolicy `json:"cors,omitempty"`

	// Csrf specifies the Cross-Site Request Forgery (CSRF) policy for this traffic policy.
	// +optional
	Csrf *CSRFPolicy `json:"csrf,omitempty"`

	// HeaderModifiers defines the policy to modify request and response headers.
	// +optional
	HeaderModifiers *shared.HeaderModifiers `json:"headerModifiers,omitempty"`

<!-- kgateway/api/v1alpha1/kgateway/traffic_policy_types.go lines 466,480 -->

// RateLimit defines a rate limiting policy.
type RateLimit struct {
	// Local defines a local rate limiting policy.
	// +optional
	Local *LocalRateLimitPolicy `json:"local,omitempty"`

	// Global defines a global rate limiting policy using an external service.
	// +optional
	Global *RateLimitPolicy `json:"global,omitempty"`
}

// LocalRateLimitPolicy configures local rate limiting using a token bucket.
// +kubebuilder:validation:XValidation:rule="!has(self.shareAcrossGateway) || !self.shareAcrossGateway || has(self.tokenBucket)",message="shareAcrossGateway requires tokenBucket to be set"
type LocalRateLimitPolicy struct {
	// TokenBucket configures the local rate limiter's token bucket.

<!-- kgateway/api/v1alpha1/kgateway/traffic_policy_types.go lines 558,570 -->

// RateLimitPolicy defines a global rate limiting policy using an external service.
type RateLimitPolicy struct {
	// Descriptors define the dimensions for rate limiting.
	// These values are passed to the rate limit service which applies configured limits based on them.
	// Each descriptor represents a single rate limit rule with one or more entries.
	// +required
	// +kubebuilder:validation:MinItems=1
	Descriptors []RateLimitDescriptor `json:"descriptors"`

	// ExtensionRef references a GatewayExtension that provides the global rate limit service.
	// +required
	ExtensionRef shared.NamespacedObjectReference `json:"extensionRef"`
}

<!-- kgateway/api/v1alpha1/kgateway/gateway_extensions_types.go lines 40,70 -->

}

// GatewayExtensionSpec defines the desired state of GatewayExtension.
// +kubebuilder:validation:ExactlyOneOf=extAuth;extProc;rateLimit;jwt;oauth2
// +kubebuilder:validation:XValidation:message="extAuth must be set when type is ExtAuth",rule="has(self.type) && self.type == 'ExtAuth' ? has(self.extAuth) : true"
// +kubebuilder:validation:XValidation:message="extProc must be set when type is ExtProc",rule="has(self.type) && self.type == 'ExtProc' ? has(self.extProc) : true"
// +kubebuilder:validation:XValidation:message="rateLimit must be set when type is RateLimit",rule="has(self.type) && self.type == 'RateLimit' ? has(self.rateLimit) : true"
// +kubebuilder:validation:XValidation:message="JWT must be set when type is JWT",rule="has(self.type) && self.type == 'JWT' ? has(self.jwt) : true"
// +kubebuilder:validation:XValidation:message="oauth2 must be set when type is OAuth2",rule="has(self.type) && self.type == 'OAuth2' ? has(self.oauth2) : true"
type GatewayExtensionSpec struct {
	// Deprecated: Setting this field has no effect.
	// Type indicates the type of the GatewayExtension to be used.
	// +kubebuilder:validation:Enum=ExtAuth;ExtProc;RateLimit;JWT;OAuth2
	// +optional
	Type *GatewayExtensionType `json:"type,omitempty"`

	// ExtAuth configuration for ExtAuth extension type.
	// +optional
	ExtAuth *ExtAuthProvider `json:"extAuth,omitempty"`

	// ExtProc configuration for ExtProc extension type.
	// +optional
	ExtProc *ExtProcProvider `json:"extProc,omitempty"`

	// RateLimit configuration for RateLimit extension type.
	// +optional
	RateLimit *RateLimitProvider `json:"rateLimit,omitempty"`

	// JWT configuration for JWT extension type.
	// +optional
	JWT *JWT `json:"jwt,omitempty"`
