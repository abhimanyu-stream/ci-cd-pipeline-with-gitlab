#!/bin/bash

# (A) Disable swap (required by kubeadm)
sudo swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# (B) Enable IPv4 packet forwarding (required for Kubernetes networking)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# (C) Install Containerd runtime using Docker repository
# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install containerd
sudo apt-get install containerd.io -y

# Configure containerd for Kubernetes
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# (D) Install kubelet, kubeadm and kubectl using updated Kubernetes repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the Kubernetes signing key
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# (E) (Optional) Install Helm for package management
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# (F) (Optional) Node labeling commands
# Run after cluster is initialized:
# On master node:
# kubectl label node $(hostname) node-role=master --overwrite
# On worker node:
# kubectl label node $(hostname) node-role=worker --overwrite

echo "Kubernetes prerequisites installed successfully"
