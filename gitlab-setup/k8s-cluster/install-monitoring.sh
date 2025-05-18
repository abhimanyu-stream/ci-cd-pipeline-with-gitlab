#!/bin/bash
# THIS SCRIPT RUNS ON THE MONITORING EC2 INSTANCE AS USER-DATA

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
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
echo "Waiting for Elasticsearch to start..."
sleep 30

# Install Kibana
sudo apt-get install -y kibana
sudo sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana

# Install Logstash
sudo apt-get install -y logstash
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl start logstash

# Install Filebeat
sudo apt-get install -y filebeat
sudo filebeat modules enable system
sudo filebeat setup -e
sudo systemctl enable filebeat
sudo systemctl start filebeat

# Install Grafana
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Install Metricbeat (for system metrics)
sudo apt-get install -y metricbeat
sudo metricbeat modules enable system
sudo metricbeat setup -e
sudo systemctl enable metricbeat
sudo systemctl start metricbeat

# Create a basic Logstash configuration pipeline
cat <<EOF | sudo tee /etc/logstash/conf.d/logstash.conf
input {
  beats {
    port => 5044
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
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOF

# Restart Logstash with new config
sudo systemctl restart logstash

# Configure Grafana to use Elasticsearch
sudo tee /etc/grafana/provisioning/datasources/elasticsearch.yaml > /dev/null << EOL
apiVersion: 1
datasources:
- name: Elasticsearch
  type: elasticsearch
  access: proxy
  url: http://localhost:9200
  jsonData:
    index: "filebeat-*"
    timeField: "@timestamp"
    esVersion: 7.0.0
  isDefault: true
EOL

# Restart Grafana with new datasource
sudo systemctl restart grafana-server

echo "ELK Stack and Grafana installation complete!"
echo "Access Kibana at: http://YOUR_SERVER_IP:5601"
echo "Access Grafana at: http://YOUR_SERVER_IP:3000 (default credentials: admin/admin)"
echo "Elasticsearch API available at: http://YOUR_SERVER_IP:9200"
echo "Logstash Beats input listening on port 5044" 