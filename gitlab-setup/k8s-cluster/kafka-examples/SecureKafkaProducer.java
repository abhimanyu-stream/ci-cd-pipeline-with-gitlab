import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringSerializer;

import java.util.Properties;
import java.util.concurrent.ExecutionException;

/**
 * Example of a Kafka producer with SSL/TLS authentication
 * Demonstrates how to connect to a Kafka cluster using mutual TLS (two-way SSL)
 */
public class SecureKafkaProducer {

    public static void main(String[] args) {
        if (args.length != 3) {
            System.out.println("Usage: java SecureKafkaProducer <broker-list> <topic-name> <keystore-path>");
            System.exit(1);
        }

        String bootstrapServers = args[0];
        String topicName = args[1];
        String keystorePath = args[2];

        // Configure the Producer
        Properties props = new Properties();
        
        // Basic producer configuration
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        
        // SSL Security configuration
        props.put("security.protocol", "SSL");
        props.put("ssl.keystore.type", "PKCS12");
        props.put("ssl.keystore.location", keystorePath);
        props.put("ssl.keystore.password", "producer-ks-password");
        props.put("ssl.key.password", "producer-key-password");
        props.put("ssl.truststore.type", "PKCS12");
        props.put("ssl.truststore.location", keystorePath.replace("keystore", "truststore"));
        props.put("ssl.truststore.password", "producer-ts-password");
        
        // Create the producer
        try (Producer<String, String> producer = new KafkaProducer<>(props)) {
            
            // Send 10 messages
            for (int i = 0; i < 10; i++) {
                String key = "key-" + i;
                String value = "message-" + System.currentTimeMillis() + "-" + i;
                
                ProducerRecord<String, String> record = new ProducerRecord<>(topicName, key, value);
                
                // Send the record and get metadata
                RecordMetadata metadata = producer.send(record).get();
                
                System.out.printf("Message sent to partition %d, offset %d%n", 
                        metadata.partition(), metadata.offset());
                
                // Wait a second between messages
                Thread.sleep(1000);
            }
            
            // Flush and close the producer
            producer.flush();
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error sending messages to Kafka: " + e.getMessage());
            e.printStackTrace();
        }
    }
} 