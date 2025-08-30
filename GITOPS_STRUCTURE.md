# Karpenter GitOps Structure

## Repository Layout:
```
k8s-gitops/
├── apps/
│   └── karpenter/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── karpenter-app.yaml
│       │   └── karpenter-nodepool.yaml
│       └── overlays/
│           └── dev/
│               ├── kustomization.yaml
│               └── values.yaml
├── infrastructure/
│   └── argocd/
│       └── application-set.yaml
└── clusters/
    └── eks-dev/
        ├── kustomization.yaml
        └── app-of-apps.yaml
```

## Files to Create:

### 1. apps/karpenter/base/karpenter-app.yaml
### 2. apps/karpenter/base/karpenter-nodepool.yaml  
### 3. apps/karpenter/base/kustomization.yaml
### 4. clusters/eks-dev/app-of-apps.yaml
### 5. clusters/eks-dev/kustomization.yaml
