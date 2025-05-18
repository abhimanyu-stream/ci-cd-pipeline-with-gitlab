#!/bin/bash
# Istio Configuration Backup Script
# This script backs up all Istio-related configurations

# Set backup directory - either use the one passed in or create new one
if [ -z "$1" ]; then
  BACKUP_DIR="/backup/istio-config/$(date +%Y-%m-%d)"
else
  BACKUP_DIR="$1/istio"
fi

mkdir -p $BACKUP_DIR

# Log file
LOG_FILE="$BACKUP_DIR/istio-backup.log"

echo "Starting Istio configuration backup at $(date)" | tee -a $LOG_FILE

# Check if istioctl is available
if ! command -v istioctl &> /dev/null; then
  echo "istioctl not found, downloading latest version..." | tee -a $LOG_FILE
  ISTIO_VERSION=$(curl -sL https://github.com/istio/istio/releases | grep -o 'releases/[0-9]*.[0-9]*.[0-9]*/' | sort -V | tail -1 | sed 's/releases\///' | sed 's/\///')
  curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istioctl-$ISTIO_VERSION-linux-amd64.tar.gz" | tar xz
  chmod +x ./istioctl
  ISTIOCTL="./istioctl"
else
  ISTIOCTL="istioctl"
fi

echo "Using istioctl version: $($ISTIOCTL version --short)" | tee -a $LOG_FILE

# Backup Istio CRDs
echo "Backing up Istio CRDs..." | tee -a $LOG_FILE

# VirtualServices
echo "Backing up VirtualServices..." | tee -a $LOG_FILE
kubectl get virtualservices --all-namespaces -o yaml > $BACKUP_DIR/virtualservices.yaml

# DestinationRules
echo "Backing up DestinationRules..." | tee -a $LOG_FILE
kubectl get destinationrules --all-namespaces -o yaml > $BACKUP_DIR/destinationrules.yaml

# Gateways
echo "Backing up Gateways..." | tee -a $LOG_FILE
kubectl get gateways --all-namespaces -o yaml > $BACKUP_DIR/gateways.yaml

# ServiceEntries
echo "Backing up ServiceEntries..." | tee -a $LOG_FILE
kubectl get serviceentries --all-namespaces -o yaml > $BACKUP_DIR/serviceentries.yaml

# EnvoyFilters
echo "Backing up EnvoyFilters..." | tee -a $LOG_FILE
kubectl get envoyfilters --all-namespaces -o yaml > $BACKUP_DIR/envoyfilters.yaml

# AuthorizationPolicies
echo "Backing up AuthorizationPolicies..." | tee -a $LOG_FILE
kubectl get authorizationpolicies --all-namespaces -o yaml > $BACKUP_DIR/authorizationpolicies.yaml

# PeerAuthentications
echo "Backing up PeerAuthentications..." | tee -a $LOG_FILE
kubectl get peerauthentications --all-namespaces -o yaml > $BACKUP_DIR/peerauthentications.yaml

# RequestAuthentications
echo "Backing up RequestAuthentications..." | tee -a $LOG_FILE
kubectl get requestauthentications --all-namespaces -o yaml > $BACKUP_DIR/requestauthentications.yaml

# Sidecars
echo "Backing up Sidecars..." | tee -a $LOG_FILE
kubectl get sidecars --all-namespaces -o yaml > $BACKUP_DIR/sidecars.yaml

# Telemetry
echo "Backing up Telemetry..." | tee -a $LOG_FILE
kubectl get telemetry --all-namespaces -o yaml > $BACKUP_DIR/telemetry.yaml

# WorkloadEntries
echo "Backing up WorkloadEntries..." | tee -a $LOG_FILE
kubectl get workloadentries --all-namespaces -o yaml > $BACKUP_DIR/workloadentries.yaml

# WorkloadGroups
echo "Backing up WorkloadGroups..." | tee -a $LOG_FILE
kubectl get workloadgroups --all-namespaces -o yaml > $BACKUP_DIR/workloadgroups.yaml

# Backup Istio mesh config
echo "Backing up Istio mesh configuration..." | tee -a $LOG_FILE
$ISTIOCTL mesh config > $BACKUP_DIR/mesh-config.yaml 2>/dev/null

# Backup Istio installation profile
echo "Backing up Istio installation profile..." | tee -a $LOG_FILE
$ISTIOCTL profile dump > $BACKUP_DIR/istio-profile-dump.yaml 2>/dev/null

# Backup Istio proxy configurations and stats
if [ "$BACKUP_DETAILED" == "true" ]; then
  echo "Backing up detailed proxy configurations..." | tee -a $LOG_FILE
  mkdir -p $BACKUP_DIR/proxies
  
  # Get all pods with Istio sidecars
  ISTIO_PODS=$(kubectl get pods -A -l security.istio.io/tlsMode=istio -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
  
  for POD in $ISTIO_PODS; do
    NS=$(echo $POD | cut -d'/' -f1)
    POD_NAME=$(echo $POD | cut -d'/' -f2)
    echo "Backing up proxy config for $NS/$POD_NAME..." | tee -a $LOG_FILE
    
    # Capture proxy config
    $ISTIOCTL proxy-config all -n $NS $POD_NAME > $BACKUP_DIR/proxies/$NS-$POD_NAME-config.txt 2>/dev/null
  done
fi

echo "Istio configuration backup completed at $(date)" | tee -a $LOG_FILE
echo "Backup saved to: $BACKUP_DIR" | tee -a $LOG_FILE

# If script was called from main backup script, don't compress
if [ -z "$1" ]; then
  # Compress the backup
  echo "Compressing Istio backup..." | tee -a $LOG_FILE
  BACKUP_ARCHIVE="/backup/istio-config-$(date +%Y-%m-%d).tar.gz"
  tar -czf $BACKUP_ARCHIVE -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)
  echo "Compressed backup saved to: $BACKUP_ARCHIVE" | tee -a $LOG_FILE
fi 