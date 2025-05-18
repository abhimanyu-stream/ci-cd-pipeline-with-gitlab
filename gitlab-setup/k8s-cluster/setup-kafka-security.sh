#!/bin/bash
set -e

# This script must be run after install-kafka.sh
# It sets up two-way SSL authentication for Kafka brokers, producers, and consumers

# Configuration parameters
DATA_DIR="/data/kafka"
SECURITY_DIR="$DATA_DIR/security"
BROKER_DIR="$SECURITY_DIR/broker"
PRODUCER_DIR="$SECURITY_DIR/producer"
CONSUMER_DIR="$SECURITY_DIR/consumer"

# Passwords (in production, use more secure methods to manage these)
BROKER_KS_PASS="broker-ks-password"
BROKER_KEY_PASS="broker-key-password"
BROKER_TS_PASS="broker-ts-password"

PRODUCER_KS_PASS="producer-ks-password"
PRODUCER_KEY_PASS="producer-key-password"
PRODUCER_TS_PASS="producer-ts-password"

CONSUMER_KS_PASS="consumer-ks-password"
CONSUMER_KEY_PASS="consumer-key-password"
CONSUMER_TS_PASS="consumer-ts-password"

# Certificate validity in days
VALIDITY=365

# Create directory structure
mkdir -p $BROKER_DIR $PRODUCER_DIR $CONSUMER_DIR

# Generate a CA (Certificate Authority)
echo "Generating Certificate Authority..."
openssl req -new -x509 -keyout $SECURITY_DIR/ca-key -out $SECURITY_DIR/ca-cert -days $VALIDITY \
  -subj "/C=US/ST=NY/L=New York/O=Kafka/OU=Security/CN=KafkaCA" -nodes

# 1. Generate Broker Keystore and Certificate
echo "Generating Broker keystore and certificate..."
keytool -keystore $BROKER_DIR/kafka.broker.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias broker \
  -validity $VALIDITY \
  -genkeypair \
  -storepass $BROKER_KS_PASS \
  -keypass $BROKER_KEY_PASS \
  -dname "CN=$(hostname -f),OU=Kafka,O=Organization,L=City,S=State,C=US" \
  -ext SAN=DNS:$(hostname -f),IP:$(hostname -i)

# Export broker certificate
keytool -keystore $BROKER_DIR/kafka.broker.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias broker \
  -storepass $BROKER_KS_PASS \
  -certreq -file $BROKER_DIR/broker-cert-sign-request

# Sign broker certificate with CA
openssl x509 -req -CA $SECURITY_DIR/ca-cert \
  -CAkey $SECURITY_DIR/ca-key \
  -in $BROKER_DIR/broker-cert-sign-request \
  -out $BROKER_DIR/broker-cert-signed \
  -days $VALIDITY \
  -CAcreateserial

# Import CA certificate and signed broker certificate into broker keystore
keytool -keystore $BROKER_DIR/kafka.broker.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $BROKER_KS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

keytool -keystore $BROKER_DIR/kafka.broker.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias broker \
  -storepass $BROKER_KS_PASS \
  -import -file $BROKER_DIR/broker-cert-signed

# Create broker truststore and import CA
keytool -keystore $BROKER_DIR/kafka.broker.truststore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $BROKER_TS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

# 2. Generate Producer Keystore and Certificate
echo "Generating Producer keystore and certificate..."
keytool -keystore $PRODUCER_DIR/kafka.producer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias producer \
  -validity $VALIDITY \
  -genkeypair \
  -storepass $PRODUCER_KS_PASS \
  -keypass $PRODUCER_KEY_PASS \
  -dname "CN=kafka-producer,OU=Kafka,O=Organization,L=City,S=State,C=US"

# Export producer certificate
keytool -keystore $PRODUCER_DIR/kafka.producer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias producer \
  -storepass $PRODUCER_KS_PASS \
  -certreq -file $PRODUCER_DIR/producer-cert-sign-request

# Sign producer certificate with CA
openssl x509 -req -CA $SECURITY_DIR/ca-cert \
  -CAkey $SECURITY_DIR/ca-key \
  -in $PRODUCER_DIR/producer-cert-sign-request \
  -out $PRODUCER_DIR/producer-cert-signed \
  -days $VALIDITY \
  -CAcreateserial

# Import CA certificate and signed producer certificate into producer keystore
keytool -keystore $PRODUCER_DIR/kafka.producer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $PRODUCER_KS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

keytool -keystore $PRODUCER_DIR/kafka.producer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias producer \
  -storepass $PRODUCER_KS_PASS \
  -import -file $PRODUCER_DIR/producer-cert-signed

# Create producer truststore and import CA
keytool -keystore $PRODUCER_DIR/kafka.producer.truststore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $PRODUCER_TS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

# 3. Generate Consumer Keystore and Certificate
echo "Generating Consumer keystore and certificate..."
keytool -keystore $CONSUMER_DIR/kafka.consumer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias consumer \
  -validity $VALIDITY \
  -genkeypair \
  -storepass $CONSUMER_KS_PASS \
  -keypass $CONSUMER_KEY_PASS \
  -dname "CN=kafka-consumer,OU=Kafka,O=Organization,L=City,S=State,C=US"

# Export consumer certificate
keytool -keystore $CONSUMER_DIR/kafka.consumer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias consumer \
  -storepass $CONSUMER_KS_PASS \
  -certreq -file $CONSUMER_DIR/consumer-cert-sign-request

# Sign consumer certificate with CA
openssl x509 -req -CA $SECURITY_DIR/ca-cert \
  -CAkey $SECURITY_DIR/ca-key \
  -in $CONSUMER_DIR/consumer-cert-sign-request \
  -out $CONSUMER_DIR/consumer-cert-signed \
  -days $VALIDITY \
  -CAcreateserial

# Import CA certificate and signed consumer certificate into consumer keystore
keytool -keystore $CONSUMER_DIR/kafka.consumer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $CONSUMER_KS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

keytool -keystore $CONSUMER_DIR/kafka.consumer.keystore.pkcs12 \
  -storetype PKCS12 \
  -alias consumer \
  -storepass $CONSUMER_KS_PASS \
  -import -file $CONSUMER_DIR/consumer-cert-signed

# Create consumer truststore and import CA
keytool -keystore $CONSUMER_DIR/kafka.consumer.truststore.pkcs12 \
  -storetype PKCS12 \
  -alias CARoot \
  -storepass $CONSUMER_TS_PASS \
  -import -file $SECURITY_DIR/ca-cert -noprompt

# Create client configuration files
echo "Creating client configuration files..."

# Create producer.properties
cat > $PRODUCER_DIR/producer.properties << EOF
# Basic producer properties
bootstrap.servers=$(hostname -i):9093
key.serializer=org.apache.kafka.common.serialization.StringSerializer
value.serializer=org.apache.kafka.common.serialization.StringSerializer
acks=all
retries=3
batch.size=16384
buffer.memory=33554432

# Security configurations
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=$PRODUCER_DIR/kafka.producer.keystore.pkcs12
ssl.keystore.password=$PRODUCER_KS_PASS
ssl.key.password=$PRODUCER_KEY_PASS
ssl.truststore.type=PKCS12
ssl.truststore.location=$PRODUCER_DIR/kafka.producer.truststore.pkcs12
ssl.truststore.password=$PRODUCER_TS_PASS
EOF

# Create consumer.properties
cat > $CONSUMER_DIR/consumer.properties << EOF
# Basic consumer properties
bootstrap.servers=$(hostname -i):9093
key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
value.deserializer=org.apache.kafka.common.serialization.StringDeserializer
group.id=test-consumer-group
auto.offset.reset=earliest
enable.auto.commit=true

# Security configurations
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=$CONSUMER_DIR/kafka.consumer.keystore.pkcs12
ssl.keystore.password=$CONSUMER_KS_PASS
ssl.key.password=$CONSUMER_KEY_PASS
ssl.truststore.type=PKCS12
ssl.truststore.location=$CONSUMER_DIR/kafka.consumer.truststore.pkcs12
ssl.truststore.password=$CONSUMER_TS_PASS
EOF

# Set proper ownership
chown -R kafka:kafka $SECURITY_DIR

# Start Kafka services
echo "Starting Kafka services..."
systemctl start zookeeper.service
sleep 10
systemctl start kafka.service

echo "Waiting for Kafka to start..."
sleep 20

# Create a test topic
echo "Creating test topic..."
/opt/kafka/bin/kafka-topics.sh --create --topic secure-test-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo "Kafka security setup completed successfully!"
echo "Broker keystore and truststore located at: $BROKER_DIR"
echo "Producer keystore and truststore located at: $PRODUCER_DIR"
echo "Consumer keystore and truststore located at: $CONSUMER_DIR"
echo
echo "SSL is configured on port 9093. To use SSL for producing messages:"
echo "/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server $(hostname -i):9093 --topic secure-test-topic --producer.config $PRODUCER_DIR/producer.properties"
echo
echo "To use SSL for consuming messages:"
echo "/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server $(hostname -i):9093 --topic secure-test-topic --consumer.config $CONSUMER_DIR/consumer.properties --from-beginning" 