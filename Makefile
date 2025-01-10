SHELL := /bin/bash

VERSION_CERT_MANAGER ?= v1.16.2
VERSION_RANCHER ?= v2.9.3
CLUSTER_NAME ?= isim-dev
CLUSTER_HOST_IP ?= 192.168.1.73

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config ./kind.yaml

ingress:
	kubectl apply -f ./ingress-nginx.yaml

repos:
	helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
	helm repo add jetstack https://charts.jetstack.io
	helm repo update

cert-manager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$(VERSION_CERT_MANAGER)/cert-manager.crds.yaml
	helm install cert-manager jetstack/cert-manager \
  --create-namespace \
  --namespace cert-manager \
  --set image.tag=$(VERSION_CERT_MANAGER)

rancher:
	helm install rancher rancher-latest/rancher \
  --create-namespace \
  --namespace cattle-system \
  --set rancherImageTag=$(VERSION_RANCHER) \
  --set hostname=$(CLUSTER_HOST_IP).sslip.io \
  --set replicas=1 \
  --set-file bootstrapPassword=.auth/rancher-bootstrap
