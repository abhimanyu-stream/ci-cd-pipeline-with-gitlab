#!/bin/bash

# This script should be run on the first master node

# Initialize the control plane with HA setup
sudo kubeadm init \
    --control-plane-endpoint "LOAD_BALANCER_DNS:6443" \
    --upload-certs \
    --pod-network-cidr=10.244.0.0/16

# Set up kubeconfig for root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Generate join commands for other nodes
echo "=== Control Plane Join Command ==="
kubeadm token create --print-join-command

echo "=== Worker Node Join Command ==="
kubeadm token create --print-join-command --worker

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
sleep 30
kubectl get nodes

# Verify cluster status
kubectl cluster-info
kubectl get pods --all-namespaces 