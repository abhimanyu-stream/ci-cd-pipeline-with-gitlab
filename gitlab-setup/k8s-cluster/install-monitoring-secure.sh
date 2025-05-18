#!/bin/bash
# THIS SCRIPT RUNS ON THE MONITORING EC2 INSTANCE AS USER-DATA
# INCLUDES SECURITY CONFIGURATION FOR ELK STACK

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Java (required for Elasticsearch & Logstash)
sudo apt-get install -y openjdk-11-jdk

# Install necessary tools
sudo apt-get install -y apt-transport-https wget curl gnupg

# Configure Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list

# Install Elasticsearch
sudo apt-get update
sudo apt-get install -y elasticsearch
sudo sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#discovery.seed_hosts: \["host1", "host2"\]/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml

# Create directories for security files
sudo mkdir -p /var/lib/elasticsearch/certs
sudo chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/certs

# Add security settings to elasticsearch.yml
sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null << EOL

# Security settings
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /var/lib/elasticsearch/certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /var/lib/elasticsearch/certs/elastic-certificates.p12

# HTTPS settings
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /var/lib/elasticsearch/certs/http.p12
EOL

# Generate certificates
cd /usr/share/elasticsearch
sudo -u elasticsearch bin/elasticsearch-certutil ca --out /var/lib/elasticsearch/certs/elastic-stack-ca.p12 --pass ""
sudo -u elasticsearch bin/elasticsearch-certutil cert --ca /var/lib/elasticsearch/certs/elastic-stack-ca.p12 --ca-pass "" --out /var/lib/elasticsearch/certs/elastic-certificates.p12 --pass "elastic-certs-password"
sudo -u elasticsearch bin/elasticsearch-certutil http --out /var/lib/elasticsearch/certs/http.p12 --pass "elastic-http-password"

# Update certificate permissions
sudo chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/certs
sudo chmod 660 /var/lib/elasticsearch/certs/*.p12

# Update Elasticsearch keystore with certificate passwords
sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password -x <<< "elastic-certs-password"
sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password -x <<< "elastic-certs-password"
sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password -x <<< "elastic-http-password"

# Start Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
echo "Waiting for Elasticsearch to start..."
sleep 60

# Set up built-in user passwords
sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -b > /var/lib/elasticsearch/passwords.txt
sudo chmod 600 /var/lib/elasticsearch/passwords.txt

# Extract passwords
ELASTIC_PASS=$(grep "PASSWORD elastic" /var/lib/elasticsearch/passwords.txt | awk '{print $4}')
KIBANA_PASS=$(grep "PASSWORD kibana_system" /var/lib/elasticsearch/passwords.txt | awk '{print $4}')

# Install Kibana
sudo apt-get install -y kibana

# Configure Kibana
sudo tee -a /etc/kibana/kibana.yml > /dev/null << EOL
server.host: "0.0.0.0"

# Security settings
elasticsearch.username: "kibana_system"
elasticsearch.password: "$KIBANA_PASS"
elasticsearch.ssl.certificateAuthorities: [ "/var/lib/elasticsearch/certs/elastic-stack-ca.p12" ]
elasticsearch.ssl.verificationMode: certificate
server.ssl.enabled: true
server.ssl.keystore.path: "/var/lib/elasticsearch/certs/http.p12"
server.ssl.keystore.password: "elastic-http-password"
xpack.security.enabled: true
xpack.encryptedSavedObjects.encryptionKey: "$(openssl rand -base64 32)"
EOL

# Start Kibana
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana

# Install Logstash
sudo apt-get install -y logstash

# Create Logstash configuration
sudo tee /etc/logstash/conf.d/logstash.conf > /dev/null << EOL
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/var/lib/elasticsearch/certs/http.p12"
    ssl_key => "/var/lib/elasticsearch/certs/http.p12"
    ssl_keystore_password => "elastic-http-password"
  }
}

filter {
  if [event][module] == "system" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["https://localhost:9200"]
    user => "elastic"
    password => "$ELASTIC_PASS"
    ssl => true
    ssl_certificate_verification => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOL

# Copy certificates for Logstash
sudo cp /var/lib/elasticsearch/certs/elastic-stack-ca.p12 /etc/logstash/
sudo chown logstash:logstash /etc/logstash/elastic-stack-ca.p12

# Start Logstash
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl start logstash

# Install Filebeat with secure configuration
sudo apt-get install -y filebeat

# Configure Filebeat
sudo tee /etc/filebeat/filebeat.yml > /dev/null << EOL
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/syslog

filebeat.modules:
  - module: system
    syslog:
      enabled: true
    auth:
      enabled: true

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: "$ELASTIC_PASS"
  ssl:
    enabled: true
    certificate_authorities: ["/var/lib/elasticsearch/certs/elastic-stack-ca.p12"]
    verification_mode: "certificate"

# Processors for adding metadata
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
EOL

# Copy certificates for Filebeat
sudo cp /var/lib/elasticsearch/certs/elastic-stack-ca.p12 /etc/filebeat/
sudo chown root:root /etc/filebeat/elastic-stack-ca.p12

# Enable Filebeat system module
sudo filebeat modules enable system

# Start Filebeat 
sudo systemctl daemon-reload
sudo systemctl enable filebeat
sudo systemctl start filebeat

# Install Metricbeat with secure configuration
sudo apt-get install -y metricbeat

# Configure Metricbeat
sudo tee /etc/metricbeat/metricbeat.yml > /dev/null << EOL
metricbeat.modules:
- module: system
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    - socket_summary
    - filesystem
    - fsstat
  enabled: true
  period: 10s
  processes: ['.*']

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: "$ELASTIC_PASS"
  ssl:
    enabled: true
    certificate_authorities: ["/var/lib/elasticsearch/certs/elastic-stack-ca.p12"]
    verification_mode: "certificate"

# Processors for adding metadata
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
EOL

# Copy certificates for Metricbeat
sudo cp /var/lib/elasticsearch/certs/elastic-stack-ca.p12 /etc/metricbeat/
sudo chown root:root /etc/metricbeat/elastic-stack-ca.p12

# Enable Metricbeat system module
sudo metricbeat modules enable system

# Start Metricbeat
sudo systemctl daemon-reload
sudo systemctl enable metricbeat
sudo systemctl start metricbeat

# Install Grafana
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

# Configure Grafana
sudo tee -a /etc/grafana/grafana.ini > /dev/null << EOL
[security]
admin_password = secure-grafana-admin
EOL

# Add Elasticsearch as datasource in Grafana
sudo tee /etc/grafana/provisioning/datasources/elasticsearch.yaml > /dev/null << EOL
apiVersion: 1
datasources:
- name: Elasticsearch
  type: elasticsearch
  access: proxy
  url: https://localhost:9200
  jsonData:
    index: "filebeat-*"
    timeField: "@timestamp"
    esVersion: 7.0.0
    tlsSkipVerify: true
  secureJsonData:
    basicAuth: true
    basicAuthUser: elastic
    basicAuthPassword: $ELASTIC_PASS
  isDefault: true
EOL

# Start Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Create roles and users in Elasticsearch
sleep 30
curl -k -X PUT "https://localhost:9200/_security/role/monitoring_user" -H 'Content-Type: application/json' -u "elastic:$ELASTIC_PASS" -d'
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ]
}'

curl -k -X PUT "https://localhost:9200/_security/user/monitor" -H 'Content-Type: application/json' -u "elastic:$ELASTIC_PASS" -d'
{
  "password" : "monitor-password",
  "roles" : [ "monitoring_user" ],
  "full_name" : "Monitoring User",
  "email" : "monitor@example.com"
}'

# Save password summary
echo "----------------------" >> /var/lib/elasticsearch/passwords.txt
echo "ADDITIONAL USERS" >> /var/lib/elasticsearch/passwords.txt
echo "----------------------" >> /var/lib/elasticsearch/passwords.txt
echo "User: monitor" >> /var/lib/elasticsearch/passwords.txt
echo "Password: monitor-password" >> /var/lib/elasticsearch/passwords.txt
echo "----------------------" >> /var/lib/elasticsearch/passwords.txt
echo "Grafana Admin" >> /var/lib/elasticsearch/passwords.txt
echo "Username: admin" >> /var/lib/elasticsearch/passwords.txt
echo "Password: secure-grafana-admin" >> /var/lib/elasticsearch/passwords.txt

echo "ELK Stack and Grafana installation complete with security!"
echo "Access Kibana at: https://YOUR_SERVER_IP:5601"
echo "Access Elasticsearch at: https://YOUR_SERVER_IP:9200"
echo "Access Grafana at: http://YOUR_SERVER_IP:3000"
echo "All passwords are saved at: /var/lib/elasticsearch/passwords.txt" 