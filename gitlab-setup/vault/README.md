# Vault Secret Management

This directory contains configurations for Vault integration with our Kubernetes infrastructure for secure secrets management.

## Structure

- `configs/` - Vault server and agent configurations
- `policies/` - Access control policies for different applications
- `scripts/` - Utility scripts for interacting with Vault
- `kubernetes/` - Kubernetes integration configurations
- `examples/` - Example usage patterns

## Setup Steps

### 1. Install Vault

```bash
# Using Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --namespace vault --create-namespace -f configs/vault-values.yaml
```

### 2. Initialize and Unseal Vault

```bash
# Initialize Vault (creates unseal keys and root token)
kubectl exec -n vault vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-init.json

# Unseal Vault (must be done after every restart)
VAULT_UNSEAL_KEY1=$(cat vault-init.json | jq -r ".unseal_keys_b64[0]")
VAULT_UNSEAL_KEY2=$(cat vault-init.json | jq -r ".unseal_keys_b64[1]")
VAULT_UNSEAL_KEY3=$(cat vault-init.json | jq -r ".unseal_keys_b64[2]")

kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY1
kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY2
kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY3
```

### 3. Configure Kubernetes Authentication

```bash
# Login to Vault
VAULT_ROOT_TOKEN=$(cat vault-init.json | jq -r ".root_token")
kubectl exec -n vault vault-0 -- vault login $VAULT_ROOT_TOKEN

# Enable Kubernetes auth
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

# Configure Kubernetes auth
kubectl exec -n vault vault-0 -- /bin/sh -c 'vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)" \
  issuer="https://kubernetes.default.svc.cluster.local"'
```

### 4. Enable Secrets Engines

```bash
# Enable KV secrets engine
kubectl exec -n vault vault-0 -- vault secrets enable -path=secret kv-v2

# Enable database secrets engine
kubectl exec -n vault vault-0 -- vault secrets enable database

# Enable PKI secrets engine for certificates
kubectl exec -n vault vault-0 -- vault secrets enable pki
kubectl exec -n vault vault-0 -- vault secrets tune -max-lease-ttl=8760h pki
```

## Using Vault with Applications

### Storing Application Secrets

```bash
# Create a secret for a Spring Boot application
kubectl exec -n vault vault-0 -- vault kv put secret/apps/spring-demo \
  db_username="appuser" \
  db_password="securepassword" \
  api_key="api-key-value" \
  jwt_secret="jwt-secret-value"
```

### Creating Access Policies

```bash
# Create a policy for the Spring Boot application
kubectl exec -n vault vault-0 -- vault policy write spring-app - <<EOF
path "secret/data/apps/spring-demo" {
  capabilities = ["read"]
}
EOF

# Create a Kubernetes auth role for the application
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/spring-app \
  bound_service_account_names=spring-app \
  bound_service_account_namespaces=apps \
  policies=spring-app \
  ttl=1h
```

### Accessing Secrets from Kubernetes

You can access secrets in several ways:

1. **Vault Agent Injector** - Injects secrets as files or environment variables
2. **Vault CSI Provider** - Mounts secrets as volumes
3. **External Secrets Operator** - Syncs secrets to Kubernetes Secrets

Example using Vault Agent Injector:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-app
  namespace: apps
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/apps/spring-demo"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/apps/spring-demo" -}}
          export DB_USERNAME="{{ .Data.data.db_username }}"
          export DB_PASSWORD="{{ .Data.data.db_password }}"
          export API_KEY="{{ .Data.data.api_key }}"
          export JWT_SECRET="{{ .Data.data.jwt_secret }}"
          {{- end -}}
        vault.hashicorp.com/role: "spring-app"
    spec:
      serviceAccountName: spring-app
      containers:
        - name: app
          image: spring-app:latest
```

## Security Best Practices

1. **Least Privilege** - Grant only the permissions needed
2. **Short TTLs** - Use short TTLs for tokens and roles
3. **Automated Rotation** - Set up automated rotation for credentials
4. **Audit Logging** - Enable audit logging for all access
5. **High Availability** - Deploy Vault in HA mode for production

## Backup and Recovery

Vault data should be backed up regularly. Use the backup scripts in the `scripts/` directory:

```bash
# Run Vault backup
./scripts/backup-vault.sh
```

## Troubleshooting

- **Vault Sealed** - After a restart, Vault needs to be unsealed with unseal keys
- **Authentication Failed** - Check service account permissions and role bindings
- **Secret Not Found** - Verify path and policy permissions

## Features

- Centralized secrets management
- Dynamic credentials generation
- Automatic secret rotation
- Audit logging for all secret access

## Integration Points

Vault is integrated with:
- Backup systems (replacing hardcoded credentials)
- Monitoring stack
- Database access credentials
- Application secrets

## Security Considerations

- All Vault access uses TLS
- Authentication is performed using Kubernetes service accounts
- Policies follow the principle of least privilege
- Regular audit of access patterns 