# Rancher On KinD

This project provides a Makefile to deploy Rancher on KinD.

## Prerequisites

Download and install these software:
  * [kubectl](https://kubernetes.io/docs/tasks/tools/)
  * [Helm](https:///helm.sh)
  * [KinD](https://kind.sigs.k8s.io/) (and Docker)

Set up a 3-node Harvester cluster following the instructions
[here](https://docs.harvesterhci.io/v1.4/install/index)

For development purposes, the following node specification should suffice:

Node Role | Node Count | vCPU | RAM  | Disk
----------|------------|------|------|------
management| 1          | 4    | 16GB | 250GB
worker    | 3          | 4    | 16GB | 250GB

### KinD Cluster Configuration

The KinD cluster is configured with host port mappings to allow HTTP/HTTPS access
from the host to the in-cluster Rancher UI.

The Rancher bootstrap password was not set during installation due to
https://github.com/rancher/rancher/issues/34686. This allows Rancher to
auto-generate a random password, per
https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/bootstrap-password

## Usage

To create a new KinD cluster:
```sh
make cluster \
  CLUSTER_NAME=<cluster-name> \
  CLUSTER_HOST_IP=<cluster-host-ip>
```

To set up Helm repo:
```sh
make repo
```

Install the dependencies: Nginx Ingress Controller, cert-manager:
```sh
make ingress cert-manager
```

Install Rancher:
```sh
make rancher
```

To get the Rancher UI URL and login password:
```sh
make rancher-url

make rancher-password
```

## Rancher/Harvester Integration

### Configure Rancher

This section describes configuration to be done on Rancher.

Use the 'Virtualization Management' page to import the Harvester cluster. Follow
the generated instructions.

Once the Harvester cluster is successfully imported, download its kubeconfig file
from the settings (`:`) menu.

### Configure Harvester

This section describes configuration to be done on Harvester.

Create a namespace for the guest cluster: `kubectl create ns <namespace>`

On the 'Images' page, add a new OS image for the guest cluster to the guest
cluster namespace. For testing purposes, the Ubuntu `jammy` cloud image can be
downloaded from
[here](https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img)

Create a new untagged network to the guest cluster namespace via the 'Virtual
Machine Network' section under the 'Networks' page. The untagged network should
have the following properties:

* Type: `UntaggedNetwork`
* Cluster Network: `mgmt`

An SSH public key can be injected into the guest cluster nodes by adding them to
the 'SSH Keys' section under the 'Advanced' page.

Retrieve the Rancher CA certifcate:
```sh
kubectl -n cattle-system get secret tls-rancher-ingress -ojsonpath='{.data.ca\.crt}' | base64 -d -
```

Add this certificate to Harvester's trust chain via the 'additional-ca' settings
on the 'Settings' page.

## Deploy RKE2 Guest Cluster On Harvester

Guest cluster nodes specification:

Pool Name | Node Count              | vCPU | RAM | Disk
----------|-------------------------|------|-----|-----
pool1     | 2 control plane, 2 etcd | 2    | 4GB | 10GB
pool2     | 1 worker                | 2    | 4GB | 10GB
pool3     | 1 etcd                  | 1    | 4GB | 10GB

- Create RKE2 cluster:
- Select guest cluster namespace
- Use untagged VLAN network

On resource constrained environment, disable Nginx ingress controller and metrics
server.

Add `iptables` to list of packages to be installed in the cloud-config:
```
#cloud-config
package_update: true
packages:
  - qemu-guest-agent
  - iptables
runcmd:
  - - systemctl
    - enable
    - '--now'
    - qemu-guest-agent.service
```

- Download guest cluster kubeconfig

## Clean Up

To delete the entire KinD cluster:
```sh
make purge
```
