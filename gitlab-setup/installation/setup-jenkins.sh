#!/bin/bash
# THIS SCRIPT RUNS ON THE JENKINS EC2 INSTANCE AS USER-DATA

# Update system
apt-get update && apt-get upgrade -y

# Install Java
apt-get install -y openjdk-11-jdk

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install -y jenkins

# Install Docker for container builds
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
usermod -aG docker jenkins

# Install kubectl for Kubernetes deployments
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Copy Jenkins configuration script
mkdir -p /var/lib/jenkins/init.groovy.d/
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

# Restart Jenkins to apply changes
systemctl restart jenkins

echo "Jenkins installation complete. Access Jenkins at http://YOUR_SERVER_IP:8080"
echo "Initial admin password can be found at: /var/lib/jenkins/secrets/initialAdminPassword" 