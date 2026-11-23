#!/usr/bin/env bash
# Cell prototype test matrix. Cells: a (allowFrom b), b (dependsOn a), c (dependsOn a, not allowed by a); rogue = non-mesh namespace.
set -uo pipefail
cd "$(dirname "$0")" || exit

workload() { # $1 = namespace
  kubectl -n "$1" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: echo}
spec:
  selector: {matchLabels: {app: echo}}
  template:
    metadata: {labels: {app: echo}}
    spec:
      containers: [{name: echo, image: registry.k8s.io/e2e-test-images/agnhost:2.53, args: [netexec, --http-port=8080]}]
---
apiVersion: v1
kind: Service
metadata: {name: echo}
spec: {selector: {app: echo}, ports: [{port: 80, targetPort: 8080}]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: client}
spec:
  selector: {matchLabels: {app: client}}
  template:
    metadata: {labels: {app: client}}
    spec:
      containers: [{name: c, image: curlimages/curl:8.11.1, command: [sleep, infinity]}]
EOF
}

call() { # $1 from-ns, $2 url -> prints http code or "conn-fail"
  kubectl -n "$1" exec deploy/client -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$2" 2>/dev/null || echo conn-fail
}

if [ "${1:-}" = setup ]; then
  kubectl create ns rogue --dry-run=client -o yaml | kubectl apply -f -
  for ns in cell-a cell-b cell-c rogue; do workload "$ns"; done
  for ns in cell-a cell-b cell-c rogue; do kubectl -n "$ns" rollout status deploy/echo deploy/client --timeout=180s; done
  exit 0
fi

A_POD=$(kubectl -n cell-a get pod -l app=echo -o jsonpath='{.items[0].status.podIP}')
printf '%-44s %-10s %s\n' CASE EXPECT GOT
row() { printf '%-44s %-10s %s\n' "$1" "$2" "$(call "$3" "$4")"; }
row "b -> a svc (allowed caller, declared dep)" 200 cell-b http://echo.cell-a/hostname
row "c -> a svc (declared dep, not in allowFrom)" 403 cell-c http://echo.cell-a/hostname
row "b -> c svc (not a declared dep)" conn-fail cell-b http://echo.cell-c/hostname
row "a -> a svc (same cell)" 200 cell-a http://echo.cell-a/hostname
row "rogue -> a svc (out of mesh)" deny rogue http://echo.cell-a/hostname
row "rogue -> a pod IP (bypass waypoint)" deny rogue "http://$A_POD:8080/hostname"
row "b -> a pod IP (bypass waypoint, in mesh)" deny cell-b "http://$A_POD:8080/hostname"
