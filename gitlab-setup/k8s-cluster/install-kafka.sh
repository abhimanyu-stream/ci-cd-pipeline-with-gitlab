#!/bin/bash
set -e

# Update the system
apt-get update
apt-get upgrade -y

# Install Java
apt-get install -y openjdk-11-jdk

# Create kafka user
useradd -m -s /bin/bash kafka

# Install necessary utilities
apt-get install -y wget net-tools netcat openssl

# Set up data directory for Kafka on the attached EBS volume
DEVICE="/dev/nvme1n1"
DATA_DIR="/data/kafka"

# Wait for the device to be attached
while [ ! -e $DEVICE ]; do
  echo "Waiting for device $DEVICE to be attached..."
  sleep 5
done

# Format the attached volume
mkfs.xfs $DEVICE

# Create the data directory
mkdir -p $DATA_DIR

# Add to fstab for automatic mounting on reboot
echo "$DEVICE $DATA_DIR xfs defaults,nofail 0 2" >> /etc/fstab
mount -a

# Set ownership
chown -R kafka:kafka $DATA_DIR

# Download and extract Kafka
KAFKA_VERSION="3.4.1"
SCALA_VERSION="2.13"

cd /opt
wget "https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"
tar -xzf "kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"
ln -s "kafka_$SCALA_VERSION-$KAFKA_VERSION" kafka
rm "kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"

chown -R kafka:kafka /opt/kafka

# Create directories for security files
mkdir -p /opt/kafka/config/security
chown -R kafka:kafka /opt/kafka/config/security

# Create directories for keystores and truststores
mkdir -p $DATA_DIR/security/broker
mkdir -p $DATA_DIR/security/producer
mkdir -p $DATA_DIR/security/consumer
chown -R kafka:kafka $DATA_DIR/security

# Configure Kafka server properties
cat > /opt/kafka/config/server.properties << EOF
# Basic broker configuration
broker.id=0
listeners=PLAINTEXT://:9092,SSL://:9093
advertised.listeners=PLAINTEXT://$(hostname -i):9092,SSL://$(hostname -i):9093
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=$DATA_DIR/logs
num.partitions=3
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181
zookeeper.connection.timeout.ms=18000
auto.create.topics.enable=true
delete.topic.enable=true

# Security configuration for SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=$DATA_DIR/security/broker/kafka.broker.keystore.pkcs12
ssl.keystore.password=broker-ks-password
ssl.key.password=broker-key-password
ssl.truststore.type=PKCS12
ssl.truststore.location=$DATA_DIR/security/broker/kafka.broker.truststore.pkcs12
ssl.truststore.password=broker-ts-password
ssl.client.auth=required
security.inter.broker.protocol=SSL
EOF

# Configure Zookeeper properties
cat > /opt/kafka/config/zookeeper.properties << EOF
dataDir=$DATA_DIR/zookeeper
clientPort=2181
maxClientCnxns=0
admin.enableServer=false
tickTime=2000
initLimit=10
syncLimit=5
server.1=$(hostname -i):2888:3888
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
EOF

# Create systemd service for Zookeeper
cat > /etc/systemd/system/zookeeper.service << EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Kafka
cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
Environment="KAFKA_HEAP_OPTS=-Xmx1G -Xms1G"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the services
systemctl daemon-reload
systemctl enable zookeeper.service
systemctl enable kafka.service

# Don't start services yet - we need to set up security first
echo "Kafka installation completed. Security setup script will be run next." 