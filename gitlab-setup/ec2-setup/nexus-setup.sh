#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for Nexus
aws ec2 create-security-group \
  --group-name nexus-sg \
  --description "Security group for Nexus Repository"

# Allow inbound SSH and Nexus ports
aws ec2 authorize-security-group-ingress --group-name nexus-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name nexus-sg --protocol tcp --port 8081 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name nexus-sg --protocol tcp --port 8082-8083 --cidr 0.0.0.0/0

# Launch Nexus EC2 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --security-groups nexus-sg \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nexus-server}]" \
  --user-data file://setup-nexus.sh

echo "Waiting for Nexus server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nexus-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 