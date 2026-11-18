---
resource: https://github.com/istio/istio.io/blob/167b0ad6625bb9f5e25859141f4808f1ed89e541/content/en/docs/tasks/policy-enforcement/rate-limit/index.md
fetched: 2026-11-16
fetch_note: "git clone --depth 1 istio/istio.io@167b0ad6625bb9f5e25859141f4808f1ed89e541 (file last changed 37d761ab3ae6 2026-05-12)"
---


<!-- istio.io/content/en/docs/tasks/policy-enforcement/rate-limit/index.md lines 1,30 -->

---
title: Enabling Rate Limits using Envoy
description: This task shows you how to configure Istio to dynamically limit the traffic to a service.
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

This task shows you how to use Envoy's native rate limiting to dynamically limit the traffic to an Istio
service. In this task, you will apply a global rate-limit for the `productpage` service through ingress gateway that allows
1 requests per minute across all instances of the service. Additionally, you will apply a local rate-limit for each
individual `productpage` instance that will allow 4 requests per minute. In this way, you will ensure that the `productpage`
service handles a maximum of 1 request per minute through the ingress gateway, but each `productpage` instance can handle
up to 4 requests per minute, allowing for any in-mesh traffic.

## Before you begin

{{< warning >}}
Rate limits as described in this document are implemented using the EnvoyFilter API. EnvoyFilter exposes internal implementation details that may change at any time. Please use extreme caution, especially around upgrades.
{{< /warning >}}

1. Setup Istio in a Kubernetes cluster by following the instructions in the
   [Installation Guide](/docs/setup/getting-started/).

1. Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Rate limits

Envoy supports two kinds of rate limiting: global and local. Global rate
