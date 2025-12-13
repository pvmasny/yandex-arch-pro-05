#!/usr/bin/env bash
NAMESPACE="test-namespace"
kubectl create namespace $NAMESPACE || true

# front-end
kubectl run front-end-app --image=nginx -n $NAMESPACE --labels role=front-end --port=80 --expose

# back-end-api
kubectl run back-end-api-app --image=nginx -n $NAMESPACE --labels role=back-end-api --port=80 --expose

# admin-front-end
kubectl run admin-front-end-app --image=nginx -n $NAMESPACE --labels role=admin-front-end --port=80 --expose

# admin-back-end-api
kubectl run admin-back-end-api-app --image=nginx -n $NAMESPACE --labels role=admin-back-end-api --port=80 --expose

kubectl apply -f non-admin-api-allow.yaml