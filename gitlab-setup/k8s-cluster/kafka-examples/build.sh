#!/bin/bash
set -e

# This script builds the Kafka SSL examples

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "Maven is not installed. Installing Maven..."
    
    # Install Maven
    apt-get update
    apt-get install -y maven
    
    echo "Maven installation completed."
fi

# Check Java version
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Installing OpenJDK 11..."
    
    # Install Java
    apt-get update
    apt-get install -y openjdk-11-jdk
    
    echo "Java installation completed."
fi

echo "Building Kafka SSL examples..."

# Build the project with Maven
mvn clean package

echo "Build completed successfully."
echo "Producer JAR: target/secure-kafka-producer.jar"
echo "Consumer JAR: target/secure-kafka-consumer.jar"

echo ""
echo "To run the producer example:"
echo "java -jar target/secure-kafka-producer.jar <broker-list> <topic-name> <keystore-path>"
echo ""
echo "To run the consumer example:"
echo "java -jar target/secure-kafka-consumer.jar <broker-list> <topic-name> <keystore-path>" 