#!/bin/bash
# THIS SCRIPT RUNS ON THE DATABASE EC2 INSTANCE AS USER-DATA

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary tools
sudo apt-get install -y apt-transport-https wget curl gnupg

# Install MySQL
echo "Installing MySQL..."
sudo apt-get install -y mysql-server

# Configure MySQL to allow remote connections
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
echo "default-authentication-plugin=mysql_native_password" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL service
sudo systemctl restart mysql

# Create a test database and user
sudo mysql -e "CREATE DATABASE testdb;"
sudo mysql -e "CREATE USER 'testuser'@'%' IDENTIFIED BY 'Password123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Install MongoDB
echo "Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Configure MongoDB to allow remote connections
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

# Restart MongoDB service
sudo systemctl daemon-reload
sudo systemctl enable mongod
sudo systemctl start mongod

# Create a test database and user
sleep 5
mongosh --eval 'db = db.getSiblingDB("testdb"); db.createUser({user: "testuser", pwd: "Password123", roles: [{role: "readWrite", db: "testdb"}]})'

# Install filebeat for logging to ELK
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update
sudo apt-get install -y filebeat

# Configure filebeat to collect MySQL and MongoDB logs
cat <<EOF | sudo tee /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/mysql/error.log
  tags: ["mysql"]

- type: log
  enabled: true
  paths:
    - /var/log/mongodb/mongod.log
  tags: ["mongodb"]

output.elasticsearch:
  hosts: ["monitoring-server:9200"]
  indices:
    - index: "filebeat-mysql-%{+yyyy.MM.dd}"
      when.contains:
        tags: "mysql"
    - index: "filebeat-mongodb-%{+yyyy.MM.dd}"
      when.contains:
        tags: "mongodb"

setup.kibana:
  host: "monitoring-server:5601"
EOF

# Create a script to configure Elasticsearch connection details later
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

# Create test data in MySQL
sudo mysql -e "USE testdb; CREATE TABLE test_data (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO test_data (name) VALUES ('Test 1'), ('Test 2'), ('Test 3');"

# Create test data in MongoDB
mongosh --eval 'db = db.getSiblingDB("testdb"); db.test_data.insertMany([{name: "Test 1", creation_date: new Date()}, {name: "Test 2", creation_date: new Date()}, {name: "Test 3", creation_date: new Date()}])'

echo "Database installation complete!"
echo "MySQL is accessible at port 3306 with testdb database and testuser user"
echo "MongoDB is accessible at port 27017 with testdb database and testuser user"
echo "Run /root/configure-elasticsearch.sh <elasticsearch-ip> to connect to ELK stack" 