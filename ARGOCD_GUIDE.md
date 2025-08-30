# ArgoCD Learning Guide

## What is ArgoCD?
ArgoCD is a **GitOps** continuous delivery tool for Kubernetes. It:
- Monitors Git repositories for application definitions
- Automatically deploys applications to Kubernetes clusters
- Ensures your cluster state matches what's defined in Git
- Provides a web UI to visualize and manage deployments

## Key Concepts

### 1. Applications
An **Application** in ArgoCD represents a set of Kubernetes resources that should be deployed together.

### 2. Projects  
**Projects** group applications and define policies (RBAC, allowed repos, clusters).

### 3. Repositories
**Repositories** are Git repos containing your application manifests or Helm charts.

### 4. Sync Policies
**Sync Policies** define how ArgoCD should handle deployment:
- **Manual**: You manually trigger deployments
- **Automated**: ArgoCD automatically deploys when changes are detected

## What We Just Set Up

### Step 1: Infrastructure Changes
- **Replaced** direct Karpenter Helm installation with ArgoCD
- **Added** ArgoCD Helm chart configuration in `main.auto.tfvars`
- **Created** namespace definitions for argocd, mysql, exam-app

### Step 2: ArgoCD Installation
- ArgoCD will be installed in `argocd` namespace
- Configured with LoadBalancer service for external access
- Insecure mode enabled for easier learning (change for production!)

### Step 3: Karpenter as ArgoCD Application
- Created `argocd-apps/karpenter-app.yaml` - this defines Karpenter as an ArgoCD application
- ArgoCD will deploy Karpenter instead of Terraform doing it directly

## Next Steps to Complete Setup

### 1. Apply Terraform Changes
```bash
cd infra-tf
terraform apply
```

### 2. Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Access ArgoCD Web UI
```bash
# Get LoadBalancer URL
kubectl get svc -n argocd argocd-server

# Or port-forward for local access
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Then visit: http://localhost:8080
# Username: admin
# Password: from step 2
```

### 4. Create Karpenter Application in ArgoCD
```bash
kubectl apply -f argocd-apps/karpenter-app.yaml
```

### 5. Update Karpenter App Values
Edit `argocd-apps/karpenter-app.yaml` and replace:
- `REPLACE_WITH_CLUSTER_ENDPOINT` with your EKS cluster endpoint
- `REPLACE_WITH_QUEUE_NAME` with your SQS queue name  
- `REPLACE_WITH_INSTANCE_PROFILE` with your instance profile name

## Benefits of This Approach

### GitOps Workflow
1. **Code Change**: Update application manifests in Git
2. **Auto Detection**: ArgoCD detects changes
3. **Sync**: ArgoCD applies changes to cluster
4. **Validation**: ArgoCD ensures cluster matches Git state

### Observability
- Web UI shows deployment status
- Diff view shows what changed
- Rollback capabilities
- Event logs and history

### Security
- Centralized RBAC
- Audit trail of all changes
- No direct cluster access needed

## Common ArgoCD Operations

### View Applications
```bash
# CLI
argocd app list

# Or use the Web UI
```

### Sync Application
```bash
# CLI
argocd app sync karpenter

# Or click "Sync" in Web UI
```

### Check Application Health
```bash
# CLI  
argocd app get karpenter

# Or view in Web UI dashboard
```

This setup transforms your infrastructure from "push" (Terraform directly installs) to "pull" (ArgoCD pulls from Git and installs), which is the core of GitOps!
