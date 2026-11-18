#!/usr/bin/env bash
# Gitea (sqlite, no HA) as a Git state store + Argo CD as the GitOps agent for a second Kratix Destination.
set -euo pipefail
cd "$(dirname "$0")"
GPASS=kratix-proto-$(date +%s)
helm upgrade --install gitea gitea-charts/gitea --version 12.6.0 -n gitea --create-namespace \
  --set postgresql-ha.enabled=false --set postgresql.enabled=false --set valkey-cluster.enabled=false --set valkey.enabled=false \
  --set gitea.config.database.DB_TYPE=sqlite3 --set gitea.config.session.PROVIDER=memory --set gitea.config.cache.ADAPTER=memory --set gitea.config.queue.TYPE=level \
  --set gitea.admin.username=kratix --set gitea.admin.password="$GPASS" --set gitea.admin.email=kratix@example.test \
  --set persistence.enabled=false --wait --timeout 10m
kubectl -n gitea run mkrepo --rm -i --restart=Never --image=curlimages/curl:8.11.1 -- \
  curl -s -u "kratix:$GPASS" -H 'Content-Type: application/json' -X POST http://gitea-http.gitea:3000/api/v1/user/repos \
  -d '{"name":"kratix","auto_init":true,"default_branch":"main"}' >/dev/null
kubectl -n default create secret generic gitea-creds --from-literal=username=kratix --from-literal=password="$GPASS" --dry-run=client -o yaml | kubectl apply -f -

kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.7/manifests/install.yaml >/dev/null
kubectl -n argocd rollout status deploy/argocd-repo-server deploy/argocd-server --timeout=10m
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=10m

kubectl apply -f - <<EOF
apiVersion: platform.kratix.io/v1alpha1
kind: GitStateStore
metadata: {name: gitea}
spec:
  url: http://gitea-http.gitea:3000/kratix/kratix.git
  branch: main
  authMethod: basicAuth
  secretRef: {name: gitea-creds, namespace: default}
---
apiVersion: platform.kratix.io/v1alpha1
kind: Destination
metadata:
  name: argo-worker
  labels: {gitops: argo}
spec:
  path: argo-worker
  stateStoreRef: {name: gitea, kind: GitStateStore}
---
apiVersion: v1
kind: Secret
metadata:
  name: gitea-repo
  namespace: argocd
  labels: {argocd.argoproj.io/secret-type: repository}
stringData: {type: git, url: http://gitea-http.gitea:3000/kratix/kratix.git, username: kratix, password: "$GPASS"}
EOF
# Applications exactly as the Kratix Argo CD guide recommends: two, automated, no ordering.
for part in dependencies resources; do
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: {name: kratix-workload-$part, namespace: argocd}
spec:
  project: default
  source: {repoURL: http://gitea-http.gitea:3000/kratix/kratix.git, targetRevision: main, path: argo-worker/$part, directory: {recurse: true}}
  destination: {server: https://kubernetes.default.svc, namespace: default}
  syncPolicy: {automated: {prune: true, selfHeal: true}}
EOF
done
echo "ARGO OK"
