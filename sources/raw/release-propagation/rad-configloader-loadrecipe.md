---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/recipes/configloader/environment.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/recipes/configloader/environment.go lines 286,316 -->

```

// LoadRecipe fetches the recipe information from the environment. It returns an error if the environment cannot be fetched.
func (e *environmentLoader) LoadRecipe(ctx context.Context, recipe *recipes.ResourceMetadata) (*recipes.EnvironmentDefinition, error) {
	envID, err := resources.Parse(recipe.EnvironmentID)
	if err != nil {
		return nil, ErrBadEnvID
	}
	var envDefinition *recipes.EnvironmentDefinition
	if strings.EqualFold(envID.ProviderNamespace(), radius.NamespaceApplicationsCore) {
		environment, err := util.FetchEnvironment(ctx, recipe.EnvironmentID, e.ArmClientOptions)
		if err != nil {
			return nil, err
		}
		envDefinition, err = getRecipeDefinition(environment, recipe)
		if err != nil {
			return nil, err
		}

	} else {
		environment, err := util.FetchEnvironmentV20250801(ctx, recipe.EnvironmentID, e.ArmClientOptions)
		if err != nil {
			return nil, err
		}
		envDefinition, err = getRecipeDefinitionFromEnvironmentV20250801(ctx, environment, recipe, e.ArmClientOptions)
		if err != nil {
			return nil, err
		}

	}
	return envDefinition, err
}
```
