---
resource: https://github.com/skupperproject/skupper/issues/1331
fetched: 2026-11-16
fetch_note: "gh api repos/skupperproject/skupper/issues/1331 + /comments (full thread, bodies verbatim)"
---

# #1331 Skupper on Cilium "No protocol header found (connection aborted)"

state: open () | created 2023-12-19T12:13:04Z | closed - | updated 2024-01-08T14:44:50Z | milestone: none | labels: 

## stelucz 2023-12-19T12:13:04Z

**Describe the bug**
Skupper does not start on Kubernetes cluster with Cilium.

```
skupper init
Waiting for LoadBalancer IP or hostname...
Waiting for status...
Skupper status is not loaded yet.
Skupper is now installed in namespace 'default'.  Use 'skupper status' to get more information.

skupper status
Status pending...
```
Skupper router pod describe:
```
  Warning  Unhealthy  7m1s (x2 over 7m2s)  kubelet            Readiness probe failed: Get "http://10.0.1.59:9090/healthz": dial tcp 10.0.1.59:9090: connect: connection refused
  Warning  Unhealthy  7m1s                 kubelet            Readiness probe failed: Get "http://10.0.1.59:9191/healthz": dial tcp 10.0.1.59:9191: connect: connection refused
```
```
k logs skupper-router-67dc4466f6-7hfht
Defaulted container "router" out of: router, config-sync
Waiting for IP address...
Waiting for IP address...
2023-12-19 10:01:28.656671 +0000 SERVER (info) Container Name: default-skupper-router-67dc4466f6-7hfht
2023-12-19 10:01:28.656747 +0000 ROUTER (info) Router started in Interior mode, area=0 id=default-skupper-router-67dc4466f6-7hfht
2023-12-19 10:01:28.656753 +0000 ROUTER (info) Version: 2.5.0
2023-12-19 10:01:28.657424 +0000 FLOW_LOG (info) Protocol logging started
2023-12-19 10:01:28.657516 +0000 TCP_ADAPTOR (info) Router buffer memory ceiling: 15.43 GiB (4068427 buffers)
2023-12-19 10:01:28.657795 +0000 ROUTER (info) Adaptor buffer memory ceiling: 16566636544 (1011147 buffers)
2023-12-19 10:01:28.658440 +0000 ROUTER (info) Router Engine Instantiated: id=default-skupper-router-67dc4466f6-7hfht instance=1702980088 max_routers=128
2023-12-19 10:01:28.718079 +0000 AGENT (info) Activating management agent on $_management_internal
2023-12-19 10:01:28.720684 +0000 POLICY (info) Policy configured maxConnections: 65535, policyDir: '',access rules enabled: 'false', use hostname patterns: 'false'
2023-12-19 10:01:28.723081 +0000 POLICY (info) Policy fallback defaultVhost is defined: '$default'
2023-12-19 10:01:28.724375 +0000 CONN_MGR (info) Created SSL Profile with name skupper-amqps
2023-12-19 10:01:28.725856 +0000 CONN_MGR (info) Created SSL Profile with name skupper-service-client
2023-12-19 10:01:28.727408 +0000 CONN_MGR (info) Created SSL Profile with name skupper-internal
2023-12-19 10:01:28.728996 +0000 CONN_MGR (info) Created address with Prefix=mc/# and distribution=multicast
2023-12-19 10:01:28.730417 +0000 CONN_MGR (info) Configured  Listener: :5671 proto=any, role=normal, sslProfile=skupper-amqps
2023-12-19 10:01:28.732261 +0000 CONN_MGR (info) Configured  Listener: :55671 proto=any, role=inter-router, sslProfile=skupper-internal
2023-12-19 10:01:28.733910 +0000 CONN_MGR (info) Configured  Listener: :45671 proto=any, role=edge, sslProfile=skupper-internal
2023-12-19 10:01:28.738085 +0000 CONN_MGR (info) Configured  Listener: :9090 proto=any, role=normal, http
2023-12-19 10:01:28.738432 +0000 HTTP (info) HTTP server thread running
2023-12-19 10:01:28.738683 +0000 HTTP (info) Listening for HTTP on :9090
2023-12-19 10:01:28.739780 +0000 CONN_MGR (info) Configured  Listener: localhost:5672 proto=any, role=normal
2023-12-19 10:01:28.740798 +0000 SERVER (info) Operational, 4 Threads Running (process ID 1)
2023-12-19 10:01:28.740926 +0000 ROUTER (info) Process VmSize 259.36 MiB RSS 36.62 MiB (15.43 GiB available memory)
2023-12-19 10:01:28.741403 +0000 SERVER (info) Listening on :5671
2023-12-19 10:01:28.741457 +0000 SERVER (info) Listening on :55671
2023-12-19 10:01:28.741492 +0000 SERVER (info) Listening on :45671
2023-12-19 10:01:28.741526 +0000 SERVER (info) Listening on localhost:5672
2023-12-19 10:01:32.951786 +0000 SERVER (info) [C1] Accepted connection to localhost:5672 from ::1:52348
2023-12-19 10:01:35.571090 +0000 SERVER (info) [C2] Accepted connection to :55671 from 10.0.1.251:21315
2023-12-19 10:01:35.571213 +0000 SERVER (error) [C2] Connection from 10.0.1.251:21315 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:35.690273 +0000 FLOW_LOG (info) ROUTER [7hfht:0] BEGIN parent=3a372edd-c49e-430c-81c7-534afab0068e namespace=default imageName=skupper-router imageVersion=latest hostname=skupper-router-67dc4466f6-7hfht name=0/default-skupper-router-67dc4466f6-7hfht buildVersion=2.5.0
2023-12-19 10:01:35.690374 +0000 FLOW_LOG (info) LOG [7hfht:1] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C2] Connection from 10.0.1.251:21315 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:36.487078 +0000 SERVER (info) [C3] Accepted connection to :45671 from 10.0.1.251:21907
2023-12-19 10:01:36.487127 +0000 SERVER (error) [C3] Connection from 10.0.1.251:21907 (to :45671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:36.493294 +0000 SERVER (info) [C4] Accepted connection to :55671 from 10.0.1.56:25738
2023-12-19 10:01:36.493335 +0000 SERVER (error) [C4] Connection from 10.0.1.56:25738 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:36.495127 +0000 FLOW_LOG (info) LOG [7hfht:2] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C3] Connection from 10.0.1.251:21907 (to :45671) failed:amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:36.495894 +0000 FLOW_LOG (info) LOG [7hfht:3] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C4] Connection from 10.0.1.56:25738 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:37.476127 +0000 SERVER (info) [C5] Accepted connection to :55671 from 10.0.0.199:16515
2023-12-19 10:01:37.476177 +0000 SERVER (error) [C5] Connection from 10.0.0.199:16515 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:37.497901 +0000 FLOW_LOG (info) LOG [7hfht:4] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C5] Connection from 10.0.0.199:16515 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:37.503553 +0000 SERVER (info) [C6] Accepted connection to :45671 from 10.0.0.199:65148
2023-12-19 10:01:37.503604 +0000 SERVER (error) [C6] Connection from 10.0.0.199:65148 (to :45671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:37.698338 +0000 FLOW_LOG (info) LOG [7hfht:5] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C6] Connection from 10.0.0.199:65148 (to :45671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:37.866140 +0000 SERVER (info) [C7] Accepted connection to :45671 from 10.0.1.56:53008
2023-12-19 10:01:37.866211 +0000 SERVER (error) [C7] Connection from 10.0.1.56:53008 (to :45671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:37.898605 +0000 FLOW_LOG (info) LOG [7hfht:6] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C7] Connection from 10.0.1.56:53008 (to :45671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:38.885840 +0000 SERVER (info) [C8] Accepted connection to :55671 from 10.0.1.251:52718
2023-12-19 10:01:38.885970 +0000 SERVER (error) [C8] Connection from 10.0.1.251:52718 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted)
2023-12-19 10:01:38.900443 +0000 FLOW_LOG (info) LOG [7hfht:7] BEGIN END parent=7hfht:0 logSeverity=3 logText=LOG_SERVER: [C8] Connection from 10.0.1.251:52718 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted) sourceFile=/build/src/server.c sourceLine=1088
2023-12-19 10:01:39.829220 +0000 SERVER (info) [C10] Accepted connection to :55671 from 10.0.1.56:33408
2023-12-19 10:01:39.829270 +0000 SERVER (error) [C10] Connection from 10.0.1.56:33408 (to :55671) failed: amqp:connection:framing-error No protocol header found (connection aborted)  
```
source addresses are Cilium "routers" of Kubernetes nodes.

**How To Reproduce**
Steps to reproduce the behavior:
* deploy cluster by Kubespray with Cilium 1.14.5
* follow *Getting started with Skupper* documentation

**Expected behavior**
Skupper up and running.

```
skupper status
Skupper is not enabled in namespace 'default'
```


**Environment details**
 - Skupper CLI: 1.5.1
 - Platform: Kubernetes + Cilium CNI 1.14.5

**Additional context**
Is Skupper even supported with Cilium or other CNIs? I have not found any information about that in documentation.



## ajssmith 2023-12-20T14:36:57Z

Skupper is supported for the basic kubernetes networking model. 

In the log you provided, it appears as though skupper routers in peer namespaces are attempting to establish mTls links to the router in the target namespace. If there is a networking intermediary in between, it must be configured to pass through the traffic. I am not familiar with cilium routers but presume there is a way to configure appropriately.


## stelucz 2023-12-20T14:53:49Z

What does it mean basic kubernetes networking model?

I did not configure any peerings as Skupper router pod is not in ready state.


## ajssmith 2023-12-20T15:00:17Z

By basic networking I meant normal pod-to-pod and pod-to-service communications in a namespace. 

The ports 45671 and 55671 are the ports used by the skupper-routers to establish mTls links. It appears that you have configured other sites  to establish connections to the skupper-router in the namespace you provided. 


## stelucz 2023-12-20T15:02:57Z

Actually, I did not. These are all commands I have run on fresh cluster:

```
skupper init
Waiting for LoadBalancer IP or hostname...
Waiting for status...
Skupper status is not loaded yet.
Skupper is now installed in namespace 'default'.  Use 'skupper status' to get more information.

skupper status
Status pending...
```


## ajssmith 2023-12-20T17:07:47Z

Hi,

Would you be able to attach the output from the 'skupper debug dump' command?

If there is no other skupper deployment in your environment, it would be helpful to understand why there are connection attempts to the router on ports 45671 and 55671.





## ted-ross 2023-12-21T16:11:55Z

It's more likely that the environment is probing the open ports for some
reason.  There are connection attempts at both the interior and edge
listening ports.  Those can probably be ignored.

The issue is that Kubernetes isn't getting health probe responses on port
9090.  How much CPU/memory has been allocated to the skupper-router pod?

My guess is that Cilium is not a factor in this situation.

-Ted

On Wed, Dec 20, 2023 at 12:08 PM ajssmith ***@***.***> wrote:

> Hi,
>
> Would you be able to attach the output from the 'skupper debug dump'
> command?
>
> If there is no other skupper deployment in your environment, it would be
> helpful to understand why there are connection attempts to the router on
> ports 45671 and 55671.
>
> —
> Reply to this email directly, view it on GitHub
> <https://github.com/skupperproject/skupper/issues/1331#issuecomment-1864837799>,
> or unsubscribe
> <https://github.com/notifications/unsubscribe-auth/AAFEKJWK3MRVVGR7YFYEALDYKMLO5AVCNFSM6AAAAABA3CKL32VHI2DSMVQWIX3LMV43OSLTON2WKQ3PNVWWK3TUHMYTQNRUHAZTONZZHE>
> .
> You are receiving this because you are subscribed to this thread.Message
> ID: ***@***.***>
>



## stelucz 2023-12-21T16:50:36Z

[skupper.tar.gz](https://github.com/skupperproject/skupper/files/13744282/skupper.tar.gz)
@ajssmith dump attached.
@ted-ross there's no limit or requests set for Skupper router deployment.
```
...
resources: {}
securityContext:
    runAsNonRoot: true
...
```


## stelucz 2023-12-21T16:53:44Z

Based on information I gathered, you are right Ted. Cilium agent (router) is probing services/endpoints, so that's the reason for these log messages.

Regarding failed health probes, can it be connected with these error messages?


## ajssmith 2023-12-21T17:58:18Z

Looking at the logs, it would appear that the skupper components are unable to resolve the skupper local services:

dial tcp: lookup skupper-router-local.default.svc.cluster.local: no such host

- Might there be network policies in place in the default namespace preventing lookups?
- Can you create another namespace and try to install skupper into it?
- Can you try to resolve services in the namespace [link](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

I am not sure if this is related to the unsuccessful health checks but it looks like the collection of skupper pods are running ok except for inability to resolve services.


## stelucz 2023-12-21T18:37:33Z

Thanks for pointing it out. Is the hostname (cluster name) of service configurable somehow? Because our clusters do not have `cluster.local` domain, instead it is based on actual cluster name.


## ajssmith 2023-12-21T20:10:09Z

iiuc and if you are using CoreDNS as a deployment, you can configure the local domain in the kubelet with flag --cluster-domain or by modifying the CoreDNS corefile via config map:

https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#coredns-configmap-options




## stelucz 2023-12-21T20:24:33Z

Thanks, I meant if I can tell Skupper to use different domain than cluster.local.


## stelucz 2024-01-08T11:18:37Z

Hi @ajssmith I managed to include cluster.local into DNS. However, is it possible to tell Skupper to use cluster name/own domain instead of cluster.local?

Once I manually added cluster.local into DNS. Skupper started to work, I can expose services between clusters, however headless service is not working. Service and pods are created in destination cluster, but connectivity from it does not work.
```
curl ds-service/v1
curl: (7) Failed to connect to ds-service port 80 after 215 ms: Couldn't connect to server
curl ds-0.ds-service/v1
curl: (7) Failed to connect to ds-0.ds-service port 80 after 1 ms: Couldn't connect to server
host ds-0.ds-service
ds-0.ds-service.default.svc.deva-stehlluk-azure has address 10.2.1.239
host ds-service
ds-service.default.svc.deva-stehlluk-azure has address 10.2.1.205
ds-service.default.svc.deva-stehlluk-azure has address 10.2.1.229
ds-service.default.svc.deva-stehlluk-azure has address 10.2.1.239
```

It works fine locally in source cluster, where statefulset is deployed.

definition of statefulset and headless service:
```
---
apiVersion: v1
kind: Service
metadata:
  name: ds-service
  labels:
    app: ds
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: ds
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ds
spec:
  serviceName: "ds-service"
  replicas: 3
  selector:
    matchLabels:
      app: ds
  template:
    metadata:
      labels:
        app: ds
    spec:
      containers:
      - name: ds
        image: docker.io/cilium/starwars
```
Command to expose:
```
skupper expose statefulset ds --headless --port 80
```

I followed [cockroachdb example](https://github.com/grs/skupper-example-cockroachdb?tab=readme-ov-file) and its works fine, at least looks so. So, I have no clue why my example does not work.

Can you help me with troubleshooting please? Thanks a lot.


## stelucz 2024-01-08T13:42:32Z

I managed to get logs from proxy container (skupper router) in destination cluster, this is the output:

```
2024-01-08 13:38:27.733984 +0000 SERVER (info) Container Name: ds-0-4dda95dd-0e93-4ff8-843f-65ab84de370d
2024-01-08 13:38:27.734076 +0000 ROUTER (info) Router started in Edge mode
2024-01-08 13:38:27.734083 +0000 ROUTER (info) Version: 2.5.0
2024-01-08 13:38:27.734424 +0000 ROUTER_CORE (info) Streaming link scrubber: Scan interval: 30 seconds, max free pool: 128 links
2024-01-08 13:38:27.734440 +0000 ROUTER_CORE (info) Core module enabled: streaming_link_scrubber
2024-01-08 13:38:27.734444 +0000 ROUTER_CORE (info) Core module present but disabled: mobile_sync
2024-01-08 13:38:27.734488 +0000 ROUTER_CORE (info) Stuck delivery detection: Scan interval: 30 seconds, Delivery age threshold: 10 seconds
2024-01-08 13:38:27.734498 +0000 ROUTER_CORE (info) Core module enabled: stuck_delivery_detection
2024-01-08 13:38:27.735020 +0000 ROUTER_CORE (info) Core module enabled: heartbeat_server
2024-01-08 13:38:27.735055 +0000 ROUTER_CORE (info) Core module enabled: heartbeat_edge
2024-01-08 13:38:27.735061 +0000 ROUTER_CORE (info) Core module enabled: address_lookup_client
2024-01-08 13:38:27.735172 +0000 ROUTER_CORE (info) Core module present but disabled: mesh_discovery_interior
2024-01-08 13:38:27.735202 +0000 ROUTER_CORE (info) Core module enabled: mesh_discovery_edge
2024-01-08 13:38:27.735315 +0000 ROUTER_CORE (info) Core module present but disabled: edge_addr_tracking
2024-01-08 13:38:27.735341 +0000 ROUTER_CORE (info) Core module present but disabled: core_test_hooks
2024-01-08 13:38:27.735352 +0000 ROUTER_CORE (info) Core module enabled: edge_router
2024-01-08 13:38:27.735925 +0000 ROUTER_CORE (info) Protocol adaptor registered: tcp_lite
2024-01-08 13:38:27.736061 +0000 TCP_ADAPTOR (info) Router buffer memory ceiling: 15.61 GiB (4114941 buffers)
2024-01-08 13:38:27.736078 +0000 ROUTER (info) Adaptor buffer memory ceiling: 16756043776 (1022707 buffers)
2024-01-08 13:38:27.736083 +0000 ROUTER_CORE (info) Protocol adaptor registered: tcp
2024-01-08 13:38:27.736096 +0000 ROUTER_CORE (info) Protocol adaptor registered: http2
2024-01-08 13:38:27.736172 +0000 ROUTER_CORE (info) Protocol adaptor registered: http/1.x
2024-01-08 13:38:27.736367 +0000 ROUTER_CORE (info) Protocol adaptor registered: amqp
2024-01-08 13:38:27.736829 +0000 ROUTER_CORE (info) Router Core thread running. 0/ds-0-4dda95dd-0e93-4ff8-843f-65ab84de370d
2024-01-08 13:38:27.740852 +0000 FLOW_LOG (info) Protocol logging started
2024-01-08 13:38:27.831191 +0000 AGENT (info) Activating management agent on $_management_internal
2024-01-08 13:38:27.832723 +0000 POLICY (info) Policy configured maxConnections: 65535, policyDir: '',access rules enabled: 'false', use hostname patterns: 'false'
2024-01-08 13:38:27.833697 +0000 POLICY (info) Policy fallback defaultVhost is defined: '$default'
2024-01-08 13:38:27.834209 +0000 CONN_MGR (info) Created SSL Profile with name skupper-internal
2024-01-08 13:38:27.835371 +0000 TCP_ADAPTOR (info) Configured TcpListener (legacy encap) for ds-service-0:80, 0.0.0.0:80
2024-01-08 13:38:27.836595 +0000 CONN_MGR (info) Configured  Connector: skupper-router.default.svc.cluster.local:45671 proto=any, role=edge, sslProfile=skupper-internal
2024-01-08 13:38:27.836643 +0000 CONN_MGR (info) Inter-router data connections set to 0
2024-01-08 13:38:27.838386 +0000 CONN_MGR (info) Configured  Listener: localhost:5672 proto=any, role=normal
2024-01-08 13:38:27.839252 +0000 SERVER (info) Operational, 4 Threads Running (process ID 1)
2024-01-08 13:38:27.839383 +0000 ROUTER (info) Process VmSize 187.11 MiB RSS 36.32 MiB (15.61 GiB available memory)
2024-01-08 13:38:27.845684 +0000 SERVER (info) Listening on localhost:5672
2024-01-08 13:38:28.004631 +0000 ROUTER_CORE (info) [C1] Connection Opened: dir=out host=skupper-router.default.svc.cluster.local:45671 encrypted=TLSv1.3 auth=EXTERNAL user=(null) container_id=default-skupper-router-679c4958b-wqrr9 props={:product="skupper-router", :version="2.5.0", :"qd.conn-id"=7296, :"qd.annotations-version"=2}
2024-01-08 13:38:28.004853 +0000 ROUTER_CORE (info) Edge connection (id=1) to interior established
2024-01-08 13:38:28.013093 +0000 ROUTER_CORE (info) EDGE_MESH - Mesh identifier sent to Interior: V_zgbTSMBcUapgb
2024-01-08 13:38:28.017509 +0000 FLOW_LOG (info) Event collector detected.  Begin sending beacons.
2024-01-08 13:38:28.017685 +0000 ROUTER (error) Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80)
2024-01-08 13:38:28.019053 +0000 ROUTER (error) Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80)
2024-01-08 13:40:19.969166 +0000 ROUTER (error) Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80)
2024-01-08 13:40:19.969225 +0000 FLOW_LOG (info) LOG [9U1R4:991930] BEGIN END parent=9U1R4:0 logSeverity=3 logText=LOG_ROUTER: Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80) sourceFile=/build/src/adaptors/adaptor_listener.c sourceLine=168
2024-01-08 13:40:19.969237 +0000 FLOW_LOG (info) LOG [9U1R4:991931] BEGIN END parent=9U1R4:0 logSeverity=3 logText=LOG_ROUTER: Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80) sourceFile=/build/src/adaptors/adaptor_listener.c sourceLine=168
2024-01-08 13:40:19.969166 +0000 ROUTER (error) Listener ingress:80: proactor listener error on 0.0.0.0:80: proton:io (Permission denied - listen on 0.0.0.0:80)
```
These error messages repeat infinitely.


## stelucz 2024-01-08T14:38:58Z

The issue here is probably the port 80. I tried different example with using nginx with port 8080 and headless service in destination cluster works fine. 

Is it known limitation of Skupper? 


## grs 2024-01-08T14:42:59Z

That is a current limitation when using the --headless option. I've raised an issue to track a fix for that: https://github.com/skupperproject/skupper/issues/1344


## stelucz 2024-01-08T14:44:48Z

@grs Thanks a lot for quick reply! :)

