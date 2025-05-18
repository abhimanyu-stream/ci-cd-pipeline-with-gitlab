#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for Monitoring (ELK Stack and Grafana)
aws ec2 create-security-group \
  --group-name monitoring-sg \
  --description "Security group for Monitoring Stack (ELK and Grafana)"

# Allow inbound SSH (22)
aws ec2 authorize-security-group-ingress \
  --group-name monitoring-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow inbound for Elasticsearch (9200, 9300)
aws ec2 authorize-security-group-ingress \
  --group-name monitoring-sg \
  --protocol tcp \
  --port 9200-9300 \
  --cidr 0.0.0.0/0

# Allow inbound for Kibana (5601)
aws ec2 authorize-security-group-ingress \
  --group-name monitoring-sg \
  --protocol tcp \
  --port 5601 \
  --cidr 0.0.0.0/0

# Allow inbound for Logstash (5044)
aws ec2 authorize-security-group-ingress \
  --group-name monitoring-sg \
  --protocol tcp \
  --port 5044 \
  --cidr 0.0.0.0/0

# Allow inbound for Grafana (3000)
aws ec2 authorize-security-group-ingress \
  --group-name monitoring-sg \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

# Launch Monitoring EC2 instance (t3.large for ELK, which requires more RAM)
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.large \
  --security-groups monitoring-sg \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"DeleteOnTermination\":true}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=monitoring-server}]" \
  --user-data file://install-monitoring.sh

echo "Waiting for Monitoring server to start..."
sleep 60
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=monitoring-server" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table 