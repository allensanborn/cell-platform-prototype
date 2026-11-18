extension radius

param environment string

resource app 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'admprobe'
  properties: { environment: environment }
}

resource web 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web'
  properties: {
    environment: environment
    application: app.id
    containers: {
      web: {
        image: 'registry.k8s.io/e2e-test-images/agnhost:2.53'
        args: ['netexec', '--http-port=8080']
        ports: { http: { containerPort: 8080 } }
      }
    }
  }
}
