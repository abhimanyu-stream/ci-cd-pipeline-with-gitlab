# Kubernetes CI/CD Infrastructure Setup Guide

This document provides a comprehensive guide for setting up a complete CI/CD infrastructure for Kubernetes deployments using AWS EC2 instances.

## Infrastructure Components

The setup consists of the following components, each on its own EC2 instance:

1. **Kubernetes Cluster** - 5 EC2 instances (3 master nodes, 2 worker nodes)
2. **GitLab Server** - Source code repository
3. **Jenkins Server** - CI/CD orchestration with Trivy integration
4. **Nexus Repository** - Artifact storage (Docker images, Maven artifacts)

## Deployment Overview

![CI/CD Architecture](https://i.imgur.com/example-architecture.png)

## Step 1: Initialize EC2 Instances

### GitLab Server Setup

Run from your local machine with AWS CLI configured:
```bash
./gitlab-setup.sh
```

This script creates an EC2 instance with:
- Ubuntu 22.04 LTS
- t3.medium instance type
- Security group allowing ports 22, 80, 443

### Nexus Repository Setup

Run from your local machine with AWS CLI configured:
```bash
./nexus-setup.sh
```

This script creates an EC2 instance with:
- Ubuntu 22.04 LTS
- t3.medium instance type
- Security group allowing ports 22, 8081, 8082-8083

### Jenkins Server Setup

Run from your local machine with AWS CLI configured:
```bash
./jenkins-setup.sh
```

This script creates an EC2 instance with:
- Ubuntu 22.04 LTS
- t3.medium instance type
- Security group allowing ports 22, 8080, 50000

## Step 2: Configure Services

### GitLab Configuration

SSH into the GitLab server and run:
```bash
# Initial setup happens automatically via user-data
# Get root password from file
sudo cat /etc/gitlab/initial_root_password

# Configure CI/CD pipeline
sudo ./configure-gitlab-cicd.sh
```

### Nexus Configuration

SSH into the Nexus server and run:
```bash
# Wait for Nexus to start (can take several minutes)
# Check status
systemctl status nexus

# Configure repositories
sudo ./configure-nexus-repos.sh
```

### Jenkins Configuration

SSH into the Jenkins server and run:
```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Install Trivy
sudo ./install-trivy.sh

# Copy Jenkins configuration
sudo cp jenkins-config.groovy /var/lib/jenkins/init.groovy.d/
sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/jenkins-config.groovy
sudo systemctl restart jenkins
```

## Step 3: Integration Setup

### Connect Jenkins to GitLab

1. In GitLab, create a Personal Access Token (Settings > Access Tokens)
2. In Jenkins, install GitLab plugin and configure connection
3. Add GitLab webhook in your project (Settings > Webhooks)
   - URL: http://jenkins-server:8080/gitlab-webhook/post
   - Secret Token: Create a token in Jenkins

### Connect Jenkins to Nexus

1. In Jenkins, configure Nexus credentials (Manage Jenkins > Credentials)
2. Add the following credentials:
   - ID: nexus-credentials
   - Username: admin
   - Password: admin123 (or your custom password)

### Connect Jenkins to Kubernetes

1. In Jenkins, install Kubernetes plugin
2. Add kubeconfig credentials (Manage Jenkins > Credentials)
   - ID: kubernetes-config
   - Kind: Secret file
   - File: Upload your kubeconfig file

## Step 4: Create CI/CD Pipeline

1. Create a Jenkinsfile in your application repository:
   ```bash
   cp Jenkinsfile /path/to/your/project/
   ```

2. Configure a Jenkins Pipeline job
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: http://gitlab-server/your-group/your-project.git
   - Credentials: gitlab-credentials
   - Script Path: Jenkinsfile

## Step 5: Deploy Sample Application

1. Push code to GitLab
2. Trigger the Jenkins pipeline
3. The application will be:
   - Built with Maven
   - Packaged in a Docker container
   - Scanned by Trivy
   - Pushed to Nexus
   - Deployed to Kubernetes

## EC2 Instance Summary

| Server | EC2 Instance Type | IP Address | Services |
|--------|-------------------|------------|----------|
| GitLab | t3.medium | x.x.x.x | GitLab CE (HTTP/HTTPS) |
| Nexus | t3.medium | x.x.x.x | Nexus Repository (8081, 8082) |
| Jenkins | t3.medium | x.x.x.x | Jenkins (8080) |
| Kubernetes Masters | t3.small | x.x.x.x | Kubernetes API (6443) |
| Kubernetes Workers | t3.small | x.x.x.x | Kubernetes Workloads |

## Script Summary

| Script | Purpose | Run Location |
|--------|---------|--------------|
| gitlab-setup.sh | Create GitLab EC2 instance | Local machine with AWS CLI |
| setup-gitlab.sh | Install GitLab | GitLab EC2 (user-data) |
| nexus-setup.sh | Create Nexus EC2 instance | Local machine with AWS CLI |
| setup-nexus.sh | Install Nexus | Nexus EC2 (user-data) |
| jenkins-setup.sh | Create Jenkins EC2 instance | Local machine with AWS CLI |
| setup-jenkins.sh | Install Jenkins | Jenkins EC2 (user-data) |
| jenkins-config.groovy | Configure Jenkins | Jenkins EC2 (/var/lib/jenkins/init.groovy.d/) |
| install-trivy.sh | Install Trivy | Jenkins EC2 |
| configure-gitlab-cicd.sh | Setup GitLab CI/CD | GitLab EC2 |
| configure-nexus-repos.sh | Setup Nexus repositories | Nexus EC2 |
| Jenkinsfile | Pipeline definition | Application Git repository |

## Troubleshooting

### GitLab Issues
- Check GitLab logs: `sudo gitlab-ctl tail`
- Reconfigure GitLab: `sudo gitlab-ctl reconfigure`

### Nexus Issues
- Check Nexus logs: `sudo cat /opt/sonatype-work/nexus3/log/nexus.log`
- Restart Nexus: `sudo systemctl restart nexus`

### Jenkins Issues
- Check Jenkins logs: `sudo cat /var/log/jenkins/jenkins.log`
- Restart Jenkins: `sudo systemctl restart jenkins`

## Next Steps

1. Set up monitoring with Prometheus and Grafana
2. Configure automated backups
3. Implement High Availability for CI/CD tools
4. Set up ArgoCD for GitOps-based deployments