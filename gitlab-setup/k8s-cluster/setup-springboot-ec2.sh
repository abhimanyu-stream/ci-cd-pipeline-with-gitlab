#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for Spring Boot application
aws ec2 create-security-group \
  --group-name springboot-sg \
  --description "Security group for Spring Boot application"

# Allow inbound SSH (22)
aws ec2 authorize-security-group-ingress \
  --group-name springboot-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow inbound for Spring Boot application (8080)
aws ec2 authorize-security-group-ingress \
  --group-name springboot-sg \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

# Launch Spring Boot EC2 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --security-groups springboot-sg \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=springboot-server}]" \
  --user-data file://install-springboot.sh

echo "Waiting for Spring Boot server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=springboot-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 