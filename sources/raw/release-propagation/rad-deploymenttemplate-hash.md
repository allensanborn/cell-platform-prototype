---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/controller/reconciler/deploymenttemplate_reconciler.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/controller/reconciler/deploymenttemplate_reconciler.go lines 596,621 -->

```
// computeHash computes a hash of the DeploymentTemplate's spec (desired state)
// to save in the status (observed state).
func computeHash(deploymentTemplate *radappiov1alpha3.DeploymentTemplate) (string, error) {
	b, err := json.Marshal(deploymentTemplate.Spec)
	if err != nil {
		return "", err
	}

	return hashutil.Hex(b), nil
}

// isUpToDate returns true if the desired state of the DeploymentTemplate
// matches the observed state.
//
// It accepts both the current SHA-256 hash and the legacy SHA-1 hash so that
// upgrading Radius (which changes the hash algorithm) does not flag an otherwise
// unchanged DeploymentTemplate as out-of-date and trigger an unnecessary deployment.
func isUpToDate(deploymentTemplate *radappiov1alpha3.DeploymentTemplate) bool {
	b, err := json.Marshal(deploymentTemplate.Spec)
	if err != nil {
		return false
	}

	stored := deploymentTemplate.Status.StatusHash
	return stored == hashutil.Hex(b) || stored == hashutil.LegacyHex(b)
}
```
