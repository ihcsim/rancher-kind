# Rancher On KinD

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

To delete the entire KinD cluster:
```sh
make purge
```
