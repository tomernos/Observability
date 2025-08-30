# GitOps Configuration for EKS Observability

This directory contains the GitOps configuration for managing the EKS observability stack using ArgoCD.

## Directory Structure

```
gitops/
├── apps/                           # Application configurations
│   └── karpenter/                  # Karpenter autoscaler
│       ├── base/                   # Base configuration
│       │   ├── kustomization.yaml  # Helm chart definition
│       │   └── nodepool.yaml       # Karpenter NodePool and EC2NodeClass
│       └── overlays/               # Environment-specific overlays
│           └── dev/                # Development environment
│               ├── kustomization.yaml
│               └── karpenter-values.yaml
├── clusters/                       # Cluster-specific configurations
│   └── eks-dev/                    # Development EKS cluster
│       ├── kustomization.yaml
│       └── karpenter-app.yaml      # ArgoCD Application definition
└── infrastructure/                 # Infrastructure components
    └── argocd/                     # ArgoCD configuration
        ├── kustomization.yaml
        └── repository-secret.yaml  # Git repository access secret
```

## Setup Instructions

### 1. Generate SSH Key for GitHub

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "argocd@eks-observability" -f ~/.ssh/argocd_observability

# Copy public key to add to GitHub
cat ~/.ssh/argocd_observability.pub
```

### 2. Add Deploy Key to GitHub

1. Go to your GitHub repository: https://github.com/Tomerkakou/Observability
2. Settings → Deploy keys
3. Click "Add deploy key"
4. Title: "ArgoCD GitOps Access"
5. Paste the public key content
6. Check "Allow write access" (if needed for ArgoCD to update status)
7. Click "Add key"

### 3. Update Repository Secret

```bash
# Copy private key content
cat ~/.ssh/argocd_observability

# Replace the placeholder in repository-secret.yaml with the private key
```

### 4. Update Cluster Endpoint

Get your EKS cluster endpoint and update the placeholder in:
- `gitops/apps/karpenter/base/kustomization.yaml`
- `gitops/apps/karpenter/overlays/dev/karpenter-values.yaml`

```bash
# Get cluster endpoint
aws eks describe-cluster --name tnt-eu-observability-dev-eks --query 'cluster.endpoint' --output text
```

### 5. Apply GitOps Configuration

```bash
# Apply repository secret first
kubectl apply -f gitops/infrastructure/argocd/

# Apply the Karpenter application
kubectl apply -f gitops/clusters/eks-dev/
```

## Components

### Karpenter Configuration
- **Base**: Contains the Helm chart definition and common NodePool configuration
- **Overlays**: Environment-specific customizations (dev, staging, prod)
- **NodePool**: Defines node provisioning rules for Karpenter

### ArgoCD Applications
- **karpenter-app.yaml**: Defines how ArgoCD should sync Karpenter configuration
- **repository-secret.yaml**: Provides ArgoCD access to the Git repository

## Customization

### Adding New Environments
1. Create new overlay directory under `apps/karpenter/overlays/`
2. Add environment-specific values
3. Create corresponding application in `clusters/`

### Adding New Applications
1. Create new directory under `apps/`
2. Follow the same base/overlays pattern
3. Add ArgoCD application definition in relevant cluster directory

## Monitoring

Check ArgoCD UI at http://localhost:8080 (when port-forwarded) to monitor:
- Application sync status
- Health status
- Deployment history
- Resource details
