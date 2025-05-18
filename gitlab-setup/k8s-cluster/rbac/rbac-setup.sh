#!/bin/bash
# Script to set up RBAC for Kubernetes cluster
set -e

echo "Creating RBAC configurations for Kubernetes..."

# Create namespaces
kubectl create namespace dev || true
kubectl create namespace staging || true
kubectl create namespace prod || true

# Apply all RBAC resources
kubectl apply -f cluster-roles/
kubectl apply -f roles/
kubectl apply -f service-accounts/

echo "RBAC setup complete!"
echo "To verify, run: kubectl get clusterroles,roles,rolebindings,clusterrolebindings --all-namespaces"
echo "Test access with: kubectl auth can-i <verb> <resource> --as=<user> --namespace=<namespace>" 