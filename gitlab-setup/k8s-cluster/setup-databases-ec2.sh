#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for databases (MySQL & MongoDB)
aws ec2 create-security-group \
  --group-name databases-sg \
  --description "Security group for MySQL and MongoDB databases"

# Allow inbound SSH (22)
aws ec2 authorize-security-group-ingress \
  --group-name databases-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow inbound for MySQL (3306)
aws ec2 authorize-security-group-ingress \
  --group-name databases-sg \
  --protocol tcp \
  --port 3306 \
  --cidr 0.0.0.0/0

# Allow inbound for MongoDB (27017)
aws ec2 authorize-security-group-ingress \
  --group-name databases-sg \
  --protocol tcp \
  --port 27017 \
  --cidr 0.0.0.0/0

# Launch Database EC2 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --security-groups databases-sg \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"DeleteOnTermination\":true}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=database-server}]" \
  --user-data file://install-databases.sh

echo "Waiting for Database server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=database-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 