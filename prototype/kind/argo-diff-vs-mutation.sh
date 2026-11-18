#!/usr/bin/env bash
# Gatekeeper mutation vs Argo CD diff modes (kind-cellproto, Argo CD v3.5.7, Gatekeeper 3.22.2, Gitea repo kratix/apps).
set -euo pipefail
CTX=kind-cellproto
k() { command kubectl --context "$CTX" "$@"; }
GPASS=$(k -n default get secret gitea-creds -o jsonpath='{.data.password}' | base64 -d)

k apply -f - <<'EOF'
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata: {name: force-pull-always}
spec:
  applyTo: [{groups: [apps], kinds: [Deployment], versions: [v1]}]
  match: {namespaces: [mut-default, mut-ssd], labelSelector: {matchLabels: {probe: conflict}}}
  location: "spec.template.spec.containers[name:*].imagePullPolicy"
  parameters: {assign: {value: Always}}
---
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata: {name: add-no-priv-esc}
spec:
  applyTo: [{groups: [apps], kinds: [Deployment], versions: [v1]}]
  match: {namespaces: [mut-default, mut-ssd], labelSelector: {matchLabels: {probe: additive}}}
  location: "spec.template.spec.containers[name:*].securityContext.allowPrivilegeEscalation"
  parameters: {assign: {value: false}}
EOF

k -n gitea delete pod seedapps --ignore-not-found >/dev/null
k -n gitea run seedapps --restart=Never --image=alpine/git:2.47.2 --env=GPASS="$GPASS" --command -- sh -ec '
  apk add -q curl >/dev/null 2>&1 || true
  curl -s -u "kratix:$GPASS" -H "Content-Type: application/json" -X POST http://gitea-http.gitea:3000/api/v1/user/repos -d "{\"name\":\"apps\",\"private\":false,\"default_branch\":\"main\"}" >/dev/null
  mkdir /w && cd /w && git init -q -b main && git config user.email k@example.test && git config user.name k
  for p in conflict additive; do
    if [ $p = conflict ]; then extra="imagePullPolicy: IfNotPresent"; else extra="ports: [{containerPort: 8080}]"; fi
    cat > $p.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: $p, labels: {probe: $p}}
spec:
  selector: {matchLabels: {app: $p}}
  template:
    metadata: {labels: {app: $p}}
    spec:
      containers:
        - name: c
          image: registry.k8s.io/e2e-test-images/agnhost:2.53
          args: [netexec, --http-port=8080]
          $extra
EOF
  done
  git add . && git commit -qm seed && git push -q "http://kratix:$GPASS@gitea-http.gitea:3000/kratix/apps.git" main && echo SEEDED'
k -n gitea wait --for=jsonpath='{.status.phase}'=Succeeded pod/seedapps --timeout=180s
for mode in default ssd; do
  k create ns mut-$mode --dry-run=client -o yaml | k apply -f - >/dev/null
  ann=""; [ $mode = ssd ] && ann='annotations: {argocd.argoproj.io/compare-options: ServerSideDiff=true}'
  k apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mut-$mode
  namespace: argocd
  $ann
spec:
  project: default
  source: {repoURL: http://gitea-http.gitea:3000/kratix/apps.git, targetRevision: main, path: .}
  destination: {server: https://kubernetes.default.svc, namespace: mut-$mode}
  syncPolicy: {automated: {prune: true, selfHeal: true}}
EOF
done
