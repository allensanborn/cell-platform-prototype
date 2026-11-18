---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/recipes/engine/engine.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/recipes/engine/engine.go lines 54,224 -->

```
func (e *engine) Execute(ctx context.Context, opts ExecuteOptions) (*recipes.RecipeOutput, error) {
	executionStart := time.Now()
	result := metrics.SuccessfulOperationState

	recipeOutput, definition, err := e.executeCore(ctx, opts.Recipe, opts.PreviousState)
	if err != nil {
		result = metrics.FailedOperationState
		if errorDetails := recipes.GetErrorDetails(err); errorDetails != nil {
			result = errorDetails.Code
		}
	}

	metrics.DefaultRecipeEngineMetrics.RecordRecipeOperationDuration(ctx, executionStart,
		metrics.NewRecipeAttributes(metrics.RecipeEngineOperationExecute, opts.Recipe.Name,
			definition, result))

	return recipeOutput, err
}

// executeCore function is the core logic of the Execute function.
// Any changes to the core logic of the Execute function should be made here.
func (e *engine) executeCore(ctx context.Context, recipe recipes.ResourceMetadata, prevState []string) (*recipes.RecipeOutput, *recipes.EnvironmentDefinition, error) {
	logger := ucplog.FromContextOrDiscard(ctx)

	configuration, err := e.options.ConfigurationLoader.LoadConfiguration(ctx, recipe)
	if err != nil {
		return nil, nil, recipes.NewRecipeError(recipes.RecipeConfigurationFailure, err.Error(), util.RecipeSetupError, recipes.GetErrorDetails(err))
	}

	// No need to try executing the recipe if it's a simulated environment.
	if configuration.Simulated {
		logger.Info("simulated environment enabled, skipping deployment")
		return nil, nil, nil
	}

	definition, driver, err := e.getDriver(ctx, recipe)
	if err != nil {
		return nil, nil, err
	}

	secrets, err := e.getRecipeConfigSecrets(ctx, driver, configuration, definition)
	if err != nil {
		return nil, nil, err
	}

	res, err := driver.Execute(ctx, recipedriver.ExecuteOptions{
		Configuration: *configuration,
		Recipe:        recipe,
		Definition:    *definition,
		Secrets:       secrets,
		PrevState:     prevState,
	})
	if err != nil {
		return nil, definition, err
	}

	return res, definition, nil
}

// Delete calls the Delete method of the driver specified in the recipe definition to delete the output resources.
func (e *engine) Delete(ctx context.Context, opts DeleteOptions) error {
	deletionStart := time.Now()
	result := metrics.SuccessfulOperationState

	definition, err := e.deleteCore(ctx, opts.Recipe, opts.OutputResources)
	if err != nil {
		result = metrics.FailedOperationState
		if errorDetails := recipes.GetErrorDetails(err); errorDetails != nil {
			result = errorDetails.Code
		}
	}

	metrics.DefaultRecipeEngineMetrics.RecordRecipeOperationDuration(ctx, deletionStart,
		metrics.NewRecipeAttributes(metrics.RecipeEngineOperationDelete, opts.Recipe.Name,
			definition, result))

	return err
}

// deleteCore function is the core logic of the Delete function.
// Any changes to the core logic of the Delete function should be made here.
func (e *engine) deleteCore(ctx context.Context, recipe recipes.ResourceMetadata, outputResources []rpv1.OutputResource) (*recipes.EnvironmentDefinition, error) {
	logger := ucplog.FromContextOrDiscard(ctx)
	configuration, err := e.options.ConfigurationLoader.LoadConfiguration(ctx, recipe)
	if err != nil {
		return nil, err
	}

	if configuration.Simulated {
		logger.Info("simulated environment enabled, skipping deleting resources")
		return nil, nil
	}

	definition, driver, err := e.getDriver(ctx, recipe)
	if err != nil {
		return nil, err
	}

	secrets, err := e.getRecipeConfigSecrets(ctx, driver, configuration, definition)
	if err != nil {
		return nil, err
	}
	err = driver.Delete(ctx, recipedriver.DeleteOptions{
		Configuration:   *configuration,
		Recipe:          recipe,
		Definition:      *definition,
		Secrets:         secrets,
		OutputResources: outputResources,
	})
	if err != nil {
		return definition, err
	}

	return definition, nil
}

// Gets the Recipe metadata and parameters from Recipe's template path.
func (e *engine) GetRecipeMetadata(ctx context.Context, opts GetRecipeMetadataOptions) (map[string]any, error) {
	recipeData, err := e.getRecipeMetadataCore(ctx, opts)
	if err != nil {
		return nil, err
	}

	return recipeData, nil
}

// getRecipeMetadataCore function is the core logic of the GetRecipeMetadata function.
// Any changes to the core logic of the GetRecipeMetadata function should be made here.
func (e *engine) getRecipeMetadataCore(ctx context.Context, opts GetRecipeMetadataOptions) (map[string]any, error) {
	// Load environment configuration to get the recipe config information which contains the secrets.
	// Secrets are needed to download terraform recipes from private module sources, currently for private git repositories.
	configuration, err := e.options.ConfigurationLoader.LoadConfiguration(ctx, opts.Recipe)
	if err != nil {
		return nil, err
	}

	// Determine Recipe driver type
	driver, ok := e.options.Drivers[opts.RecipeDefinition.Driver]
	if !ok {
		return nil, fmt.Errorf("could not find driver %s", opts.RecipeDefinition.Driver)
	}

	secrets, err := e.getRecipeConfigSecrets(ctx, driver, configuration, &opts.RecipeDefinition)
	if err != nil {
		return nil, err
	}

	return driver.GetRecipeMetadata(ctx, recipedriver.BaseOptions{
		Recipe:        recipes.ResourceMetadata{},
		Definition:    opts.RecipeDefinition,
		Secrets:       secrets,
		Configuration: *configuration,
	})
}

func (e *engine) getDriver(ctx context.Context, recipeMetadata recipes.ResourceMetadata) (*recipes.EnvironmentDefinition, recipedriver.Driver, error) {
	// Load Recipe Definition from the environment.
	definition, err := e.options.ConfigurationLoader.LoadRecipe(ctx, &recipeMetadata)
	if err != nil {
		return nil, nil, err
	}

	// Determine Recipe driver type
	driver, ok := e.options.Drivers[definition.Driver]
	if !ok {
		err := fmt.Errorf("could not find driver `%s`", definition.Driver)
		return nil, nil, recipes.NewRecipeError(recipes.RecipeDriverNotFoundFailure, err.Error(), util.RecipeSetupError, recipes.GetErrorDetails(err))
	}
	return definition, driver, nil
}

```
