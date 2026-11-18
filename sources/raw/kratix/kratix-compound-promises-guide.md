---
type: source
title: "Kratix: Compound Promises guide"
resource: "https://docs.kratix.io/main/guides/compound-promises"
source_kind: webpage
tags: ["kratix", "compound-promises"]
timestamp: 2026-10-22T00:00:00Z
fetch_note: "obscura fetch --stealth --dump text. Plain-text dump: markup lost, so YAML/code blocks are flattened to unindented lines; indentation-dependent examples are not reliable here. Docs \"main\" branch as of 2026-10-22."
---

# Kratix: Compound Promises guide

Skip to main content

On this page

Compound Promises are Promises that depend on other Promises to deliver their promised service.
The abiltiy to chain Promises together allows platform teams to deliver entire stacks on demand, while keeping each sub-Promise small and focused on its own service.

In this tutorial, you will

Encapsulate multiple Promises into a Compound Promise

Request a complete development environment Resource through a Compound Promise

Pre-requisites​
You need an installation of Kratix for this section. Click here for instructions

The simplest way to do so is by running the quick-start script from within the
Kratix directory. The script will create two KinD clusters, install, and
configure Kratix.

./scripts/quick-start.sh --recreate

You can run Kratix either with a multi-cluster or a single-cluster setup. The
commands on the remainder of this document assume that two environment variables
are set:

PLATFORM representing the platform cluster Kubernetes context

WORKER representing the worker cluster Kubernetes context

If you ran the quick-start script above, do:

export PLATFORM="kind-platform"

export WORKER="kind-worker"

For single cluster setups, the two variables should be set to the same value.
You can find your cluster context by running:

kubectl config get-contexts

Refer back to Installing Kratix for more
details.

Register the Platform as a Destination​

Compound Promises work by scheduling their workflow outputs to the Platform cluster itself. For that to work, you will need to register the Platform cluster as a Destination, and run a GitOps Agent in the Platform cluster listening to the State Store associated with the platform destination.

Create a new Destination document - platform-cluster.yaml - with the following contents:

platform-cluster.yaml

apiVersion: platform.kratix.io/v1alpha1

kind: Destination

metadata:

name: platform-cluster

labels:

environment: platform

spec:

path: platform-cluster

strictMatchLabels: true

stateStoreRef:

name: default

kind: BucketStateStore

Register the Destination:

kubectl --context $PLATFORM apply --filename platform-cluster.yaml

Install and configure GitOps​

Now that your Destination is registered, make sure to install the GitOps Agent into your Platform cluster. The quickest way to do that is to run the ./scripts/install-gitops script from the Kratix root directory:

cd /path/to/kratix

./scripts/install-gitops --context $PLATFORM --path platform-cluster

Install a Compound Promise​

In the Kratix Marketplace there's an example Compound Promise that provides Apps-as-a-Service. Go ahead and install that promise:

kubectl --context $PLATFORM apply --filename https://raw.githubusercontent.com/syntasso/kratix-marketplace/refs/heads/main/app-as-a-service/promise.yaml

This Promise is composed of a NGINX and Postgres Promise. When you applied the promise, you should've seen a warning in the output saying the required promises are not available. In fact, the App promise itself should be marked as Unavailable:

$ kubectl --context $PLATFORM get promises

NAME   STATUS        KIND   API VERSION                VERSION

app    Unavailable   app    marketplace.kratix.io/v1   v1.0.0-beta.1

You can make the promise available by installing the required promises:

kubectl --context $PLATFORM apply --filename https://raw.githubusercontent.com/syntasso/promise-postgresql/ee05fdd0c37c13fed7241ad90bd028de29000943/promise.yaml

kubectl --context $PLATFORM apply --filename https://raw.githubusercontent.com/syntasso/kratix-marketplace/main/nginx-ingress/promise.yaml

Once these two Promises become available, you should see the App promise becoming available as well:

$ kubectl --context $PLATFORM get promises

NAME            STATUS      KIND         API VERSION                      VERSION

app             Available   app          marketplace.kratix.io/v1         v1.0.0-beta.1

nginx-ingress   Available                                                 v1.0.0-beta.2

postgresql      Available   postgresql   marketplace.kratix.io/v1alpha2   v1.0.0-beta.5

$ kubectl --context $WORKER get pods

NAME                                              READY   STATUS    RESTARTS   AGE

nginx-nginx-ingress-controller-6fd8bbcf49-fdnnz   1/1     Running   0          87s

postgres-operator-578ff5d886-qcwz8                1/1     Running   0          87s

$ kubectl --context $WORKER get crds | grep nginx

dnsendpoints.externaldns.nginx.org           2026-03-04T11:39:57Z

globalconfigurations.k8s.nginx.org           2026-03-04T11:39:57Z

policies.k8s.nginx.org                       2026-03-04T11:39:57Z

transportservers.k8s.nginx.org               2026-03-04T11:39:57Z

virtualserverroutes.k8s.nginx.org            2026-03-04T11:39:57Z

virtualservers.k8s.nginx.org                 2026-03-04T11:39:57Z

Send a request for a Resource​

When a new resource request is created, the Compound Promise's Workflow is triggered. The Workflow will output a resource request for the Postgres Promise, and produce the Ingress rules using the NGINX Ingress Controller. Create a resource request for the App-as-a-Service Promise:

kubectl --context $PLATFORM apply --filename https://raw.githubusercontent.com/syntasso/kratix-marketplace/main/app-as-a-service/resource-request.yaml

You should see the Workflow for the App-as-a-Service Promise running, which will in turn trigger the Postgres Promise:

$ kubectl --context $PLATFORM get pods

NAME                                                        READY   STATUS      RESTARTS   AGE

kratix-app-todoer-resource-configure-b8535-hbq2b            0/1     Completed   0          1m

kratix-postgresql-todoerdb-instance-configure-83965-d5gc8   0/1     Completed   0          1m

Eventually, the resources will be ready to be used:

$ kubectl --context $WORKER get pods -A

NAMESPACE            NAME                                              READY   STATUS    RESTARTS   AGE

default              nginx-nginx-ingress-controller-6fd8bbcf49-fdnnz   1/1     Running   0          1m

default              postgres-operator-578ff5d886-qcwz8                1/1     Running   0          1m

default              todoer-58d6d695cb-2jsxg                           1/1     Running   0          1m

default              todoerteam-todoerdb-postgresql-0                  1/1     Running   0          1m

🎉 Congratulations: you have installed a Compound Promise and requested a App-as-a-Service Resource!

A closer look in the Promise​

Start by noticing the requiredPromises in the Promise spec:

apiVersion:

apiVersion: platform.kratix.io/v1alpha1

kind: Promise

metadata:

name: app

spec:

# ...

requiredPromises:

- name: postgresql

version: v1.0.0-beta.5

- name: nginx-ingress

version: v1.0.0-beta.2

# ...

This is what tells Kratix that this Promise depends on the other Promises, on the particular version specified. When the required Promises are not available at install time, you will see the warning on the output. When the required Promises are available, the Promise will be marked as Available.

Kratix resolves each required version against the Promise
Revisions of the required Promise, and Promise Revisions are
retained by Kratix across Promise upgrades. See Compound
Promises for the full resolution rules, for example what happens when a required
Promise stops being Available.

Next, let's take a look at the destinationSelectors key:

apiVersion: platform.kratix.io/v1alpha1

kind: Promise

metadata:

name: app

spec:

destinationSelectors:

- matchLabels:

environment: platform

The App-as-a-Service Promise destinationSelectors are set to target clusters with matchLabel equal to environment: platform. In other words, that is telling Kratix to send any output of the workflows of the App Promise into Destinations with an environment: platform label.

You may have noticed that, when registering the Platform Destination, the Destination definition
included exactly that label. You can verify the applied labels with:

$ kubectl --context $PLATFORM get destinations.platform.kratix.io --show-labels

NAME               STATESTOREKIND     STATESTORENAME   READY   LABELS

platform-cluster   BucketStateStore   default          True    environment=platform

worker-1           BucketStateStore   default          True    environment=dev

The sub-Promises themselves also have their own destinationSelectors key. For example, the Postgres Promise has the following selectors:

$ kubectl --context $PLATFORM describe promise postgresql | grep "Destination Selectors" -A 2

Destination Selectors:

Match Labels:

Environment:  dev

This configuration ensures the Postgres Operator is installed exclusively in the Worker destination. This stops requests for Postgres resources being scheduled to the Platform destination accidentally.

A closer look in the Workflow​

When a request for a Resource is created, the App Promise Workflow is triggered. Usually, the
output of the Workflow is a set of Kubernetes Resources that need to be created. For
Compound Promises, that's usually a set of requests for other promised Resources to be applied in the Platform itself.

The App Promise Workflow is a very basic example, but you can see that's exactly what the
Workflow Pipeline is doing by checking the pipeline code here. The stage is creating a request for Postgres, and generating a set of resources to deploy the application, including the Ingress rules using the NGINX Ingress Controller.

🎉 Congratulations​

✅   You have just installed and used your first Compound Promise.

If you want to learn more about Compound Promises, you can check the Compound Promise Workshop, or check out this blog post for a more detailed explanation.

Register the Platform as a Destination

Install and configure GitOps

Install a Compound Promise

Send a request for a Resource

A closer look in the Promise

A closer look in the Workflow

🎉 Congratulations
