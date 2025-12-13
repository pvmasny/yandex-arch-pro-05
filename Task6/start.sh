#!/usr/bin/env bash
minikube stop
# minikube delete --purge

mkdir -p ~/.minikube/files/etc/ssl/certs
mkdir -p ~/.minikube/files/var/log

cp "./audit-policy.yaml" ~/.minikube/files/etc/ssl/certs/audit-policy.yaml

minikube start --driver=docker --cpus=4 --memory=5g \
  --extra-config=apiserver.audit-log-format=json \
  --extra-config=apiserver.audit-log-path=/var/log/audit_test.log \
  --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml

minikube addons enable metrics-server
minikube addons enable default-storageclass
minikube addons enable storage-provisioner

minikube status
