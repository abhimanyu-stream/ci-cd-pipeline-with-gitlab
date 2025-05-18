#!/bin/bash
# Istio Installation Script
# This script downloads and installs Istio with the specified profile

set -e

# Get the profile from command line argument or use default
ISTIO_PROFILE=${1:-default}
ISTIO_VERSION="1.20.0"
ISTIO_NAMESPACE="istio-system"

echo "Installing Istio with profile: $ISTIO_PROFILE"

# Create namespace if it doesn't exist
if ! kubectl get namespace $ISTIO_NAMESPACE &> /dev/null; then
  echo "Creating namespace $ISTIO_NAMESPACE"
  kubectl create namespace $ISTIO_NAMESPACE
fi

# Download Istio if not already downloaded
if [ ! -d "istio-$ISTIO_VERSION" ]; then
  echo "Downloading Istio $ISTIO_VERSION..."
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
fi

# Add istioctl to PATH
export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH

# Verify istioctl is available
if ! command -v istioctl &> /dev/null; then
  echo "Error: istioctl not found in PATH"
  exit 1
fi

# Install Istio
echo "Installing Istio with $ISTIO_PROFILE profile..."
istioctl install --set profile=$ISTIO_PROFILE -y

# Enable automatic sidecar injection for default namespace
echo "Enabling automatic sidecar injection for default namespace..."
kubectl label namespace default istio-injection=enabled --overwrite

# Install addons based on profile
if [ "$ISTIO_PROFILE" != "minimal" ] && [ "$ISTIO_PROFILE" != "empty" ]; then
  echo "Installing Istio addons..."
  
  # Install Kiali
  echo "Installing Kiali..."
  kubectl apply -f istio-$ISTIO_VERSION/samples/addons/kiali.yaml
  
  # Install Jaeger
  echo "Installing Jaeger..."
  kubectl apply -f istio-$ISTIO_VERSION/samples/addons/jaeger.yaml
  
  # Install Prometheus if not already installed through our monitoring stack
  if ! kubectl get deployment -n monitoring prometheus-server &> /dev/null; then
    echo "Installing Prometheus..."
    kubectl apply -f istio-$ISTIO_VERSION/samples/addons/prometheus.yaml
  else
    echo "Prometheus already installed in monitoring namespace, configuring for Istio metrics..."
    kubectl apply -f prometheus-config/istio-scrape-config.yaml
  fi
  
  # Install Grafana if not already installed through our monitoring stack
  if ! kubectl get deployment -n monitoring grafana &> /dev/null; then
    echo "Installing Grafana..."
    kubectl apply -f istio-$ISTIO_VERSION/samples/addons/grafana.yaml
  else
    echo "Grafana already installed in monitoring namespace, importing Istio dashboards..."
    kubectl apply -f grafana-config/istio-dashboards.yaml
  fi
fi

# Apply default gateway
echo "Applying default gateway configuration..."
kubectl apply -f gateways/default-gateway.yaml

# Wait for Istio components to be ready
echo "Waiting for Istio components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/istiod -n $ISTIO_NAMESPACE

# Verify installation
echo "Verifying Istio installation..."
istioctl verify-install

echo "Istio $ISTIO_VERSION installed successfully with $ISTIO_PROFILE profile"
echo "To access the dashboards, run:"
echo "  istioctl dashboard kiali"
echo "  istioctl dashboard jaeger" 