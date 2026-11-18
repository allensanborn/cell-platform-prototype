---
resource: https://github.com/crossplane-contrib/provider-kubernetes/tree/v1.4.1
fetched: 2026-11-16
fetch_note: gh api contents ?ref=v1.4.1; crossplane-contrib/provider-kubernetes@9a27a441d3f87c1fc183876c8b40ebfd3a2f027c (tag v1.4.1, released 2026-10-08)
---

# README.md (v1.4.1) - verbatim

# provider-kubernetes

`provider-kubernetes` is a Crossplane Provider that enables deployment and management
of arbitrary Kubernetes objects on clusters typically provisioned by Crossplane:

- A `Provider` resource type that only points to a credentials `Secret`.
- An `Object` resource type that is to manage Kubernetes Objects.
- A managed resource controller that reconciles `Object` typed resources and manages arbitrary Kubernetes Objects.

## Install

If you would like to install `provider-kubernetes` without modifications, you may do
so using the Crossplane CLI in a Kubernetes cluster where Crossplane is
installed:

```console
crossplane xpkg install provider xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0
```

You may also manually install `provider-kubernetes` by creating a `Provider` directly:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0
```

## Target cluster clients

The provider builds one client per distinct ProviderConfig credential set
(kubeconfig plus identity) and keeps it in an LRU cache. Building a client is
expensive because its REST mapper primes itself with full aggregated discovery
on first use, so the cache has to hold every credential set the provider talks
to. Once the credential sets in use outnumber the bound, every new client
evicts the least recently used one, whose next reconcile rebuilds it (discovery
included) and evicts another: the whole cache churns, not only the credential
set that did not fit.

At startup the provider sizes the cache from the cluster: it lists its
`ProviderConfig` and `ClusterProviderConfig` objects, derives the cache key of
each one the way the client builder does (so ProviderConfigs sharing a
kubeconfig count once, and every in-cluster ProviderConfig counts as one), and
bounds the cache at the number of distinct credential sets plus headroom of
ten percent or four entries, whichever is larger, for credentials that rotate
and ProviderConfigs created later, never below 8. The result is logged at
startup. The provider does not start if its ProviderConfigs and their
credentials cannot be read within 300 seconds. When the provider runs outside a
cluster, as in local development, ProviderConfigs with an in-cluster identity
cannot be resolved and each counts as a credential set of its own, so the
cache is merely oversized.

The bound is fixed for the lifetime of the process, so ProviderConfigs created
after startup share the headroom until the next restart. The cache reports
`provider_kubernetes_client_cache_size` (the bound),
`provider_kubernetes_client_cache_entries` (clients currently cached) and
`provider_kubernetes_client_cache_events_total` with an `event` label of
`hit`, `miss` or `evict`; a sustained eviction rate means the credential sets
in use no longer fit the bound and the cache is churning.

Client-side rate limiting is disabled for these clients. A cached client is
shared by every concurrent reconcile of its credential set, so client-go's
per-client token bucket (5 QPS, burst 10) would serialize them. This applies to
everything built from the same configuration: the reconcile client, the watch
informers and the server-side apply discovery client. Load on the target
cluster is bounded by `--max-reconcile-rate` on the provider side and by API
Priority and Fairness on the API server.

## Known limitations

### Write-only fields cannot be reconciled

Some Kubernetes fields are "write-only": the API server accepts them but
transforms or drops them on write, so they never appear when the resource is
read back. The canonical example is `Secret.stringData`, which the API server
merges into `data` without ever storing `stringData` itself.

The provider cannot correctly reconcile such fields in an `Object` manifest
(see the analysis in
[#420](https://github.com/crossplane-contrib/provider-kubernetes/issues/420)):

- With server-side apply (the default since v1.2.0), drift detection compares
  the fields owned by the provider's field manager on the observed resource
  against the result of a dry-run apply of the manifest. A write-only field
  appears in neither, so changing e.g. `stringData` in the manifest after
  creation produces no diff and is never applied to the cluster. The provider
  has no way of knowing that `data` is the server-side transformation of
  `stringData`.
- If the provider's field manager owns *only* fields that are absent from the
  observed resource — a `Secret` whose manifest sets only `stringData`
  ([#420](https://github.com/crossplane-contrib/provider-kubernetes/issues/420)),
  or one created with an empty `data`
  ([#418](https://github.com/crossplane-contrib/provider-kubernetes/issues/418)) —
  the managed-fields extraction fails with `ExtractInto ... expected map, got
  <nil>` and the `Object` gets stuck with `Synced: False` in `ReconcileError`.

Prefer round-trippable fields in `Object` manifests: for `Secret`s, set
base64-encoded values in `data` instead of using `stringData`.

## Developing locally

See the header of [`go.mod`](./go.mod) for the minimum supported version of Go.

Start a local development environment with Kind where `crossplane` is installed:

```
make
make local-dev
```

Now you can either run the controller locally or in-cluster.

### Running locally

Run controller locally against the cluster:

```
make run
```

Since the controller is running outside the Kind cluster, you need to make the
API server accessible to the controller. You can do this by running a proxy:

```
# on a separate terminal
sudo kubectl proxy --port=8081
```

See [below](#required-configuration) for how to properly setup the RBAC for the
locally running controller.

### Running in-cluster

Run controller in-cluster:

```
make local-deploy
```

See [below](#required-configuration) for how to properly setup the RBAC for the
locally running controller.

### Required configuration

1. Prepare provider config for the local cluster:
  1. If provider kubernetes running in the cluster (e.g. provider installed with crossplane or using `make local-deploy`):

      ```
      SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
      kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
      kubectl apply -f examples/namespaced/provider/config-in-cluster.yaml
      ```
  1. If provider kubernetes running outside the cluster (e.g. running locally with `make run`)

      ```
      KUBECONFIG=$(kind get kubeconfig --name local-dev | sed -e 's|server:\s*.*$|server: http://localhost:8081|g')
      kubectl -n crossplane-system create secret generic cluster-config --from-literal=kubeconfig="${KUBECONFIG}"
      kubectl apply -f examples/namespaced/provider/config.yaml
      ```

1. Now you can create `Object` resources with provider reference, see [sample object.yaml](examples/namespaced/object/object.yaml).

    ```
    kubectl create -f examples/namespaced/object/object.yaml
    ```

### Cleanup

To delete the local kind cluster:

```
make controlplane.down
```

# cmd/provider/main.go lines 92-113 - verbatim
```go
		app                     = kingpin.New(filepath.Base(os.Args[0]), "Template support for Crossplane.").DefaultEnvars()
		debug                   = app.Flag("debug", "Run with debug logging.").Short('d').Bool()
		syncInterval            = app.Flag("sync", "Controller manager sync period such as 300ms, 1.5h, or 2h45m").Short('s').Default("1h").Duration()
		pollInterval            = app.Flag("poll", "Poll interval controls how often an individual resource should be checked for drift.").Default("10m").Duration()
		pollStateMetricInterval = app.Flag("poll-state-metric", "State metric recording interval").Default("5s").Duration()
		pollJitterPercentage    = app.Flag("poll-jitter-percentage", "Percentage of jitter to apply to poll interval. It cannot be negative, and must be less than 100.").Default("10").Uint()
		leaderElection          = app.Flag("leader-election", "Use leader election for the controller manager.").Short('l').Default("false").Envar("LEADER_ELECTION").Bool()
		maxReconcileRate        = app.Flag("max-reconcile-rate", "The number of concurrent reconciliations that may be running at one time.").Default("100").Int()
		sanitizeSecrets         = app.Flag("sanitize-secrets", "when enabled, redacts Secret data from Object status").Default("false").Envar("SANITIZE_SECRETS").Bool()
		webhookPort             = app.Flag("webhook-port", "The port the webhook server listens on.").Default("9443").Envar("WEBHOOK_PORT").Int()
		metricsBindAddress      = app.Flag("metrics-bind-address", "The address the metrics server listens on").Default(":8080").Envar("METRICS_BIND_ADDRESS").String()
		healthProbeBindAddress  = app.Flag("health-probe-bind-addr", "The address the health/readiness probe server listens on").Default(":8081").Envar("HEALTH_PROBE_BIND_ADDRESS").String()
		changelogsSocketPath    = app.Flag("changelogs-socket-path", "Path for changelogs socket (if enabled)").Default("/var/run/changelogs/changelogs.sock").Envar("CHANGELOGS_SOCKET_PATH").String()

		enableManagementPolicies = app.Flag("enable-management-policies", "Enable support for Management Policies.").Default("true").Envar("ENABLE_MANAGEMENT_POLICIES").Bool()
		enableWatches            = app.Flag("enable-watches", "Enable support for watching resources.").Default("true").Envar("ENABLE_WATCHES").Bool()
		enableServerSideApply    = app.Flag("enable-server-side-apply", "Enable server side apply to sync object manifests to k8s API.").Default("true").Envar("ENABLE_SERVER_SIDE_APPLY").Bool()
		enableChangeLogs         = app.Flag("enable-changelogs", "Enable support for capturing change logs during reconciliation.").Default("false").Envar("ENABLE_CHANGE_LOGS").Bool()
		removeManagedFields      = app.Flag("remove-managed-fields", "Remove metadata.managedFields from status.atProvider.manifest.").Default("false").Envar("REMOVE_MANAGED_FIELDS").Bool()
		// Additional legacy field managers to upgrade to Server-side apply field manager
		legacyCSAFieldManagers = app.Flag("legacy-csa-field-managers", "Additional legacy client-side apply Kubernetes field manager names for upgrading to SSA field manager").Default().Strings()
		enableSecretCache      = app.Flag("enable-secret-cache", "Enable caching of Secret objects. When true, Secrets are served from the informer cache instead of direct API calls. This reduces API server load but increases memory usage.").Default("true").Envar("ENABLE_SECRET_CACHE").Bool()
	if *enableWatches {
		o.Features.Enable(features.EnableBetaWatches)
		log.Info("Beta feature enabled", "flag", features.EnableBetaWatches)
	}
```
# internal/controller/namespaced/object/object.go lines 165-177, 400-412 - verbatim
```go
	reconcilerOptions := []managed.ReconcilerOption{
		managed.WithFinalizer(&objFinalizer{client: mgr.GetClient()}),
		managed.WithPollInterval(o.PollInterval),
		managed.WithPollIntervalHook(func(mg resource.Managed, pollInterval time.Duration) time.Duration {
			if mg.GetCondition(xpv2.TypeReady).Status != v1.ConditionTrue {
				// If the resource is not ready, we should poll more frequently not to delay time to readiness.
				pollInterval = 30 * time.Second
			}
			pollJitter := time.Duration(float64(pollInterval) * (float64(pollJitterPercentage) / 100.0))
			// This is the same as runtime default poll interval with jitter, see:
			// https://github.com/crossplane/crossplane-runtime/blob/7fcb8c5cad6fc4abb6649813b92ab92e1832d368/pkg/reconciler/managed/reconciler.go#L573
			return pollInterval + time.Duration((rand.Float64()-0.5)*2*float64(pollJitter)) //nolint G404 // No need for secure randomness
		}),
...
	if c.shouldWatch(obj) {
		c.kindObserver.WatchResources(c.rest, providerConfigRefKey(obj), manifest.GroupVersionKind())
	}

	current := manifest.DeepCopy()
	err = c.client.Get(ctx, types.NamespacedName{
		Namespace: current.GetNamespace(),
		Name:      current.GetName(),
	}, current)

	if kerrors.IsNotFound(err) {
		return managed.ExternalObservation{ResourceExists: false}, nil
	}
...
	errAddFinalizer             = "cannot add finalizer to Object"
	errRemoveFinalizer          = "cannot remove finalizer from Object"
	errAddReferenceFinalizer    = "cannot add finalizer to referenced resource"
	errRemoveReferenceFinalizer = "cannot remove finalizer from referenced resource"
	objFinalizerName            = "finalizer.managedresource.crossplane.io"
	refFinalizerNamePrefix      = "kubernetes.crossplane.io/referred-by-object-"
```
# internal/controller/namespaced/object/informers.go lines 44-50, 104-112 - verbatim
```go
// resourceInformers manages resource informers referenced or managed
// by Objects. It serves as an event source for realtime notifications of
// changed resources, with the Object reconcilers as sinks.
// It keeps resource informers alive as long as there are Objects referencing
// them. In parallel, the Object reconcilers keep track of references to
// resources, and inform resourceInformers about them via the
// WatchReferencedResources method.
// WatchResources starts informers for the given resource GVKs for the given
// cluster (i.e. rest.Config & providerConfig).
// The is wired into the Object reconciler, which will call this method on
// every reconcile to make resourceInformers aware of the referenced or managed
// resources of the given Object.
//
// Note that this complements cleanupResourceInformers which regularly
// garbage collects resource informers that are no longer referenced by
// any Object.
```
