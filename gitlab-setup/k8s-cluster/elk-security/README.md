# Elasticsearch, Logstash, and Kibana (ELK) Security Setup

This directory contains configurations and scripts to secure your ELK stack.

## Security Features Implemented

1. **TLS/SSL Encryption**
   - HTTPS for all Elasticsearch and Kibana communications
   - TLS for inter-node communications
   - Certificate-based security with PKI certificates

2. **Authentication**
   - User authentication for all components
   - Role-based access control in Elasticsearch
   - Secure password management

3. **Authorization**
   - Custom roles with specific permissions
   - Monitoring-specific user with restricted access
   - System users for Logstash, Filebeat, and other components

## Setup Instructions

### 1. Run the Security Setup Script

```bash
# On your monitoring EC2 instance
sudo bash setup-elk-security.sh
```

This script will:
- Generate SSL certificates for Elasticsearch and Kibana
- Enable X-Pack security
- Configure HTTPS for the Elasticsearch REST API
- Set up secure passwords for built-in users
- Configure Kibana to use HTTPS and authentication
- Update Logstash to connect securely to Elasticsearch
- Create additional roles and users

### 2. Configure Beats (Filebeat, Metricbeat)

After running the setup script, configure your Beats instances:

```bash
# Set the Elastic password as an environment variable
export ELASTIC_PASSWORD="your_elastic_password"

# Copy the example configuration
sudo cp filebeat-secure.yml /etc/filebeat/filebeat.yml
sudo cp metricbeat-secure.yml /etc/metricbeat/metricbeat.yml

# Copy the CA certificate to beats
sudo cp /var/lib/elasticsearch/certs/elastic-stack-ca.p12 /etc/filebeat/
sudo cp /var/lib/elasticsearch/certs/elastic-stack-ca.p12 /etc/metricbeat/

# Restart services
sudo systemctl restart filebeat
sudo systemctl restart metricbeat
```

## Secure Access

### Accessing Kibana

Access Kibana via HTTPS:
```
https://YOUR_SERVER_IP:5601
```

Use the credentials saved in `/var/lib/elasticsearch/passwords.txt` on the monitoring server.

### Accessing Elasticsearch

Access the Elasticsearch API via HTTPS:
```
https://YOUR_SERVER_IP:9200
```

## Troubleshooting

1. **Certificate issues**
   - Check certificate paths in configuration files
   - Verify certificate permissions (should be readable by elasticsearch user)

2. **Authentication problems**
   - Verify correct passwords are being used
   - Ensure users have appropriate roles assigned

3. **Connection errors**
   - Check firewall settings for ports 9200 (Elasticsearch) and 5601 (Kibana)
   - Verify TLS settings in configuration files

## Security Best Practices

1. Store passwords securely, not in plaintext files
2. Rotate certificates periodically (recommended every 6-12 months)
3. Implement network segmentation for your ELK stack
4. Use minimal permissions for each component
5. Regularly update all ELK components to address security vulnerabilities 