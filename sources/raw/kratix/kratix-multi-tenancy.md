---
type: source
resource: https://docs.kratix.io/main/platform-concepts/multi-tenancy
title: "Multi-tenancy"
source_kind: webpage
tags: [kratix, multi-tenancy, namespaces, rbac]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/syntasso/kratix-docs/contents/docs/main/05-platform-concepts/06-multi-tenancy.mdx -H Accept: application/vnd.github.raw (2026-11-13), main@169418223c15b2fc231f80890db7842e5e77e550; raw MDX/markdown source byte-for-byte, Docusaurus components not rendered; resource URL is the docs.kratix.io slug for this file. Slug inferred from path; not opened rendered."
---

---
title: Multi-tenancy
description: Multi-tenancy for Kratix using standard Kubernetes isolation models.
---

Kratix does not introduce a custom multi-tenancy layer. Instead, it fits into
the same Kubernetes isolation patterns you already use. Depending on your
security and operational requirements, you can isolate tenants with separate
clusters, node pools, or namespaces.

Separate clusters are often used to reduce blast radius or to meet DR/HA or
regulatory requirements. Node pools help ensure workloads and workflows run on
the right type of compute (for example, dedicated, compliant, or GPU nodes).
Namespaces provide a lightweight boundary for teams. For example, an
organisation might allocate `backend` and `frontend` namespaces so each team can
manage their own Promise requests independently from the same Platform.

Kratix Promises can create namespaced CRDs and therefore resource requests 
(for example a Kratix Promise for `Database` or `App`) will be namespaced. 
This makes namespaces a natural boundary for teams, environments, or 
organisations. You can then combine namespaces with Kubernetes features 
like ResourceQuotas and NetworkPolicies to enforce limits and isolation per
team or other organisational division.

Promises themselves are cluster-scoped and are not namespaced. That means a
Promise is visible across the cluster once installed. Use Kubernetes RBAC to
control who can list Promises and who can create request resources in each
namespace. See the Kratix [RBAC](/main/platform-concepts/auth/rbac) guide for
examples and guidance.

For the Kubernetes details, see the [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) docs.
