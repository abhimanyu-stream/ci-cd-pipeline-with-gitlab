import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.common.serialization.StringDeserializer;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

/**
 * Example of a Kafka consumer with SSL/TLS authentication
 * Demonstrates how to connect to a Kafka cluster using mutual TLS (two-way SSL)
 */
public class SecureKafkaConsumer {

    public static void main(String[] args) {
        if (args.length != 3) {
            System.out.println("Usage: java SecureKafkaConsumer <broker-list> <topic-name> <keystore-path>");
            System.exit(1);
        }

        String bootstrapServers = args[0];
        String topicName = args[1];
        String keystorePath = args[2];

        // Configure the Consumer
        Properties props = new Properties();
        
        // Basic consumer configuration
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "secure-consumer-group");
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
        
        // SSL Security configuration
        props.put("security.protocol", "SSL");
        props.put("ssl.keystore.type", "PKCS12");
        props.put("ssl.keystore.location", keystorePath);
        props.put("ssl.keystore.password", "consumer-ks-password");
        props.put("ssl.key.password", "consumer-key-password");
        props.put("ssl.truststore.type", "PKCS12");
        props.put("ssl.truststore.location", keystorePath.replace("keystore", "truststore"));
        props.put("ssl.truststore.password", "consumer-ts-password");
        
        // Create the consumer
        try (Consumer<String, String> consumer = new KafkaConsumer<>(props)) {
            
            // Subscribe to the topic
            consumer.subscribe(Collections.singleton(topicName));
            
            System.out.println("Subscribed to topic: " + topicName);
            System.out.println("Waiting for messages...");
            
            // Poll for new data
            while (true) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
                
                for (ConsumerRecord<String, String> record : records) {
                    System.out.printf("Received message: key = %s, value = %s, partition = %d, offset = %d%n",
                            record.key(), record.value(), record.partition(), record.offset());
                }
            }
        } catch (Exception e) {
            System.err.println("Error consuming messages from Kafka: " + e.getMessage());
            e.printStackTrace();
        }
    }
} 