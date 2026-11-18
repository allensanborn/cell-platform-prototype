---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/controller/reconciler/flux_controller.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/controller/reconciler/flux_controller.go lines 134,150 -->

```
// setupFluxController creates a new controller for GitRepository objects
// and sets it up with the manager.
func (r *FluxController) setupFluxController(mgr ctrl.Manager) error {
	if err := mgr.GetFieldIndexer().IndexField(context.Background(), &radappiov1alpha3.DeploymentTemplate{}, deploymentTemplateRepositoryField, deploymentTemplateRepositoryIndexer); err != nil {
		return err
	}

	err := ctrl.NewControllerManagedBy(mgr).
		For(&sourcev1.GitRepository{}, builder.WithPredicates(&GitRepositoryRevisionChangePredicate{})).
		Complete(r)

	if err != nil {
		return err
	}

	r.initialized.Store(true)
	return nil
```
