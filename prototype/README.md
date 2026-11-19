# Cell prototype (2026-11-16)


Manifests and scripts behind [prototype-results](../docs/prototype-results.md) and [recommendation](../docs/recommendation.md). Local experiments only; nothing here is production-shaped.

## kind/ — Kratix + Istio ambient + Cilium (`kind-cellproto`)

1. `up.sh` builds the cluster: kind, Cilium 1.20.4, Istio 1.32.0 ambient (Helm repo `blob.istio.io`), Gateway API v1.5.0, cert-manager, Kratix `latest` with MinIO + Flux.
2. `kubectl apply -f cell-promise.yaml`, wait for the `cells.platform.example.org` CRD, then `kubectl apply -f cells.yaml`.
3. `./test.sh setup` deploys echo + curl workloads; `./test.sh` runs the west/east matrix.
4. Cilium ClusterNetworkPolicy: `helm upgrade cilium … --reuse-values --set k8sClusterNetworkPolicy.enabled=true`, apply the network-policy-api `release-0.2` CRD, then `kcnp-admin-deny.yaml`.
5. North/south: `platform-ns.yaml`, then `cell-promise-v2.yaml`, `kubectl patch cell a --type merge -p '{"spec":{"hostname":"a.example.test"}}'`, then `./test-ns.sh`.
6. Release train: `cell-promise-edit.yaml` / `cell-promise-v2-edit.yaml` (same version, changed template) and `cell-promise-v3.yaml` (bump).
7. Argo CD: `argo.sh` (Gitea + Argo CD v3.5.7 + `argo-worker` Destination). The GitStateStore was then switched to SSH by hand: generate a key, register it in Gitea, `ssh-keyscan -p 2222 gitea-ssh.gitea`, and store `sshPrivateKey` and `knownHosts` in a Secret. Ordering probe: `widget-promise.yaml`, `widget2-promise.yaml`.

## openchoreo/ — OpenChoreo v1.3.3 (`k3d-openchoreo`)

Installed with `install/k3d/k3d-install.sh` from an `openchoreo/openchoreo` v1.3.3 checkout. `cct-service.yaml` is the shipped `service` ClusterComponentType; `-v2` and `-v3` add an annotation. Use the `samples/from-image/echo-websocket-service` Component.

## radius/ — Radius v0.62.0 (in `kind-cellproto`)

`rad install kubernetes --kubecontext kind-cellproto --skip-contour-install`. `vap.yaml` is the deny-all ValidatingAdmissionPolicy; edit its `apiGroups` to probe `api.ucp.dev`, `ucp.dev` or a control CRD group.

Rendered objects: `rad initialize` needs a TTY, so set up by hand. Run `rad group create default`, then `rad bicep download`, then `rad deploy` of the community `kubernetes` recipe pack (`radius/recipepack-default.bicep`, from `radius-project/resource-types-contrib` main@9073ec4adf71). Create the namespace `radprobe`, then `rad env create radprobe --kubernetes-namespace radprobe --recipe-packs default`. Finally run `rad deploy app.bicep` with and without `vap-rendered.yaml`. Keep `bicepconfig.json` beside `app.bicep`. Run every `rad` command with `HOME` pointed at a scratch dir so `~/.rad` isn't touched.

## kind/kgateway-egress-credential.yaml

kgateway v2.5.2 (`oci://cr.kgateway.dev/kgateway-dev/charts/kgateway{-crds}`) egress Gateway with a Static Backend for `httpbin.org` and a TrafficPolicy that sets `X-Api-Key` from a Secret. Test it with `curl -H 'Host: api.httpbin.test' http://egress.kgw-egress:8080/headers`.

## Round 3

- `kind/kcnp-admin-deny-v1beta1.yaml`: run it after applying the network-policy-api v0.3.0 standard CRD (`config/crd/standard/policy.networking.k8s.io_clusternetworkpolicies.yaml` at tag v0.3.0) over `release-0.2`.
- REGISTRY_ONLY: `helm upgrade istiod … --reuse-values --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY`. Use an ambient namespace and a sidecar-injected namespace (`istio-injection=enabled`) with curl clients, and set it back to `ALLOW_ANY` afterwards.
- `openchoreo/argo-owns-openchoreo.sh`: Gitea + Argo CD v3.5.7 on `k3d-openchoreo`, with Argo owning the Component, Workload and dev ReleaseBinding. Then apply `cct-service-v4.yaml` and watch the binding (`results/oc-argo-fight.txt`). The fix: `ignoreDifferences` on `/spec/releaseName` + `RespectIgnoreDifferences=true`, then `cct-service-v5.yaml`.
- `kind/argo-diff-vs-mutation.sh`: Gatekeeper 3.22.2 (`helm … gatekeeper/gatekeeper --version 3.22.2`) `Assign` mutators, against two Argo apps (default diff vs `ServerSideDiff=true`) over a Gitea repo `kratix/apps`.

## Round 4

- `kind/ccnp-east-cell-b.yaml`: cell-b's east fence as a CiliumClusterwideNetworkPolicy. Suspend the Kratix Flux Kustomization, delete cell-b's namespaced `east-allowlist`, then run `test.sh`. RBAC check: `kubectl auth can-i delete … --as=system:serviceaccount:cell-b:tenant-b` with `admin` bound in `cell-b`.
- `kind/crossplane-xcell.yaml` (+ `-r2`, `-r3`): Crossplane 2.4.2 (`helm … crossplane-stable/crossplane --version 2.4.2`) with the function `xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.13.1`. Create XCells `p` (default), `q` (`compositionUpdatePolicy: Manual`) and `s` (`compositionRevisionSelector: {matchLabels: {channel: stable}}`), then apply r2 (`channel: dev`) and r3 (`channel: stable`).

## Round 6: per-team accounts on floci

- Start a dedicated floci: `docker run -d --name xp-floci -p 127.0.0.1:4590:4566 -v /var/run/docker.sock:/var/run/docker.sock -e FLOCI_BASE_URL=http://localhost:4590 -e FLOCI_DOCKER_RESOURCE_NAMESPACE=xp floci/floci:2.5.0`, then `docker network connect kind xp-floci`. Access key `111111111111` is team-a's account and `222222222222` is team-b's.
- `kind/crossplane-team-database.yaml`: installs provider-aws-rds v2.8.1, function-go-templating v0.13.1 and function-auto-ready v0.6.0, and creates a `Database orders` in each team namespace. Replace `FLOCI_URL` with `http://<xp-floci kind IP>:4566` and apply it twice (the Databases need the XRD first).
- `kind/opentofu-team-workspaces.yaml`: provider-opentofu v1.1.10. Both modules come from the public registry, so no Gitea is needed: `cloudposse/dynamodb/aws` 0.37.0 and `terraform-aws-modules/rds/aws` 6.13.1 (7.x needs OpenTofu >= 1.11.1; the provider bundles 1.10.0). Same `FLOCI_URL` substitution. Apply `kind/provider-egress-fence.yaml` first; its second policy fences provider-opentofu to floci plus the registry and GitHub release hosts.
- Verify with `AWS_ENDPOINT_URL=http://localhost:4590 AWS_ACCESS_KEY_ID=<team key> aws rds describe-db-instances` / `aws dynamodb list-tables`.

## Round 7: Argo CD XR health and cross-account IAM

- `hub/argocd-xr-health.yaml`: `kubectl -n argocd patch cm argocd-cm --type merge --patch-file hub/argocd-xr-health.yaml`, then hard-refresh the apps.
- **Fence first:** `kind/provider-egress-fence.yaml` (substitute each floci IP/32). provider-aws-rds sends `assumeRoleChain` STS calls to real AWS unless redirected.
- Enforcing floci: `docker run -d --name xp-floci-iam -p 127.0.0.1:4591:4566 -v /var/run/docker.sock:/var/run/docker.sock -e FLOCI_BASE_URL=http://localhost:4591 -e FLOCI_DOCKER_RESOURCE_NAMESPACE=xpiam -e FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true floci/floci:2.5.0`, then `docker network connect kind xp-floci-iam`. Create the role `crossplane-provisioner` in 111111111111 with `kind/iam/trust-platform-account.json` as its trust policy and `kind/iam/role-policy-rds-all.json` inline.
- `kind/provider-sts-endpoint.yaml` (DeploymentRuntimeConfig with `AWS_ENDPOINT_URL_STS`), then `kind/crossplane-team-assume-role.yaml`. `iam-a` should provision into 111111111111; `iam-b`, using an untrusted key, should get AccessDenied.
- Scoping: `aws iam put-role-policy --role-name crossplane-provisioner --policy-name rds --policy-document file://kind/iam/role-policy-rds-describe-only.json` in 111111111111, then create a new Database in `iam-a`: expect `rds:CreateDBInstance` AccessDenied. Delete it before restoring `rds:*`.

## hub/ — Argo CD hub ships XCells to two clusters (round 5)

1. Install Crossplane 2.4.2 and function-go-templating on `k3d-openchoreo`.
2. Run `docker network connect kind k3d-openchoreo-server-0`, create an `argocd-manager` ServiceAccount token there, and register it in cellproto's Argo CD as a cluster Secret (`env: prod`, `insecure: true`).
3. Start the helper pod `gitwork` (alpine/git) in `gitea`, create the repo `kratix/cells`, and run `./push.sh "<msg>"` to push `repo/`.
4. Apply `appset.yaml` with `SERVER_PROD` set to the k3d server's kind-network IP. `./show.sh` prints revisions, hub1's revision and the rendered template per cluster.
5. Edit `repo/platform/xcell-np.yaml` (template h1 → h2, `channel` label dev → stable) and push after each edit.

## results/

Raw outputs: `run1.txt` (west/east), `control.txt` (fences removed), `run2.txt` (restored), `run-kcnp.txt` (Admin deny), `run-ns1.txt` (north/south), `argo-order.txt` (Argo CD happy path), `radius-deploy-under-policy.txt` (rendered Deployment denied, then deployed), `oc-argo-fight.txt` (Argo vs autoDeploy), `hub-channels.txt` (round 5).

Left out on purpose: the Gitea SSH key, a script with the generated Gitea password in it, and install logs.
