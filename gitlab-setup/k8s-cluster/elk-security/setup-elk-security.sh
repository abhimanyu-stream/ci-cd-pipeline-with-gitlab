#!/bin/bash
# Script to secure Elasticsearch and Kibana
set -e

# Variables
ES_HOME="/etc/elasticsearch"
KIBANA_HOME="/etc/kibana"
LOGSTASH_HOME="/etc/logstash"
DATA_DIR="/var/lib/elasticsearch"
CERTS_DIR="$DATA_DIR/certs"
PASSWORD_FILE="$DATA_DIR/passwords.txt"

# Create directories
sudo mkdir -p $CERTS_DIR
sudo chown -R elasticsearch:elasticsearch $CERTS_DIR

echo "Setting up Elasticsearch security..."

# Add security settings to elasticsearch.yml
sudo tee -a $ES_HOME/elasticsearch.yml > /dev/null << EOL

# Security settings
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: $CERTS_DIR/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: $CERTS_DIR/elastic-certificates.p12

# HTTPS settings
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: $CERTS_DIR/http.p12
EOL

# Generate certificates
echo "Generating certificates..."
cd $ES_HOME
sudo -u elasticsearch bin/elasticsearch-certutil ca --out $CERTS_DIR/elastic-stack-ca.p12 --pass ""
sudo -u elasticsearch bin/elasticsearch-certutil cert --ca $CERTS_DIR/elastic-stack-ca.p12 --ca-pass "" --out $CERTS_DIR/elastic-certificates.p12 --pass "elastic-certs-password"
sudo -u elasticsearch bin/elasticsearch-certutil http --out $CERTS_DIR/http.p12 --pass "elastic-http-password"

# Update certificate permissions
sudo chown -R elasticsearch:elasticsearch $CERTS_DIR
sudo chmod 660 $CERTS_DIR/*.p12

# Update Elasticsearch keystore with certificate passwords
echo "Configuring certificate passwords..."
sudo -u elasticsearch bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password -x <<< "elastic-certs-password"
sudo -u elasticsearch bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password -x <<< "elastic-certs-password"
sudo -u elasticsearch bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password -x <<< "elastic-http-password"

# Restart Elasticsearch
echo "Restarting Elasticsearch..."
sudo systemctl restart elasticsearch
sudo systemctl status elasticsearch

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
until curl --silent --cacert $CERTS_DIR/elastic-stack-ca.p12 https://localhost:9200 > /dev/null; do
  sleep 10
  echo "Still waiting..."
done

# Set up passwords
echo "Setting up built-in user passwords..."
sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -b > $PASSWORD_FILE
sudo chmod 600 $PASSWORD_FILE

# Extract the elastic user password
ELASTIC_PASS=$(grep "PASSWORD elastic" $PASSWORD_FILE | awk '{print $4}')
KIBANA_PASS=$(grep "PASSWORD kibana_system" $PASSWORD_FILE | awk '{print $4}')

# Configure Kibana to use security
echo "Configuring Kibana security..."
sudo tee -a $KIBANA_HOME/kibana.yml > /dev/null << EOL

# Security settings
elasticsearch.username: "kibana_system"
elasticsearch.password: "$KIBANA_PASS"
elasticsearch.ssl.certificateAuthorities: [ "$CERTS_DIR/elastic-stack-ca.p12" ]
elasticsearch.ssl.verificationMode: certificate
server.ssl.enabled: true
server.ssl.keystore.path: "$CERTS_DIR/http.p12"
server.ssl.keystore.password: "elastic-http-password"
xpack.security.enabled: true
xpack.encryptedSavedObjects.encryptionKey: "$(openssl rand -base64 32)"
EOL

# Configure Logstash security
echo "Configuring Logstash security..."
sudo tee -a $LOGSTASH_HOME/conf.d/logstash.conf > /dev/null << EOL
output {
  elasticsearch {
    hosts => ["https://localhost:9200"]
    user => "elastic"
    password => "$ELASTIC_PASS"
    ssl => true
    cacert => "$CERTS_DIR/elastic-stack-ca.p12"
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOL

# Restart Kibana and Logstash
echo "Restarting Kibana and Logstash..."
sudo systemctl restart kibana
sudo systemctl restart logstash

echo "Creating Elasticsearch roles..."
# Create roles with curl, using the elastic user password
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

echo "Creating Elasticsearch users..."
# Create users
curl -k -X PUT "https://localhost:9200/_security/user/monitor" -H 'Content-Type: application/json' -u "elastic:$ELASTIC_PASS" -d'
{
  "password" : "monitor-password",
  "roles" : [ "monitoring_user" ],
  "full_name" : "Monitoring User",
  "email" : "monitor@example.com"
}'

curl -k -X PUT "https://localhost:9200/_security/user/logstash_system" -H 'Content-Type: application/json' -u "elastic:$ELASTIC_PASS" -d'
{
  "password" : "logstash-password",
  "roles" : [ "logstash_system" ],
  "full_name" : "Logstash System User",
  "email" : "logstash@example.com"
}'

echo "ELK security setup complete!"
echo "Elasticsearch is now secured with HTTPS and authentication."
echo "Passwords have been saved to $PASSWORD_FILE"
echo 
echo "Access Kibana at: https://YOUR_SERVER_IP:5601"
echo "Access Elasticsearch at: https://YOUR_SERVER_IP:9200"
echo 
echo "Monitor user created with password: monitor-password"
echo "Logstash system user created with password: logstash-password"
echo
echo "IMPORTANT: Save these passwords in a secure location!" 