#!/usr/bin/env bash
# kind cluster for the Cell Promise prototype: Cilium + Istio ambient + cert-manager + Kratix (single-cluster, MinIO + Flux destination).
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER=cellproto
CILIUM=1.20.4
ISTIO=1.32.0
CERTMGR=v1.19.1

cat > kind.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
nodes:
  - role: control-plane
  - role: worker
EOF

kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER" --config kind.yaml
kubectl config use-context "kind-$CLUSTER"

helm repo add cilium https://helm.cilium.io >/dev/null
helm repo add istio https://blob.istio.io/istio-release/charts >/dev/null
helm repo add jetstack https://charts.jetstack.io >/dev/null
helm repo update >/dev/null

# Cilium: non-exclusive CNI so istio-cni can chain; socketLB scoped to host ns per Istio's Cilium guidance.
helm upgrade --install cilium cilium/cilium --version "$CILIUM" -n kube-system \
  --set ipam.mode=kubernetes --set cni.exclusive=false --set socketLB.hostNamespaceOnly=true \
  --set image.pullPolicy=IfNotPresent --wait --timeout 10m

helm upgrade --install istio-base istio/base --version "$ISTIO" -n istio-system --create-namespace --wait
helm upgrade --install istiod istio/istiod --version "$ISTIO" -n istio-system --set profile=ambient --wait
helm upgrade --install istio-cni istio/cni --version "$ISTIO" -n istio-system --set profile=ambient --wait
helm upgrade --install ztunnel istio/ztunnel --version "$ISTIO" -n istio-system --wait

# Gateway API CRDs (waypoints are Gateways).
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

helm upgrade --install cert-manager jetstack/cert-manager --version "$CERTMGR" -n cert-manager --create-namespace \
  --set crds.enabled=true --wait

kubectl apply -f https://github.com/syntasso/kratix/releases/latest/download/install-all-in-one.yaml
kubectl -n kratix-platform-system wait --for=condition=Available deploy --all --timeout=10m
kubectl apply -f https://github.com/syntasso/kratix/releases/latest/download/config-all-in-one.yaml
echo "UP OK"
