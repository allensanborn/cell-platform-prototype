---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/install/helm/openchoreo-workflow-plane/Chart.yaml
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d, full file"
---

```yaml
apiVersion: v2
name: openchoreo-workflow-plane
description: A Helm chart for OpenChoreo Workflow Plane
type: application

# Version strategy: latest-dev for development, replaced by CI for releases
version: 0.0.0-latest-dev
appVersion: "latest-dev"

home: https://github.com/openchoreo/openchoreo
icon: https://openchoreo.dev/img/openchoreo-logo.svg
sources:
  - https://github.com/openchoreo/openchoreo
keywords:
  - openchoreo
  - internal-developer-platform
  - idp
  - kubernetes
  - workflow-automation
  - ci-cd
  - argo-workflows
  - devops
maintainers:
  - name: OpenChoreo Team
    url: https://github.com/openchoreo/openchoreo
dependencies:
  - name: argo-workflows
    repository: "https://argoproj.github.io/argo-helm"
    version: 1.0.23
```
