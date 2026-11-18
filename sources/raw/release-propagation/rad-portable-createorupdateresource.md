---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/portableresources/backend/controller/createorupdateresource.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/portableresources/backend/controller/createorupdateresource.go lines 45,319 -->

```
// CreateOrUpdateResource is the async operation controller to create or update portable resources.
type CreateOrUpdateResource[P interface {
	*T
	rpv1.RadiusResourceModel
}, T any] struct {
	ctrl.BaseController
	processor           processors.ResourceProcessor[P, T]
	engine              engine.Engine
	configurationLoader configloader.ConfigurationLoader
}

// NewCreateOrUpdateResource creates a new controller for creating or updating a resource with the given processor, engine,
// client, configurationLoader and options. The processor function will be called to process updates to the resource.
func NewCreateOrUpdateResource[P interface {
	*T
	rpv1.RadiusResourceModel
}, T any](opts ctrl.Options, processor processors.ResourceProcessor[P, T], eng engine.Engine, configurationLoader configloader.ConfigurationLoader) (ctrl.Controller, error) {
	return &CreateOrUpdateResource[P, T]{
		ctrl.NewBaseAsyncController(opts),
		processor,
		eng,
		configurationLoader,
	}, nil
}

// Run retrieves an existing resource, executes a recipe if needed, loads runtime configuration,
// processes the resource, cleans up any obsolete output resources, and saves the updated resource.
func (c *CreateOrUpdateResource[P, T]) Run(ctx context.Context, req *ctrl.Request) (ctrl.Result, error) {
	logger := ucplog.FromContextOrDiscard(ctx)
	storedResource, err := c.DatabaseClient().Get(ctx, req.ResourceID)
	if errors.Is(&database.ErrNotFound{ID: req.ResourceID}, err) {
		return ctrl.Result{}, err
	} else if err != nil {
		return ctrl.Result{}, err
	}

	resource := P(new(T))
	if err = storedResource.As(resource); err != nil {
		return ctrl.Result{}, err
	}

	currentETag := storedResource.ETag
	var recipeProperties map[string]any
	redactionCompleted := false

	// Attempt to decrypt and redact sensitive fields before recipe execution.
	apiVersion := getResourceAPIVersion(resource)
	if apiVersion != "" {
		resourceType := resource.GetBaseResource().Type
		schema, schemaErr := schemautil.GetSchema(ctx, c.UcpClient(), req.ResourceID, resourceType, apiVersion)
		if schemaErr != nil {
			return ctrl.Result{}, fmt.Errorf("failed to fetch schema for sensitive field detection: %w", schemaErr)
		} else if schema != nil {
			sensitiveFieldPaths := schemautil.ExtractSensitiveFieldPaths(schema, "")
			if len(sensitiveFieldPaths) > 0 {
				logger.Info("Sensitive fields detected for resource", "resourceID", req.ResourceID, "paths", sensitiveFieldPaths)

				properties, err := resourceutil.GetPropertiesFromResource(resource)
				if err != nil {
					return ctrl.Result{}, err
				}

				recipeProperties, err = deepCopyProperties(properties)
				if err != nil {
					return ctrl.Result{}, err
				}

				if c.KubeClient() == nil {
					err = fmt.Errorf("kubernetes client not configured for sensitive data decryption")
					logger.Error(err, "Failed to initialize encryption key provider", "resourceID", req.ResourceID)
					return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
				}

				keyProvider := encryption.NewKubernetesKeyProvider(c.KubeClient(), nil)
				handler, err := encryption.NewSensitiveDataHandlerFromProvider(ctx, keyProvider)
				if err != nil {
					logger.Error(err, "Failed to initialize sensitive data handler", "resourceID", req.ResourceID)
					return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
				}

				if err = handler.DecryptSensitiveFieldsWithSchema(ctx, recipeProperties, sensitiveFieldPaths, req.ResourceID, schema); err != nil {
					logger.Error(err, "Failed to decrypt sensitive fields", "resourceID", req.ResourceID)
					return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
				}

				// Derive the redacted copy from the original encrypted properties,
				// NOT from the decrypted recipeProperties. recipeProperties
				// (decrypted) is kept exclusively for in-memory recipe execution.
				redactedProperties, err := deepCopyProperties(properties)
				if err != nil {
					return ctrl.Result{}, err
				}
				schemautil.RedactFields(redactedProperties, sensitiveFieldPaths)

				if err = applyPropertiesToResource(resource, redactedProperties); err != nil {
					logger.Error(err, "Failed to apply redacted properties", "resourceID", req.ResourceID)
					return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
				}

				update := &database.Object{
					ID:   req.ResourceID,
					Data: resource,
				}
				if err = c.DatabaseClient().Save(ctx, update, database.WithETag(currentETag)); err != nil {
					logger.Error(err, "Failed to persist redacted resource", "resourceID", req.ResourceID)
					return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
				}
				currentETag = update.ETag
				redactionCompleted = true
			}
		}
	} else {
		logger.Info("Skipping sensitive field detection due to missing apiVersion", "resourceID", req.ResourceID)
	}

	// Clone existing output resources so we can diff them later.
	previousOutputResources := c.copyOutputResources(resource)

	// Load configuration
	metadata := recipes.ResourceMetadata{EnvironmentID: resource.ResourceMetadata().EnvironmentID(), ApplicationID: resource.ResourceMetadata().ApplicationID(), ResourceID: resource.GetBaseResource().ID}
	config, err := c.configurationLoader.LoadConfiguration(ctx, metadata)
	if err != nil {
		if redactionCompleted {
			return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
		}
		return ctrl.Result{}, err
	}

	// Now we're ready to process recipes (if needed).
	recipeDataModel, supportsRecipes := any(resource).(datamodel.RecipeDataModel)
	var recipeOutput *recipes.RecipeOutput
	if supportsRecipes && recipeDataModel.GetRecipe() != nil {
		recipeOutput, err = c.executeRecipeIfNeeded(ctx, resource, recipeDataModel, previousOutputResources, config.Simulated, recipeProperties)
		if err != nil {
			return c.handleRecipeError(ctx, err, recipeDataModel, req.ResourceID, currentETag, logger, redactionCompleted)
		}
	}

	if config.Simulated {
		logger.Info("The recipe was executed in simulation mode. No resources were deployed.")
	} else {
		// Now we're ready to process the resource. This will handle the updates to any user-visible state.
		err = c.processor.Process(ctx, resource, processors.Options{RecipeOutput: recipeOutput, RuntimeConfiguration: config.Runtime, UcpClient: c.BaseController.UcpClient()})
		if err != nil {
			if redactionCompleted {
				return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
			}
			return ctrl.Result{}, err
		}
	}

	if supportsRecipes {
		recipeData := recipeDataModel.GetRecipe()
		if recipeData != nil {
			recipeData.DeploymentStatus = util.Success
			recipeDataModel.SetRecipe(recipeData)
		}
		if recipeOutput != nil && recipeOutput.Status != nil {
			setRecipeStatus(resource, *recipeOutput.Status)
		}
	}

	update := &database.Object{
		ID:   req.ResourceID,
		Data: recipeDataModel.(rpv1.RadiusResourceModel),
	}
	err = c.DatabaseClient().Save(ctx, update, database.WithETag(currentETag))
	if err != nil {
		if redactionCompleted {
			return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
		}
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, err
}

// handleRecipeError handles recipe execution errors: logs, updates status, persists, and returns the appropriate result.
// A RecipeError is always terminal and returns NewFailedResult with the recipe's error details, even if the
// best-effort status persistence fails, so the real recipe failure is never masked. For non-RecipeError failures,
// when redactionCompleted is true the failure is made terminal (NewFailedResult) to prevent a retry that would fail
// because sensitive data has already been nullified from the database.
func (c *CreateOrUpdateResource[P, T]) handleRecipeError(ctx context.Context, err error, recipeDataModel datamodel.RecipeDataModel, resourceID string, etag string, logger logr.Logger, redactionCompleted bool) (ctrl.Result, error) {
	if recipeErr, ok := errors.AsType[*recipes.RecipeError](err); ok {
		logger.Error(recipeErr, fmt.Sprintf("failed to execute recipe. Encountered error while processing %s ", recipeErr.ErrorDetails.Target))

		// Set the deployment status to the recipe error code
		recipeDataModel.GetRecipe().DeploymentStatus = util.RecipeDeploymentStatus(recipeErr.DeploymentStatus)
		update := &database.Object{
			ID:   resourceID,
			Data: recipeDataModel.(rpv1.RadiusResourceModel),
		}

		// Save portable resource with updated deployment status to track errors during deletion.
		// This persistence is best-effort bookkeeping: if it fails we must still surface the
		// original recipe error to the caller rather than masking it with the save error (for
		// example a spurious ErrConcurrency). The operation is terminal either way, so there is
		// nothing to be gained by returning the save error instead of the real recipe failure.
		if saveErr := c.DatabaseClient().Save(ctx, update, database.WithETag(etag)); saveErr != nil {
			logger.Error(saveErr, "failed to persist recipe error status; returning the original recipe error")
		}

		return ctrl.NewFailedResult(recipeErr.ErrorDetails), nil
	}

	// For non-RecipeError: if sensitive data was redacted, prevent retry since
	// the data is gone from the database and retry would fail.
	if redactionCompleted {
		return ctrl.NewFailedResult(v1.ErrorDetails{Message: err.Error()}), err
	}

	return ctrl.Result{}, err
}

func (c *CreateOrUpdateResource[P, T]) copyOutputResources(resource P) []string {
	previousOutputResources := []string{}
	for _, outputResource := range resource.OutputResources() {
		previousOutputResources = append(previousOutputResources, outputResource.ID.String())
	}
	return previousOutputResources
}

func (c *CreateOrUpdateResource[P, T]) executeRecipeIfNeeded(ctx context.Context, resource P, recipeDataModel datamodel.RecipeDataModel, prevState []string, simulated bool, recipeProperties map[string]any) (*recipes.RecipeOutput, error) {
	// Caller ensures recipeDataModel supports recipes and has a non-nil recipe
	recipe := recipeDataModel.GetRecipe()

	resourceProperties := recipeProperties
	if resourceProperties == nil {
		var err error
		resourceProperties, err = resourceutil.GetPropertiesFromResource(resource)
		if err != nil {
			return nil, err
		}
	}

	connectionsAndSourceIDs, err := resourceutil.GetConnectionNameandSourceIDs(resource)
	if err != nil {
		return nil, fmt.Errorf("failed to get connected resource IDs: %w", err)
	}
	connectedResourcesMetadata := make(map[string]recipes.ConnectedResource)

	// If there are connected resources, we need to fetch their properties and add them to the recipe context.
	for connName, connectedResourceID := range connectionsAndSourceIDs {
		connectedResource, err := c.DatabaseClient().Get(ctx, connectedResourceID)
		if errors.Is(err, &database.ErrNotFound{ID: connectedResourceID}) {
			return nil, fmt.Errorf("connected resource %s not found: %w", connectedResourceID, err)
		} else if err != nil {
			return nil, fmt.Errorf("failed to get connected resource %s: %w", connectedResourceID, err)
		}

		connectedResourceMetadata, err := buildConnectedResource(ctx, c.DatabaseClient(), connectedResource.Data)
		if err != nil {
			return nil, fmt.Errorf("failed to get metadata from connected resource %s: %w", connectedResourceID, err)
		}

		connectedResourcesMetadata[connName] = connectedResourceMetadata
	}

	metadata := recipes.ResourceMetadata{
		Name:                         recipe.Name,
		Parameters:                   recipe.Parameters,
		EnvironmentID:                resource.ResourceMetadata().EnvironmentID(),
		ApplicationID:                resource.ResourceMetadata().ApplicationID(),
		ResourceID:                   resource.GetBaseResource().ID,
		Properties:                   resourceProperties,
		ConnectedResourcesProperties: connectedResourcesMetadata,
	}

	return c.engine.Execute(ctx, engine.ExecuteOptions{
		Recipe:        metadata,
		PreviousState: prevState,
		Simulated:     simulated,
	})
}

```
