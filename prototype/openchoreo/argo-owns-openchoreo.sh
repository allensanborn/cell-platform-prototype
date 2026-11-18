#!/usr/bin/env bash
# Argo CD v3.5.7 + Gitea on the OpenChoreo k3d cluster; Argo owns a Component (autoDeploy) and its dev ReleaseBinding.
set -euo pipefail
CTX=k3d-openchoreo
k() { command kubectl --context "$CTX" "$@"; }
GPASS=oc-proto-$(date +%s)
helm upgrade --install gitea gitea-charts/gitea --version 12.6.0 -n gitea --create-namespace --kube-context "$CTX" \
  --set postgresql-ha.enabled=false --set postgresql.enabled=false --set valkey-cluster.enabled=false --set valkey.enabled=false \
  --set gitea.config.database.DB_TYPE=sqlite3 --set gitea.config.session.PROVIDER=memory --set gitea.config.cache.ADAPTER=memory --set gitea.config.queue.TYPE=level \
  --set gitea.admin.username=oc --set gitea.admin.password="$GPASS" --set gitea.admin.email=oc@example.test \
  --set persistence.enabled=false --wait --timeout 10m
k create ns argocd --dry-run=client -o yaml | k apply -f -
k apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.7/manifests/install.yaml >/dev/null
k -n argocd rollout status deploy/argocd-repo-server --timeout=10m
k -n argocd rollout status statefulset/argocd-application-controller --timeout=10m

REL=$(k -n default get releasebinding echo-websocket-service-development -o jsonpath='{.spec.releaseName}')
# Seed a public repo with the Component, Workload and dev ReleaseBinding as they exist now.
k -n gitea delete pod seed --ignore-not-found >/dev/null
k -n gitea run seed --restart=Never --image=alpine/git:2.47.2 --env=GPASS="$GPASS" --env=REL="$REL" --command -- sh -ec '
  apk add -q curl >/dev/null 2>&1 || true
  curl -s -u "oc:$GPASS" -H "Content-Type: application/json" -X POST http://gitea-http.gitea:3000/api/v1/user/repos -d "{\"name\":\"apps\",\"private\":false,\"default_branch\":\"main\"}" >/dev/null
  mkdir /w && cd /w && git init -q -b main && git config user.email oc@example.test && git config user.name oc
  cat > echo.yaml <<EOF
apiVersion: openchoreo.dev/v1alpha1
kind: Component
metadata: {name: echo-websocket-service, namespace: default}
spec:
  owner: {projectName: default}
  autoDeploy: true
  componentType: {kind: ClusterComponentType, name: deployment/service}
---
apiVersion: openchoreo.dev/v1alpha1
kind: Workload
metadata: {name: echo-websocket-service-workload, namespace: default}
spec:
  owner: {componentName: echo-websocket-service, projectName: default}
  endpoints: {websocket: {type: Websocket, port: 8080, visibility: [external]}}
  container: {image: "jmalloc/echo-server:latest", env: [{key: PORT, value: "8080"}]}
---
apiVersion: openchoreo.dev/v1alpha1
kind: ReleaseBinding
metadata: {name: echo-websocket-service-development, namespace: default}
spec:
  environment: development
  owner: {componentName: echo-websocket-service, projectName: default}
  releaseName: $REL
  state: Active
EOF
  git add . && git commit -qm seed && git push -q "http://oc:$GPASS@gitea-http.gitea:3000/oc/apps.git" main
  echo SEEDED'
k -n gitea wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed --timeout=180s
k -n gitea logs seed | tail -1
k apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: {name: echo, namespace: argocd}
spec:
  project: default
  source: {repoURL: http://gitea-http.gitea:3000/oc/apps.git, targetRevision: main, path: .}
  destination: {server: https://kubernetes.default.svc, namespace: default}
  syncPolicy: {automated: {prune: true, selfHeal: true}}
EOF
echo "pinned dev release in Git: $REL"
