# GitOps Configuration

This directory contains GitOps configurations for managing the Kubernetes infrastructure using ArgoCD.

## Structure

- `applications/` - ArgoCD Application resources
- `projects/` - ArgoCD Project resources for organizing applications
- `config/` - General ArgoCD configuration

## Usage

These manifests define how ArgoCD deploys and manages our various Kubernetes components including:

- Backup system
- Monitoring stack
- Infrastructure components
- Application deployments

All changes to the infrastructure should be made through git commits to maintain a complete audit trail and ensure consistency between the git repository and the deployed state. 