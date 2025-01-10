SHELL := /bin/bash

VERSION_CERT_MANAGER ?= v1.16.2
VERSION_RANCHER ?= v2.9.3
CLUSTER_NAME ?= isim-dev
CLUSTER_HOST_IP ?= 192.168.1.73

repos:
	helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
	helm repo add jetstack https://charts.jetstack.io
	helm repo update

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config ./kind.yaml

ingress:
	kubectl apply -f ./ingress-nginx.yaml
	kubectl -n ingress-nginx wait --for=jsonpath='{.status.conditions[?(@.type=="Available")].status}=True' deploy/ingress-nginx-controller
	kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller

cert-manager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$(VERSION_CERT_MANAGER)/cert-manager.crds.yaml
	helm install cert-manager jetstack/cert-manager \
	--create-namespace \
	--namespace cert-manager \
	--set image.tag=$(VERSION_CERT_MANAGER)
	for deploy in cert-manager cert-manager-webhook cert-manager-cainjector; do \
		kubectl -n cert-manager wait --for=jsonpath='{.status.conditions[?(@.type=="Available")].status}=True' deploy/$${deploy}; \
		kubectl -n cert-manager rollout status deploy/$${deploy} ;\
	done

rancher:
	helm install rancher rancher-latest/rancher \
	--create-namespace \
	--namespace cattle-system \
	--set hostname=$(CLUSTER_HOST_IP).sslip.io \
	--set rancherImageTag=$(VERSION_RANCHER) \
	--set replicas=1 \
	for deploy in rancher rancher-webhook; do \
		kubectl -n cattle-system wait --for=jsonpath='{.status.conditions[?(@.type=="Available")].status}=True' deploy/$${deploy}; \
		kubectl -n cattle-system rollout status deploy/$${deploy} ;\
	done

purge:
	kind delete cluster --name $(CLUSTER_NAME)
