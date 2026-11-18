---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/api/v1alpha1/componentrelease_types.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/api/v1alpha1/componentrelease_types.go lines 11,83 -->

```
// ComponentReleaseSpec defines the desired state of ComponentRelease.
type ComponentReleaseSpec struct {
	// Owner identifies the component and project this ComponentRelease belongs to
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.owner is immutable"
	Owner ComponentReleaseOwner `json:"owner"`

	// ComponentType is a frozen snapshot of the ComponentType resource at the time of component release.
	// It records the kind and name of the original resource alongside its full spec, enabling
	// the rendering pipeline to distinguish ComponentType from ClusterComponentType.
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.componentType is immutable"
	ComponentType ComponentReleaseComponentType `json:"componentType"`

	// Traits holds frozen trait specifications at the time of ComponentRelease, ensuring immutability.
	// Each entry carries its kind (Trait or ClusterTrait), name, and spec, preserving the original
	// resource identity so that a Trait and ClusterTrait with the same name can coexist.
	// MaxItems bounds this unbounded array so the CEL cost estimate of the embedded TraitSpec
	// XValidation rules (evaluated per trait item) stays within the apiserver's cost budget.
	// +optional
	// +kubebuilder:validation:MaxItems=100
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.traits is immutable"
	Traits []ComponentReleaseTrait `json:"traits,omitempty"`

	// ComponentProfile contains the immutable snapshot of parameter values and trait configs
	// specified for this component at release time
	// +optional
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.componentProfile is immutable"
	ComponentProfile *ComponentProfile `json:"componentProfile,omitempty"`

	// Workload is a full embedded copy of the Workload
	// This preserves the workload spec with the built image
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="spec.workload is immutable"
	Workload WorkloadTemplateSpec `json:"workload"`
}

// ComponentReleaseComponentType is the frozen snapshot of a ComponentType or ClusterComponentType
// resource stored on a ComponentRelease. It preserves the Kind and Name of the original resource
// alongside its full spec so that consumers can distinguish namespace-scoped ComponentTypes from
// cluster-scoped ClusterComponentTypes.
type ComponentReleaseComponentType struct {
	// Kind identifies whether this is a namespace-scoped ComponentType or a cluster-scoped ClusterComponentType.
	// +kubebuilder:validation:Required
	Kind ComponentTypeRefKind `json:"kind"`

	// Name is the component type reference in format: {workloadType}/{componentTypeName}
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:MinLength=1
	Name string `json:"name"`

	// Spec is the frozen specification of the component type at the time of this ComponentRelease.
	// +kubebuilder:validation:Required
	Spec ComponentTypeSpec `json:"spec"`
}

// ComponentReleaseTrait is an entry in the frozen traits snapshot stored on a ComponentRelease.
// It preserves both the Kind and Name of the original trait resource so that a namespace-scoped
// Trait and a cluster-scoped ClusterTrait with the same name can coexist.
type ComponentReleaseTrait struct {
	// Kind identifies whether this is a namespace-scoped Trait or a cluster-scoped ClusterTrait.
	// +kubebuilder:validation:Required
	Kind TraitRefKind `json:"kind"`

	// Name is the name of the Trait or ClusterTrait resource.
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:MinLength=1
	Name string `json:"name"`

	// Spec is the frozen specification of the trait at the time of this ComponentRelease.
	// +kubebuilder:validation:Required
	Spec TraitSpec `json:"spec"`
}
```
