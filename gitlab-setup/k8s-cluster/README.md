# Kubernetes Cluster Setup Scripts

This directory contains scripts for setting up a Kubernetes cluster on AWS EC2 instances.

## Scripts Overview

1. **all_nodes.sh** - Bootstrap script that runs on all EC2 instances (both master and worker nodes)
   - Disables swap
   - Enables IPv4 forwarding (required for Kubernetes networking)
   - Installs and configures containerd runtime with SystemdCgroup=true
   - Installs kubelet, kubeadm, and kubectl using the latest stable repositories
   - Installs Helm for Kubernetes package management
   - Contains commented commands for node labeling after cluster initialization

2. **setup-k8s-cluster.sh** - Creates EC2 instances for the Kubernetes cluster
   - Creates a security group with appropriate rules
   - Launches 3 master nodes and 2 worker nodes
   - Uses t3.small instances with Ubuntu AMI
   - Applies the all_nodes.sh script as user-data

3. **init-k8s-cluster.sh** - Initializes the Kubernetes control plane
   - Configures the first master node
   - Sets up a highly available control plane with a load balancer
   - Installs Calico network plugin
   - Generates join commands for additional nodes

4. **setup-cicd-ec2.sh** - Creates an EC2 instance for CI/CD tools
   - Creates a dedicated security group
   - Launches a t3.small instance with Ubuntu AMI
   - Uses the all_nodes.sh script as user-data
   - Designed for hosting CI/CD tools (Jenkins, SonarQube, ArgoCD)

5. **setup-monitoring-ec2.sh** - Creates an EC2 instance for monitoring
   - Sets up ELK stack (Elasticsearch, Logstash, Kibana)
   - Installs Grafana for dashboard visualization
   - Configures persistence with attached EBS volume

6. **setup-databases-ec2.sh** - Creates an EC2 instance for databases
   - Installs MySQL and MongoDB with proper configurations
   - Sets up persistent storage using attached EBS volume

7. **setup-springboot-ec2.sh** - Creates an EC2 instance for Spring Boot applications
   - Configures Java and Docker for application deployment
   - Sets up connections to databases

8. **setup-kafka-ec2.sh** - Creates a highly available Kafka cluster
   - Creates 3 Kafka broker nodes for high availability
   - Provisions 100GB EBS volumes per node for data persistence
   - Creates necessary security groups with appropriate ports open

9. **install-kafka.sh** - Installs and configures Kafka on EC2 instances
   - Installs Java and other required packages
   - Sets up data directory on attached EBS volume
   - Configures Zookeeper and Kafka with systemd services
   - Prepares security directories for SSL/TLS configuration

10. **setup-kafka-security.sh** - Configures Kafka security with mutual TLS
   - Sets up two-way SSL authentication between brokers and clients
   - Creates separate PKCS12 keystores for brokers, producers, and consumers
   - Generates a Certificate Authority (CA) for signing certificates
   - Configures secure client-broker communication

## Usage Instructions

1. First, run the setup-k8s-cluster.sh script to create the EC2 instances:
   ```bash
   ./setup-k8s-cluster.sh
   ```

2. Create an AWS Network Load Balancer (NLB) pointing to your master nodes:
   - Create a target group with TCP port 6443
   - Register your three master node instances
   - Create an NLB with TCP listener on port 6443 forwarding to the target group
   - Note the NLB's DNS name

3. SSH into the first master node and run:
   ```bash
   # Edit the script to replace LOAD_BALANCER_DNS with your NLB DNS name
   vi init-k8s-cluster.sh
   # Run the script
   ./init-k8s-cluster.sh
   ```

4. Copy the join commands output by the init-k8s-cluster.sh script, and use them to join the other nodes to the cluster:
   ```bash
   # On other master nodes
   sudo kubeadm join LOAD_BALANCER_DNS:6443 --token TOKEN --discovery-token-ca-cert-hash HASH --control-plane --certificate-key KEY
   
   # On worker nodes
   sudo kubeadm join LOAD_BALANCER_DNS:6443 --token TOKEN --discovery-token-ca-cert-hash HASH
   ```

5. Optionally, create a dedicated EC2 instance for CI/CD tools:
   ```bash
   ./setup-cicd-ec2.sh
   ```

6. To set up a highly available Kafka cluster with security:
   ```bash
   # Create EC2 instances for Kafka with attached EBS volumes
   ./setup-kafka-ec2.sh
   
   # SSH into each Kafka node and execute the security setup script
   # This will create keystores and configure mutual TLS
   sudo ./setup-kafka-security.sh
   ```

## Kafka Security Setup

The Kafka cluster is configured with mutual TLS authentication:

- Each broker has its own PKCS12 keystore and truststore
- Separate PKCS12 keystores for producers and consumers
- Two-way SSL handshake for mutual authentication
- Secure connection available on port 9093
- Standard connection available on port 9092

For detailed information on the Kafka security configuration:
- See `kafka-security-documentation.md` for complete documentation
- Client configuration examples are provided for Java applications
- Producer and consumer connection examples are included

## Important Notes

- These scripts use containerd as the container runtime instead of Docker
- IPv4 forwarding is properly configured for Kubernetes networking
- SystemdCgroup is set to true for containerd, which is required for kubeadm
- The load balancer setup is essential for high availability
- For production use, security groups should be more restrictive
- Remember to save the kubeconfig file (/etc/kubernetes/admin.conf) from the first master node
- For further details, refer to the documentation in the docs/ directory 