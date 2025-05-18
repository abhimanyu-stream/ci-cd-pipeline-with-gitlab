# Helm Charts

This directory contains Helm charts for deploying and managing applications in our Kubernetes infrastructure.

## Structure

- `monitoring/` - Charts for the monitoring stack (Prometheus, Grafana)
- `backup/` - Charts for the backup system
- `databases/` - Charts for MySQL and MongoDB databases
- `application/` - Charts for our Spring Boot application
- `istio/` - Charts for Istio components and configuration
- `kafka/` - Charts for Kafka cluster

## Usage

These Helm charts can be installed using:

```bash
helm install [RELEASE_NAME] [CHART_DIRECTORY] -n [NAMESPACE] -f [VALUES_FILE]
```

For example:

```bash
helm install monitoring gitlab-setup/helm-charts/monitoring -n monitoring -f custom-values.yaml
```

## Chart Versioning

All charts follow semantic versioning. Version information is stored in the Chart.yaml file within each chart directory.

## Contributing

When adding or modifying charts:

1. Update the version in Chart.yaml following semantic versioning rules
2. Document all available configuration values in values.yaml with comments
3. Update the README.md in the chart directory with usage examples 