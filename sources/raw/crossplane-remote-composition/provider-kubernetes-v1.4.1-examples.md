---
resource: https://github.com/crossplane-contrib/provider-kubernetes/tree/v1.4.1/examples
fetched: 2026-11-16
fetch_note: gh api contents ?ref=v1.4.1; crossplane-contrib/provider-kubernetes@9a27a441d3f87c1fc183876c8b40ebfd3a2f027c
---

## examples/cluster/provider/config.yaml
```yaml
#apiVersion: v1
#kind: Secret
#metadata:
#  namespace: crossplane-system
#  name: example-provider-secret
#type: Opaque
#data:
  # credentials: BASE64ENCODED_PROVIDER_CREDS
---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: cluster-config
      key: kubeconfig

```
## examples/cluster/provider/config-in-cluster.yaml
```yaml
# Check ./provider-in-cluster.yaml to see how to grant permissions to the Provider
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: InjectedIdentity
```
## examples/cluster/provider/provider-config-with-aws-identity.yaml
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: cluster-config
      key: kubeconfig
  identity:
    source: InjectedIdentity
    type: AWSWebIdentityCredentials
---
apiVersion: v1
kind: Secret
metadata:
  name: cluster-config
  namespace: crossplane-system
type: Opaque
stringData:
  # The cluster name must be the actual EKS cluster name or the full ARN.
  # Examples:
  #   - name: my-cluster-name
  #   - name: arn:aws:eks:us-west-2:123456789012:cluster/my-cluster-name
  kubeconfig: |
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: LS0tLS1CRUdJTi...BASE64_ENCODED_CA...
        server: https://ABCD1234EFGH5678.gr7.us-west-2.eks.amazonaws.com
      name: eks-cluster
    contexts:
    - context:
        cluster: eks-cluster
        user: eks-user
      name: eks-context
    current-context: eks-context
    users:
    - name: eks-user
      user: {}

```
## examples/cluster/provider/provider-config-with-secret-upbound-identity.yaml
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: cluster-config
      key: kubeconfig
  identity:
    type: UpboundTokens
    source: Secret
    secretRef:
      name: upbound-credentials
      namespace: crossplane-system
      key: token

```
## examples/namespaced/object/object-watching.yaml
```yaml
# Note: This example is for the alpha feature of watching resources.
# It requires the provider to be started with the --enable-watches flag.
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: Object
metadata:
  name: foo
  namespace: default
  annotations:
    uptest.upbound.io/post-assert-hook: testhooks/validate-watching.sh
    uptest.upbound.io/timeout: "60"
spec:
  # Watch for changes to the Namespace object.
  # Watching resources is an alpha feature and needs to be enabled with --enable-watches
  # in the provider to get this configuration working.
  watch: true
  references:
  # Use patchesFrom to patch field from other k8s resource to this object
  - patchesFrom:
      apiVersion: v1
      kind: Secret
      name: bar
      namespace: default
      fieldPath: data.key
    toFieldPath: data.key-from-bar
  forProvider:
    manifest:
      apiVersion: v1
      kind: Secret
      metadata:
        namespace: default
      stringData:
        another-key: another-value
  providerConfigRef:
    kind: ClusterProviderConfig
    name: kubernetes-provider
---
apiVersion: v1
kind: Secret
metadata:
  name: bar
  namespace: default
stringData:
  key: some-value

```
## examples/namespaced/collection/collection.yaml
```yaml
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    foo: bar
  name: pod-bar
  namespace: crossplane-system
spec:
  containers:
  - image: registry.k8s.io/pause
    name: pod-bar

---
apiVersion: v1
kind: Pod
metadata:
  labels:
    foo: bar
  name: pod-foo
  namespace: crossplane-system
spec:
  containers:
  - image: registry.k8s.io/pause
    name: pod-foo

---
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ObservedObjectCollection
metadata:
  name: foo-collection
  namespace: default
spec:
  observeObjects:
    apiVersion: v1
    kind: Pod
    selector:
      matchLabels:
        foo: bar
  objectTemplate:
    metadata:
      labels:
        l1: v1
      annotations:
        a1: v1
  providerConfigRef:
    kind: ClusterProviderConfig
    name: kubernetes-provider

```
## examples/cluster/in-composition/composition.yaml lines 1-25, 115-255 (GKE cluster -> ProviderConfig -> Helm Release + Object on the new cluster)
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: argocdclusters.example.crossplane.io
spec:
  writeConnectionSecretsToNamespace: crossplane-system
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1alpha1
    kind: ArgocdCluster
  resources:
    - base:
        apiVersion: compute.gcp.crossplane.io/v1beta1
        kind: Network
        spec:
          forProvider:
            autoCreateSubnetworks: false
            routingConfig:
              routingMode: REGIONAL
    - base:
        apiVersion: container.gcp.crossplane.io/v1beta1
        kind: GKECluster
        spec:
          forProvider:
            initialClusterVersion: "1.18"
            addonsConfig:
...
              autoUpgrade: true
            maxPodsConstraint:
              maxPodsPerNode: 110
    - base:
        apiVersion: helm.crossplane.io/v1beta1
        kind: ProviderConfig
        spec:
          credentials:
            source: Secret
            secretRef:
              namespace: crossplane-system
              key: kubeconfig
      patches:
        - fromFieldPath: metadata.name
          toFieldPath: metadata.name
        # This ProviderConfig uses the above GKECluster's connection secret as
        # its credentials secret.
        - fromFieldPath: "metadata.uid"
          toFieldPath: spec.credentials.secretRef.name
          transforms:
            - type: string
              string:
                fmt: "%s-gkecluster"
      readinessChecks:
        - type: None
    - base:
        apiVersion: helm.crossplane.io/v1beta1
        kind: Release
        metadata:
          annotations: 
            crossplane.io/external-name: argocd
        spec:
          forProvider:
            chart:
              name: argo-cd
              repository: https://argoproj.github.io/argo-helm
              version: 3.8.2
            namespace: argocd
            values:
              server:
                service:
                  type: LoadBalancer
          connectionDetails:
            - apiVersion: v1
              kind: Service
              name: argocd-server
              namespace: argocd
              fieldPath: status.loadBalancer.ingress[0].ip
              toConnectionSecretKey: argocd-ip
            - apiVersion: v1
              kind: Secret
              name: argocd-initial-admin-secret
              namespace: argocd
              fieldPath: data.password
              toConnectionSecretKey: argocd-password
              skipPartOfReleaseCheck: true
          writeConnectionSecretToRef:
            namespace: crossplane-system
      patches:
        - fromFieldPath: metadata.name
          toFieldPath: spec.providerConfigRef.name
      connectionDetails:
        - fromConnectionSecretKey: argocd-ip
        - fromConnectionSecretKey: argocd-password
      patches:
        - fromFieldPath: "metadata.uid"
          toFieldPath: "spec.writeConnectionSecretToRef.name"
          transforms:
            - type: string
              string:
                fmt: "%s-argocd"
    - base:
        apiVersion: kubernetes.crossplane.io/v1beta1
        kind: ProviderConfig
        spec:
          credentials:
            source: Secret
            secretRef:
              namespace: crossplane-system
              key: kubeconfig
      patches:
        - fromFieldPath: metadata.name
          toFieldPath: metadata.name
        # This ProviderConfig uses the above GKECluster's connection secret as
        # its credentials secret.
        - fromFieldPath: "metadata.uid"
          toFieldPath: spec.credentials.secretRef.name
          transforms:
            - type: string
              string:
                fmt: "%s-gkecluster"
      readinessChecks:
        - type: None
    - base:
        apiVersion: kubernetes.crossplane.io/v1alpha2
        kind: Object
        spec:
          forProvider:
            manifest:
              apiVersion: argoproj.io/v1alpha1
              kind: Application
              metadata:
                name: guestbook
                namespace: argocd
              spec:
                project: default
                syncPolicy:
                  automated: {}
                destination:
                  namespace: argocd
                  server: https://kubernetes.default.svc
          connectionDetails:
            - apiVersion: v1
              kind: Service
              name: guestbook-ui
              namespace: argocd
              fieldPath: spec.clusterIP
              toConnectionSecretKey: host
            - apiVersion: v1
              kind: Service
              name: guestbook-ui
              namespace: argocd
              fieldPath: spec.ports[0].port
              toConnectionSecretKey: port
          writeConnectionSecretToRef:
            namespace: crossplane-system
      connectionDetails:
        - fromConnectionSecretKey: host
        - fromConnectionSecretKey: port
      patches:
        - fromFieldPath: metadata.name
          toFieldPath: spec.providerConfigRef.name
        - fromFieldPath: "spec.repoURL"
          toFieldPath: "spec.forProvider.manifest.spec.source.repoURL"
        - fromFieldPath: "spec.path"
          toFieldPath: "spec.forProvider.manifest.spec.source.path"
        - fromFieldPath: "metadata.uid"
          toFieldPath: "spec.writeConnectionSecretToRef.name"
          transforms:
            - type: string
              string:
```
