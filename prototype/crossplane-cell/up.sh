#!/usr/bin/env bash
# kind cluster for round 8: Cilium + Istio ambient + Crossplane, no Kratix. Safe to re-run.
# Writes a kubeconfig beside this script and leaves yours alone: export KUBECONFIG=$PWD/.kubeconfig
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER=cellxp
CILIUM=1.20.4
ISTIO=1.32.0
CROSSPLANE=2.4.2
export KUBECONFIG="$PWD/.kubeconfig"

kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER" --config ../kind/kind.yaml
kind export kubeconfig --name "$CLUSTER"

helm repo add cilium https://helm.cilium.io >/dev/null
helm repo add istio https://blob.istio.io/istio-release/charts >/dev/null
helm repo add crossplane-stable https://charts.crossplane.io/stable >/dev/null
helm repo update >/dev/null

# ClusterNetworkPolicy CRD before Cilium, which serves it only with the flag on (south fence).
kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/network-policy-api/release-0.2/config/crd/standard/policy.networking.k8s.io_clusternetworkpolicies.yaml
helm upgrade --install cilium cilium/cilium --version "$CILIUM" -n kube-system \
  --set ipam.mode=kubernetes --set cni.exclusive=false --set socketLB.hostNamespaceOnly=true \
  --set k8sClusterNetworkPolicy.enabled=true --set image.pullPolicy=IfNotPresent --wait --timeout 10m

helm upgrade --install istio-base istio/base --version "$ISTIO" -n istio-system --create-namespace --wait
helm upgrade --install istiod istio/istiod --version "$ISTIO" -n istio-system --set profile=ambient --wait
helm upgrade --install istio-cni istio/cni --version "$ISTIO" -n istio-system --set profile=ambient --wait
helm upgrade --install ztunnel istio/ztunnel --version "$ISTIO" -n istio-system --wait

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

helm upgrade --install crossplane crossplane-stable/crossplane --version "$CROSSPLANE" -n crossplane-system --create-namespace --wait
kubectl apply -f - <<'EOF'
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata: {name: function-go-templating}
spec: {package: xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.13.1}
EOF
kubectl wait --for=condition=Healthy function/function-go-templating --timeout=5m

kubectl apply -f ../kind/platform-ns.yaml
kubectl apply -f xcell.yaml
kubectl wait --for=condition=Established xrd/xcells.platform.example.org --timeout=2m
kubectl apply -f cells.yaml
kubectl wait --for=condition=Ready xcell --all --timeout=3m
echo "UP OK"
