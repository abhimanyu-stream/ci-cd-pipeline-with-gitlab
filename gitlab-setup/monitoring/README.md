# Kubernetes Monitoring with Prometheus and Grafana

This directory contains the Kubernetes configuration for implementing a comprehensive monitoring solution using Prometheus and Grafana.

## Architecture

The monitoring setup consists of the following components:

1. **Prometheus** - For metrics collection, storage, and querying
2. **Grafana** - For visualization and dashboarding
3. **Node Exporter** - For collecting hardware and OS metrics
4. **kube-state-metrics** - For gathering Kubernetes objects metrics

## Directory Structure

```
monitoring/
├── prometheus/
│   ├── configs/           # Prometheus configuration files
│   ├── rules/             # Alerting and recording rules
│   ├── dashboards/        # JSON dashboards
│   └── prometheus-deployment.yaml  # Deployment manifests
└── grafana/
    ├── grafana-deployment.yaml    # Deployment manifests
    └── dashboards/                # Grafana dashboard configurations
```

## Installation

### Prerequisites

- A running Kubernetes cluster
- kubectl configured to communicate with your cluster
- Storage class available for persistent volumes

### Deployment Steps

1. Create the monitoring namespace:
   ```bash
   kubectl create namespace monitoring
   ```

2. Deploy Prometheus:
   ```bash
   kubectl apply -f prometheus/prometheus-deployment.yaml
   ```

3. Deploy Grafana:
   ```bash
   kubectl apply -f grafana/grafana-deployment.yaml
   ```

4. Access Grafana:
   ```bash
   # Port forward to access Grafana on http://localhost:3000
   kubectl port-forward svc/grafana 3000:3000 -n monitoring
   ```

5. Login using the default credentials:
   - Username: admin
   - Password: admin123

## Configuration

### Adding Custom Prometheus Rules

1. Create your rule files in the `prometheus/rules/` directory
2. Update the ConfigMap in `prometheus-deployment.yaml` to include these files
3. Apply the changes:
   ```bash
   kubectl apply -f prometheus/prometheus-deployment.yaml
   ```

### Importing Dashboards to Grafana

1. Use the Grafana UI to import dashboard JSON files from the `grafana/dashboards/` directory
2. Alternatively, set up auto-provisioning by adding dashboard JSONs to ConfigMaps

## Security Considerations

- The current setup uses basic authentication for Grafana
- For production use, consider:
  - Using a proper secret management solution
  - Implementing TLS for all connections
  - Setting up proper network policies
  - Configuring more granular RBAC permissions

## Maintenance Tasks

### Scaling

- Adjust Prometheus resource limits and requests in the deployment file as needed
- For larger clusters, consider using Prometheus Operator and Thanos for a scalable monitoring stack

### Upgrading

1. Update the container image tag in the deployment files
2. Apply the changes with kubectl
3. Verify the new versions are running correctly

## Troubleshooting

- **Prometheus not scraping targets:**
  Check service discovery configuration and network access to targets

- **Grafana cannot connect to Prometheus:**
  Verify the Prometheus service is running and accessible from Grafana

- **High resource usage:**
  Adjust retention periods, recording rules, or resource limits

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/) 