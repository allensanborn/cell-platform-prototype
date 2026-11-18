---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/corerp/frontend/controller/recipepacks/createorupdaterecipepack.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/corerp/frontend/controller/recipepacks/createorupdaterecipepack.go lines 31,76 -->

```
var _ ctrl.Controller = (*CreateOrUpdateRecipePack)(nil)

// CreateOrUpdateRecipePack is the controller implementation to create or update recipe pack resource.
type CreateOrUpdateRecipePack struct {
	ctrl.Operation[*datamodel.RecipePack, datamodel.RecipePack]
}

// NewCreateOrUpdateRecipePack creates a new controller for creating or updating a recipe pack resource.
func NewCreateOrUpdateRecipePack(opts ctrl.Options) (ctrl.Controller, error) {
	return &CreateOrUpdateRecipePack{
		ctrl.NewOperation(opts,
			ctrl.ResourceOptions[datamodel.RecipePack]{
				RequestConverter:  converter.RecipePackDataModelFromVersioned,
				ResponseConverter: converter.RecipePackDataModelToVersioned,
			},
		),
	}, nil
}

// Run creates or updates a recipe pack resource.
func (r *CreateOrUpdateRecipePack) Run(ctx context.Context, w http.ResponseWriter, req *http.Request) (rest.Response, error) {
	logger := ucplog.FromContextOrDiscard(ctx)
	serviceCtx := v1.ARMRequestContextFromContext(ctx)
	newResource, err := r.GetResourceFromRequest(ctx, req)
	if err != nil {
		return nil, err
	}
	old, etag, err := r.GetResource(ctx, serviceCtx.ResourceID)
	if err != nil {
		return nil, err
	}

	if resp, err := r.PrepareResource(ctx, req, newResource, old, etag); resp != nil || err != nil {
		return resp, err
	}

	logger.Info("Creating or updating recipe pack", "resourceID", serviceCtx.ResourceID.String())

	newResource.SetProvisioningState(v1.ProvisioningStateSucceeded)
	newEtag, err := r.SaveResource(ctx, serviceCtx.ResourceID.String(), newResource, etag)
	if err != nil {
		return nil, err
	}

	return r.ConstructSyncResponse(ctx, req.Method, newEtag, newResource)
}
```
