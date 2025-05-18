# CI/CD Pipeline Configurations

This directory contains configurations for GitLab CI/CD pipelines used in the project.

## Structure

- **templates/** - Reusable GitLab CI/CD templates
- **examples/** - Example pipelines for different application types
- **scripts/** - Helper scripts used in pipeline jobs
- **docker/** - Dockerfile for CI runner images

## Getting Started

To use these CI/CD pipelines in your projects:

1. Copy the appropriate template to your project repository
2. Customize the variables and stages as needed
3. Commit and push to trigger the pipeline

## Pipeline Templates

The following templates are available:

- **java-maven.yml** - For Java/Maven projects
- **nodejs.yml** - For Node.js projects
- **python.yml** - For Python projects
- **docker-build.yml** - For Docker image build and push
- **helm-deploy.yml** - For Helm chart deployment

## Environment Setup

The pipelines require the following environment variables to be set in GitLab:

- **DOCKER_REGISTRY** - Docker registry URL
- **DOCKER_USERNAME** - Docker registry username
- **DOCKER_PASSWORD** - Docker registry password
- **KUBE_CONFIG** - Base64 encoded kubeconfig file
- **HELM_REPO_URL** - Helm chart repository URL
- **HELM_REPO_USERNAME** - Helm repository username
- **HELM_REPO_PASSWORD** - Helm repository password

## Security Considerations

- Secrets are stored in GitLab CI/CD variables (protected and masked)
- Pipeline jobs use dedicated service accounts with limited permissions
- Docker images are scanned for vulnerabilities with Trivy
- Helm charts are linted before deployment

## Integration with GitOps

These pipelines can be integrated with our GitOps workflow:

1. CI pipeline builds and tests the application
2. Pipeline updates the Helm chart values in the GitOps repository
3. ArgoCD detects the changes and applies them to the cluster 