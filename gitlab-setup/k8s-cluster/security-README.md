# Kubernetes & ELK Stack Security Setup

This document outlines the security implementations for the Kubernetes cluster and ELK (Elasticsearch, Logstash, Kibana) stack.

## 1. Kubernetes RBAC Security

Role-Based Access Control (RBAC) is implemented to control access to the Kubernetes cluster resources.

### Components

- **ClusterRoles & Roles**: Define permissions to specific resources
- **ClusterRoleBindings & RoleBindings**: Connect roles to users, groups, or service accounts
- **ServiceAccounts**: Identity used by processes running in the cluster

### Role Hierarchy

1. **Cluster Administrator** - Full access to all cluster resources
2. **DevOps** - Wide access for CI/CD pipelines and maintenance
3. **Developer** - Environment-specific permissions with restrictions in production
4. **Read-Only** - Monitoring and auditing access

### Deployment Instructions

```bash
# From the cluster master node
cd /path/to/rbac/
# Create the namespaces and apply RBAC configurations
./rbac-setup.sh
```

For detailed configuration and usage, see [RBAC README](rbac/README.md).

## 2. ELK Stack Security

Security for the ELK stack implements encryption, authentication, and authorization.

### Security Features

- **TLS/SSL Encryption**: All communications secured via HTTPS
- **X-Pack Security**: Authentication and authorization for Elasticsearch and Kibana
- **Role-Based Access**: Different users have specific permissions
- **Secure Passwords**: Automated password generation and management

### Components Secured

- **Elasticsearch**: Secured with TLS, authentication, and authorization
- **Kibana**: HTTPS access and user authentication
- **Logstash**: Secure connection to Elasticsearch
- **Filebeat/Metricbeat**: Authenticated and encrypted connections

### Deployment Instructions

```bash
# On the ELK monitoring server
cd /path/to/elk-security/
sudo bash setup-elk-security.sh
```

For Kubernetes deployments of Filebeat and Metricbeat, apply the provided Kubernetes manifests:

```bash
kubectl apply -f elk-security/filebeat-k8s.yaml
```

For detailed configuration and troubleshooting, see [ELK Security README](elk-security/README.md).

## Integration Between Systems

### Kubernetes to ELK Stack Monitoring

The Filebeat and Metricbeat Kubernetes deployments securely send data to Elasticsearch:

1. They use service accounts with appropriate RBAC permissions
2. Communications with Elasticsearch are authenticated and encrypted
3. Beats use dedicated credentials stored as Kubernetes secrets

## Security Best Practices

1. **Rotate Certificates**: Regularly rotate certificates and keys
2. **Password Management**: Use a secure password manager for credentials
3. **Regular Audits**: Periodically audit access and permissions
4. **Least Privilege**: Apply the principle of least privilege for all accounts
5. **Regular Updates**: Keep all components up-to-date with security patches

## Troubleshooting

For RBAC issues:
```bash
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<serviceaccount>
```

For ELK security issues:
```bash
# Check Elasticsearch logs
sudo journalctl -u elasticsearch
# Test Elasticsearch connectivity
curl -k -u elastic:PASSWORD https://localhost:9200
``` 