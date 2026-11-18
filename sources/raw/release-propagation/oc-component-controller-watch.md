---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/internal/controller/component/controller_watch.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/internal/controller/component/controller_watch.go lines 95,205 -->

```
		})
}

// listComponentsForComponentType returns reconcile requests for all Components using this ComponentType
func (r *Reconciler) listComponentsForComponentType(ctx context.Context, obj client.Object) []reconcile.Request {
	ct := obj.(*openchoreov1alpha1.ComponentType)

	// Find all components using this ComponentType
	// Index key format: "ComponentType:{workloadType}/{ctName}"
	indexKey := string(openchoreov1alpha1.ComponentTypeRefKindComponentType) + ":" + fmt.Sprintf("%s/%s", ct.Spec.WorkloadType, ct.Name)

	var components openchoreov1alpha1.ComponentList
	if err := r.List(ctx, &components,
		client.InNamespace(ct.Namespace),
		client.MatchingFields{componentTypeIndex: indexKey}); err != nil {
		logger := ctrl.LoggerFrom(ctx)
		logger.Error(err, "Failed to list components for ComponentType", "componentType", ct.Name)
		return nil
	}

	requests := make([]reconcile.Request, len(components.Items))
	for i, comp := range components.Items {
		requests[i] = reconcile.Request{
			NamespacedName: types.NamespacedName{
				Name:      comp.Name,
				Namespace: comp.Namespace,
			},
		}
	}
	return requests
}

// listComponentsForClusterComponentType returns reconcile requests for all Components using this ClusterComponentType
func (r *Reconciler) listComponentsForClusterComponentType(ctx context.Context, obj client.Object) []reconcile.Request {
	cct := obj.(*openchoreov1alpha1.ClusterComponentType)

	// Find all components using this ClusterComponentType
	// Index key format: "ClusterComponentType:{workloadType}/{cctName}"
	indexKey := string(openchoreov1alpha1.ComponentTypeRefKindClusterComponentType) + ":" + fmt.Sprintf("%s/%s", cct.Spec.WorkloadType, cct.Name)

	var components openchoreov1alpha1.ComponentList
	if err := r.List(ctx, &components,
		client.MatchingFields{componentTypeIndex: indexKey}); err != nil {
		logger := ctrl.LoggerFrom(ctx)
		logger.Error(err, "Failed to list components for ClusterComponentType", "clusterComponentType", cct.Name)
		return nil
	}

	requests := make([]reconcile.Request, len(components.Items))
	for i, comp := range components.Items {
		requests[i] = reconcile.Request{
			NamespacedName: types.NamespacedName{
				Name:      comp.Name,
				Namespace: comp.Namespace,
			},
		}
	}
	return requests
}

// listComponentsUsingTrait returns reconcile requests for all Components using this Trait
func (r *Reconciler) listComponentsUsingTrait(ctx context.Context, obj client.Object) []reconcile.Request {
	trait := obj.(*openchoreov1alpha1.Trait)

	indexKey := string(openchoreov1alpha1.TraitRefKindTrait) + ":" + trait.Name
	var components openchoreov1alpha1.ComponentList
	if err := r.List(ctx, &components,
		client.MatchingFields{traitsIndex: indexKey}); err != nil {
		logger := ctrl.LoggerFrom(ctx)
		logger.Error(err, "Failed to list components for Trait", "trait", trait.Name)
		return nil
	}

	requests := make([]reconcile.Request, len(components.Items))
	for i, comp := range components.Items {
		requests[i] = reconcile.Request{
			NamespacedName: types.NamespacedName{
				Name:      comp.Name,
				Namespace: comp.Namespace,
			},
		}
	}
	return requests
}

// listComponentsUsingClusterTrait returns reconcile requests for all Components using this ClusterTrait
func (r *Reconciler) listComponentsUsingClusterTrait(ctx context.Context, obj client.Object) []reconcile.Request {
	clusterTrait := obj.(*openchoreov1alpha1.ClusterTrait)

	indexKey := string(openchoreov1alpha1.TraitRefKindClusterTrait) + ":" + clusterTrait.Name
	var components openchoreov1alpha1.ComponentList
	if err := r.List(ctx, &components,
		client.MatchingFields{traitsIndex: indexKey}); err != nil {
		logger := ctrl.LoggerFrom(ctx)
		logger.Error(err, "Failed to list components for ClusterTrait", "clusterTrait", clusterTrait.Name)
		return nil
	}

	requests := make([]reconcile.Request, len(components.Items))
	for i, comp := range components.Items {
		requests[i] = reconcile.Request{
			NamespacedName: types.NamespacedName{
				Name:      comp.Name,
				Namespace: comp.Namespace,
			},
		}
	}
	return requests
}

// listComponentsForWorkflow returns reconcile requests for all Components using this Workflow.
```
