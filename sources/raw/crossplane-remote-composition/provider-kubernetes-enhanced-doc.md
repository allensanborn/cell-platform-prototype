---
resource: https://github.com/crossplane-contrib/provider-kubernetes/blob/v1.4.1/docs/enhanced-provider-k8s.md
fetched: 2026-11-16
fetch_note: gh api contents ?ref=v1.4.1; crossplane-contrib/provider-kubernetes@9a27a441d3f87c1fc183876c8b40ebfd3a2f027c; lines 27-92 and 276-298 verbatim
---

The Crossplane Provider [provider-kubernetes](https://github.com/crossplane-contrib/provider-kubernetes) is designed to enable deployment and management of arbitrary Kubernetes resources in clusters. It defines an `Object` resource type which represents arbitrary Kubernetes resources, then uses a Kubernetes controller to reconcile `Object` typed resources to manage the corresponding Kubernetes resources.

As an example, below YAML manifest defines an `Object` which represents a Kubernetes namesapce.

```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: Object
metadata:
  name: sample-namespace
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Namespace
      metadata:
        # name in manifest is optional and defaults to Object name
        # name: some-other-name
        labels:
          example: "true"
  providerConfigRef:
    name: kubernetes-provider
```

The detailed manifest for the namespace is defined in `spec.forProvider.manifest`. So, essentially, `Object` resource simply wraps the manifest of target Kubernetes resource, in this case the namespace. After `Object` resource is created, the provider will also watch the target Kubernetes resource and attach the runtime copy for the manifest including runtime status to the `Object` resource at `status.atProvider.manifest` so that we can monitor the target Kubernetes resource by checking the `Object` status field. 

By convention in Crossplane, we usually call `Object` as managed resource, and the target Kubernetes resource as external resource. The managed resource `Object` is always co-located with the provider so that it can be watched by the provider. The external resource can be either co-located with the provider on the same cluster, or on a remote cluster, depending on the kubeconfig information defined in `spec.providerConfigRef` as above. Typically, the provider will check if the external resource exists on the target cluster, and if does not, it will create for us.

![](images/provider-k8s-1.png)

![](images/provider-k8s-2.png)

## Why Provider Kubernetes

The major usage scenario of Provider Kubernetes is to provision and manage Kubernetes objects on Kubernetes clusters, especially on remote clusters. It wraps Kubernetes resource manifest in `Object` resource, then does transformation from the `Object` resource to the actual Kubernetes resource on target clusters. With that, you can apply arbitrary Kubernetes resources on target clusters.

Of course you can manage Kubernetes resource directly without leveraging the provider and its `Object`, e.g.: using command line tool such as kubectl manually or normal Kubernetes controller programmatically. However, if you are using Crossplane and want to rely on Crossplane to deliver such a capability, Provider Kubernetes is the best choice.

On the other hand, when composing arbitrary Kubernetes resources with other resources managed by other providers in a Crossplane `Composition` resource, you can use `Object` to wrap those Kubernetes resources so that you don't need to worry about the restriction that the Kubernetes resources appeared in `Composition` has to be cluster scoped. See [this issue](https://github.com/crossplane/crossplane/issues/1730) for more detailed discussion on this topic.

Moreover, start from next section, I will explain how an enhanced version of Provider Kubernetes can bring more values to the provisioning and management of arbitrary Kubernetes resources, by leveraging some new features such as resource management policy and resource reference.

## Enhanced Provider Kubernetes

The enhanced Provider Kubernetes provides a couple of new features to help you manage arbitrary Kubernetes resources more effectively：

* It allows you to define fine-grained resource management policy to instruct the provider how to manage Kubernetes resources.
* It allows you to define resource references for current `Object` as dependencies to retrieve values from dependant resources at runtime and guarantee the resource rendering in a specified order.

Note: These new features are implemented in [this git repository](https://github.com/morningspace/provider-kubernetes) at the moment which is forked from [the upstream repository](https://github.com/crossplane-contrib/provider-kubernetes) in Crossplane community. It
has not been merged into the community version yet.

In order to better understand how these features can help to manage Kubernetes resources, I will use a demo project called [capabilities-shim](https://github.com/morningspace/capabilities-shim) to describe the problems that I experienced and how the enhanced provider can help to address these problems.

### About The Demo Project

The project `capabilities-shim` is aimed to demonstrate the composing of software capabilities from different applications to build user-oriented solution. It leverages the powerful Crossplane composition engine, the Provider Kubernetes, along with other cloud native install methods run at back end such as Operator Lifecycle Manager (OLM) to provision the actual workloads in a declarative way.

The project defined a couple of sample capabilities that can be installed:

* `Networking` capability to privion a Kong proxy as an API Gateway.
* `Logging` capability to provision an Elasticsearch and Kibana instance for logging storage and visualization.
* `All` capability to compose all the above capabilities as an all-in-one delivery.

![](images/architecture.png)

Please note, although the above diagram shows the capabilities are provisioned on the same cluster that runs Crossplane and Provider Kubernetes, it does not mean it can only be applied to the local cluster. The same idea should be applicable to both local and remote cluster, depending on what kubeconfig that you use to access the target cluster. Also, to let Provider Kubernetes talk to the target cluster, it is always your responsibility to feed the proper kubeconfig to Provider Kubernetes. For example, it should include the service account with properly configured RBAC.
...
![](images/failed-deleting-csv.png)

By default, the provider will delete all `Object` resources in paralell after the resource claim is deleted. This triggers the deletion of the corresponding external resources and they will be deleted in paralell too. In some cases, the `Subscription` resource can be deleted earlier than the `ClusterServiceVersion` resource. This will cause the `ClusterServiceVersion` resource failed to delete as it requires the `Subscription` resource which has already been deleted. So, the resource deletion should also follow a specific order, i.e. the uninstall order. It is usually the reverse order as opposed to the install order.

### Using Finalizers

In order to guarentee the uninstall order, the enhanced provider adds finalizer to each dependent external resource when it resolves the reference to that external resource.

In our case, when the provider resolves the resource references, the `Object` resource for the `Kong` resource has a reference to the `Object` resource for the `ClusterServiceVersion` resource, so the provider adds a finalizer to `ClusterServiceVersion`, which is the dependent resource of `Kong`. Similarly, it adds a finalizer to `Subscription` since `ClusterServiceVersion` depends on `Subscription`.

![](images/defining-dependencies-2.png)

When a managed resource and its external resource are deleted, the provider will remove the finalizers from its dependent external resources.

In our case, after all `Object` resources are deleted, the `Kong` resource will be deleted at first, so that the `Kong` pod will be deleted.

![](images/deleting-in-order-1.png)

During the time when the `Object` resource for `Kong` is deleted, it also removes the finalizer from its dependent external resource, the `ClusterServiceVersion` resource. This triggers the actual deletion of the `ClusterServiceVersion` resource, then the deletion of `InstallPlan`. As a result, the Kong operator will be deleted.

![](images/deleting-in-order-2.png)

Now that the `Object` resource for `ClusterServiceVersion` is deleted, it also removes the finalizer from its dependent external resource, the `Subscription` resource. Ultimately, all resources involved in `Networking` capability will be deleted. This leaves the cluster in a clean state after the uninstall process is completed.
