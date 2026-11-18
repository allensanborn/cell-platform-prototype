---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/corerp/handlers/kubernetes.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/corerp/handlers/kubernetes.go lines 77,160 -->

```
// Put stores the Kubernetes resource in the cluster and returns the properties of the resource. If the resource is a
// deployment, it also waits until the deployment is ready.
func (handler *kubernetesHandler) Put(ctx context.Context, options *PutOptions) (map[string]string, error) {
	logger := ucplog.FromContextOrDiscard(ctx)

	// If CreateResource is nil, then we don't need to create a resource.
	if options.Resource.CreateResource == nil {
		return map[string]string{}, nil
	}

	item, err := convertToUnstructured(*options.Resource)
	if err != nil {
		return nil, err
	}

	// For a Kubernetes resource we only need to store the ObjectMeta and TypeMeta data
	properties := map[string]string{
		KubernetesKindKey:       item.GetKind(),
		KubernetesAPIVersionKey: item.GetAPIVersion(),
		KubernetesNamespaceKey:  item.GetNamespace(),
		ResourceName:            item.GetName(),
	}

	err = kubeutil.PatchNamespace(ctx, handler.client, item.GetNamespace())
	if err != nil {
		return nil, err
	}

	// Using client.Apply patch type for server-side apply with unstructured types.
	// The new client.Client.Apply() API requires ApplyConfiguration types which are
	// not straightforward to generate for dynamic/unstructured resources.
	//nolint:staticcheck // SA1019: client.Apply will be replaced when ApplyConfiguration support is available
	err = handler.client.Patch(ctx, &item, client.Apply, &client.PatchOptions{FieldManager: kubernetes.FieldManager})
	if err != nil {
		return nil, err
	}

	groupVersion, err := schema.ParseGroupVersion(item.GetAPIVersion())
	if err != nil {
		return nil, err
	}

	id := resources_kubernetes.IDFromParts(
		resources_kubernetes.PlaneNameTODO,
		groupVersion.Group,
		item.GetKind(),
		item.GetNamespace(),
		item.GetName())
	options.Resource.ID = id

	// Monitor the created or updated resource until it is ready.
	switch strings.ToLower(item.GetKind()) {
	case "deployment":
		// Monitor the deployment until it is ready.
		err = handler.deploymentWaiter.waitUntilReady(ctx, &item)
		if err != nil {
			return nil, err
		}
		logger.Info(fmt.Sprintf("Deployment %s in namespace %s is ready", item.GetName(), item.GetNamespace()))
		return properties, nil
	case "httpproxy":
		if !isContourHTTPProxy(&item) {
			return properties, nil
		}
		if isContourHTTPProxyRouteChild(&item) {
			logger.Info(fmt.Sprintf("Skipping readiness wait for route HTTP proxy %s in namespace %s", item.GetName(), item.GetNamespace()))
			return properties, nil
		}
		err = handler.httpProxyWaiter.waitUntilReady(ctx, &item)
		if err != nil {
			return nil, err
		}
		logger.Info(fmt.Sprintf("HTTP Proxy %s in namespace %s is ready", item.GetName(), item.GetNamespace()))
		return properties, nil
	default:
		// We do not monitor the other resource types.
		return properties, nil
	}
}

// Delete decodes the identity data from the DeleteOptions, creates an unstructured object from the identity data,
// and then attempts to delete the object from the Kubernetes cluster, returning an error if one occurs.
func (handler *kubernetesHandler) Delete(ctx context.Context, options *DeleteOptions) error {
	apiVersion, err := handler.lookupKubernetesAPIVersion(options.Resource.ID)
```
