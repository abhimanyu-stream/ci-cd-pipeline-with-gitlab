# Spring Boot Application Helm Chart

This Helm chart deploys a Spring Boot application with support for MySQL and MongoDB databases, Istio service mesh integration, and ELK stack logging.

## Features

- Spring Boot application deployment with proper health checks
- Database connectivity (MySQL and MongoDB)
- Horizontal Pod Autoscaler for automatic scaling
- Prometheus metrics integration
- ELK stack logging
- Istio service mesh integration
- Kubernetes Ingress for non-Istio deployments

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Istio service mesh (optional)
- ELK stack for logging (optional)

## Installing the Chart

```bash
helm install spring-app ./spring-boot-app -f values.yaml
```

## Configuration

The following table lists some of the most common configurable parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Application image repository | `your-registry/spring-app` |
| `image.tag` | Application image tag | `latest` |
| `replicaCount` | Number of replicas to deploy | `2` |
| `config.springProfiles` | Spring active profiles | `prod` |
| `config.javaOpts` | JVM options | `-Xms256m -Xmx512m` |
| `database.mysql.enabled` | Enable MySQL database | `true` |
| `database.mongodb.enabled` | Enable MongoDB database | `true` |
| `logging.elk.enabled` | Enable ELK stack logging | `true` |
| `istio.enabled` | Enable Istio service mesh | `true` |
| `autoscaling.enabled` | Enable HPA | `true` |

## Security

For production deployments, it's recommended to:

1. Store database credentials in Kubernetes secrets by setting `database.mysql.existingSecret` and `database.mongodb.existingSecret`
2. Use TLS for all ingress/gateway resources
3. Set appropriate resource limits and requests

## Persistence

This chart doesn't use persistent volumes directly since the database is expected to be deployed separately.

## Upgrading

To upgrade an existing release:

```bash
helm upgrade spring-app ./spring-boot-app -f values.yaml
``` 