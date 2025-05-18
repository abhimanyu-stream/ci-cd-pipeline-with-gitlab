# Backup Helm Chart

This Helm chart deploys a Kubernetes backup solution with Vault integration for secure credential management.

## Features

- Regular scheduled backups of all Kubernetes resources
- Integration with HashiCorp Vault for secure credential storage
- Support for S3 remote backup storage
- Backup encryption with custom keys
- Istio configuration backups
- Configurable retention policies

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- For Vault integration: Vault server with Kubernetes auth configured
- For S3 storage: AWS credentials with S3 access

## Installing the Chart

First, create a `values.yaml` file with your custom configuration:

```yaml
backup:
  schedule: "0 1 * * *"  # Daily at 1 AM
  useS3Storage: true
  storage:
    size: 20Gi  # Adjust based on your cluster size

vault:
  enabled: true
  role: "backup-role"
  secrets:
    aws: "secret/data/aws/s3-backup"
    config: "secret/data/backup/config"
```

Then install the chart:

```bash
helm install k8s-backup ./backup -n kube-system -f values.yaml
```

## Configuration

The following table lists the configurable parameters of the backup chart:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backup.schedule` | Cron schedule for the backup job | `"0 1 * * *"` |
| `backup.successfulJobsHistoryLimit` | Number of successful jobs to keep | `3` |
| `backup.failedJobsHistoryLimit` | Number of failed jobs to keep | `1` |
| `backup.useS3Storage` | Whether to use S3 storage | `true` |
| `backup.storage.size` | Size of the backup PVC | `10Gi` |
| `backup.storage.storageClassName` | Storage class for the backup PVC | `standard` |
| `backup.image.repository` | Backup container image repository | `bitnami/kubectl` |
| `backup.image.tag` | Backup container image tag | `latest` |
| `vault.enabled` | Whether to enable Vault integration | `true` |
| `vault.role` | Vault role for authentication | `"backup-role"` |
| `istio.enabled` | Whether to backup Istio configurations | `true` |
| `istio.backupDetailed` | Whether to include detailed Istio proxy configs | `false` |

## Vault Integration

The chart expects the following secrets in Vault:

1. AWS credentials for S3 storage (format):
   ```json
   {
     "access_key": "AWS_ACCESS_KEY",
     "secret_key": "AWS_SECRET_KEY",
     "region": "us-east-1",
     "bucket": "my-backup-bucket"
   }
   ```

2. Backup configuration (format):
   ```json
   {
     "retention_days": "7",
     "encryption_key": "backup-encryption-key"
   }
   ```

## Upgrading

To upgrade the chart:

```bash
helm upgrade k8s-backup ./backup -n kube-system -f values.yaml
```

## Uninstalling the Chart

To uninstall/delete the `k8s-backup` deployment:

```bash
helm delete k8s-backup -n kube-system
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

**Note:** The PersistentVolumeClaim isn't automatically deleted. To delete it:

```bash
kubectl delete pvc backup-pvc -n kube-system
``` 