---
type: source
resource: https://istio.io/latest/docs/tasks/traffic-management/egress/egress-control/
title: "Istio (sidecar) — egress control (REGISTRY_ONLY, ServiceEntry) and egress gateways"
source_kind: webpage
tags: [istio, egress, serviceentry, registry-only, egress-gateway, sidecar]
timestamp: 2026-11-13T00:00:00Z
fetch_note: "gh api repos/istio/istio.io/contents/content/en/docs/tasks/traffic-management/egress/{egress-control,egress-gateway}/index.md raw, master, 2026-11-13. Hugo source verbatim, concatenated. Sidecar-mode tasks; egress-gateway page includes 'Additional security considerations' section."
---


<!-- ===== istio-tasks-traffic-management-egress-egress-control.md ===== -->

---
title: Accessing External Services
description: Describes how to configure Istio to route traffic from services in the mesh to external services.
weight: 10
aliases:
    - /docs/tasks/egress.html
    - /docs/tasks/egress
keywords: [traffic-management,egress]
owner: istio/wg-networking-maintainers
test: yes
---

Because all outbound traffic from an Istio-enabled pod is redirected to its sidecar proxy by default,
accessibility of URLs outside of the cluster depends on the configuration of the proxy.
By default, Istio configures the Envoy proxy to pass through requests for unknown services.
Although this provides a convenient way to get started with Istio, configuring
stricter control is usually preferable.

This task shows you how to access external services in three different ways:

1. Allow the Envoy proxy to pass requests through to services that are not configured inside the mesh.
1. Configure [service entries](/docs/reference/config/networking/service-entry/) to provide controlled access to external services.
1. Completely bypass the Envoy proxy for a specific range of IPs.

## Before you begin

*   Set up Istio by following the instructions in the [Installation guide](/docs/setup/).
    Use the `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/) or otherwise
    [enable Envoy’s access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging).

*   Deploy the [curl]({{< github_tree >}}/samples/curl) sample app to use as a test source for sending requests.
    If you have
    [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    enabled, run the following command to deploy the sample app:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    Otherwise, manually inject the sidecar before deploying the `curl` application with the following command:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Set the `SOURCE_POD` environment variable to the name of your source pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    {{< /text >}}

## Envoy passthrough to external services

Istio has an [installation option](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode),
`meshConfig.outboundTrafficPolicy.mode`, that configures the sidecar handling
of external services, that is, those services that are not defined in Istio's internal service registry.
If this option is set to `ALLOW_ANY`, the Istio proxy lets calls to unknown services pass through.
If the option is set to `REGISTRY_ONLY`, then the Istio proxy blocks any host without an HTTP service or
service entry defined within the mesh.
`ALLOW_ANY` is the default value, allowing you to start evaluating Istio quickly,
without controlling access to external services.
You can then decide to [configure access to external services](#controlled-access-to-external-services) later.

1.  To see this approach in action you need to ensure that your Istio installation is configured
    with the `meshConfig.outboundTrafficPolicy.mode` option set to `ALLOW_ANY`. Unless you explicitly
    set it to `REGISTRY_ONLY` mode when you installed Istio, it is probably enabled by default.

    If you are unsure, you can run the following command to display your mesh config:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml
    {{< /text >}}

    Unless you see an explicit setting of `meshConfig.outboundTrafficPolicy.mode` with value `REGISTRY_ONLY`,
    you can be sure the option is set to `ALLOW_ANY`, which is the only other possible value and the default.

    {{< tip >}}
    If you have explicitly configured `REGISTRY_ONLY` mode, you can change it
    by rerunning your original `istioctl install` command with the changed setting, for example:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY
    {{< /text >}}

    {{< /tip >}}

1.  Make a couple of requests to external HTTPS services from the `SOURCE_POD` to confirm
    successful `200` responses:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

Congratulations! You successfully sent egress traffic from your mesh.

This simple approach to access external services, has the drawback that you lose Istio monitoring and control
for traffic to external services. The next section shows you how to monitor and control your mesh's access to
external services.

## Controlled access to external services

Using Istio `ServiceEntry` configurations, you can access any publicly accessible service
from within your Istio cluster. This section shows you how to configure access to an external HTTP service,
[httpbin.org](http://httpbin.org), as well as an external HTTPS service,
[www.google.com](https://www.google.com) without losing Istio's traffic monitoring and control features.

### Change to the blocking-by-default policy

To demonstrate the controlled way of enabling access to external services, you need to change the
`meshConfig.outboundTrafficPolicy.mode` option from the `ALLOW_ANY` mode to the `REGISTRY_ONLY` mode.

{{< tip >}}
You can add controlled access to services that are already accessible in `ALLOW_ANY` mode.
This way, you can start using Istio features on some external services without blocking any others.
Once you've configured all of your services, you can then switch the mode to `REGISTRY_ONLY` to block
any other unintentional accesses.
{{< /tip >}}

1.  Change the `meshConfig.outboundTrafficPolicy.mode` option to `REGISTRY_ONLY`.

    If you used an `IstioOperator` configuration to install Istio, add the following field to your configuration:

    {{< text yaml >}}
    spec:
      meshConfig:
        outboundTrafficPolicy:
          mode: REGISTRY_ONLY
    {{< /text >}}

    Otherwise, add the equivalent setting to your original `istioctl install` command, for example:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
    {{< /text >}}

1.  Make a couple of requests to external HTTPS services from `SOURCE_POD` to verify that they are now blocked:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    It may take a while for the configuration change to propagate, so you might still get successful connections.
    Wait for several seconds and then retry the last command.
    {{< /warning >}}

### Access an external HTTP service

1.  Create a `ServiceEntry` to allow access to an external HTTP service.

    {{< warning >}}
    `DNS` resolution is used in the service entry below as a security measure. Setting the resolution to `NONE`
    opens a possibility for attack. A malicious client could pretend that it's
    accessing `httpbin.org` by setting it in the `HOST` header, while really connecting to a different IP
    (that is not associated with `httpbin.org`). The Istio sidecar proxy will trust the HOST header, and incorrectly allow
    the traffic, even though it is being delivered to the IP address of a different host. That host can be a malicious
    site, or a legitimate site, prohibited by the mesh security policies.

    With `DNS` resolution, the sidecar proxy will ignore the original destination IP address and direct the traffic
    to `httpbin.org`, performing a DNS query to get an IP address of `httpbin.org`.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Make a request to the external HTTP service from `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.org",
        ...
        "X-Envoy-Attempt-Count": "1",
        ...
      }
    }
    {{< /text >}}

    Note the `X-Envoy-*` headers added by the Istio sidecar proxy.

1.  Check the log of the sidecar proxy of `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    Note the entry related to your HTTP request to `httpbin.org/headers`.

### Access an external HTTPS service

1.  Create a `ServiceEntry` to allow access to an external HTTPS service.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Make a request to the external HTTPS service from `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"
    HTTP/2 200
    {{< /text >}}

1.  Check the log of the sidecar proxy of `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    Note the entry related to your HTTPS request to `www.google.com`.

### Manage traffic to external services

Similar to inter-cluster requests, routing rules
can also be configured for external services that are accessed using `ServiceEntry` configurations.
In this example, you set a timeout rule on calls to the `httpbin.org` service.

{{< boilerplate gateway-api-support >}}

1)  From inside the pod being used as the test source, make a _curl_ request to the `/delay` endpoint of the
    httpbin.org external service:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    200
    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    The request should return 200 (OK) in approximately 5 seconds.

2)  Use `kubectl` to set a 3s timeout on calls to the `httpbin.org` external service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  http:
  - timeout: 3s
    route:
    - destination:
        host: httpbin.org
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-ext
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-ext
  hostnames:
  - httpbin.org
  rules:
  - timeouts:
      request: 3s
    backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: httpbin.org
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Wait a few seconds, then make the _curl_ request again:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    504
    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    This time a 504 (Gateway Timeout) appears after 3 seconds.
    Although httpbin.org was waiting 5 seconds, Istio cut off the request at 3 seconds.

### Cleanup the controlled access to external services

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext
$ kubectl delete httproute httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Direct access to external services

If you want to completely bypass Istio for a specific IP range,
you can configure the Envoy sidecars to prevent them from
[intercepting](/docs/concepts/traffic-management/)
external requests. To set up the bypass, change either the `global.proxy.includeIPRanges`
or the `global.proxy.excludeIPRanges` [configuration option](https://archive.istio.io/v1.4/docs/reference/config/installation-options/) and
update the `istio-sidecar-injector` configuration map using the `kubectl apply` command. This can also
be configured on a pod by setting corresponding [annotations](/docs/reference/config/annotations/) such as
`traffic.sidecar.istio.io/includeOutboundIPRanges`.
After updating the `istio-sidecar-injector` configuration, it affects all
future application pod deployments.

{{< warning >}}
Unlike [Envoy passthrough to external services](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services),
which uses the `ALLOW_ANY` traffic policy to instruct the Istio sidecar proxy to
passthrough calls to unknown services,
this approach completely bypasses the sidecar, essentially disabling all of Istio's features
for the specified IPs. You cannot incrementally add service entries for specific
destinations, as you can with the `ALLOW_ANY` approach.
Therefore, this configuration approach is only recommended as a last resort
when, for performance or other reasons, external access cannot be configured using the sidecar.
{{< /warning >}}

A simple way to exclude all external IPs from being redirected to the sidecar proxy is
to set the `global.proxy.includeIPRanges` configuration option to the IP range or ranges
used for internal cluster services.
These IP range values depend on the platform where your cluster runs.

### Determine the internal IP ranges for your platform

Set the value of `values.global.proxy.includeIPRanges` according to your cluster provider.

#### IBM Cloud Private

1.  Get your `service_cluster_ip_range` from IBM Cloud Private configuration file under `cluster/config.yaml`:

    {{< text bash >}}
    $ grep service_cluster_ip_range cluster/config.yaml
    {{< /text >}}

    The following is a sample output:

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  Use `--set values.global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

To see which CIDR is used in the cluster use `ibmcloud ks cluster get -c <CLUSTER-NAME>` and look for the `Service Subnet`:

{{< text bash >}}
$ ibmcloud ks cluster get -c my-cluster | grep "Service Subnet"
Service Subnet:                 172.21.0.0/16
{{< /text >}}

Then use `--set values.global.proxy.includeIPRanges="172.21.0.0/16"`

{{< warning >}}
On very old clusters, this may not work so you can use `--set values.global.proxy.includeIPRanges="172.30.0.0/16,172.21.0.0/16,10.10.10.0/24"` or use `kubectl get svc -o wide -A` to further narrow down the CIDR value for the setting.
{{< /warning >}}

#### Google Kubernetes Engine (GKE)

The ranges are not fixed, so you will need to run the `gcloud container clusters describe` command to determine the
ranges to use. For example:

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

Use `--set values.global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Kubernetes Service (AKS)

##### Kubenet

To see which service CIDR and pod CIDR are used in the cluster, use `az aks show` and look for the `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep Cidr
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

Then use `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"`

##### Azure CNI

Follow these steps if you are using Azure CNI with a non-overlay networking mode. If using Azure CNI with overlay networking, please follow the [Kubenet instructions](#kubenet). For more information, see the [Azure CNI Overlay documentation](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay).

To see which service CIDR is used in the cluster, use `az aks show` and look for the `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep serviceCidr
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

To see which pod CIDR is used in the cluster, use `az` CLI to inspect the `vnet`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep nodeResourceGroup
  "nodeResourceGroup": "MC_user-rg_user-cluster_region",
  "nodeResourceGroupProfile": null,
$ az network vnet list -g MC_user-rg_user-cluster_region | grep name
    "name": "aks-vnet-74242220",
        "name": "aks-subnet",
$ az network vnet show -g MC_user-rg_user-cluster_region -n aks-vnet-74242220 | grep addressPrefix
    "addressPrefixes": [
      "addressPrefix": "10.224.0.0/16",
{{< /text >}}

Then use `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"`

#### Minikube, Docker For Desktop, Bare Metal

The default value is `10.96.0.0/12`, but it's not fixed. Use the following command to determine your actual value:

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

Use `--set values.global.proxy.includeIPRanges="10.96.0.0/12"`

### Configuring the proxy bypass

{{< warning >}}
Remove the service entry and virtual service previously deployed in this guide.
{{< /warning >}}

Update your `istio-sidecar-injector` configuration map using the IP ranges specific to your platform.
For example, if the range is 10.0.0.1&#47;24, use the following command:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set values.global.proxy.includeIPRanges="10.0.0.1/24"
{{< /text >}}

Use the same command that you used to [install Istio](/docs/setup/install/istioctl) and
add `--set values.global.proxy.includeIPRanges="10.0.0.1/24"`.

### Access the external services

Because the bypass configuration only affects new deployments, you need to terminate and then redeploy the `curl`
application as described in the [Before you begin](#before-you-begin) section.

After updating the `istio-sidecar-injector` configmap and redeploying the `curl` application,
the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request bypasses the sidecar and goes straight to its intended destination.
For example:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
  }
}
{{< /text >}}

Unlike accessing external services through HTTP or HTTPS, you don't see any headers related to the Istio sidecar and the
requests sent to external services do not appear in the log of the sidecar. Bypassing the Istio sidecars means you can
no longer monitor the access to external services.

### Cleanup the direct access to external services

Update the configuration to stop bypassing sidecar proxies for a range of IPs:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio>
{{< /text >}}

## Understanding what happened

In this task you looked at three ways to call external services from an Istio mesh:

1. Configuring Envoy to allow access to any external service.

1. Use a service entry to register an accessible external service inside the mesh. This is the
   recommended approach.

1. Configuring the Istio sidecar to exclude external IPs from its remapped IP table.

The first approach directs traffic through the Istio sidecar proxy, including calls to services
that are unknown inside the mesh. When using this approach,
you can't monitor access to external services or take advantage of Istio's traffic control features for them.
To easily switch to the second approach for specific services, simply create service entries for those external services.
This process allows you to initially access any external service and then later
decide whether or not to control access, enable traffic monitoring, and use traffic control features as needed.

The second approach lets you use all of the same Istio service mesh features for calls to services inside or
outside of the cluster. In this task, you learned how to monitor access to external services and set a timeout
rule for calls to an external service.

The third approach bypasses the Istio sidecar proxy, giving your services direct access to any external server.
However, configuring the proxy this way does require cluster-provider specific knowledge and configuration.
Similar to the first approach, you also lose monitoring of access to external services and you can't apply
Istio features on traffic to external services.

## Security note

{{< warning >}}
Note that configuration examples in this task **do not enable secure egress traffic control** in Istio.
A malicious application can bypass the Istio sidecar proxy and access any external service without Istio control.
{{< /warning >}}

To implement egress traffic control in a more secure way, you must
[direct egress traffic through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/)
and review the security concerns described in the
[additional security considerations](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)
section.

## Cleanup

Shutdown the [curl]({{< github_tree >}}/samples/curl) service:

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}

<!-- ===== istio-tasks-traffic-management-egress-egress-gateway.md ===== -->

---
title: Egress Gateways
description: Describes how to configure Istio to direct traffic to external services through a dedicated gateway.
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
This example does not work in Minikube.
{{</warning>}}

The [Accessing External Services](/docs/tasks/traffic-management/egress/egress-control) task shows how to configure
Istio to allow access to external HTTP and HTTPS services from applications inside the mesh.
There, the external services are called directly from the client sidecar.
This example also shows how to configure Istio to call external services, although this time
indirectly via a dedicated _egress gateway_ service.

Istio uses [ingress and egress gateways](/docs/reference/config/networking/gateway/)
to configure load balancers executing at the edge of a service mesh.
An ingress gateway allows you to define entry points into the mesh that all incoming traffic flows through.
Egress gateway is a symmetrical concept; it defines exit points from the mesh. Egress gateways allow
you to apply Istio features, for example, monitoring and route rules, to traffic exiting the mesh.

## Use case

Consider an organization that has a strict security requirement that all traffic leaving
the service mesh must flow through a set of dedicated nodes. These nodes will run on dedicated machines,
separated from the rest of the nodes running applications in the cluster. These special nodes will serve
for policy enforcement on the egress traffic and will be monitored more thoroughly than other nodes.

Another use case is a cluster where the application nodes don't have public IPs, so the in-mesh services that run
on them cannot access the Internet. Defining an egress gateway, directing all the egress traffic through it, and
allocating public IPs to the egress gateway nodes allows the application nodes to access external services in a
controlled way.

{{< boilerplate gateway-api-gamma-experimental >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    {{< tip >}}
    The egress gateway and access logging will be enabled if you install the `demo`
    [configuration profile](/docs/setup/additional-setup/config-profiles/).
    {{< /tip >}}

*   Deploy the [curl]({{< github_tree >}}/samples/curl) sample app to use as a test source for sending requests.

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Set the `SOURCE_POD` environment variable to the name of your source pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

    {{< warning >}}
    The instructions in this task create a destination rule for the egress gateway in the `default` namespace
    and assume that the client, `SOURCE_POD`, is also running in the `default` namespace.
    If not, the destination rule will not be found on the
    [destination rule lookup path](/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)
    and the client requests will fail.
    {{< /warning >}}

*   [Enable Envoy’s access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)
    if not already enabled. For example, using `istioctl`:

    {{< text bash >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

## Deploy Istio egress gateway

{{< tip >}}
Egress gateways are [deployed automatically](/docs/tasks/traffic-management/ingress/gateway-api/#deployment-methods)
when using Gateway API to configure them. You can skip this section if you are using the `Gateway API` instructions
in the following sections.
{{< /tip >}}

1.  Check if the Istio egress gateway is deployed:

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    If no pods are returned, deploy the Istio egress gateway by performing the following step.

1.  If you used an `IstioOperator` configuration to install Istio, add the following fields to your configuration:

    {{< text yaml >}}
    spec:
      components:
        egressGateways:
        - name: istio-egressgateway
          enabled: true
    {{< /text >}}

    Otherwise, add the equivalent settings to your original `istioctl install` command, for example:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set "components.egressGateways[0].name=istio-egressgateway" \
                       --set "components.egressGateways[0].enabled=true"
    {{< /text >}}

## Egress gateway for HTTP traffic

First create a `ServiceEntry` to allow direct traffic to an external service.

1.  Define a `ServiceEntry` for `edition.cnn.com`.

    {{< warning >}}
    `DNS` resolution must be used in the service entry below. If the resolution is `NONE`, the gateway will
    direct the traffic to itself in an infinite loop. This is because the gateway receives a request with the original
    destination IP address which is equal to the service IP of the gateway (since the request is directed by sidecar
    proxies to the gateway).

    With `DNS` resolution, the gateway performs a DNS query to get an IP address of the external service and directs
    the traffic to that IP address.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly by sending an HTTP request to [http://edition.cnn.com/politics](http://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    The output should be the same as in the
    [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/) example,
    without TLS origination.

1.  Create a `Gateway` for egress traffic to _edition.cnn.com_ port 80.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
To direct multiple hosts through an egress gateway, you can include a list of hosts, or use `*` to match all, in the `Gateway`.
The `subset` field in the `DestinationRule` should be reused for the additional hosts.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Configure route rules to direct traffic from the sidecars to the egress gateway and from the egress gateway
    to the external service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Resend the HTTP request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    The output should be the same as in the step 2.

6)  Check the log of the egress gateway pod for a line corresponding to our request.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
{{< /text >}}

{{< tip >}}
If [mutual TLS Authentication](/docs/tasks/security/authentication/authn-policy/) is enabled, and you have issues connecting to the egress gateway, run the following command to verify the certificate is correct:

{{< text bash >}}
$ istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< tip >}}
If [mutual TLS Authentication](/docs/tasks/security/authentication/authn-policy/) is enabled, and you have issues connecting to the egress gateway, run the following command to verify the certificate is correct:

{{< text bash >}}
$ istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

Note that you only redirected the HTTP traffic from port 80 through the egress gateway.
The HTTPS traffic to port 443 went directly to _edition.cnn.com_.

### Cleanup HTTP gateway

Remove the previous definitions before proceeding to the next step:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Egress gateway for HTTPS traffic

In this section you direct HTTPS traffic (TLS originated by the application) through an egress gateway.
You need to specify port 443 with protocol `TLS` in a corresponding `ServiceEntry` and egress `Gateway`.

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly by sending an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

1.  Create an egress `Gateway` for _edition.cnn.com_ and route rules to direct the traffic
    through the egress gateway and from the egress gateway to the external service.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
To direct multiple hosts through an egress gateway, you can include a list of hosts, or use `*` to match all, in the `Gateway`.
The `subset` field in the `DestinationRule` should be reused for the additional hosts.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics).
    The output should be the same as before.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

5)  Check the log of the egress gateway's proxy.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Cleanup HTTPS gateway

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete tlsroute direct-cnn-to-egress-gateway
$ kubectl delete tlsroute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Additional security considerations

Note that defining an egress `Gateway` in Istio does not in itself provides any special treatment for the nodes
on which the egress gateway service runs. It is up to the cluster administrator or the cloud provider to deploy
the egress gateways on dedicated nodes and to introduce additional security measures to make these nodes more
secure than the rest of the mesh.

Istio *cannot securely enforce* that all egress traffic actually flows through the egress gateways. Istio only
enables such flow through its sidecar proxies. If attackers bypass the sidecar proxy, they could directly access
external services without traversing the egress gateway. Thus, the attackers escape Istio's control and monitoring.
The cluster administrator or the cloud provider must ensure that no traffic leaves the mesh bypassing the egress
gateway. Mechanisms external to Istio must enforce this requirement. For example, the cluster administrator
can configure a firewall to deny all traffic not coming from the egress gateway.
The [Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can
also forbid all the egress traffic not originating from the egress gateway (see
[the next section](#apply-kubernetes-network-policies) for an example).
Additionally, the cluster administrator or the cloud provider can configure the network to ensure application nodes can
only access the Internet via a gateway. To do this, the cluster administrator or the cloud provider can prevent the
allocation of public IPs to pods other than gateways and can configure NAT devices to drop packets not originating at
the egress gateways.

## Apply Kubernetes network policies

This section shows you how to create a
[Kubernetes network policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to prevent
bypassing of the egress gateway. To test the network policy, you create a namespace, `test-egress`, deploy
the [curl]({{< github_tree >}}/samples/curl) sample to it, and then attempt to send requests to a gateway-secured
external service.

1)  Follow the steps in the
    [Egress gateway for HTTPS traffic](#egress-gateway-for-https-traffic) section.

2)  Create the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

3)  Deploy the [curl]({{< github_tree >}}/samples/curl) sample to the `test-egress` namespace.

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/curl/curl.yaml@
    {{< /text >}}

4)  Check that the deployed pod has a single container with no Istio sidecar attached:

    {{< text bash >}}
    $ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    curl-776b7bcdcd-z7mc4    1/1       Running   0          18m
    {{< /text >}}

5)  Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics) from the `curl` pod in
    the `test-egress` namespace. The request will succeed since you did not define any restrictive policies yet.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

6)  Label the namespaces where the Istio control plane and egress gateway are running.
    If you deployed Istio in the `istio-system` namespace, the command is:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
$ kubectl label namespace default gateway=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7)  Label the `kube-system` namespace.

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

8)  Define a `NetworkPolicy` to limit the egress traffic from the `test-egress` namespace to traffic destined to
    the control plane, gateway, and to the `kube-system` DNS service (port 53).

    {{< warning >}}
    [Network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
    are implemented by the network plugin in your Kubernetes cluster.
    Depending on your test cluster, the traffic may not be blocked in the following
    step.
    {{< /warning >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

9)  Resend the previous HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it
    should fail since the traffic is blocked by the network policy. Note that the `curl` pod cannot bypass
    the egress gateway. The only way it can access `edition.cnn.com` is by using an Istio sidecar proxy and by
    directing the traffic to the egress gateway. This setting demonstrates that even if some malicious pod manages to
    bypass its sidecar proxy, it will not be able to access external sites and will be blocked by the network policy.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -v -sS https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

10) Now inject an Istio sidecar proxy into the `curl` pod in the `test-egress` namespace by first enabling
    automatic sidecar proxy injection in the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

11) Then redeploy the `curl` deployment:

    {{< text bash >}}
    $ kubectl delete deployment curl -n test-egress
    $ kubectl apply -f @samples/curl/curl.yaml@ -n test-egress
    {{< /text >}}

12) Check that the deployed pod includes the Istio sidecar proxy (`istio-proxy`). On Kubernetes 1.33+, sidecars are injected as
    [native sidecars](/blog/2023/native-sidecars/) (`initContainers` with `restartPolicy: Always`), so list both
    `containers` and `initContainers`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}{" "}{.spec.initContainers[*].name}'
curl istio-validation istio-proxy
{{< /text >}}

Before proceeding, you'll need to create a similar destination rule as the one used for the `curl` pod in the `default` namespace,
to direct the `test-egress` namespace traffic through the egress gateway:

{{< text bash >}}
$ kubectl apply -n test-egress -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}{" "}{.spec.initContainers[*].name}'
curl istio-validation istio-proxy
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

13) Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it should succeed
    since the traffic flows to the egress gateway is allowed by the
    Network Policy you defined. The gateway then forwards the traffic to `edition.cnn.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

14) Check the log of the egress gateway's proxy.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504837 46 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Cleanup network policies

1.  Delete the resources created in this section:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl label namespace default gateway-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Follow the steps in the [Cleanup HTTPS gateway](#cleanup-https-gateway) section.

## Cleanup

Shutdown the [curl]({{< github_tree >}}/samples/curl) service:

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
