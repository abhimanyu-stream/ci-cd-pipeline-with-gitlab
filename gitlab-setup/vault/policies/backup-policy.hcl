# Backup System Policy
# Allows the backup system to read specific secrets needed for operation

# Allow reading backup-specific secrets
path "secret/data/backup/*" {
  capabilities = ["read", "list"]
}

# Allow reading AWS credentials for S3 backup storage
path "secret/data/aws/s3-backup" {
  capabilities = ["read"]
}

# Allow retrieving database credentials for backup operations
path "secret/data/databases/backup-user" {
  capabilities = ["read"]
}

# Allow the backup system to create and update its own dynamic secrets
path "secret/data/generated/backup/*" {
  capabilities = ["create", "update", "read", "delete"]
}

# Deny access to all other paths
path "secret/*" {
  capabilities = ["deny"]
}

# Allow reading own entity and identity information
path "identity/entity/id/{{identity.entity.id}}" {
  capabilities = ["read"]
} 