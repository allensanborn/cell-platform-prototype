---
resource: https://github.com/radius-project/radius/blob/37a8cbd33e990886460f4fd1987d6a4fefd901c5/pkg/components/database/apiserverstore/apiserverclient.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v0.62.0, radius-project/radius@37a8cbd33e990886460f4fd1987d6a4fefd901c5"
---

<!-- src/rad/pkg/components/database/apiserverstore/apiserverclient.go lines 17,45 -->

```
// Package apiserverstore stores resources using the Kubernetes API Server - using CRDs as a key-value store.
// We don't represent UCP data directly as Kubernetes resources because that would require the creation of
// many types. The complex hierarchies of data that are possible for UCP aren't a good fit for Kubernetes
// data model.
//
// Our strategy is to use the resource name and hash of the object name in order to derive a *likely*-unique
// kubernetes object name. Then we affix labels to the object that match its scopes so we can easily author queries.
//
// Since this scheme allows collisions we need to use optimistic concurrency controls when writing and
// consider the possibility of multiple resources being present when reading.
//
// Each Kubernetes Resource object stores a list of UCP resources. Since we use SHA1 to generate hashes,
// we expect collisions to be extremely rare. The only case we need to be concerned about is when collisions
// cause the total size of the Kubernetes Resource object to be larger than the 8mb limit of Kubernetes.
//
// This scheme allows us to perform O(1) reads and writes for key-based lookups while still handling
// collisions.
//
// The kubernetes resource names we use are built according to the following format:
//
//	<resource name>.<id hash>
//
// We also use a labeling scheme to attach each root scope segment and the resource type as a label to the
// Kubernetes objects. This allows us to filter the number of objects we transact with using the labels as hints.
package apiserverstore

import (
	"context"
	"encoding/json"
```
