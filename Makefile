SHELL := /bin/bash

VERSION_CERT_MANAGER ?= v1.16.2
VERSION_RANCHER ?= v2.10.2
CLUSTER_NAME ?=
CLUSTER_PRIVATE_IP ?= 192.168.1.73
CLUSTER_HOSTNAME ?=

repos:
	helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
	helm repo add jetstack https://charts.jetstack.io
	helm repo update

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config ./kind.yaml
	rm -f $(HOME)/.rancher-kind
	mkdir -p $(HOME)/.rancher-kind
	echo "name: $(CLUSTER_NAME)" >> $(HOME)/.rancher-kind/cluster.yaml

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
	if [ ! -z $(CLUSTER_HOSTNAME) ]; then \
		echo "hostname: $(CLUSTER_HOSTNAME)" >> $(HOME)/.rancher-kind/cluster.yaml ;\
	elif [ ! -z $(CLUSTER_PRIVATE_IP) ]; then \
		echo "hostname: $(CLUSTER_PRIVATE_IP).sslip.io" >> $(HOME)/.rancher-kind/cluster.yaml ;\
	fi;\
	helm install rancher rancher-latest/rancher \
	--create-namespace \
	--namespace cattle-system \
	--set hostname=$(shell cat $(HOME)/.rancher-kind/cluster.yaml | yq .hostname) \
	--set rancherImageTag=$(VERSION_RANCHER) \
	--set replicas=1
	for deploy in rancher; do \
		kubectl -n cattle-system wait --timeout=1200s --for=jsonpath='{.status.conditions[?(@.type=="Available")].status}=True' deploy/$${deploy}; \
		kubectl -n cattle-system rollout status deploy/$${deploy} ;\
	done

rancher-url:
	@hostname=$(shell cat $(HOME)/.rancher-kind/cluster.yaml | yq .hostname) ;\
	echo https://$$(hostname)/dashboard/?setup=$(shell kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')

rancher-password:
	@kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'

rancher-reset-password:
	kubectl -n cattle-system exec -it deploy/rancher -- reset-password

purge:
	kind delete cluster --name $(CLUSTER_NAME)
