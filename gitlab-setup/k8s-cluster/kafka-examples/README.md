# Kafka SSL Authentication Examples

This directory contains Java examples demonstrating how to connect to a Kafka cluster using mutual TLS (two-way SSL) authentication with PKCS12 keystores.

## Prerequisites

- Java 11 or higher
- Maven 3.6.0 or higher
- Access to Kafka cluster configured with SSL

## Building the Examples

```bash
# Navigate to this directory
cd kafka-examples

# Build the examples with Maven
mvn clean package
```

This will produce two executable JAR files:
- `secure-kafka-producer.jar`: For producing messages to a secure Kafka topic
- `secure-kafka-consumer.jar`: For consuming messages from a secure Kafka topic

## Running the Examples

### Producer Example

To run the Kafka producer example:

```bash
java -jar target/secure-kafka-producer.jar <broker-list> <topic-name> <keystore-path>

# Example:
java -jar target/secure-kafka-producer.jar kafka-node-1:9093 secure-test-topic /data/kafka/security/producer/kafka.producer.keystore.pkcs12
```

Parameters:
- `broker-list`: Comma-separated list of Kafka brokers with port (e.g., `host1:9093,host2:9093`)
- `topic-name`: The Kafka topic to produce messages to
- `keystore-path`: Full path to the producer keystore file

### Consumer Example

To run the Kafka consumer example:

```bash
java -jar target/secure-kafka-consumer.jar <broker-list> <topic-name> <keystore-path>

# Example:
java -jar target/secure-kafka-consumer.jar kafka-node-1:9093 secure-test-topic /data/kafka/security/consumer/kafka.consumer.keystore.pkcs12
```

Parameters:
- `broker-list`: Comma-separated list of Kafka brokers with port (e.g., `host1:9093,host2:9093`)
- `topic-name`: The Kafka topic to consume messages from
- `keystore-path`: Full path to the consumer keystore file

## Code Overview

### SecureKafkaProducer.java

This example:
- Sets up a Kafka producer with SSL security configuration
- Sends 10 messages to a specified topic
- Shows how to configure PKCS12 keystores and truststores for the producer

### SecureKafkaConsumer.java

This example:
- Sets up a Kafka consumer with SSL security configuration
- Subscribes to a specified topic
- Continuously polls for new messages
- Shows how to configure PKCS12 keystores and truststores for the consumer

## Troubleshooting

If you encounter issues connecting to the Kafka cluster:

1. Verify that the Kafka brokers are running and accessible over the network
2. Check that the keystore and truststore paths are correct
3. Verify that the keystore/truststore passwords match the ones configured in the code
4. Ensure that the certificates in your keystores are signed by the same CA used by the brokers
5. Check Kafka broker logs for any SSL-related errors

For more detailed information on Kafka security configuration, refer to the `kafka-security-documentation.md` file in the parent directory. 