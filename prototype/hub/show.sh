#!/usr/bin/env bash
# Per-cluster view: Composition revisions, hub1's revision, rendered namespace template, Argo app state.
for pair in dev:kind-cellproto prod:k3d-openchoreo; do
  env=${pair%%:*}; ctx=${pair#*:}
  k() { command kubectl --context "$ctx" "$@"; }
  revs=$(k get compositionrevisions -l crossplane.io/composition-name=xcell-np -o jsonpath='{range .items[*]}{.spec.revision}:{.metadata.labels.channel} {end}')
  rev=$(k get xcell hub1 -o jsonpath='{.spec.crossplane.compositionRevisionRef.name}' 2>/dev/null)
  rnum=$(k get compositionrevision "$rev" -o jsonpath='{.spec.revision}' 2>/dev/null)
  tpl=$(k get ns hub-hub1 -o jsonpath='{.metadata.labels.platform\.example\.org/hub-template}' 2>/dev/null)
  app=$(command kubectl --context kind-cellproto -n argocd get app "cells-$env" -o jsonpath='{.status.sync.status}/{.status.health.status}')
  printf '%-5s revisions=[%s] hub1=rev%s ns-template=%s argo=%s\n' "$env" "$revs" "$rnum" "$tpl" "$app"
done
