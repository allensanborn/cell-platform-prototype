---
resource: https://github.com/crossplane-contrib/provider-kubernetes/tree/v1.4.1/package/crds
fetched: 2026-11-16
fetch_note: gh api contents ?ref=v1.4.1 package/crds/*.yaml, field descriptions extracted with python yaml (descriptions truncated at 300 chars); crossplane-contrib/provider-kubernetes@9a27a441d3f87c1fc183876c8b40ebfd3a2f027c
---

```text
===== kubernetes.m.crossplane.io_providerconfigs.yaml scope: Namespaced storage version: v1alpha1
spec.credentials   | Credentials used to connect to the Kubernetes API. Typically a kubeconfig file. Use InjectedIdentity for in-cluster config.
spec.credentials.env   | Env is a reference to an environment variable that contains credentials that must be used to connect to the provider.
spec.credentials.fs   | Fs is a reference to a filesystem location that contains credentials that must be used to connect to the provider.
spec.credentials.secretRef   | A SecretRef is a reference to a secret key that contains the credentials that must be used to connect to the provider.
spec.credentials.source enum=['None', 'Secret', 'InjectedIdentity', 'Environment', 'Filesystem']  | Source of the provider credentials.
spec.identity   | Identity used to authenticate to the Kubernetes API. The identity credentials can be used to supplement kubeconfig 'credentials', for example by configuring a bearer token source such as OAuth.
spec.identity.env   | Env is a reference to an environment variable that contains credentials that must be used to connect to the provider.
spec.identity.fs   | Fs is a reference to a filesystem location that contains credentials that must be used to connect to the provider.
spec.identity.secretRef   | A SecretRef is a reference to a secret key that contains the credentials that must be used to connect to the provider.
spec.identity.source enum=['None', 'Secret', 'InjectedIdentity', 'Environment', 'Filesystem']  | Source of the provider credentials.
spec.identity.type enum=['GoogleApplicationCredentials', 'AzureServicePrincipalCredentials', 'AzureWorkloadIdentityCredentials', 'UpboundTokens', 'AWSWebIdentityCredentials', 'NebiusServiceAccountCredentials']  | Type of identity.
===== kubernetes.m.crossplane.io_clusterproviderconfigs.yaml scope: Cluster storage version: v1alpha1
spec.credentials   | Credentials used to connect to the Kubernetes API. Typically a kubeconfig file. Use InjectedIdentity for in-cluster config.
spec.credentials.env   | Env is a reference to an environment variable that contains credentials that must be used to connect to the provider.
spec.credentials.fs   | Fs is a reference to a filesystem location that contains credentials that must be used to connect to the provider.
spec.credentials.secretRef   | A SecretRef is a reference to a secret key that contains the credentials that must be used to connect to the provider.
spec.credentials.source enum=['None', 'Secret', 'InjectedIdentity', 'Environment', 'Filesystem']  | Source of the provider credentials.
spec.identity   | Identity used to authenticate to the Kubernetes API. The identity credentials can be used to supplement kubeconfig 'credentials', for example by configuring a bearer token source such as OAuth.
spec.identity.env   | Env is a reference to an environment variable that contains credentials that must be used to connect to the provider.
spec.identity.fs   | Fs is a reference to a filesystem location that contains credentials that must be used to connect to the provider.
spec.identity.secretRef   | A SecretRef is a reference to a secret key that contains the credentials that must be used to connect to the provider.
spec.identity.source enum=['None', 'Secret', 'InjectedIdentity', 'Environment', 'Filesystem']  | Source of the provider credentials.
spec.identity.type enum=['GoogleApplicationCredentials', 'AzureServicePrincipalCredentials', 'AzureWorkloadIdentityCredentials', 'UpboundTokens', 'AWSWebIdentityCredentials', 'NebiusServiceAccountCredentials']  | Type of identity.
===== kubernetes.m.crossplane.io_objects.yaml scope: Namespaced storage version: v1alpha1
spec.connectionDetails   | 
spec.forProvider   | ObjectParameters are the configurable fields of a Object.
spec.forProvider.deletionPropagationPolicy enum=['Orphan', 'Background', 'Foreground'] default=Background | Deletion policy for created kubernetes object, defaults to Background
spec.forProvider.manifest   | Raw JSON representation of the kubernetes object to be created.
spec.managementPolicies  default=['*'] | THIS IS A BETA FIELD. It is on by default but can be opted out through a Crossplane feature flag. ManagementPolicies specify the array of actions Crossplane is allowed to take on the managed and external resources. See the design doc for more information: https://github.com/crossplane/crossplane/blo
spec.providerConfigRef  default={'kind': 'ClusterProviderConfig', 'name': 'default'} | ProviderConfigReference specifies how the provider that will be used to create, observe, update, and delete this managed resource should be configured.
spec.providerConfigRef.kind   | Kind of the referenced object.
spec.providerConfigRef.name   | Name of the referenced object.
spec.readiness   | Readiness defines how the object's readiness condition should be computed, if not specified it will be considered ready as soon as the underlying external resource is considered up-to-date.
spec.readiness.celQuery   | CelQuery defines a cel query to evaluate the readiness. The observed object is passed to the cel query with the word `object`. Cel macros are available to be used, see https://github.com/google/cel-spec/blob/master/doc/langdef.md#macros for more information. Examples:  `object.status.isReady == true
spec.readiness.policy enum=['SuccessfulCreate', 'DeriveFromObject', 'AllTrue', 'DeriveFromCelQuery'] default=SuccessfulCreate | Policy defines how the Object's readiness condition should be computed.
spec.references   | 
spec.watch  default=False | Watch enables watching the referenced or managed kubernetes resources.  THIS IS AN ALPHA FIELD. Do not use it in production. It is not honored unless "watches" feature gate is enabled, and may be changed or removed without notice.
spec.writeConnectionSecretToRef   | WriteConnectionSecretToReference specifies the namespace and name of a Secret to which any connection details for this managed resource should be written. Connection details frequently include the endpoint, username, and password required to connect to the managed resource.
spec.writeConnectionSecretToRef.name   | Name of the secret.
===== kubernetes.crossplane.io_objects.yaml scope: Cluster storage version: v1alpha2
spec.connectionDetails   | 
spec.deletionPolicy enum=['Orphan', 'Delete'] default=Delete | DeletionPolicy specifies what will happen to the underlying external when this managed resource is deleted - either "Delete" or "Orphan" the external resource. This field is planned to be deprecated in favor of the ManagementPolicies field in a future release. Currently, both could be set independen
spec.forProvider   | ObjectParameters are the configurable fields of a Object.
spec.forProvider.deletionPropagationPolicy enum=['Orphan', 'Background', 'Foreground'] default=Background | Deletion policy for created kubernetes object, defaults to Background
spec.forProvider.manifest   | Raw JSON representation of the kubernetes object to be created.
spec.managementPolicies  default=['*'] | THIS IS A BETA FIELD. It is on by default but can be opted out through a Crossplane feature flag. ManagementPolicies specify the array of actions Crossplane is allowed to take on the managed and external resources. This field is planned to replace the DeletionPolicy field in a future release. Curren
spec.providerConfigRef  default={'name': 'default'} | ProviderConfigReference specifies how the provider that will be used to create, observe, update, and delete this managed resource should be configured.
spec.providerConfigRef.name   | Name of the referenced object.
spec.providerConfigRef.policy   | Policies for referencing.
spec.readiness   | Readiness defines how the object's readiness condition should be computed, if not specified it will be considered ready as soon as the underlying external resource is considered up-to-date.
spec.readiness.celQuery   | CelQuery defines a cel query to evaluate the readiness. The observed object is passed to the cel query with the word `object`. Cel macros are available to be used, see https://github.com/google/cel-spec/blob/master/doc/langdef.md#macros for more information. Examples:  `object.status.isReady == true
spec.readiness.policy enum=['SuccessfulCreate', 'DeriveFromObject', 'AllTrue', 'DeriveFromCelQuery'] default=SuccessfulCreate | Policy defines how the Object's readiness condition should be computed.
spec.references   | 
spec.watch  default=False | Watch enables watching the referenced or managed kubernetes resources.  THIS IS AN ALPHA FIELD. Do not use it in production. It is not honored unless "watches" feature gate is enabled, and may be changed or removed without notice.
spec.writeConnectionSecretToRef   | WriteConnectionSecretToReference specifies the namespace and name of a Secret to which any connection details for this managed resource should be written. Connection details frequently include the endpoint, username, and password required to connect to the managed resource.
spec.writeConnectionSecretToRef.name   | Name of the secret.
spec.writeConnectionSecretToRef.namespace   | Namespace of the secret.
```
