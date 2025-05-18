#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for Jenkins
aws ec2 create-security-group \
  --group-name jenkins-sg \
  --description "Security group for Jenkins CI/CD server"

# Allow inbound SSH and Jenkins ports
aws ec2 authorize-security-group-ingress --group-name jenkins-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name jenkins-sg --protocol tcp --port 8080 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name jenkins-sg --protocol tcp --port 50000 --cidr 0.0.0.0/0

# Launch Jenkins EC2 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --security-groups jenkins-sg \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=jenkins-server}]" \
  --user-data file://setup-jenkins.sh

echo "Waiting for Jenkins server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=jenkins-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 