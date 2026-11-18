---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/api/v1alpha1/component_types.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/api/v1alpha1/component_types.go lines 40,54 -->

```
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.owner is immutable"
	Owner ComponentOwner `json:"owner"`

	// ComponentType specifies the component type reference with kind and name.
	// Name is in the format: {workloadType}/{componentTypeName}
	// Example: kind=ComponentType, name="deployment/web-app"
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.componentType cannot be changed after creation"
	ComponentType ComponentTypeRef `json:"componentType"`

	// AutoDeploy indicates whether the component should be deployed automatically when created
	// When not specified, defaults to false (zero value)
	// +optional
	AutoDeploy bool `json:"autoDeploy,omitempty"`

```
