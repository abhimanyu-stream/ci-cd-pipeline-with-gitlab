# Kubernetes RBAC Configuration

This directory contains Role-Based Access Control (RBAC) configurations for your Kubernetes cluster.

## Overview

RBAC is implemented using:
- **ClusterRoles** and **ClusterRoleBindings** for cluster-wide permissions
- **Roles** and **RoleBindings** for namespace-specific permissions
- **ServiceAccounts** for identity

## Roles Hierarchy

1. **Cluster Administrator**
   - Full access to all resources
   - Typically used for cluster management
   - ServiceAccount: `cluster-admin` in `kube-system` namespace

2. **DevOps**
   - Wide access to most resources but limited RBAC management
   - Used for automation, CI/CD pipelines, and cluster maintenance
   - ServiceAccount: `devops` in `kube-system` namespace

3. **Developer**
   - Environment-specific permissions:
     - **Dev**: Full access to workloads within namespace
     - **Staging**: Full access to workloads within namespace
     - **Prod**: Read-only access with limited abilities
   - ServiceAccount: `developer` in respective namespaces

4. **Read-Only**
   - Cluster-wide read-only access for monitoring and auditing
   - ServiceAccount: `readonly-user` in `kube-system` and `monitoring-user` in `monitoring` namespace

## Service Accounts & Tokens

To create a token for a service account:

```bash
# Create a token for a service account
kubectl create token <service-account-name> -n <namespace> --duration=8760h
```

## Usage with kubectl

Use the token with kubectl:

```bash
kubectl --token=<token> --server=<api-server-url> get pods

# Or set up a kubeconfig context
kubectl config set-credentials <user-name> --token=<token>
kubectl config set-context <context-name> --cluster=<cluster-name> --user=<user-name>
kubectl config use-context <context-name>
```

## RBAC Testing

Verify permissions:

```bash
# Test if a service account can do specific actions
kubectl auth can-i get pods --as=system:serviceaccount:<namespace>:<service-account> -n <namespace>
kubectl auth can-i create deployments --as=system:serviceaccount:<namespace>:<service-account> -n <namespace>
```

## Integration with External Authentication

For production environments, consider integrating with:
- OIDC providers (such as Google, Okta, Auth0)
- Active Directory or LDAP
- X.509 client certificates

## Recommended Workflows

1. **Cluster Admin**: Use for critical cluster changes and management
2. **DevOps**: Use for CI/CD pipelines and automation
3. **Developer**: Use for application development and debugging
4. **Read-Only**: Use for monitoring dashboards and audit tools 