# GitOps Workflow - Complete Guide

**How CI/CD + ArgoCD work together for automated deployments.**

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. Developer pushes code                                    │
│     → ChatApplication repo (develop/staging/main branch)    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  2. CI Pipeline (Jenkins)                                   │
│     → Build Docker images                                   │
│     → Push to ECR                                           │
│     → Update image tags in CompanyGitOps repo              │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  3. CompanyGitOps Repository (Git as Source of Truth)      │
│     → Helm chart + values per environment                  │
│     → deployment.yaml (version tracking)                   │
│     → ArgoCD Applications                                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  4. ArgoCD (Running in EKS - Deployed via Terraform)       │
│     → Polls Git repo every 3 minutes                       │
│     → Detects changes                                       │
│     → Auto-syncs dev/staging (within 3 min)               │
│     → Shows "OutOfSync" for prod (manual approval)        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  5. EKS Cluster                                            │
│     → chatapp-dev namespace (auto-deployed)                │
│     → chatapp-staging namespace (auto-deployed)            │
│     → chatapp-prod namespace (requires manual sync)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Initial Setup (One-Time)

### **Step 1: Deploy Infrastructure (ArgoCD)**

ArgoCD is **already deployed** via Terraform:

```bash
cd Observability/infra-tf

# ArgoCD is included in helm releases
terraform apply

# Verify ArgoCD is running
kubectl get pods -n argocd
```

**Configuration:**
- Defined in: `infra-tf/main.auto.tfvars` (line 163)
- Values: `infra-tf/helm/argocd/values.yaml`
- Namespace: `argocd`

### **Step 2: Access ArgoCD UI**

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080
# Login: admin / <password from above>
```

### **Step 3: Apply ArgoCD Project & Applications**

```bash
cd CompanyGitOps

# Apply Project (defines RBAC and allowed resources)
kubectl apply -f argocd/projects/chatapp-project.yaml

# Apply Applications (one per environment)
kubectl apply -f argocd/applications/chatapp-dev.yaml
kubectl apply -f argocd/applications/chatapp-staging.yaml
kubectl apply -f argocd/applications/chatapp-prod.yaml

# Verify
kubectl get applications -n argocd
```

Expected output:
```
NAME              SYNC STATUS   HEALTH STATUS
chatapp-dev       Synced        Healthy
chatapp-staging   Synced        Healthy
chatapp-prod      OutOfSync     Healthy
```

---

## 🔄 Daily Workflow

### **Developer Workflow:**

```bash
# 1. Developer makes changes
cd ChatApplication
git checkout develop
# ... make code changes ...
git add .
git commit -m "Add new feature"
git push origin develop
```

### **CI Pipeline (Automatic):**

```bash
# 2. Jenkins CI runs automatically on push
# - Builds images: chatapp-backend:dev-abc123, chatapp-frontend:dev-abc123
# - Pushes to ECR
# - Updates CompanyGitOps/applications/chatapp/dev/deployment.yaml
# - Commits change: "CI: Update dev to abc123"
```

### **ArgoCD (Automatic):**

```bash
# 3. ArgoCD detects change (within 3 minutes)
# - Dev: Auto-syncs immediately ✅
# - Staging: Auto-syncs immediately ✅
# - Prod: Shows "OutOfSync" ⏸️ (requires manual approval)
```

### **CD Pipeline (For Manual Verification):**

The CD pipeline now **does NOT deploy directly**. Instead:

```bash
# 4. Optional: Run CD pipeline to verify GitOps update
# Jenkins → Jenkinsfile.cd
# - Reads deployment.yaml from GitOps repo
# - Verifies image tags updated
# - Confirms ArgoCD application status
# - Displays sync instructions
```

---

## 🎯 Deployment Per Environment

### **Dev Environment (Auto-Deploy)**

```
CI updates GitOps repo
    ↓ (within 3 min)
ArgoCD auto-syncs
    ↓
Pods restart with new image
    ↓
Ready for testing
```

**Configuration:**
- File: `CompanyGitOps/argocd/applications/chatapp-dev.yaml`
- Sync: Automatic
- Self-Heal: Yes (reverts manual changes)
- Prune: Yes (deletes removed resources)

### **Staging Environment (Auto-Deploy)**

```
CI builds staging image
    ↓
Updates GitOps repo
    ↓ (within 3 min)
ArgoCD auto-syncs
    ↓
Pre-production testing
```

**Configuration:**
- File: `CompanyGitOps/argocd/applications/chatapp-staging.yaml`
- Sync: Automatic
- Self-Heal: Yes
- Prune: Yes

### **Production Environment (Manual Approval)**

```
CI builds prod image
    ↓
Updates GitOps repo
    ↓
ArgoCD shows "OutOfSync"
    ↓
Manual review & approval required
    ↓
Sync via UI or CLI
    ↓
Production deployment
```

**Configuration:**
- File: `CompanyGitOps/argocd/applications/chatapp-prod.yaml`
- Sync: **Manual** (no auto-sync)
- Self-Heal: No (manual investigation)
- Prune: No (safety first)

**To deploy to prod:**

```bash
# Option 1: ArgoCD CLI
argocd app sync chatapp-prod

# Option 2: ArgoCD UI
# 1. Open https://localhost:8080
# 2. Click "chatapp-prod"
# 3. Click "Sync" button
# 4. Review changes
# 5. Click "Synchronize"
```

---

## 📊 Monitoring Deployments

### **Check ArgoCD Application Status**

```bash
# List all applications
kubectl get applications -n argocd

# Detailed status
kubectl describe application chatapp-dev -n argocd

# Watch sync progress
watch kubectl get applications -n argocd
```

### **Check Deployment Status**

```bash
# Check pods
kubectl get pods -n chatapp-dev

# Check deployment rollout
kubectl rollout status deployment/chatapp-backend -n chatapp-dev

# View recent events
kubectl get events -n chatapp-dev --sort-by='.lastTimestamp'
```

### **View ArgoCD Logs**

```bash
# ArgoCD application controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# ArgoCD server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# ArgoCD repo server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

---

## 🔧 Troubleshooting

### **ArgoCD Not Syncing**

```bash
# Force refresh
kubectl patch application chatapp-dev -n argocd \
  --type merge -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}'

# Check application details
kubectl get application chatapp-dev -n argocd -o yaml
```

### **Application Stuck "Progressing"**

```bash
# Check pod status
kubectl get pods -n chatapp-dev

# Describe failing pods
kubectl describe pod -n chatapp-dev -l app=backend

# Check events
kubectl get events -n chatapp-dev --sort-by='.lastTimestamp' | tail -20
```

### **Manual Rollback**

```bash
# Via ArgoCD (rollback to previous version)
argocd app history chatapp-dev
argocd app rollback chatapp-dev <HISTORY_ID>

# Via kubectl (emergency)
kubectl rollout undo deployment/chatapp-backend -n chatapp-dev
```

---

## 🎓 Best Practices

### **✅ DO:**

1. **Let ArgoCD handle deployments** - Don't use `kubectl apply` directly
2. **Update GitOps repo via CI** - Single source of truth
3. **Test in dev first** - Auto-sync helps catch issues early
4. **Review staging before prod** - Staging is pre-production
5. **Use manual approval for prod** - Safety gate
6. **Monitor ArgoCD UI** - Visual feedback on sync status
7. **Check Grafana dashboards** - Metrics, traces, logs

### **❌ DON'T:**

1. ❌ Don't `kubectl apply` directly to cluster (bypasses GitOps)
2. ❌ Don't edit pods manually (ArgoCD will revert)
3. ❌ Don't force-sync prod without review
4. ❌ Don't commit secrets to GitOps repo
5. ❌ Don't skip testing in lower environments
6. ❌ Don't disable self-heal in dev/staging

---

## 📚 File Locations

### **Infrastructure (Observability Repo)**
```
Observability/
├── infra-tf/
│   ├── main.auto.tfvars          # ArgoCD Helm release config
│   └── helm/argocd/
│       └── values.yaml            # ArgoCD Helm values
└── docs/
    └── GITOPS-WORKFLOW.md         # This file
```

### **GitOps (CompanyGitOps Repo)**
```
CompanyGitOps/
├── argocd/
│   ├── projects/
│   │   └── chatapp-project.yaml   # ArgoCD Project (RBAC)
│   └── applications/
│       ├── chatapp-dev.yaml       # Dev application
│       ├── chatapp-staging.yaml   # Staging application
│       └── chatapp-prod.yaml      # Prod application
│
└── applications/chatapp/
    ├── helm-chart/                # Helm chart (from ChatApplication)
    ├── dev/
    │   ├── values.yaml            # Dev Helm values
    │   └── deployment.yaml        # Version tracking (CI updates)
    ├── staging/
    │   ├── values.yaml
    │   └── deployment.yaml
    └── prod/
        ├── values.yaml
        └── deployment.yaml
```

### **Application (ChatApplication Repo)**
```
ChatApplication/
├── Jenkins/gitops/
│   ├── Jenkinsfile.ci            # CI: Build & push to GitOps
│   └── Jenkinsfile.cd            # CD: Verify ArgoCD status (no direct deploy)
└── helm-chart/                   # Source Helm chart (copied to GitOps)
```

---

## 🔗 Related Documentation

- [ArgoCD Setup Guide](./ARGOCD-SETUP.md)
- [CompanyGitOps README](../../CompanyGitOps/README.md)
- [ChatApp GitOps Config](../../CompanyGitOps/applications/chatapp/README.md)
- [CI/CD Pipeline Docs](../../ChatApplication/docs/jenkins/)

---

## ✅ Success Criteria

- [x] ArgoCD deployed via Terraform
- [x] ArgoCD Project applied
- [x] ArgoCD Applications applied (dev/staging/prod)
- [ ] Dev auto-syncing within 3 minutes
- [ ] Staging auto-syncing within 3 minutes
- [ ] Prod showing "OutOfSync" (manual sync working)
- [ ] CI pipeline updating GitOps repo
- [ ] CD pipeline showing ArgoCD status (not deploying directly)
- [ ] Metrics flowing to Grafana
- [ ] Team trained on GitOps workflow



