### Description of your changes

Fixes #2328

The STS AssumeRole calls made for `spec.assumeRoleChain` always went to the public STS endpoint, even when the ProviderConfig sets `spec.endpoint`.

The cause is ordering in `getAWSConfig`. `GetRoleChainConfig` built the chain's STS clients before `SetResolver` installed the custom endpoint resolver. Separately, each link of the chain loads a fresh `aws.Config`, which drops any resolver. So even after a reorder, the second and later hops would still go to public STS.

This change:

- calls `SetResolver` before `GetRoleChainConfig` in `getAWSConfig`;
- passes the resolver into each link's `config.LoadDefaultConfig` in `GetRoleChainConfig`, so every hop, and the clients built from the final config, use `spec.endpoint`.

A second commit fixes the same problem for the **WebIdentity** credential source. `UseWebIdentityToken` built the STS client for `AssumeRoleWithWebIdentity` from a default config with no endpoint resolver, so that call also went to public STS. The resolver is now installed on that config first, through a new unexported `setEndpointResolver(endpoint, cfg)` that `SetResolver` delegates to (its signature and behaviour are unchanged). It is also carried into the config `GetAssumeRoleWithWebIdentityConfigViaTokenRetriever` returns.

The behaviour without `spec.endpoint`, or with `url.type: Auto`, is unchanged: `SetResolver` returns the config as is, and a nil resolver is carried as nil.

I have:

- [x] Read and followed Crossplane's [contribution process].
- [x] Not needed `make generate`: no API or generated files change.
- [ ] Run `make check-diff` (not run locally).

### How has this code been tested

New unit test `TestRoleChainUsesCustomEndpoint` in `internal/clients/role_chain_endpoint_test.go`. It sets up a two-role chain against an `httptest` fake STS given as `spec.endpoint`, goes through `GetAWSConfigWithoutTracking`, and asserts that both AssumeRole calls reach the fake and that the credentials come from the last link. `HTTPS_PROXY` points at a dead loopback port, so a call that escapes to a real AWS endpoint fails fast instead of leaving the machine.

| Code | Result |
|---|---|
| `main` (371d38b5) | FAIL: `Post "https://sts.us-east-1.amazonaws.com/": proxyconnect … connection refused` |
| Reorder only, no propagation | FAIL: the second hop goes to public STS |
| This change | PASS |

`TestWebIdentityUsesCustomEndpoint` covers the WebIdentity source with a Filesystem token: it fails on `main` and on the first commit alone (`Post "https://sts.us-east-1.amazonaws.com/"`) and passes with both commits. Removing the new `setEndpointResolver` call from `UseWebIdentityToken` makes it fail again.

Not covered here: the IRSA and PodIdentity sources resolve credentials through the SDK's default chain, whose internal STS client this provider doesn't build. `AWS_ENDPOINT_URL_STS` still applies there.

`go test ./internal/clients/...`, `go vet ./internal/clients/` and `gofmt` all pass.

End to end on a kind cluster against a local AWS emulator, provider-aws-rds v2.8.1 with this ProviderConfig shape only worked with the `AWS_ENDPOINT_URL_STS` workaround described in #2328.

[contribution process]: https://git.io/fj2m9
