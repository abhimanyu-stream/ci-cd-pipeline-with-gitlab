#!/bin/bash
# THIS SCRIPT RUNS ON THE SPRING BOOT APPLICATION EC2 INSTANCE AS USER-DATA

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Create a user for Docker
sudo usermod -aG docker ubuntu

# Install filebeat for logging to ELK
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update
sudo apt-get install -y filebeat

# Configure filebeat to collect Spring Boot logs
cat <<EOF | sudo tee /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: docker
  enabled: true
  containers:
    path: "/var/lib/docker/containers"
    ids:
      - "*"
  tags: ["docker", "springboot"]

output.elasticsearch:
  hosts: ["monitoring-server:9200"]
  indices:
    - index: "filebeat-springboot-%{+yyyy.MM.dd}"
      when.contains:
        tags: "springboot"

setup.kibana:
  host: "monitoring-server:5601"
EOF

# Create a script to configure Elasticsearch connection
cat <<EOF | sudo tee /root/configure-elasticsearch.sh
#!/bin/bash
# After Elasticsearch is up, run this script with the Elasticsearch server IP

if [ \$# -ne 1 ]; then
  echo "Usage: \$0 <elasticsearch-ip>"
  exit 1
fi

ES_IP=\$1

# Update Filebeat configuration
sudo sed -i "s/monitoring-server:9200/\$ES_IP:9200/g" /etc/filebeat/filebeat.yml
sudo sed -i "s/monitoring-server:5601/\$ES_IP:5601/g" /etc/filebeat/filebeat.yml

# Restart Filebeat
sudo systemctl restart filebeat

echo "Filebeat configured to send logs to Elasticsearch at \$ES_IP"
EOF

sudo chmod +x /root/configure-elasticsearch.sh

# Create a script to configure database connection
cat <<EOF | sudo tee /root/configure-databases.sh
#!/bin/bash
# After databases are up, run this script with the database server IP

if [ \$# -ne 1 ]; then
  echo "Usage: \$0 <database-ip>"
  exit 1
fi

DB_IP=\$1

# Create docker-compose.yml for Spring Boot application with database connection
cat <<EOC | sudo tee /home/ubuntu/docker-compose.yml
version: '3'
services:
  springboot-app:
    image: springio/gs-spring-boot-docker
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://\${DB_IP}:3306/testdb
      - SPRING_DATASOURCE_USERNAME=testuser
      - SPRING_DATASOURCE_PASSWORD=Password123
      - SPRING_DATA_MONGODB_URI=mongodb://testuser:Password123@\${DB_IP}:27017/testdb
    volumes:
      - /var/log/springboot:/var/log/springboot
    networks:
      - app-network
    restart: always

  springboot-custom-app:
    build:
      context: ./app
      dockerfile: Dockerfile
    ports:
      - "8081:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://\${DB_IP}:3306/testdb
      - SPRING_DATASOURCE_USERNAME=testuser
      - SPRING_DATASOURCE_PASSWORD=Password123
      - SPRING_DATA_MONGODB_URI=mongodb://testuser:Password123@\${DB_IP}:27017/testdb
    volumes:
      - /var/log/springboot-custom:/var/log/springboot-custom
    networks:
      - app-network
    restart: always

networks:
  app-network:
    driver: bridge
EOC

# Create a sample Spring Boot application directory
mkdir -p /home/ubuntu/app
cat <<EOC | sudo tee /home/ubuntu/app/Dockerfile
FROM openjdk:11-jdk-slim
VOLUME /tmp
COPY app.jar app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
EOC

# Create a simple Spring Boot JAR file
cat <<EOC | sudo tee /home/ubuntu/app/download-jar.sh
#!/bin/bash
wget -O app.jar https://start.spring.io/starter.zip?type=maven-project&language=java&bootVersion=2.7.0&baseDir=demo&groupId=com.example&artifactId=demo&name=demo&description=Demo%20project%20for%20Spring%20Boot&packageName=com.example.demo&packaging=jar&javaVersion=11&dependencies=web,data-jpa,mysql,data-mongodb
EOC

sudo chmod +x /home/ubuntu/app/download-jar.sh
cd /home/ubuntu/app && ./download-jar.sh

# Run the Spring Boot application with Docker Compose
cd /home/ubuntu && docker compose up -d

echo "Spring Boot application with database connection to \$DB_IP configured and started"
EOF

sudo chmod +x /root/configure-databases.sh

# Create directories for logs
sudo mkdir -p /var/log/springboot /var/log/springboot-custom
sudo chmod 777 /var/log/springboot /var/log/springboot-custom

echo "Spring Boot Docker environment setup complete!"
echo "Run /root/configure-elasticsearch.sh <elasticsearch-ip> to connect to ELK stack"
echo "Run /root/configure-databases.sh <database-ip> to set up Spring Boot with database connections" 