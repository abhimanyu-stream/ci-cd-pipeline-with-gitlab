#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for GitLab
aws ec2 create-security-group \
  --group-name gitlab-sg \
  --description "Security group for GitLab server"

# Allow inbound SSH, HTTP, HTTPS
aws ec2 authorize-security-group-ingress --group-name gitlab-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name gitlab-sg --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name gitlab-sg --protocol tcp --port 443 --cidr 0.0.0.0/0

# Launch GitLab EC2 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --security-groups gitlab-sg \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=gitlab-server}]" \
  --user-data file://setup-gitlab.sh

echo "Waiting for GitLab server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gitlab-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 