#!/bin/bash
# RUN THIS SCRIPT FROM YOUR LOCAL MACHINE WITH AWS CLI CONFIGURED

# Create security group for Kafka cluster
aws ec2 create-security-group \
  --group-name kafka-sg \
  --description "Security group for Kafka cluster"

# Allow inbound SSH (22)
aws ec2 authorize-security-group-ingress \
  --group-name kafka-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow inbound for Zookeeper client (2181)
aws ec2 authorize-security-group-ingress \
  --group-name kafka-sg \
  --protocol tcp \
  --port 2181 \
  --cidr 0.0.0.0/0

# Allow inbound for Zookeeper internal communication (2888, 3888)
aws ec2 authorize-security-group-ingress \
  --group-name kafka-sg \
  --protocol tcp \
  --port 2888-3888 \
  --cidr 0.0.0.0/0

# Allow inbound for Kafka brokers (9092, 9093)
aws ec2 authorize-security-group-ingress \
  --group-name kafka-sg \
  --protocol tcp \
  --port 9092-9093 \
  --cidr 0.0.0.0/0

# Create multiple Kafka nodes for high availability (3 nodes recommended)
for i in {1..3}; do
  # Create EBS volume for Kafka data
  VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone us-east-1a \
    --size 100 \
    --volume-type gp3 \
    --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=kafka-data-$i}]" \
    --query 'VolumeId' \
    --output text)
  
  echo "Created EBS volume $VOLUME_ID for Kafka node $i"
  
  # Create user-data script that installs Kafka and runs security setup
  cat > /tmp/kafka-node-$i-user-data.sh << EOF
#!/bin/bash
# Save install-kafka.sh script
cat > /tmp/install-kafka.sh << 'EOFINNER'
$(cat install-kafka.sh)
EOFINNER

# Save setup-kafka-security.sh script
cat > /tmp/setup-kafka-security.sh << 'EOFINNER'
$(cat setup-kafka-security.sh)
EOFINNER

# Make scripts executable
chmod +x /tmp/install-kafka.sh
chmod +x /tmp/setup-kafka-security.sh

# Run install script
/tmp/install-kafka.sh

# Run security setup script
/tmp/setup-kafka-security.sh
EOF
  
  # Launch EC2 instance with the user-data script
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c7217cdde317cfec \
    --instance-type t3.large \
    --security-groups kafka-sg \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":true}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=kafka-node-$i}]" \
    --user-data file:///tmp/kafka-node-$i-user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text)
  
  echo "Launched Kafka node $i with instance ID $INSTANCE_ID"
  
  # Wait for instance to be running
  echo "Waiting for instance to be running..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID
  
  # Attach EBS volume
  aws ec2 attach-volume \
    --volume-id $VOLUME_ID \
    --instance-id $INSTANCE_ID \
    --device /dev/sdf
  
  echo "Attached volume $VOLUME_ID to instance $INSTANCE_ID"
  
  # Clean up the temporary user-data file
  rm /tmp/kafka-node-$i-user-data.sh
done

echo "Waiting for all Kafka nodes to start..."
sleep 60

echo "Kafka cluster information:"
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=kafka-node-*" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceId]' \
  --output table

echo "Kafka data volumes information:"
aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=kafka-data-*" \
  --query 'Volumes[*].[Tags[?Key==`Name`].Value|[0],VolumeId,Size,State]' \
  --output table

echo "Kafka nodes are being set up with security. The full initialization including security configuration"
echo "will take some time. You can SSH into the instances to check progress." 