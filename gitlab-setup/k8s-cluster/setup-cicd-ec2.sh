#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# (A) Create a dedicated security group (for CI/CD EC2 instance) (allowing inbound SSH (22) and (optionally) HTTP (80) and HTTPS (443) traffic)
aws ec2 create-security-group \
  --group-name cicd-sg \
  --description "Security group for CI/CD EC2 instance (Jenkins, SonarQube, ArgoCD)"

# (B) Allow inbound SSH (22) traffic (from anywhere (for demo; restrict in production))
aws ec2 authorize-security-group-ingress \
  --group-name cicd-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# (C) (Optional) Allow inbound HTTP (80) and HTTPS (443) traffic (from anywhere (for demo; restrict in production))
aws ec2 authorize-security-group-ingress \
  --group-name cicd-sg \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-name cicd-sg \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# (D) Launch a new EC2 instance (using Ubuntu AMI (ami‑0c7217cdde317cfec), t3.small, and "all_nodes.sh" (bootstrap) as user‑data)
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.small \
  --security-groups cicd-sg \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cicd-instance}]" \
  --user-data file://all_nodes.sh

# (E) Wait (60 seconds) for the instance to start, then print its public IP (and instance ID)
echo "Waiting (60 seconds) for the CI/CD EC2 instance to start ..."
sleep 60
echo "CI/CD EC2 Instance Information:"
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=cicd-instance" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 