#!/bin/bash
set -e

# This script copies keystores and truststores from a Kafka node to a local directory
# for use with the Kafka SSL examples

# Check if arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <kafka-node-ip>"
    exit 1
fi

KAFKA_NODE_IP=$1
REMOTE_USER="ubuntu"
LOCAL_DIR="./keystores"

# Create local directory for keystores
mkdir -p $LOCAL_DIR/producer
mkdir -p $LOCAL_DIR/consumer

echo "Copying keystores and truststores from Kafka node $KAFKA_NODE_IP..."

# Copy producer keystore and truststore
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/producer/kafka.producer.keystore.pkcs12 $LOCAL_DIR/producer/
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/producer/kafka.producer.truststore.pkcs12 $LOCAL_DIR/producer/

# Copy consumer keystore and truststore
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/consumer/kafka.consumer.keystore.pkcs12 $LOCAL_DIR/consumer/
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/consumer/kafka.consumer.truststore.pkcs12 $LOCAL_DIR/consumer/

# Copy producer and consumer properties
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/producer/producer.properties $LOCAL_DIR/producer/
scp $REMOTE_USER@$KAFKA_NODE_IP:/data/kafka/security/consumer/consumer.properties $LOCAL_DIR/consumer/

echo "Keystores and truststores copied successfully to $LOCAL_DIR."
echo "Use these keystores with the Java examples:"
echo "Producer keystore: $LOCAL_DIR/producer/kafka.producer.keystore.pkcs12"
echo "Consumer keystore: $LOCAL_DIR/consumer/kafka.consumer.keystore.pkcs12" 