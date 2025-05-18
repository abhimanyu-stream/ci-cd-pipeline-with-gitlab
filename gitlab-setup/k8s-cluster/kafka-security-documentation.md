# Kafka Security Setup with Mutual TLS Authentication

This documentation explains the Kafka security implementation using two-way SSL/TLS handshake with PKCS12 keystores for mutual authentication between brokers, producers, and consumers.

## Overview

The security implementation includes:

1. Separate PKCS12 keystores and truststores for:
   - Kafka brokers
   - Kafka producers
   - Kafka consumers
2. A single Certificate Authority (CA) that signs all certificates
3. Two-way SSL authentication (mutual TLS) configuration
4. Secure communication on port 9093 (standard communication remains on 9092)

## Security Components

### Certificate Authority (CA)

A self-signed CA certificate is created to establish trust between all components. 
The CA certificate is used to:
- Sign all component certificates
- Verify the authenticity of certificates during connection

### Keystores and Truststores

Each component (broker, producer, consumer) has:

1. **Keystore (PKCS12)**: Contains the component's private key and certificate
2. **Truststore (PKCS12)**: Contains trusted certificates (the CA certificate)

## Authentication Flow

In two-way SSL/TLS:

1. The client (producer/consumer) initiates a connection to the broker
2. The broker presents its certificate from its keystore
3. The client verifies the broker's certificate using its truststore
4. The client presents its certificate from its keystore
5. The broker verifies the client's certificate using its truststore
6. If both verifications succeed, a secure connection is established

## File Locations

All security files are stored in the following directory structure under `/data/kafka/security/`:

```
/data/kafka/security/
├── ca-cert                # CA certificate
├── ca-key                 # CA private key  
├── broker/                # Broker security files
│   ├── kafka.broker.keystore.pkcs12    
│   ├── kafka.broker.truststore.pkcs12
│   └── broker-cert-signed
├── producer/              # Producer security files
│   ├── kafka.producer.keystore.pkcs12
│   ├── kafka.producer.truststore.pkcs12
│   ├── producer.properties
│   └── producer-cert-signed
└── consumer/              # Consumer security files
    ├── kafka.consumer.keystore.pkcs12
    ├── kafka.consumer.truststore.pkcs12
    ├── consumer.properties
    └── consumer-cert-signed
```

## Configuration Details

### Broker Configuration

The Kafka broker is configured with SSL in `server.properties`:

```properties
listeners=PLAINTEXT://:9092,SSL://:9093
advertised.listeners=PLAINTEXT://<hostname>:9092,SSL://<hostname>:9093
ssl.keystore.type=PKCS12
ssl.keystore.location=/data/kafka/security/broker/kafka.broker.keystore.pkcs12
ssl.keystore.password=broker-ks-password
ssl.key.password=broker-key-password
ssl.truststore.type=PKCS12
ssl.truststore.location=/data/kafka/security/broker/kafka.broker.truststore.pkcs12
ssl.truststore.password=broker-ts-password
ssl.client.auth=required
security.inter.broker.protocol=SSL
```

### Producer Configuration

Producers connect using SSL with the configuration in `producer.properties`:

```properties
bootstrap.servers=<hostname>:9093
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=/data/kafka/security/producer/kafka.producer.keystore.pkcs12
ssl.keystore.password=producer-ks-password
ssl.key.password=producer-key-password
ssl.truststore.type=PKCS12
ssl.truststore.location=/data/kafka/security/producer/kafka.producer.truststore.pkcs12
ssl.truststore.password=producer-ts-password
```

### Consumer Configuration

Consumers connect using SSL with the configuration in `consumer.properties`:

```properties
bootstrap.servers=<hostname>:9093
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=/data/kafka/security/consumer/kafka.consumer.keystore.pkcs12
ssl.keystore.password=consumer-ks-password
ssl.key.password=consumer-key-password
ssl.truststore.type=PKCS12
ssl.truststore.location=/data/kafka/security/consumer/kafka.consumer.truststore.pkcs12
ssl.truststore.password=consumer-ts-password
```

## Usage Examples

### Producing Messages with SSL

```bash
/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server <hostname>:9093 \
  --topic secure-test-topic \
  --producer.config /data/kafka/security/producer/producer.properties
```

### Consuming Messages with SSL

```bash
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server <hostname>:9093 \
  --topic secure-test-topic \
  --consumer.config /data/kafka/security/consumer/consumer.properties \
  --from-beginning
```

## Java Client Example

### Producer

```java
Properties props = new Properties();
props.put("bootstrap.servers", "<hostname>:9093");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

// Security settings
props.put("security.protocol", "SSL");
props.put("ssl.keystore.type", "PKCS12");
props.put("ssl.keystore.location", "/path/to/kafka.producer.keystore.pkcs12");
props.put("ssl.keystore.password", "producer-ks-password");
props.put("ssl.key.password", "producer-key-password");
props.put("ssl.truststore.type", "PKCS12");
props.put("ssl.truststore.location", "/path/to/kafka.producer.truststore.pkcs12");
props.put("ssl.truststore.password", "producer-ts-password");

KafkaProducer<String, String> producer = new KafkaProducer<>(props);
```

### Consumer

```java
Properties props = new Properties();
props.put("bootstrap.servers", "<hostname>:9093");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("group.id", "test-consumer-group");

// Security settings
props.put("security.protocol", "SSL");
props.put("ssl.keystore.type", "PKCS12");
props.put("ssl.keystore.location", "/path/to/kafka.consumer.keystore.pkcs12");
props.put("ssl.keystore.password", "consumer-ks-password");
props.put("ssl.key.password", "consumer-key-password");
props.put("ssl.truststore.type", "PKCS12");
props.put("ssl.truststore.location", "/path/to/kafka.consumer.truststore.pkcs12");
props.put("ssl.truststore.password", "consumer-ts-password");

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
```

## Security Considerations

1. In production environments, use secure methods to manage passwords
2. Consider implementing key rotation policies
3. Regularly update and patch Kafka to address security vulnerabilities
4. Consider adding authorization (e.g., Kafka ACLs) for finer-grained access control 