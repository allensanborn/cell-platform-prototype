---
type: source
resource: https://docs.kratix.io/main/reference/resources/updates
title: "Resource Updates"
source_kind: webpage
tags: [kratix, resources, updates, scheduling]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/syntasso/kratix-docs/contents/docs/main/03-reference/15-resources/05-updates.md -H Accept: application/vnd.github.raw (2026-11-13), main@169418223c15b2fc231f80890db7842e5e77e550; raw MDX/markdown source byte-for-byte, Docusaurus components not rendered; resource URL is the docs.kratix.io slug for this file. Slug inferred from sidebar id; not opened rendered."
---

---
title: Resource Updates
sidebar_label: Updates
description: How updating a Resource request works in Kratix, including status changes and how the pipeline responds.
---

# Resource Updates

Kratix supports updating Resource Requests with new specifications.

Given that the Resource workflows are defined within the parent Promise, updates to a
Resource Request are limited to updating the request parameters in the `spec`.

## Workflows

Any update to the Resource will result in Kratix re-running the
[Resource Configure](./workflows#configure-workflows) workflow.

If a configure Pipeline is already running when the Resource is updated, Kratix waits for
the current Job to reach a terminal state before restarting the workflow from the
beginning.

Any files which are output by this workflow will replace all existing files associated
with this Resource in the [StateStore](../statestore/intro).

This workflow runs against the Promise Revision the Resource is currently bound to. Updating
the request `spec` does not change that version. To reconcile a Resource against a different
Promise version, update its [Resource Binding](../promises/promise-upgrade/resource-bindings) —
see the [Upgrading a Promise](/main/guides/upgrading-resource-requests) guide.

## Scheduling

If an update to a Resource changes its scheduling, the change will be **ignored**.

The Destination selected at the first Workflow run is always used. To move a Resource
from one Destination to another, you can delete and create it again.

See [Managing Multiple Destinations](../destinations/multidestination-management#resources) for
more details on scheduling.
