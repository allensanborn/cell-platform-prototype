#!/usr/bin/env bash
# North/south matrix. "Internet" client = rogue namespace (out of mesh). Body shows which pod answered.
set -uo pipefail
GW=http://north-istio.platform-ingress
req() { # ns, url, [host] -> "code body"
  local h=(); [ -n "${3:-}" ] && h=(-H "Host: $3")
  kubectl -n "$1" exec deploy/client -- sh -c "curl -s --max-time 6 -w ' %{http_code}' ${h[*]:+-H 'Host: $3'} '$2' | tail -c 80" 2>/dev/null || echo conn-fail
}
printf '%-50s %-24s %s\n' CASE EXPECT GOT
row() { printf '%-50s %-24s %s\n' "$1" "$2" "$(req "$3" "$4" "${5:-}" | tr -d '\n')"; }
row "N1 internet -> a.example.test" "200 from cell-a echo" rogue "$GW/hostname" a.example.test
row "N2 internet -> b.example.test (not public)" 404 rogue "$GW/hostname" b.example.test
row "S1 b -> httpbin.org (ServiceEntry, allowed)" 200 cell-b http://httpbin.org/status/200
row "S2 c -> httpbin.org (not allowed at waypoint)" 403 cell-c http://httpbin.org/status/200
row "S3 b -> example.com (no ServiceEntry)" "blocked" cell-b http://example.com/
row "S4 rogue -> example.com (no fence, baseline)" 200 rogue http://example.com/
