#!/usr/bin/env bash
# Push ./repo to the Gitea repo kratix/cells through the gitwork pod. Usage: ./push.sh "<commit message>"
set -euo pipefail
cd "$(dirname "$0")"
k() { command kubectl --context kind-cellproto -n gitea "$@"; }
k exec gitwork -- rm -rf /w
k cp repo gitwork:/w
k exec gitwork -- sh -ec "cd /w && git init -q -b main 2>/dev/null; git config user.email k@example.test; git config user.name k;
  git remote get-url origin >/dev/null 2>&1 || git remote add origin http://kratix:\$GPASS@gitea-http.gitea:3000/kratix/cells.git;
  git fetch -q origin main 2>/dev/null && git reset -q --soft origin/main || true;
  git add -A && git commit -qm '$1' && git push -q origin HEAD:main && git rev-parse --short HEAD"
