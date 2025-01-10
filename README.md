# Rancher On KinD

This project provides a Makefile to deploy Rancher on KinD.

Prerequisites:

* Download and install these software:
  * kubectl
  * Helm
  * KinD (and Docker)

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
	CLUSTER_NAME=<cluster-name>
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

To delete the entire KinD cluster:
```sh
make purge
```
