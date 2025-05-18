#!/bin/bash
# EXECUTE THIS SCRIPT ON THE JENKINS SERVER AFTER INSTALLATION

# Install Trivy on Jenkins server
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

# Configure Trivy cache directory
mkdir -p /var/jenkins_home/trivy-cache
chown jenkins:jenkins /var/jenkins_home/trivy-cache
echo 'export TRIVY_CACHE_DIR=/var/jenkins_home/trivy-cache' >> /etc/profile.d/trivy.sh

# Test Trivy installation
echo "Testing Trivy installation..."
trivy --version

echo "Trivy installation complete!" 