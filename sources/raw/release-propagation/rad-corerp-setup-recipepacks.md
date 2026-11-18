---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/corerp/setup/setup.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/corerp/setup/setup.go lines 257,284 -->

```
// SetupRadiusCoreNamespace builds the namespace for core resource provider.
func SetupRadiusCoreNamespace(recipeControllerConfig *controllerconfig.RecipeControllerConfig) *builder.Namespace {
	ns := builder.NewNamespace("Radius.Core")

	_ = ns.AddResource("recipePacks", &builder.ResourceOption[*datamodel.RecipePack, datamodel.RecipePack]{
		RequestConverter:  converter.RecipePackDataModelFromVersioned,
		ResponseConverter: converter.RecipePackDataModelToVersioned,

		Put: builder.Operation[datamodel.RecipePack]{
			APIController: rp_ctrl.NewCreateOrUpdateRecipePack,
		},
		Patch: builder.Operation[datamodel.RecipePack]{
			APIController: rp_ctrl.NewCreateOrUpdateRecipePack,
		},
	})

	_ = ns.AddResource("environments", &builder.ResourceOption[*datamodel.Environment_v20250801preview, datamodel.Environment_v20250801preview]{
		RequestConverter:  converter.Environment20250801DataModelFromVersioned,
		ResponseConverter: converter.Environment20250801DataModelToVersioned,

		Put: builder.Operation[datamodel.Environment_v20250801preview]{
			APIController: env_v20250801_ctrl.NewCreateOrUpdateEnvironmentv20250801preview,
		},
		Patch: builder.Operation[datamodel.Environment_v20250801preview]{
			APIController: env_v20250801_ctrl.NewCreateOrUpdateEnvironmentv20250801preview,
		},
	})

```
