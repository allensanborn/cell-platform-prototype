---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/deploy/Chart/templates/rp/configmaps.yaml
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/deploy/Chart/templates/rp/configmaps.yaml lines 10,30 -->

```
  radius-self-host.yaml: |-
    # Radius configuration file.
    # See https://github.com/radius-project/radius/blob/main/docs/contributing/contributing-code/contributing-code-control-plane/configSettings.md for more information.
    environment:
      name: self-hosted
      roleLocation: "global"
    databaseProvider:
    {{- if .Values.database.enabled }}
      provider: "postgresql"
      postgresql:
        url: "postgresql://applications_rp:${POSTGRES_PASSWORD}@database.{{ .Release.Namespace }}:5432/applications_rp?sslmode=disable"
    {{- else }}
      provider: "apiserver"
      apiserver:
        context: ""
        namespace: "radius-system"
    {{- end }}
    queueProvider:
      provider: "apiserver"
      name: "radius"
      apiserver:
```
