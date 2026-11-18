Title: [Bug]: assumeRoleChain STS calls ignore ProviderConfig spec.endpoint and go to the public STS endpoint

### Is there an existing issue for this?
- [x] I have searched the existing issues

Closest: #971 (an endpoint pre-check removed in v0.44) and #2292 (assumeRoleChain session expiry). Neither covers this.

### Affected Resource(s)
Any managed resource whose ProviderConfig sets both `spec.endpoint` and `spec.assumeRoleChain`. Reproduced with `rds.aws.m.upbound.io/v1beta1 Instance`.

### Resource MRs required to reproduce the bug
```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata: {name: aws, namespace: iam-a}
spec:
  credentials: {source: Secret, secretRef: {namespace: iam-a, name: platform-identity, key: creds}}
  assumeRoleChain:
    - roleARN: arn:aws:iam::111111111111:role/crossplane-provisioner
  endpoint:
    url: {type: Static, static: http://192.168.97.9:4566}   # local AWS emulator
    hostnameImmutable: true
    services: [rds, sts, iam]
  skip_credentials_validation: true
  skip_metadata_api_check: true
  skip_requesting_account_id: true
---
apiVersion: rds.aws.m.upbound.io/v1beta1
kind: Instance
metadata: {name: ledger, namespace: iam-a}
spec:
  providerConfigRef: {kind: ProviderConfig, name: aws}
  forProvider:
    region: us-east-1
    engine: postgres
    engineVersion: "16"
    instanceClass: db.t3.micro
    allocatedStorage: 20
    username: appadmin
    autoGeneratePassword: true
    passwordSecretRef: {name: ledger-master, key: password}
    skipFinalSnapshot: true
```

### Steps to Reproduce
1. Run an AWS-compatible endpoint that implements STS AssumeRole (we used a local emulator), and create the role in it.
2. Apply the ProviderConfig and Instance above.
3. Observe the MR's `Synced` condition.

To confirm where the call goes, restrict the provider pod's egress to the cluster and the endpoint's IP only (we used a CiliumNetworkPolicy).

### What happened?
Without the egress restriction, the MR reports:

```
connect failed: … cannot retrieve the AWS credentials: failed to refresh cached credentials, operation error STS: AssumeRole, https response error StatusCode: 403, …, api error InvalidClientTokenId: The security token included in the request is invalid.
```

The emulator received no AssumeRole call. With egress restricted, the same MR reports:

```
… operation error STS: AssumeRole, exceeded maximum number of attempts, 3, https response error StatusCode: 0, RequestID: , request send failed, Post "https://sts.us-east-1.amazonaws.com/": dial tcp 13.217.79.240:443: i/o timeout
```

So the AssumeRole call goes to the public STS endpoint, even though `spec.endpoint` is static and lists `sts`. The same ProviderConfig without `assumeRoleChain` uses the custom endpoint for RDS as expected.

Expected: when `spec.endpoint` is set (static, or with `services` including `sts`), the STS clients used for `assumeRoleChain` resolve through it, as every other service client does.

### Likely cause
In `internal/clients/provider_config.go` (v2.8.1, 09d38f54), the ProviderConfig credential path builds the role chain before installing the endpoint resolver:

```go
cfg, err = GetRoleChainConfig(ctx, &pc.Spec, cfg)   // line 194: sts.NewFromConfig(*pCfg, …) per chain link
...
cfg, err = SetResolver(pc, cfg)                     // line 198: sets cfg.EndpointResolverWithOptions
```

`GetRoleChainConfig` creates each `stscreds.NewAssumeRoleProvider` from `sts.NewFromConfig(*pCfg, stsRegionOrDefault(cfg.Region))`. `pCfg` has no endpoint resolver yet, so STS resolves to the default AWS endpoint. Applying the resolver to the base config before building the chain, or passing an `sts.Options` endpoint for the chain clients, would likely fix it. `GetAssumeRoleWithWebIdentityConfigViaTokenRetriever` looks to have the same ordering, but that wasn't tested.

### Workaround
Set `AWS_ENDPOINT_URL_STS` on the provider pod through a DeploymentRuntimeConfig. aws-sdk-go-v2 honours it for the chain's STS clients:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata: {name: aws-sts-endpoint}
spec:
  deploymentTemplate:
    spec:
      selector: {}
      template:
        spec:
          containers:
            - name: package-runtime
              env: [{name: AWS_ENDPOINT_URL_STS, value: http://192.168.97.9:4566}]
```

With it, the AssumeRole call reaches the custom endpoint and the Instance becomes Ready in the assumed role's account. An untrusted caller gets `AccessDenied` from the endpoint, as expected.

### Why it matters
- With an emulator, credentials meant for a local endpoint are sent, signed, to real AWS.
- In real AWS, setups that need STS to resolve to a specific endpoint (VPC interface endpoints, FIPS, or partitions where the default global or regional endpoint is wrong) would also bypass `spec.endpoint` for role chaining. This is inferred, not tested.

### Crossplane Version
v2.4.2

### Provider Version
provider-aws-rds v2.8.1 (provider-family-aws v2.9.0)

### Kubernetes Version
v1.35.0 (kind)

### Kubernetes Distribution
kind

### Additional Info
Reproduced 2026-11-16/17. Happy to test a fix.
