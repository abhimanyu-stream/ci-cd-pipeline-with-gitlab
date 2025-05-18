# Kubernetes Cluster Restore Procedure

This document outlines the steps to restore a Kubernetes cluster from backups.

## Prerequisites

- Access to backup archives (`/backup/k8s-resources-*.tar.gz`)
- `kubectl` configured with appropriate admin permissions
- For etcd restore: access to etcd machine and etcdctl utility
- For Istio restore: `istioctl` installed and configured

## Restore Steps

### 1. Prepare the Restore Environment

```bash
# Extract the backup archive
BACKUP_DATE="YYYY-MM-DD"  # Replace with the date of the backup to restore
BACKUP_ARCHIVE="/backup/k8s-resources-${BACKUP_DATE}.tar.gz"
RESTORE_DIR="/tmp/k8s-restore"

mkdir -p $RESTORE_DIR
tar -xzf $BACKUP_ARCHIVE -C $RESTORE_DIR
```

### 2. Restore etcd (if applicable)

If you need to restore etcd (most critical component):

```bash
# Stop the API server on the master node
sudo systemctl stop kube-apiserver

# Restore etcd from snapshot (adjust paths as necessary)
ETCDCTL_API=3 etcdctl snapshot restore $RESTORE_DIR/k8s-resources/etcd/etcd-snapshot.db \
  --data-dir /var/lib/etcd-restored \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-cluster-token=etcd-cluster \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Update etcd configuration to use restored data
sudo mv /var/lib/etcd /var/lib/etcd.bak
sudo mv /var/lib/etcd-restored /var/lib/etcd
sudo systemctl restart etcd
sudo systemctl start kube-apiserver
```

### 3. Restore Kubernetes Resources

For a working cluster with empty/missing resources:

```bash
# Restore CRDs first
kubectl apply -f $RESTORE_DIR/k8s-resources/crds.yaml

# Allow time for CRDs to register
sleep 10

# Restore cluster-wide resources
kubectl apply -f $RESTORE_DIR/k8s-resources/namespaces.yaml
kubectl apply -f $RESTORE_DIR/k8s-resources/clusterroles.yaml
kubectl apply -f $RESTORE_DIR/k8s-resources/clusterrolebindings.yaml
kubectl apply -f $RESTORE_DIR/k8s-resources/storageclasses.yaml

# Wait for namespaces to be active
sleep 5

# Restore namespace resources (excluding the kube-system, which should be handled carefully)
for NAMESPACE_DIR in $RESTORE_DIR/k8s-resources/*; do
  if [ -d "$NAMESPACE_DIR" ]; then
    NAMESPACE=$(basename $NAMESPACE_DIR)
    
    # Skip special namespaces that should be handled with care
    if [[ "$NAMESPACE" != "kube-system" && "$NAMESPACE" != "kube-public" && "$NAMESPACE" != "kube-node-lease" ]]; then
      echo "Restoring resources for namespace: $NAMESPACE"
      
      # Restore in a specific order to handle dependencies
      kubectl apply -f $NAMESPACE_DIR/configmaps.yaml
      kubectl apply -f $NAMESPACE_DIR/secrets.yaml
      kubectl apply -f $NAMESPACE_DIR/pvcs.yaml
      kubectl apply -f $NAMESPACE_DIR/services.yaml
      kubectl apply -f $NAMESPACE_DIR/deployments.yaml
      kubectl apply -f $NAMESPACE_DIR/statefulsets.yaml
      kubectl apply -f $NAMESPACE_DIR/daemonsets.yaml
      
      # Restore ingresses last
      if [ -f "$NAMESPACE_DIR/ingresses.yaml" ]; then
        kubectl apply -f $NAMESPACE_DIR/ingresses.yaml
      fi
    fi
  fi
done
```

### 4. Restore Istio Configuration (if applicable)

If Istio was included in the backup:

```bash
# Check if Istio directory exists in the backup
if [ -d "$RESTORE_DIR/k8s-resources/istio" ]; then
  echo "Restoring Istio configurations..."
  
  # Verify Istio is installed
  if ! kubectl get namespace istio-system &>/dev/null; then
    echo "Warning: istio-system namespace not found. Istio might not be installed."
    echo "Please install Istio first, then restore its configuration."
    # Optionally install Istio here if you have the installation profile saved
    # istioctl install --set profile=default -f $RESTORE_DIR/k8s-resources/istio/istio-profile-dump.yaml
  fi
  
  # Restore Istio CRDs in a specific order to respect dependencies
  ISTIO_DIR="$RESTORE_DIR/k8s-resources/istio"
  
  # Start with Gateway and base networking resources
  if [ -f "$ISTIO_DIR/gateways.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/gateways.yaml
  fi
  
  if [ -f "$ISTIO_DIR/serviceentries.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/serviceentries.yaml
  fi
  
  # Then apply routing rules
  if [ -f "$ISTIO_DIR/destinationrules.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/destinationrules.yaml
  fi
  
  if [ -f "$ISTIO_DIR/virtualservices.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/virtualservices.yaml
  fi
  
  # Finally apply security policies
  if [ -f "$ISTIO_DIR/peerauthentications.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/peerauthentications.yaml
  fi
  
  if [ -f "$ISTIO_DIR/requestauthentications.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/requestauthentications.yaml
  fi
  
  if [ -f "$ISTIO_DIR/authorizationpolicies.yaml" ]; then
    kubectl apply -f $ISTIO_DIR/authorizationpolicies.yaml
  fi
  
  # Apply remaining Istio resources
  for CONFIG_FILE in $ISTIO_DIR/*.yaml; do
    # Skip files we've already applied
    if [[ "$CONFIG_FILE" != *"gateways.yaml" && 
          "$CONFIG_FILE" != *"serviceentries.yaml" && 
          "$CONFIG_FILE" != *"destinationrules.yaml" && 
          "$CONFIG_FILE" != *"virtualservices.yaml" && 
          "$CONFIG_FILE" != *"peerauthentications.yaml" && 
          "$CONFIG_FILE" != *"requestauthentications.yaml" && 
          "$CONFIG_FILE" != *"authorizationpolicies.yaml" ]]; then
      kubectl apply -f $CONFIG_FILE
    fi
  done
  
  echo "Istio configuration restore completed."
fi
```

### 5. Verify the Restore

```bash
# Check critical resources
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get pv,pvc --all-namespaces

# Check for any issues
kubectl get events --all-namespaces

# Verify Istio (if applicable)
if kubectl get namespace istio-system &>/dev/null; then
  echo "Verifying Istio configuration..."
  kubectl get gateways --all-namespaces
  kubectl get virtualservices --all-namespaces
  kubectl get destinationrules --all-namespaces
  istioctl analyze --all-namespaces
fi
```

### 6. Restore Specific Applications (if needed)

Depending on your applications, you might need to:

1. Restore application-specific persistent data
2. Restart services in a specific order
3. Run application-specific validation

## Disaster Recovery Testing

It's recommended to regularly test this restore procedure in a non-production environment to ensure:

1. Backups are valid and can be restored
2. The procedure is accurate and complete
3. Team members are familiar with the restore process

## Notes

- Always review the Kubernetes resources before applying them to avoid overwriting newer configurations
- For stateful applications, additional application-specific restore procedures may be required
- Consider keeping multiple backup versions to mitigate against corrupted backups
- For Istio, you may need to restart proxies after configuration is restored: `kubectl rollout restart deployment -n your-application-namespace` 