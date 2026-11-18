---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/api/v1alpha1/releasebinding_types.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/api/v1alpha1/releasebinding_types.go lines 157,198 -->

```
type ReleaseBindingSpec struct {
	// Owner identifies the component and project this ReleaseBinding belongs to
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.owner is immutable"
	Owner ReleaseBindingOwner `json:"owner"`

	// EnvironmentName is the name of the environment this binds the ComponentRelease to
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.environment is immutable"
	Environment string `json:"environment"`

	// ReleaseName is the name of the ComponentRelease to bind
	// When ComponentSpec.AutoDeploy is enabled, this field will be handled by the controller
	// +optional
	ReleaseName string `json:"releaseName,omitempty"`

	// ComponentTypeEnvironmentConfigs for ComponentType environmentConfigs parameters
	// These values override the defaults defined in the Component for this specific environment
	// +optional
	// +kubebuilder:pruning:PreserveUnknownFields
	ComponentTypeEnvironmentConfigs *runtime.RawExtension `json:"componentTypeEnvironmentConfigs,omitempty"`

	// TraitEnvironmentConfigs provides environment-specific overrides for trait configurations
	// Keyed by instanceName (which must be unique across all traits in the component)
	// Structure: map[instanceName]overrideValues
	// +optional
	TraitEnvironmentConfigs map[string]runtime.RawExtension `json:"traitEnvironmentConfigs,omitempty"`

	// WorkloadOverrides provides environment-specific overrides for the entire workload spec
	// These values override the workload specification for this specific environment
	// +optional
	// +kubebuilder:pruning:PreserveUnknownFields
	WorkloadOverrides *WorkloadOverrideTemplateSpec `json:"workloadOverrides,omitempty"`

	// State controls the state of the Release created by this binding.
	// Active: Resources are deployed normally
	// Undeploy: Resources are removed from the data plane
	// +kubebuilder:default=Active
	// +kubebuilder:validation:Enum=Active;Undeploy
	// +optional
	State ReleaseState `json:"state,omitempty"`
}
```
