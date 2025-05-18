#!/bin/bash

# Create security group for Kubernetes cluster
aws ec2 create-security-group \
    --group-name k8s-cluster-sg \
    --description "Security group for Kubernetes cluster"

# Add inbound rules for Kubernetes
aws ec2 authorize-security-group-ingress \
    --group-name k8s-cluster-sg \
    --protocol tcp \
    --port 0-65535 \
    --cidr 0.0.0.0/0

# Create 3 master nodes
for i in {1..3}; do
    aws ec2 run-instances \
        --image-id ami-0c7217cdde317cfec \  # Ubuntu 22.04 LTS AMI
        --instance-type t3.small \
        --security-groups k8s-cluster-sg \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=k8s-master-$i}]" \
        --user-data file://all_nodes.sh
done

# Create 2 worker nodes
for i in {1..2}; do
    aws ec2 run-instances \
        --image-id ami-0c7217cdde317cfec \  # Ubuntu 22.04 LTS AMI
        --instance-type t3.small \
        --security-groups k8s-cluster-sg \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=k8s-worker-$i}]" \
        --user-data file://all_nodes.sh
done

echo "Waiting for instances to start..."
sleep 60

# Get instance IDs and public IPs
echo "Instance Information:"
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=k8s-*" \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
    --output table 