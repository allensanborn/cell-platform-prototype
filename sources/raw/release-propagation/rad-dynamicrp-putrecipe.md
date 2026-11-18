---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/dynamicrp/backend/controller/putrecipe.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/dynamicrp/backend/controller/putrecipe.go lines 30,59 -->

```
// RecipePutController is the async operation controller to perform PUT processing on "recipe" dynamic resources.
type RecipePutController struct {
	ctrl.BaseController
	opts                ctrl.Options
	engine              engine.Engine
	configurationLoader configloader.ConfigurationLoader
	secretMaterializer  secret.Materializer
}

// NewRecipePutController creates a new RecipePutController.
func NewRecipePutController(opts ctrl.Options, engine engine.Engine, configurationLoader configloader.ConfigurationLoader, secretMaterializer secret.Materializer) (ctrl.Controller, error) {
	return &RecipePutController{
		BaseController:      ctrl.NewBaseAsyncController(opts),
		opts:                opts,
		engine:              engine,
		configurationLoader: configurationLoader,
		secretMaterializer:  secretMaterializer,
	}, nil
}

// Run processes PUT operations for dynamic resources deployed using recipes.
// It creates and delegates the request to CreateOrUpdateResource controller to handle the operation.
func (c *RecipePutController) Run(ctx context.Context, request *ctrl.Request) (ctrl.Result, error) {
	putController, err := recipecontroller.NewCreateOrUpdateResource(c.opts, &processor.DynamicProcessor{SecretMaterializer: c.secretMaterializer}, c.engine, c.configurationLoader)
	if err != nil {
		return ctrl.Result{}, err
	}

	return putController.Run(ctx, request)
}
```
