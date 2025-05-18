# Istio Service Mesh

This directory contains the installation scripts and configuration files for Istio service mesh implementation.

## Components

- **Installation**: Scripts to install Istio with proper profile and configuration
- **Gateways**: Default gateway configurations for ingress traffic
- **Control Plane Config**: Custom configurations for the Istio control plane
- **Security**: mTLS and authorization policies
- **Observability**: Configurations for tracing, metrics, and logs

## Installation

To install Istio with the default profile:

```bash
./install-istio.sh
```

Or specify a custom profile:

```bash
./install-istio.sh demo
```

Available profiles: default, demo, minimal, remote, empty

## Gateway Setup

The default gateway is deployed as part of the installation. To create additional gateways:

```bash
kubectl apply -f gateways/custom-gateway.yaml
```

## Securing with mTLS

By default, mTLS is enabled in PERMISSIVE mode. To enable STRICT mode:

```bash
kubectl apply -f security/strict-mtls.yaml
```

## Observability

Istio integrates with the existing monitoring stack:

- Prometheus scrapes Istio metrics
- Grafana displays pre-configured Istio dashboards
- Kiali provides service mesh visualization
- Jaeger enables distributed tracing

To access the dashboards:

```bash
# Kiali dashboard
istioctl dashboard kiali

# Jaeger dashboard
istioctl dashboard jaeger
``` 