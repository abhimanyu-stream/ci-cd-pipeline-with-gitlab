#!/bin/bash
# Kubernetes Resource Backup Script
# This script backs up all Kubernetes resources in the cluster

# Set backup directory
BACKUP_DIR="/backup/k8s-resources/$(date +%Y-%m-%d)"
mkdir -p $BACKUP_DIR

# Log file
LOG_FILE="$BACKUP_DIR/backup.log"

echo "Starting Kubernetes resource backup at $(date)" | tee -a $LOG_FILE

# Get all namespaces
echo "Backing up namespaces..." | tee -a $LOG_FILE
kubectl get namespaces -o yaml > $BACKUP_DIR/namespaces.yaml

# For each namespace, backup key resources
for NAMESPACE in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
    NS_DIR="$BACKUP_DIR/$NAMESPACE"
    mkdir -p $NS_DIR
    
    echo "Backing up resources in namespace: $NAMESPACE" | tee -a $LOG_FILE
    
    # Deployments
    kubectl get deployments -n $NAMESPACE -o yaml > $NS_DIR/deployments.yaml
    
    # StatefulSets
    kubectl get statefulsets -n $NAMESPACE -o yaml > $NS_DIR/statefulsets.yaml
    
    # DaemonSets
    kubectl get daemonsets -n $NAMESPACE -o yaml > $NS_DIR/daemonsets.yaml
    
    # ConfigMaps
    kubectl get configmaps -n $NAMESPACE -o yaml > $NS_DIR/configmaps.yaml
    
    # Secrets
    kubectl get secrets -n $NAMESPACE -o yaml > $NS_DIR/secrets.yaml
    
    # Services
    kubectl get services -n $NAMESPACE -o yaml > $NS_DIR/services.yaml
    
    # PersistentVolumeClaims
    kubectl get pvc -n $NAMESPACE -o yaml > $NS_DIR/pvcs.yaml
    
    # Ingresses
    kubectl get ingress -n $NAMESPACE -o yaml > $NS_DIR/ingresses.yaml 2>/dev/null
done

# Custom Resource Definitions (if any)
echo "Backing up Custom Resource Definitions..." | tee -a $LOG_FILE
kubectl get crds -o yaml > $BACKUP_DIR/crds.yaml 2>/dev/null

# Backup PersistentVolumes (cluster-wide resource)
echo "Backing up PersistentVolumes..." | tee -a $LOG_FILE
kubectl get pv -o yaml > $BACKUP_DIR/pvs.yaml

# Backup StorageClasses (cluster-wide resource)
echo "Backing up StorageClasses..." | tee -a $LOG_FILE
kubectl get storageclass -o yaml > $BACKUP_DIR/storageclasses.yaml

# Backup ClusterRoles and ClusterRoleBindings
echo "Backing up RBAC resources..." | tee -a $LOG_FILE
kubectl get clusterroles -o yaml > $BACKUP_DIR/clusterroles.yaml
kubectl get clusterrolebindings -o yaml > $BACKUP_DIR/clusterrolebindings.yaml

# Backup etcd (requires that etcdctl is configured correctly)
if command -v etcdctl &> /dev/null; then
    echo "Backing up etcd..." | tee -a $LOG_FILE
    ETCD_BACKUP_DIR="$BACKUP_DIR/etcd"
    mkdir -p $ETCD_BACKUP_DIR
    
    # Add your etcdctl snapshot command here
    # Example: ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
    #          --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    #          --cert=/etc/kubernetes/pki/etcd/server.crt \
    #          --key=/etc/kubernetes/pki/etcd/server.key \
    #          snapshot save $ETCD_BACKUP_DIR/etcd-snapshot.db
fi

# Backup Istio configurations if present
if kubectl get namespace istio-system &>/dev/null; then
    echo "Istio detected, backing up Istio configurations..." | tee -a $LOG_FILE
    
    # Check if the backup-istio-config.sh script exists in the same directory
    SCRIPT_DIR="$(dirname "$0")"
    ISTIO_BACKUP_SCRIPT="$SCRIPT_DIR/backup-istio-config.sh"
    
    if [ -f "$ISTIO_BACKUP_SCRIPT" ]; then
        echo "Running Istio backup script..." | tee -a $LOG_FILE
        bash "$ISTIO_BACKUP_SCRIPT" "$BACKUP_DIR"
    else
        echo "Istio backup script not found at $ISTIO_BACKUP_SCRIPT" | tee -a $LOG_FILE
        echo "Performing basic Istio backup..." | tee -a $LOG_FILE
        
        # Create Istio backup directory
        ISTIO_DIR="$BACKUP_DIR/istio"
        mkdir -p $ISTIO_DIR
        
        # Backup basic Istio CRDs and resources
        kubectl get virtualservices --all-namespaces -o yaml > $ISTIO_DIR/virtualservices.yaml
        kubectl get destinationrules --all-namespaces -o yaml > $ISTIO_DIR/destinationrules.yaml
        kubectl get gateways --all-namespaces -o yaml > $ISTIO_DIR/gateways.yaml
        kubectl get serviceentries --all-namespaces -o yaml > $ISTIO_DIR/serviceentries.yaml
        kubectl get authorizationpolicies --all-namespaces -o yaml > $ISTIO_DIR/authorizationpolicies.yaml
    fi
fi

# Compress the backup
echo "Compressing backup..." | tee -a $LOG_FILE
BACKUP_ARCHIVE="/backup/k8s-resources-$(date +%Y-%m-%d).tar.gz"
tar -czf $BACKUP_ARCHIVE -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)

# Clean up old backups (keep last 7 days by default)
find /backup -name "k8s-resources-*.tar.gz" -type f -mtime +7 -delete

echo "Backup completed at $(date)" | tee -a $LOG_FILE
echo "Backup saved to: $BACKUP_ARCHIVE" | tee -a $LOG_FILE 