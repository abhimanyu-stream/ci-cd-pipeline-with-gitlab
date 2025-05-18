# Kubernetes Backup and Disaster Recovery

This directory contains configurations and procedures for Kubernetes cluster backup and disaster recovery.

## Directory Structure

```
backup/
├── configs/            # Backup configuration and CronJob definitions
├── procedures/         # Step-by-step recovery procedures
└── scripts/            # Backup scripts
```

## Overview

The backup solution implements the following components:

1. **Regular automated backups** of all Kubernetes resources (deployments, configmaps, secrets, etc.)
2. **ETCD snapshot backups** for complete cluster recovery
3. **Scheduled CronJobs** for consistent backup execution
4. **Retention policies** to manage backup storage

## Backup Schedule

| Component | Frequency | Retention |
|-----------|-----------|-----------|
| K8s Resources | Daily at 1:00 AM | 7 days |
| ETCD Snapshots | Daily at 2:00 AM | 7 days |
| PV Data | Weekly (Sunday at 1:00 AM) | 4 weeks |

## Setup Instructions

### Prerequisites

- Kubernetes cluster with admin access
- Storage provisioner that supports ReadWriteMany access mode
- `kubectl` with cluster admin privileges

### Deployment Steps

1. Create the backup storage:

```bash
# Adjust the storage class as needed for your environment
kubectl apply -f configs/backup-storage.yaml
```

2. Deploy the backup CronJob:

```bash
kubectl apply -f configs/backup-cronjob.yaml
```

3. Verify the installation:

```bash
kubectl get cronjobs -n kube-system
kubectl get pvc -n kube-system
```

## Manual Backup

In addition to scheduled backups, you can trigger a manual backup:

```bash
kubectl create job --from=cronjob/k8s-backup manual-backup-$(date +%Y%m%d) -n kube-system
```

## Recovery Procedure

Detailed recovery procedures are provided in the [procedures directory](procedures/):

- [Full Cluster Recovery](procedures/restore-procedure.md) - For catastrophic failures
- [Individual Resource Recovery](procedures/resource-recovery.md) - For recovering specific resources

## Disaster Recovery Testing

It is strongly recommended to conduct disaster recovery testing at least quarterly:

1. Set up a test cluster environment
2. Restore backups to the test environment
3. Verify application functionality
4. Document any issues and improve the recovery procedures

## Security Considerations

- Backup files contain sensitive information including secrets
- Access to backup storage should be strictly limited
- Consider encrypting backups at rest
- The backup service account has read access to all cluster resources

## Monitoring

The backup system includes monitoring through:

1. Logs sent to the centralized logging system
2. CronJob success/failure metrics in Prometheus
3. Alerts configured for backup failures

## Limitations

- StatefulSet PV data requires application-specific backup procedures
- Some cloud provider resources may require additional backup steps
- Custom resources might need specialized handling

## Troubleshooting

- **Backup job fails**: Check pod logs with `kubectl logs job/k8s-backup-<id> -n kube-system`
- **Storage issues**: Verify PVC binding with `kubectl get pvc -n kube-system`
- **Restore issues**: Follow the step-by-step guide and check for errors after each step 