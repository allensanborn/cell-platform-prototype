---
resource: https://github.com/skupperproject/skupper/issues/818
fetched: 2026-11-16
fetch_note: "gh api repos/skupperproject/skupper/issues/818 + /comments (full thread, bodies verbatim)"
---

# #818 Skupper does not function with istio on openshift

state: closed (completed) | created 2022-07-07T09:55:25Z | closed 2025-04-17T16:03:06Z | updated 2026-01-24T19:44:40Z | milestone: none | labels: 

## PatiUdayKiran-ab-scm 2022-07-07T09:55:25Z

We have installed istio on openshift and added a namespace as service mesh member roll. When we try to install skupper on the same namespace, It doesn't work. We suspect it to be a port conflict with istio as the logs on the skupper service controller says that the console server starts on 8888. 
How can we resolve this? 


## grs 2022-07-07T10:11:18Z

use options `--annotations traffic.sidecar.istio.io/excludeInboundPorts=5671,45671,55671,8081 --annotations traffic.sidecar.istio.io/excludeOutboundPorts=5671,45671,55671,8081` with skupper init.



## PatiUdayKiran-ab-scm 2022-07-07T11:50:03Z

We added the annotations however the error still persists. We even tried with `--annotations traffic.sidecar.istio.io/excludeInboundPorts='*' --annotations traffic.sidecar.istio.io/excludeOutboundPorts='*'` but not working.



## grs 2022-07-07T20:42:22Z

Can you give a bit more detail of what you have done and what does not work?


## PatiUdayKiran-ab-scm 2022-07-08T03:52:17Z

- Installed istio service mesh on openshift and added a namespace(x) as a member in istio service mesh member roll instance.
- Initialized skupper in same namespace(x) using `skupper init --console-auth openshift`

Later, When trying to access the web console using the route provided, we are unable to access the UI. 

```
Application is not available
The application is currently not serving requests at this endpoint. It may not have been started or is still starting.

Possible reasons you are seeing this page:

The host doesn't exist. Make sure the hostname was typed correctly and that a route matching this hostname exists.
The host exists, but doesn't have a matching path. Check if the URL path was typed correctly and that the route was created using the desired path.
Route and path matches, but all pods are down. Make sure that the resources exposed by this route (pods, services, deployment configs, etc) have at least one pod running
```


But the skupper-router and skupper-service-controller pods are up and running successfully.
And the logs for skupper-service-controller pod are as below,
```
2022/07/08 03:40:27 Skupper service controller
2022/07/08 03:40:27 Version: 1.0.2
2022/07/08 03:40:27 Setting up event handlers
2022/07/08 03:40:27 Waiting for Skupper router component to start
2022/07/08 03:40:37 Starting the Skupper controller
2022/07/08 03:40:37 Waiting for informer caches to sync
2022/07/08 03:40:38 Starting workers
2022/07/08 03:40:40 Console server listening on localhost:8888
2022/07/08 03:40:40 Claim verifier listening on :8081
2022/07/08 03:40:40 Started workers
2022/07/08 03:40:41 Skupper policy is disabled
```
We even tried with the annotations that you have mentioned but the UI access problem is still the same.


## grs 2022-07-08T08:21:11Z

Can you try running curl against the service controller by pod ip, on port 8888, from within the namespace (e.g. with oc exec)?

Did you verify that the istio annotations were actually on the pods?

Does changing the --console-auth option make any difference?


## PatiUdayKiran-ab-scm 2022-07-08T08:36:04Z

```
Defaulted container "service-controller" out of: service-controller, oauth-proxy
curl: (7) Failed to connect to 10.128.2.28 port 8888: Connection refused
command terminated with exit code 7
```
--console-auth removal doesn't make any difference.
Yes, Istio annotations are on the pods but still the same error.


## grs 2022-07-08T09:29:51Z

That sounds then like istio is not honouring those annotations. I have no istio expertise I'm afraid. I would check the various env vars set on the istio side car for the pod. You couldalso  try debugging with istioctl proxy-status and/or istioctl x describe pod. 

BTW I left port 8888 out of the exclude list by accident above, if you did not add that already then please do so.


## grs 2022-07-08T09:33:25Z

From googling, some versions (or some istio installation methods) also require that traffic.sidecar.istio.io/includeInboundPorts: "*" by set explicitly, so could try that.


## grs 2022-07-08T09:37:40Z

`kubectl exec -it <pod-name> -c istio-proxy -- bash` then `iptables --list` would I think give you the current redirect rules to verify that the annotations are not in effect


## grs 2022-07-08T09:49:17Z

I would also change the console-auth setting for debugging purposes to eliminate the oauth-proxy container.

What does kubectl/oc describe pod show?


## PatiUdayKiran-ab-scm 2022-07-08T09:50:09Z

> iptables --list

iptables command not found in istio-proxy container, any other alternative command to check


## PatiUdayKiran-ab-scm 2022-07-08T09:56:59Z

> What does kubectl/oc describe pod show?

```
Name:         skupper-router-7fb8cd8cfd-tj6jn
Namespace:    namespacex
Priority:     0
Node:         ip-xxxxxxx.ap-south-1.compute.internal/x.x.x.x
Start Time:   Fri, 08 Jul 2022 09:43:57 +0000
Labels:       app.kubernetes.io/name=skupper-router
              app.kubernetes.io/part-of=skupper
              application=skupper-router
              failure-domain.beta.kubernetes.io/region=ap-south-1
              failure-domain.beta.kubernetes.io/zone=ap-south-1c
              maistra-version=2.2.0
              pod-template-hash=7fb8cd8cfd
              security.istio.io/tlsMode=istio
              service.istio.io/canonical-name=skupper-router
              service.istio.io/canonical-revision=latest
              skupper.io/component=router
              topology.istio.io/subzone=
              topology.kubernetes.io/region=ap-south-1
              topology.kubernetes.io/zone=ap-south-1c
Annotations:  k8s.v1.cni.cncf.io/network-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.128.2.30"
                    ],
                    "default": true,
                    "dns": {}
                },{
                    "name": "namespacex/v2-2-istio-cni",
                    "dns": {}
                }]
              k8s.v1.cni.cncf.io/networks: v2-2-istio-cni
              k8s.v1.cni.cncf.io/networks-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.128.2.30"
                    ],
                    "default": true,
                    "dns": {}
                },{
                    "name": "namespacex/v2-2-istio-cni",
                    "dns": {}
                }]
              openshift.io/scc: restricted
              prometheus.io/path: /stats/prometheus
              prometheus.io/port: 15020
              prometheus.io/scrape: true
              sidecar.istio.io/inject: true
              sidecar.istio.io/interceptionMode: REDIRECT
              sidecar.istio.io/status:
                {"initContainers":null,"containers":["istio-proxy"],"volumes":["istio-envoy","istio-data","istio-podinfo","istiod-ca-cert"],"imagePullSecr...
              traffic.sidecar.istio.io/excludeInboundPorts: 15090,15021
              traffic.sidecar.istio.io/includeInboundPorts: *
              traffic.sidecar.istio.io/includeOutboundIPRanges: *
              traffic.sidecar.istio.io/includeOutboundPorts: 5671,45671,55671,8081,8888,8443,8080
Status:       Running
IP:           10.128.2.30
IPs:
  IP:           10.128.2.30
Controlled By:  ReplicaSet/skupper-router-7fb8cd8cfd
Containers:
  router:
    Container ID:   cri-o://692955f0033c0fca7fc53a1eb23218dd151a13ed1abe6150f91a04a3f0c4303c
    Image:          quay.io/skupper/skupper-router:2.0.2
    Image ID:       quay.io/skupper/skupper-router@sha256:e563f069635fbabe4080770107defcd15d10125aa2f1e0747f118942efe9f9b8
    Ports:          5671/TCP, 9090/TCP, 55671/TCP, 45671/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Fri, 08 Jul 2022 09:44:02 +0000
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:15020/app-health/router/livez delay=60s timeout=1s period=10s #success=1 #failure=3
    Environment:
      APPLICATION_NAME:               skupper-router
      POD_NAMESPACE:                  namespacex (v1:metadata.namespace)
      POD_IP:                          (v1:status.podIP)
      QDROUTERD_AUTO_MESH_DISCOVERY:  QUERY
      QDROUTERD_CONF:                 /etc/skupper-router/config/skrouterd.json
      QDROUTERD_CONF_TYPE:            json
      SKUPPER_SITE_ID:                a5716f63-c173-439c-9305-e626c23c23f1
    Mounts:
      /etc/skupper-router-certs from skupper-router-certs (rw)
      /etc/skupper-router-certs/skupper-amqps/ from skupper-local-server (rw)
      /etc/skupper-router-certs/skupper-internal/ from skupper-site-server (rw)
      /etc/skupper-router/config/ from router-config (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-44m9l (ro)
  config-sync:
    Container ID:   cri-o://38945449622a70714cbc1c9e9ec5bc436ec20f1fc8d801382b3435ad24bd2f44
    Image:          quay.io/skupper/config-sync:1.0.2
    Image ID:       quay.io/skupper/config-sync@sha256:bc590b33af5aceebcb864d0325a280c816cd5f0466d8a69de250e2620854e054
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Fri, 08 Jul 2022 09:44:04 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/skupper-router-certs from skupper-router-certs (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-44m9l (ro)
  istio-proxy:
    Container ID:  cri-o://3c962f8519aef009a08df304c2a1c371afd6474afd594bfc6517b892d2046e3f
    Image:         registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:156343ce8515401a29fc405e2142ffdbd5ef32ff2e5de7078baed3211a4f4fe5
    Image ID:      registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:156343ce8515401a29fc405e2142ffdbd5ef32ff2e5de7078baed3211a4f4fe5
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --proxyLogLevel=warning
      --proxyComponentLogLevel=misc:error
      --log_output_level=default:warn
      --concurrency
      2
    State:          Running
      Started:      Fri, 08 Jul 2022 09:44:05 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:      10m
      memory:   128Mi
    Readiness:  http-get http://:15021/healthz/ready delay=1s timeout=3s period=2s #success=1 #failure=30
    Environment:
      JWT_POLICY:                    first-party-jwt
      PILOT_CERT_PROVIDER:           istiod
      CA_ADDR:                       istiod-basic.istio-system.svc:15012
      POD_NAME:                      skupper-router-7fb8cd8cfd-tj6jn (v1:metadata.name)
      POD_NAMESPACE:                 namespacex (v1:metadata.namespace)
      INSTANCE_IP:                    (v1:status.podIP)
      SERVICE_ACCOUNT:                (v1:spec.serviceAccountName)
      HOST_IP:                        (v1:status.hostIP)
      PROXY_CONFIG:                  {"discoveryAddress":"istiod-basic.istio-system.svc:15012","tracing":{"zipkin":{"address":"jaeger-collector.istio-system.svc:9411"}},"proxyMetadata":{"ISTIO_META_DNS_AUTO_ALLOCATE":"true","ISTIO_META_DNS_CAPTURE":"true","PROXY_XDS_VIA_AGENT":"true"}}

      ISTIO_META_POD_PORTS:          [
                                         {"name":"amqps","containerPort":5671,"protocol":"TCP"}
                                         ,{"name":"http","containerPort":9090,"protocol":"TCP"}
                                         ,{"name":"inter-router","containerPort":55671,"protocol":"TCP"}
                                         ,{"name":"edge","containerPort":45671,"protocol":"TCP"}
                                     ]
      ISTIO_META_APP_CONTAINERS:     router,config-sync
      ISTIO_META_CLUSTER_ID:         Kubernetes
      ISTIO_META_INTERCEPTION_MODE:  REDIRECT
      ISTIO_META_WORKLOAD_NAME:      skupper-router
      ISTIO_META_OWNER:              kubernetes://apis/apps/v1/namespaces/namespacex/deployments/skupper-router
      ISTIO_META_MESH_ID:            cluster.local
      TRUST_DOMAIN:                  cluster.local
      ISTIO_META_DNS_AUTO_ALLOCATE:  true
      ISTIO_META_DNS_CAPTURE:        true
      PROXY_XDS_VIA_AGENT:           true
      ISTIO_PROMETHEUS_ANNOTATIONS:  {"scrape":"true","path":"","port":"9090"}
      ISTIO_KUBE_APP_PROBERS:        {"/app-health/router/livez":{"httpGet":{"path":"/healthz","port":9090,"scheme":"HTTP"},"timeoutSeconds":1}}
    Mounts:
      /etc/istio/pod from istio-podinfo (rw)
      /etc/istio/proxy from istio-envoy (rw)
      /var/lib/istio/data from istio-data (rw)
      /var/run/secrets/istio from istiod-ca-cert (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-44m9l (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  istio-envoy:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  istio-data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  istio-podinfo:
    Type:  DownwardAPI (a volume populated by information about the pod)
    Items:
      metadata.labels -> labels
      metadata.annotations -> annotations
  istiod-ca-cert:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      istio-ca-root-cert
    Optional:  false
  skupper-local-server:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-local-server
    Optional:    false
  router-config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      skupper-internal
    Optional:  false
  skupper-site-server:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-site-server
    Optional:    false
  skupper-router-certs:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  kube-api-access-44m9l:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
    ConfigMapName:           openshift-service-ca.crt
    ConfigMapOptional:       <nil>
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/memory-pressure:NoSchedule op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason          Age    From               Message
  ----    ------          ----   ----               -------
  Normal  Scheduled       7m35s  default-scheduler  Successfully assigned namespacex/skupper-router-7fb8cd8cfd-tj6jn to ip-xxxx.ap-south-1.compute.internal
  Normal  AddedInterface  7m33s  multus             Add eth0 [10.128.2.30/23] from openshift-sdn
  Normal  AddedInterface  7m33s  multus             Add net1 [] from namespacex/v2-2-istio-cni
  Normal  Pulling         7m33s  kubelet            Pulling image "quay.io/skupper/skupper-router:2.0.2"
  Normal  Pulled          7m30s  kubelet            Successfully pulled image "quay.io/skupper/skupper-router:2.0.2" in 2.344744754s
  Normal  Created         7m30s  kubelet            Created container router
  Normal  Started         7m30s  kubelet            Started container router
  Normal  Pulling         7m30s  kubelet            Pulling image "quay.io/skupper/config-sync:1.0.2"
  Normal  Pulled          7m28s  kubelet            Successfully pulled image "quay.io/skupper/config-sync:1.0.2" in 2.379680199s
  Normal  Created         7m28s  kubelet            Created container config-sync
  Normal  Started         7m28s  kubelet            Started container config-sync
  Normal  Pulled          7m28s  kubelet            Container image "registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:156343ce8515401a29fc405e2142ffdbd5ef32ff2e5de7078baed3211a4f4fe5" already present on machine
  Normal  Created         7m27s  kubelet            Created container istio-proxy
  Normal  Started         7m27s  kubelet            Started container istio-proxy
```


## grs 2022-07-08T10:23:47Z

traffic.sidecar.istio.io/excludeInboundPorts: 15090,15021 is wrong, and there appears to be no traffic.sidecar.istio.io/excludeOutboundPorts set.

What about service-controller pod?


## grs 2022-07-08T10:25:35Z

Also, stepping back, the 8888 port is only locally accessible when using oauth proxy, so actually we would not expect to be able to connect to that. There may be some other ports needed to be excluded for oauth proxy, so I would avoid it in the first instance.


## PatiUdayKiran-ab-scm 2022-07-08T10:35:31Z

Shall I try with this?

````
skupper init --annotations traffic.sidecar.istio.io/excludeInboundPorts='5671,45671,55671,8081,8888' --annotations traffic.sidecar.istio.io/excludeOutboundPorts='5671,45671,55671,8081,8888' --annotations traffic.sidecar.istio.io/includeInboundPorts='*' 
````


## grs 2022-07-08T11:08:26Z

Try: `skupper init --annotations traffic.sidecar.istio.io/excludeInboundPorts='5671,5672,45671,55671,8081,8080' --annotations traffic.sidecar.istio.io/excludeOutboundPorts='5671,5672,45671,55671,8081'`


## PatiUdayKiran-ab-scm 2022-07-08T13:12:55Z

It's the same error again. 
Skupper Pod Details
````
Name:         skupper-router-7fdf5b5f4d-d8d2h
Namespace:    namespacex
Priority:     0
Node:         ip-X-X-X-X.ap-south-1.compute.internal/X.X.X.X
Start Time:   Fri, 08 Jul 2022 13:06:45 +0000
Labels:       app.kubernetes.io/name=skupper-router
              app.kubernetes.io/part-of=skupper
              application=skupper-router
              pod-template-hash=7fdf5b5f4d
              skupper.io/component=router
Annotations:  k8s.v1.cni.cncf.io/network-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.130.0.220"
                    ],
                    "default": true,
                    "dns": {}
                }]
              k8s.v1.cni.cncf.io/networks-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.130.0.220"
                    ],
                    "default": true,
                    "dns": {}
                }]
              openshift.io/scc: restricted
              prometheus.io/port: 9090
              prometheus.io/scrape: true
              traffic.sidecar.istio.io/excludeInboundPorts: 5671,5672,45671,55671,8081,8080
              traffic.sidecar.istio.io/excludeOutboundPorts: 5671,5672,45671,55671,8081
Status:       Running
IP:           10.130.0.220
IPs:
  IP:           10.130.0.220
Controlled By:  ReplicaSet/skupper-router-7fdf5b5f4d
Containers:
  router:
    Container ID:   cri-o://37777b8d50d42b93c2db5b15a919358e283ac12627c7ddc39a870b927e8de488
    Image:          quay.io/skupper/skupper-router:2.0.2
    Image ID:       quay.io/skupper/skupper-router@sha256:e563f069635fbabe4080770107defcd15d10125aa2f1e0747f118942efe9f9b8
    Ports:          5671/TCP, 9090/TCP, 55671/TCP, 45671/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Fri, 08 Jul 2022 13:06:49 +0000
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:9090/healthz delay=60s timeout=1s period=10s #success=1 #failure=3
    Environment:
      APPLICATION_NAME:               skupper-router
      POD_NAMESPACE:                  namespacex (v1:metadata.namespace)
      POD_IP:                          (v1:status.podIP)
      QDROUTERD_AUTO_MESH_DISCOVERY:  QUERY
      QDROUTERD_CONF:                 /etc/skupper-router/config/skrouterd.json
      QDROUTERD_CONF_TYPE:            json
      SKUPPER_SITE_ID:                fae3351d-e601-469e-abc0-42d5c8a82795
    Mounts:
      /etc/skupper-router-certs from skupper-router-certs (rw)
      /etc/skupper-router-certs/skupper-amqps/ from skupper-local-server (rw)
      /etc/skupper-router-certs/skupper-internal/ from skupper-site-server (rw)
      /etc/skupper-router/config/ from router-config (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bngdq (ro)
  config-sync:
    Container ID:   cri-o://9efbd957a90810e76ff0ab2437bcdc80113be0e9b5c298073ef5fa1007d40828
    Image:          quay.io/skupper/config-sync:1.0.2
    Image ID:       quay.io/skupper/config-sync@sha256:bc590b33af5aceebcb864d0325a280c816cd5f0466d8a69de250e2620854e054
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Fri, 08 Jul 2022 13:06:51 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/skupper-router-certs from skupper-router-certs (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bngdq (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  skupper-local-server:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-local-server
    Optional:    false
  router-config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      skupper-internal
    Optional:  false
  skupper-site-server:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-site-server
    Optional:    false
  skupper-router-certs:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  kube-api-access-bngdq:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
    ConfigMapName:           openshift-service-ca.crt
    ConfigMapOptional:       <nil>
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason          Age    From               Message
  ----    ------          ----   ----               -------
  Normal  Scheduled       2m44s  default-scheduler  Successfully assigned namespacex/skupper-router-7fdf5b5f4d-d8d2h to ip-X-X-X-X.ap-south-1.compute.internal
  Normal  AddedInterface  2m43s  multus             Add eth0 [10.130.0.220/23] from openshift-sdn
  Normal  Pulling         2m43s  kubelet            Pulling image "quay.io/skupper/skupper-router:2.0.2"
  Normal  Pulled          2m40s  kubelet            Successfully pulled image "quay.io/skupper/skupper-router:2.0.2" in 2.380201721s
  Normal  Created         2m40s  kubelet            Created container router
  Normal  Started         2m40s  kubelet            Started container router
  Normal  Pulling         2m40s  kubelet            Pulling image "quay.io/skupper/config-sync:1.0.2"
  Normal  Pulled          2m38s  kubelet            Successfully pulled image "quay.io/skupper/config-sync:1.0.2" in 2.36201398s
  Normal  Created         2m38s  kubelet            Created container config-sync
  Normal  Started         2m38s  kubelet            Started container config-sync 
````


## PatiUdayKiran-ab-scm 2022-07-08T13:16:34Z

Skupper Service Controller Details
````
Name:         skupper-service-controller-7879cbd6b5-fp2j9
Namespace:    namespacex
Priority:     0
Node:         ip-X-X-X-X.ap-south-1.compute.internal/X.X.X.X
Start Time:   Fri, 08 Jul 2022 13:05:50 +0000
Labels:       app.kubernetes.io/name=skupper-service-controller
              app.kubernetes.io/part-of=skupper
              pod-template-hash=7879cbd6b5
              skupper.io/component=service-controller
Annotations:  k8s.v1.cni.cncf.io/network-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.130.0.219"
                    ],
                    "default": true,
                    "dns": {}
                }]
              k8s.v1.cni.cncf.io/networks-status:
                [{
                    "name": "openshift-sdn",
                    "interface": "eth0",
                    "ips": [
                        "10.130.0.219"
                    ],
                    "default": true,
                    "dns": {}
                }]
              openshift.io/scc: restricted
              traffic.sidecar.istio.io/excludeInboundPorts: 5671,5672,45671,55671,8081,8080
              traffic.sidecar.istio.io/excludeOutboundPorts: 5671,5672,45671,55671,8081
Status:       Running
IP:           10.130.0.219
IPs:
  IP:           10.130.0.219
Controlled By:  ReplicaSet/skupper-service-controller-7879cbd6b5
Containers:
  service-controller:
    Container ID:   cri-o://16549eb884cb653abba0c387bcb440624e3bb09177eab775680d4ed2f37eb493
    Image:          quay.io/skupper/service-controller:1.0.2
    Image ID:       quay.io/skupper/service-controller@sha256:e948b0481cc1b9dc4df2c28f2af55a232d1dd2da5354c98b7a632ba920968f1a
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Fri, 08 Jul 2022 13:05:55 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      SKUPPER_NAMESPACE:        namespacex
      SKUPPER_SITE_NAME:        namespacex
      SKUPPER_SITE_ID:          fae3351d-e601-469e-abc0-42d5c8a82795
      SKUPPER_SERVICE_ACCOUNT:  skupper-router
      SKUPPER_ROUTER_MODE:      interior
      OWNER_NAME:               skupper-router
      OWNER_UID:                e500cdd8-05c7-4791-a502-1d546b293888
      METRICS_USERS:            /etc/console-users
    Mounts:
      /etc/console-users/ from skupper-console-users (rw)
      /etc/messaging/ from skupper-local-client (rw)
      /etc/service-controller/certs/ from skupper-claims-server (rw)
      /etc/service-controller/console/ from skupper-console-certs (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-fvjmn (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  skupper-console-users:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-console-users
    Optional:    false
  skupper-claims-server:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-claims-server
    Optional:    false
  skupper-console-certs:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-console-certs
    Optional:    false
  skupper-local-client:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  skupper-local-client
    Optional:    false
  kube-api-access-fvjmn:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
    ConfigMapName:           openshift-service-ca.crt
    ConfigMapOptional:       <nil>
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason          Age    From               Message
  ----    ------          ----   ----               -------
  Normal  Scheduled       8m37s  default-scheduler  Successfully assigned namespacex/skupper-service-controller-7879cbd6b5-fp2j9 to ip-X-X-X-X.ap-south-1.compute.internal
  Normal  AddedInterface  8m35s  multus             Add eth0 [10.130.0.219/23] from openshift-sdn
  Normal  Pulling         8m35s  kubelet            Pulling image "quay.io/skupper/service-controller:1.0.2"
  Normal  Pulled          8m32s  kubelet            Successfully pulled image "quay.io/skupper/service-controller:1.0.2" in 2.340227794s
  Normal  Created         8m32s  kubelet            Created container service-controller
  Normal  Started         8m32s  kubelet            Started container service-controller 
````


## PatiUdayKiran-ab-scm 2022-07-08T13:18:03Z

Skupper Service Controller Logs

````
2022/07/08 13:05:55 Skupper service controller
2022/07/08 13:05:55 Version: 1.0.2
2022/07/08 13:05:55 Setting up event handlers
2022/07/08 13:05:55 Waiting for Skupper router component to start
2022/07/08 13:06:00 Starting the Skupper controller
2022/07/08 13:06:00 Waiting for informer caches to sync
2022/07/08 13:06:00 Starting workers
2022/07/08 13:06:00 Claim verifier listening on :8081
2022/07/08 13:06:00 Console server listening on :8080
2022/07/08 13:06:00 Started workers
2022/07/08 13:06:00 Skupper policy is disabled
````


## PatiUdayKiran-ab-scm 2022-07-08T13:21:21Z

Skupper Router Pod Logs

````
Waiting for IP address...
Waiting for IP address...
Waiting for IP address...
2022-07-08 13:06:52.598055 +0000 SERVER (info) Container Name: namespacex-skupper-router-7fdf5b5f4d-d8d2h
2022-07-08 13:06:52.598153 +0000 ROUTER (info) Router started in Interior mode, area=0 id=namespacex-skupper-router-7fdf5b5f4d-d8d2h
2022-07-08 13:06:52.598164 +0000 ROUTER (info) Version: 2.0.2
2022-07-08 13:06:52.598655 +0000 ROUTER_CORE (info) Streaming link scrubber: Scan interval: 30 seconds, max free pool: 128 links
2022-07-08 13:06:52.598673 +0000 ROUTER_CORE (info) Core module enabled: streaming_link_scrubber
2022-07-08 13:06:52.599942 +0000 ROUTER_CORE (info) Core module enabled: mobile_sync
2022-07-08 13:06:52.599966 +0000 ROUTER_CORE (info) Stuck delivery detection: Scan interval: 30 seconds, Delivery age threshold: 10 seconds
2022-07-08 13:06:52.599974 +0000 ROUTER_CORE (info) Core module enabled: stuck_delivery_detection
2022-07-08 13:06:52.599989 +0000 ROUTER_CORE (info) Core module enabled: heartbeat_server
2022-07-08 13:06:52.599995 +0000 ROUTER_CORE (info) Core module present but disabled: heartbeat_edge
2022-07-08 13:06:52.600001 +0000 ROUTER_CORE (info) Core module enabled: address_lookup_client
2022-07-08 13:06:52.600010 +0000 ROUTER_CORE (info) Core module enabled: edge_addr_tracking
2022-07-08 13:06:52.600016 +0000 ROUTER_CORE (info) Core module present but disabled: core_test_hooks
2022-07-08 13:06:52.600021 +0000 ROUTER_CORE (info) Core module present but disabled: edge_router
2022-07-08 13:06:52.600130 +0000 ROUTER_CORE (info) Protocol adaptor registered: http2
2022-07-08 13:06:52.600157 +0000 ROUTER_CORE (info) Protocol adaptor registered: tcp
2022-07-08 13:06:52.600210 +0000 ROUTER_CORE (info) Protocol adaptor registered: http/1.x
2022-07-08 13:06:52.600262 +0000 ROUTER_CORE (info) Protocol adaptor registered: amqp
2022-07-08 13:06:52.600598 +0000 ROUTER (info) Router Engine Instantiated: id=namespacex-skupper-router-7fdf5b5f4d-d8d2h instance=1657285612 max_routers=128
2022-07-08 13:06:52.601008 +0000 FLOW_LOG (info) Protocol logging started
2022-07-08 13:06:52.602611 +0000 ROUTER_CORE (info) Router Core thread running. 0/namespacex-skupper-router-7fdf5b5f4d-d8d2h
2022-07-08 13:06:52.602637 +0000 ROUTER_CORE (info) In-process subscription L/qdrouter.ma
2022-07-08 13:06:52.602651 +0000 ROUTER_CORE (info) In-process subscription T/qdrouter.ma
2022-07-08 13:06:52.602657 +0000 ROUTER_CORE (info) In-process subscription M/$management
2022-07-08 13:06:52.602725 +0000 ROUTER_CORE (info) In-process subscription L/$management
2022-07-08 13:06:52.602732 +0000 ROUTER_CORE (info) In-process subscription L/qdrouter
2022-07-08 13:06:52.602736 +0000 ROUTER_CORE (info) In-process subscription T/qdrouter
2022-07-08 13:06:52.602741 +0000 ROUTER_CORE (info) In-process subscription L/qdhello
2022-07-08 13:06:52.615196 +0000 AGENT (info) Activating management agent on $_management_internal
2022-07-08 13:06:52.615601 +0000 ROUTER_CORE (info) In-process subscription L/$_management_internal
2022-07-08 13:06:52.617839 +0000 POLICY (info) Policy configured maxConnections: 65535, policyDir: '',access rules enabled: 'false', use hostname patterns: 'false'
2022-07-08 13:06:52.618893 +0000 POLICY (info) Policy fallback defaultVhost is defined: '$default'
2022-07-08 13:06:52.619359 +0000 CONN_MGR (info) Created SSL Profile with name skupper-amqps 
2022-07-08 13:06:52.620327 +0000 CONN_MGR (info) Created SSL Profile with name skupper-service-client 
2022-07-08 13:06:52.621204 +0000 CONN_MGR (info) Created SSL Profile with name skupper-internal 
2022-07-08 13:06:52.623268 +0000 CONN_MGR (info) Configured Listener: :9090 proto=any, role=normal, http
2022-07-08 13:06:52.625061 +0000 CONN_MGR (info) Configured Listener: localhost:5672 proto=any, role=normal
2022-07-08 13:06:52.626505 +0000 CONN_MGR (info) Configured Listener: :5671 proto=any, role=normal, sslProfile=skupper-amqps
2022-07-08 13:06:52.627845 +0000 CONN_MGR (info) Configured Listener: :55671 proto=any, role=inter-router, sslProfile=skupper-internal
2022-07-08 13:06:52.628971 +0000 SERVER (info) HTTP server thread running
2022-07-08 13:06:52.629232 +0000 SERVER (notice) Listening for HTTP on :9090
2022-07-08 13:06:52.629272 +0000 CONN_MGR (info) Configured Listener: :45671 proto=any, role=edge, sslProfile=skupper-internal
2022-07-08 13:06:52.630149 +0000 SERVER (notice) Operational, 4 Threads Running (process ID 1)
2022-07-08 13:06:52.630303 +0000 SERVER (notice) Process VmSize 327.40 MiB (30.95 GiB available memory)
2022-07-08 13:06:52.630472 +0000 SERVER (notice) Listening on localhost:5672
2022-07-08 13:06:52.630491 +0000 SERVER (notice) Listening on :5671
2022-07-08 13:06:52.630499 +0000 SERVER (notice) Listening on :55671
2022-07-08 13:06:52.630507 +0000 SERVER (notice) Listening on :45671
2022-07-08 13:06:53.040837 +0000 SERVER (info) [C1] Accepted connection to localhost:5672 from ::1:44178
2022-07-08 13:06:53.041118 +0000 ROUTER_CORE (info) [C1] Connection Opened: dir=in host=::1:44178 encrypted=no auth=no user=anonymous container_id=AtJ-cEdp3AnkPDRFr6YZ16Ng4j8OOf6e8DQYHWNJpCfHfk2-2yPIjg props=
2022-07-08 13:06:53.041601 +0000 ROUTER_CORE (info) [C1][L2] Link attached: dir=out source={(dyn)<none> expire:sess} target={<none> expire:sess}
2022-07-08 13:06:53.042007 +0000 ROUTER_CORE (info) [C1][L3] Link attached: dir=in source={<none> expire:sess} target={$management expire:sess}
2022-07-08 13:06:53.042246 +0000 ROUTER_CORE (info) [C1][L4] Link attached: dir=in source={<none> expire:sess} target={<none> expire:sess}
2022-07-08 13:06:53.354716 +0000 SERVER (info) [C2] Accepted connection to :5671 from 10.130.0.219:35564
2022-07-08 13:06:53.355472 +0000 SERVER (info) [C3] Accepted connection to :5671 from 10.130.0.219:35562
2022-07-08 13:06:53.365434 +0000 ROUTER_CORE (info) [C2] Connection Opened: dir=in host=10.130.0.219:35564 encrypted=TLSv1.3 auth=EXTERNAL user=CN=skupper-router-local container_id=K7dvGxGGQ5qdlpWD18OYptPA9lkUiEBaCNh2JvkHuSilWjWak6ZLDw props=
2022-07-08 13:06:53.366097 +0000 ROUTER_CORE (info) [C2][L5] Link attached: dir=out source={(dyn)<none> expire:sess} target={<none> expire:sess}
2022-07-08 13:06:53.366754 +0000 ROUTER_CORE (info) [C2][L6] Link attached: dir=in source={<none> expire:sess} target={$management expire:sess}
2022-07-08 13:06:53.367116 +0000 ROUTER_CORE (info) [C2][L7] Link attached: dir=in source={<none> expire:sess} target={<none> expire:sess}
2022-07-08 13:06:53.368445 +0000 ROUTER_CORE (info) [C2][L8] Link attached: dir=out source={fae3351d-e601-469e-abc0-42d5c8a82795/skupper-site-query expire:sess} target={<none> expire:sess}
2022-07-08 13:06:53.369446 +0000 ROUTER_CORE (info) [C3] Connection Opened: dir=in host=10.130.0.219:35562 encrypted=TLSv1.3 auth=EXTERNAL user=CN=skupper-router-local container_id=urVnVcoZQHXsXFigt28V3sWBo5ZVa98fGuP7S8TgtCL9OEoMU-Wceg props=
2022-07-08 13:06:53.369822 +0000 ROUTER_CORE (info) [C3][L9] Link attached: dir=out source={mc/$skupper-service-sync expire:sess} target={<none> expire:sess}
2022-07-08 13:06:55.411406 +0000 SERVER (info) [C4] Accepted connection to :5671 from 10.130.0.219:35666
2022-07-08 13:06:55.420587 +0000 ROUTER_CORE (info) [C4] Connection Opened: dir=in host=10.130.0.219:35666 encrypted=TLSv1.3 auth=EXTERNAL user=CN=skupper-router-local container_id=lOYfyiByzQ-SmtlLw0aQ42_Rjx5atFZpqEl8LD_AHE8armWCIxR9fQ props=
2022-07-08 13:06:55.421200 +0000 ROUTER_CORE (info) [C4][L10] Link attached: dir=in source={<none> expire:sess} target={mc/$skupper-service-sync expire:sess}
````


## grs 2022-07-08T13:48:01Z

Try to curl 10.130.0.219:8080 from inside the namespace.

There is no istio proxy sidecar on either pod in those details, but the annotations are at least as expected. I forgot 9090 for the router though, is it running ok or being restarted frequently? Logs for router show service controller has connected ok.

Also try: `kubectl exec -it <skupper-service-controller-pod-name> get events`


## PatiUdayKiran-ab-scm 2022-07-08T16:16:30Z

```
bash-4.4$ curl 10.130.0.219:8080
Client sent an HTTP request to an HTTPS server
```
-- get events

````
NAME                   COUNT                                                              AGE
ServiceSyncEvent       47                                                                 3h10m17s
                       2     Service sync sender connection to                            3h10m17s
                             amqps://skupper-router-local.namespacex.svc.cluster.local:5671
                             established
                       1     Error sending out updates: EOF                               3h10m17s
                       2     Service sync receiver connection to                          3h10m19s
                             amqps://skupper-router-local.namespacex.svc.cluster.local:5671
                             established
                       41    Error receiving updates: dial tcp X.X.X.X:5671:       3h10m20s
                             connect: connection refused
                       1     Error receiving updates: EOF                                 3h10m20s
IpMappingEvent         16                                                                 3h10m19s
                       1     mapping for 10.130.0.205 deleted                             3h10m19s
                       3     10.130.0.205 mapped to skupper-router-579c9ccc84-xz8ws       3h10m19s
                       1     10.130.0.220 mapped to skupper-router-7fdf5b5f4d-d8d2h       3h10m20s
                       4      mapped to skupper-router-7fdf5b5f4d-d8d2h                   3h10m26s
                       1     10.130.0.41 mapped to gty-qry-inventory-55ddf58f6b-g9mwv     3h11m12s
SiteQueryError         42                                                                 3h10m20s
                       41    Error handling requests: Could not get management agent:     3h10m20s
                             Failed to create connection: dial tcp X.X.X.X:5671:
                             connect: connection refused
                       1     Error handling requests: Error handling request for          3h10m20s
                             fae3351d-e601-469e-abc0-42d5c8a82795/skupper-site-query:
                             Failed reading request from
                             fae3351d-e601-469e-abc0-42d5c8a82795/skupper-site-query: EOF
````


## grs 2022-07-08T16:58:11Z

That looks like it is working... what do you see for `skupper status`?


## PatiUdayKiran-ab-scm 2022-07-10T11:39:13Z

No, The UI is not working. Still the same error.


## grs 2022-07-10T20:09:23Z

Try `curl https://10.130.0.219:8080` from inside the cluster. What do `oc get route` and `oc get svc` show?


## michaelalang 2023-06-18T09:41:41Z

with OpenShift ServiceMesh 2.4 and `cluster mode` Skupper is working properly with mTLS enforced.
All you need to ensure is that ServiceEntries for peer systems are in place. 

`$ oc -n skupper get pods -o jsonpath='{.items[*].status.containerStatuses}' | jq -r ' .[]| .name + " " + .image'
config-sync registry.redhat.io/application-interconnect/skupper-config-sync-rhel8@sha256:5e01564d9f2f6a4929cf01f9d81652bff007834ffcc6727eac6c90bd8b71869e
istio-proxy registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:07e174d5df7062b5f398291aed31cd01b874c8a6491ba6148675955b9d77ac5b
router registry.redhat.io/application-interconnect/skupper-router-rhel8@sha256:8f49633e98e4c8900a32cdbb5a67b859be188525305b969f019e4d445b5488f0
istio-proxy registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:07e174d5df7062b5f398291aed31cd01b874c8a6491ba6148675955b9d77ac5b
service-controller registry.redhat.io/application-interconnect/skupper-service-controller-rhel8@sha256:1a5f058401b10ecd45dc0841e485d73a686de8d0c20dcb1139f26c550677997b
`


## JonkeyGuan 2024-03-06T10:32:48Z

> with OpenShift ServiceMesh 2.4 and `cluster mode` Skupper is working properly with mTLS enforced. All you need to ensure is that ServiceEntries for peer systems are in place.
> 
> `$ oc -n skupper get pods -o jsonpath='{.items[*].status.containerStatuses}' | jq -r ' .[]| .name + " " + .image' config-sync registry.redhat.io/application-interconnect/skupper-config-sync-rhel8@sha256:5e01564d9f2f6a4929cf01f9d81652bff007834ffcc6727eac6c90bd8b71869e istio-proxy registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:07e174d5df7062b5f398291aed31cd01b874c8a6491ba6148675955b9d77ac5b router registry.redhat.io/application-interconnect/skupper-router-rhel8@sha256:8f49633e98e4c8900a32cdbb5a67b859be188525305b969f019e4d445b5488f0 istio-proxy registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:07e174d5df7062b5f398291aed31cd01b874c8a6491ba6148675955b9d77ac5b service-controller registry.redhat.io/application-interconnect/skupper-service-controller-rhel8@sha256:1a5f058401b10ecd45dc0841e485d73a686de8d0c20dcb1139f26c550677997b `

Please can you provide a sample?


## ibrassfield 2026-01-23T22:32:51Z

just curious if there was ever a resolution ? is there an example 



## michaelalang 2026-01-24T19:44:40Z

@ibrassfield https://github.com/michaelalang/rhsi-hackfest/blob/main/README.md but that code and assumed versions are old now 

