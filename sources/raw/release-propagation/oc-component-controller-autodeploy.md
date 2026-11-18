---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/internal/controller/component/controller.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/internal/controller/component/controller.go lines 583,900 -->

```
// handleAutoDeploy handles automatic deployment when autoDeploy is enabled.
// It computes the hash of the current release spec and creates/updates ComponentRelease
// and ReleaseBinding if the hash has changed.
func (r *Reconciler) handleAutoDeploy(
	ctx context.Context,
	comp *openchoreov1alpha1.Component,
	ct *openchoreov1alpha1.ComponentType,
	workload *openchoreov1alpha1.Workload,
	traits map[string]openchoreov1alpha1.TraitSpec,
	clusterTraits map[string]openchoreov1alpha1.ClusterTraitSpec,
	firstEnv string,
) error {
	logger := log.FromContext(ctx)

	// ReleaseBinding name to create releaseBinding if not exits
	bindingName := fmt.Sprintf("%s-%s", comp.Name, firstEnv)

	crSpec, err := componentrelease.BuildSpec(componentrelease.BuildInput{
		Component: comp,
		ComponentType: openchoreov1alpha1.ComponentReleaseComponentType{
			Kind: comp.Spec.ComponentType.Kind,
			Name: comp.Spec.ComponentType.Name,
			Spec: ct.Spec,
		},
		Traits:        traits,
		ClusterTraits: clusterTraits,
		Workload:      &workload.Spec.WorkloadTemplateSpec,
	})
	if err != nil {
		return fmt.Errorf("failed to build ComponentReleaseSpec: %w", err)
	}

	releaseSpec := ReleaseSpecFromComponentReleaseSpec(crSpec)
	currentHash := ComputeReleaseHash(releaseSpec, nil)

	// Check if hash exists in status.LatestRelease and it hasn't changed
	if comp.Status.LatestRelease != nil && comp.Status.LatestRelease.ReleaseHash == currentHash {
		// Hash matches, verify the ComponentRelease exists and recreate if needed
		releaseName := comp.Status.LatestRelease.Name
		exists, err := r.ensureComponentRelease(ctx, comp, crSpec, releaseName, currentHash)
		if err != nil {
			return err
		}
		if exists {
			// ComponentRelease already existed, nothing more to do
			logger.Info("ComponentRelease hash unchanged and release exists",
				"component", comp.Name,
				"hash", currentHash,
				"release", releaseName)
			return r.ensureReleaseBinding(ctx, comp, releaseName, firstEnv, bindingName)
		}
		// ComponentRelease was recreated, continue to update status and binding
		logger.Info("ComponentRelease recreated after being missing",
			"component", comp.Name,
			"hash", currentHash,
			"release", releaseName)
	} else {
		// Hash is different, create new ComponentRelease
		logger.Info("ComponentRelease hash diff detected, creating new release",
			"component", comp.Name,
			"oldHash", func() string {
				if comp.Status.LatestRelease != nil {
					return comp.Status.LatestRelease.ReleaseHash
				}
				return "none"
			}(),
			"newHash", currentHash)

		releaseName := fmt.Sprintf("%s-%s", comp.Name, currentHash)
		if _, err := r.ensureComponentRelease(ctx, comp, crSpec, releaseName, currentHash); err != nil {
			return err
		}
	}

	// Generate release name for status update
	releaseName := fmt.Sprintf("%s-%s", comp.Name, currentHash)

	// Update status.LatestRelease
	comp.Status.LatestRelease = &openchoreov1alpha1.LatestRelease{
		Name:        releaseName,
		ReleaseHash: currentHash,
	}

	return r.ensureReleaseBinding(ctx, comp, releaseName, firstEnv, bindingName)
}

// ensureComponentRelease ensures a ComponentRelease with the given name exists.
// Returns (true, nil) if the release already existed.
// Returns (false, nil) if the release was created.
// Returns (false, error) if there was an error checking or creating the release.
func (r *Reconciler) ensureComponentRelease(
	ctx context.Context,
	comp *openchoreov1alpha1.Component,
	crSpec *openchoreov1alpha1.ComponentReleaseSpec,
	releaseName string,
	currentHash string,
) (bool, error) {
	logger := log.FromContext(ctx)

	// Check if ComponentRelease already exists
	existingRelease := &openchoreov1alpha1.ComponentRelease{}
	err := r.Get(ctx, types.NamespacedName{Name: releaseName, Namespace: comp.Namespace}, existingRelease)
	if err == nil {
		// ComponentRelease exists - validate its hash matches expectations
		existingSpec := ReleaseSpecFromComponentReleaseSpec(&existingRelease.Spec)
		existingHash := ComputeReleaseHash(existingSpec, nil)

		if existingHash != currentHash {
			// Hash mismatch - ComponentRelease was modified or corrupted, restore correct content
			logger.Info("ComponentRelease hash mismatch detected, updating to restore correct content",
				"name", releaseName,
				"expectedHash", currentHash,
				"actualHash", existingHash,
				"reason", "possible manual modification or data corruption")

			existingRelease.Spec = *crSpec

			if err := r.Update(ctx, existingRelease); err != nil {
				return false, fmt.Errorf("failed to update corrupted ComponentRelease %q: %w", releaseName, err)
			}

			logger.Info("ComponentRelease updated to restore correct content",
				"name", releaseName,
				"hash", currentHash)
			return false, nil
		}

		// Hash matches - ComponentRelease is valid
		logger.Info("ComponentRelease exists and hash is valid",
			"name", releaseName,
			"hash", currentHash)
		return true, nil
	}
	if !apierrors.IsNotFound(err) {
		return false, fmt.Errorf("failed to get ComponentRelease %q: %w", releaseName, err)
	}

	// ComponentRelease doesn't exist, create it
	componentRelease := &openchoreov1alpha1.ComponentRelease{
		ObjectMeta: metav1.ObjectMeta{
			Name:      releaseName,
			Namespace: comp.Namespace,
		},
		Spec: *crSpec,
	}

	if err := r.Create(ctx, componentRelease); err != nil {
		if !apierrors.IsAlreadyExists(err) {
			return false, fmt.Errorf("failed to create ComponentRelease: %w", err)
		}
		// Already exists - this is fine, likely a race condition
		logger.Info("ComponentRelease already exists (race condition)", "name", releaseName)
		return true, nil
	}

	logger.Info("Created ComponentRelease", "name", releaseName, "hash", currentHash)
	return false, nil
}

// ensureReleaseBinding ensures a ReleaseBinding exists for the given environment and component.
// If the ReleaseBinding doesn't exist, it creates one.
// If it exists, it updates the release name if different.
// Returns an error if multiple ReleaseBindings are found for the same environment.
// bindingName is the name of the ReleaseBinding to create if it doesn't exist.
func (r *Reconciler) ensureReleaseBinding(
	ctx context.Context,
	comp *openchoreov1alpha1.Component,
	releaseName string,
	firstEnv string,
	bindingName string,
) error {
	logger := log.FromContext(ctx)

	envKey := controller.MakeReleaseBindingOwnerEnvKey(comp.Spec.Owner.ProjectName, comp.Name, firstEnv)
	releaseBindingList := openchoreov1alpha1.ReleaseBindingList{}
	err := r.List(ctx, &releaseBindingList, client.InNamespace(comp.Namespace),
		client.MatchingFields{controller.IndexKeyReleaseBindingOwnerEnv: envKey})
	if err != nil {
		return fmt.Errorf("failed to list ReleaseBinding: %w", err)
	}

	if len(releaseBindingList.Items) == 0 {
		// ReleaseBinding doesn't exist, create it
		releaseBinding := &openchoreov1alpha1.ReleaseBinding{
			ObjectMeta: metav1.ObjectMeta{
				Name:      bindingName,
				Namespace: comp.Namespace,
			},
			Spec: openchoreov1alpha1.ReleaseBindingSpec{
				Owner: openchoreov1alpha1.ReleaseBindingOwner{
					ProjectName:   comp.Spec.Owner.ProjectName,
					ComponentName: comp.Name,
				},
				ReleaseName: releaseName,
				Environment: firstEnv,
				// No overrides for initial auto-deploy
			},
		}

		if err := r.Create(ctx, releaseBinding); err != nil {
			return fmt.Errorf("failed to create ReleaseBinding: %w", err)
		}

		logger.Info("Created ReleaseBinding", "binding", bindingName, "release", releaseName,
			"environment", firstEnv)
		return nil
	}

	if len(releaseBindingList.Items) > 1 {
		return fmt.Errorf("found multiple ReleaseBinding objects for environment %q", firstEnv)
	}

	releaseBinding := releaseBindingList.Items[0]

	// ReleaseBinding exists, patch the release name if different
	if releaseBinding.Spec.ReleaseName != releaseName {
		releaseBinding.Spec.ReleaseName = releaseName

		if err := r.Update(ctx, &releaseBinding); err != nil {
			return fmt.Errorf("failed to update ReleaseBinding: %w", err)
		}

		logger.Info("Updated ReleaseBinding with new release",
			"binding", bindingName,
			"release", releaseName,
			"environment", firstEnv)
	} else {
		logger.Info("ReleaseBinding already references current release",
			"binding", bindingName,
			"release", releaseName)
	}

	return nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *Reconciler) SetupWithManager(mgr ctrl.Manager) error {
	ctx := context.Background()

	// Set up field indexes for efficient lookups
	if err := r.setupComponentTypeRefIndex(ctx, mgr); err != nil {
		return fmt.Errorf("failed to setup component type reference index: %w", err)
	}

	if err := r.setupTraitsRefIndex(ctx, mgr); err != nil {
		return fmt.Errorf("failed to setup traits reference index: %w", err)
	}

	if err := r.setupWorkflowRefIndex(ctx, mgr); err != nil {
		return fmt.Errorf("failed to setup workflow reference index: %w", err)
	}

	if err := r.setupWorkloadOwnerIndex(ctx, mgr); err != nil {
		return fmt.Errorf("failed to setup workload owner index: %w", err)
	}

	// Note: ReleaseBinding owner+env index is set up in controller.SetupSharedIndexes

	if err := r.setupComponentReleaseOwnerIndex(ctx, mgr); err != nil {
		return fmt.Errorf("failed to setup component release owner index: %w", err)
	}

	// Note: The following shared indexes are set up in controller.SetupSharedIndexes (called from main.go):
	// - ReleaseBinding owner index (used by Component and ReleaseBinding controllers)
	// - Component owner project index (used by Project and Component controllers)
	// - Project deploymentPipelineRef index (used by Component controller)

	return ctrl.NewControllerManagedBy(mgr).
		For(&openchoreov1alpha1.Component{}).
		Watches(&openchoreov1alpha1.ComponentRelease{},
			handler.EnqueueRequestsFromMapFunc(r.findComponentsForComponentRelease)).
		Watches(&openchoreov1alpha1.ReleaseBinding{},
			handler.EnqueueRequestsFromMapFunc(r.findComponentsForReleaseBinding)).
		Watches(&openchoreov1alpha1.ComponentType{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForComponentType)).
		Watches(&openchoreov1alpha1.ClusterComponentType{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForClusterComponentType)).
		Watches(&openchoreov1alpha1.Trait{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsUsingTrait)).
		Watches(&openchoreov1alpha1.ClusterTrait{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsUsingClusterTrait)).
		Watches(&openchoreov1alpha1.Workflow{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForWorkflow)).
		Watches(&openchoreov1alpha1.ClusterWorkflow{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForClusterWorkflow)).
		Watches(&openchoreov1alpha1.Workload{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForWorkload)).
		Watches(&openchoreov1alpha1.Project{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForProject)).
		Watches(&openchoreov1alpha1.DeploymentPipeline{},
			handler.EnqueueRequestsFromMapFunc(r.listComponentsForDeploymentPipeline)).
		Named("component").
		Complete(r)
}
```
