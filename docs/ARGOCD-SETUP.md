# ArgoCD Setup Guide - GitOps Deployment Platform

**Complete guide to deploying and configuring ArgoCD for automated application deployments.**

---

## 🎯 What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

**Key Benefits:**
- ✅ **Git as Single Source of Truth** - All configs in Git
- ✅ **Automated Deployments** - Git push → auto-deploy
- ✅ **Self-Healing** - Automatically fix drift
- ✅ **Rollback Capability** - Easy rollback to any version
- ✅ **Multi-Environment** - Dev, Staging, Prod from one repo
- ✅ **RBAC** - Control who can deploy what
- ✅ **Audit Trail** - Track all changes

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Developer Workflow                     │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   CI Pipeline (Jenkins)         │
        │   1. Build Docker image         │
        │   2. Push to ECR                │
        │   3. Update GitOps repo         │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   CompanyGitOps Repo            │
        │   (Git as Source of Truth)      │
        │   - K8s manifests               │
        │   - Helm values                 │
        │   - ArgoCD apps                 │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   ArgoCD (in EKS)               │
        │   - Monitors Git repo           │
        │   - Auto-syncs changes          │
        │   - Manages deployments         │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   EKS Cluster                   │
        │   - chatapp-dev namespace       │
        │   - chatapp-staging namespace   │
        │   - chatapp-prod namespace      │
        └─────────────────────────────────┘
```

---

## 🚀 Installation

### **Option 1: Automated Script** (Recommended)

```bash
cd /path/to/Observability
./scripts/deploy-argocd.sh
```

### **Option 2: Manual Installation**

```bash
# Add Argo CD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f infra-tf/helm/argocd/values.yaml \
  --wait \
  --timeout 10m

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=5m
```

---

## 🔑 Access ArgoCD UI

### **Step 1: Get Admin Password**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### **Step 2: Port-Forward**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### **Step 3: Login**

- Open: https://localhost:8080
- Username: `admin`
- Password: (from Step 1)

### **Step 4: Change Password (Recommended)**

```bash
# Install ArgoCD CLI first (if needed)
brew install argocd  # MacOS
# or
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login via CLI
argocd login localhost:8080

# Change password
argocd account update-password
```

---

## 📦 Configure ArgoCD Applications

### **Step 1: Apply Project**

```bash
cd /path/to/CompanyGitOps

# Apply ArgoCD Project (defines RBAC and allowed resources)
kubectl apply -f argocd/projects/chatapp-project.yaml
```

### **Step 2: Apply Applications**

```bash
# Apply all applications
kubectl apply -f argocd/applications/

# Or apply individually
kubectl apply -f argocd/applications/chatapp-dev.yaml
kubectl apply -f argocd/applications/chatapp-staging.yaml
kubectl apply -f argocd/applications/chatapp-prod.yaml
```

### **Step 3: Verify**

```bash
# Check applications
kubectl get applications -n argocd

# Expected output:
# NAME              SYNC STATUS   HEALTH STATUS
# chatapp-dev       Synced        Healthy
# chatapp-staging   Synced        Healthy
# chatapp-prod      OutOfSync     Healthy
```

---

## 🔄 Workflow: How It Works

### **1. Development Flow**

```bash
# Developer makes changes
cd ChatApplication
git checkout develop
# ... make changes ...
git commit -m "Add new feature"
git push origin develop
```

### **2. CI Pipeline**

```groovy
// Jenkins automatically:
1. Builds Docker image
2. Pushes to ECR: chatapp-backend:dev-abc123
3. Updates CompanyGitOps repo:
   - applications/chatapp/dev/backend-deployment.yaml
   - Changes image: tag to dev-abc123
4. Commits and pushes to GitOps repo
```

### **3. ArgoCD Detects Change**

```
ArgoCD polls Git repo every 3 minutes
    ↓
Detects new commit in CompanyGitOps
    ↓
Compares Git state vs Cluster state
    ↓
Finds difference in image tag
    ↓
[Dev] Auto-syncs immediately
[Staging] Auto-syncs immediately
[Prod] Shows "OutOfSync" - requires manual approval
```

### **4. Manual Sync for Production**

```bash
# Option 1: Via CLI
argocd app sync chatapp-prod

# Option 2: Via UI
# 1. Open ArgoCD UI
# 2. Click "chatapp-prod"
# 3. Click "Sync" button
# 4. Review changes (shows diff)
# 5. Click "Synchronize"
```

---

## 🎯 Environment Strategies

| Environment | Auto-Sync | Self-Heal | Prune | Use Case |
|-------------|-----------|-----------|-------|----------|
| **Dev** | ✅ Yes | ✅ Yes | ✅ Yes | Rapid iteration |
| **Staging** | ✅ Yes | ✅ Yes | ✅ Yes | Pre-prod testing |
| **Prod** | ❌ Manual | ❌ No | ❌ No | Safety first |

### **Dev Environment:**
- **Purpose:** Fast feedback loop for developers
- **Auto-sync:** Changes deploy within 3 minutes
- **Self-heal:** If someone `kubectl edit`, ArgoCD reverts to Git
- **Prune:** Deleted resources in Git = deleted in cluster

### **Staging Environment:**
- **Purpose:** Pre-production testing
- **Auto-sync:** Test integration before prod
- **Self-heal:** Ensure consistent state
- **Prune:** Clean up unused resources

### **Production Environment:**
- **Purpose:** Live customer-facing environment
- **Manual sync:** Explicit approval required
- **No self-heal:** Investigate issues manually
- **No prune:** Safety - prevent accidental deletions

---

## 🛠️ Common Operations

### **View Application Status**

```bash
# List all applications
kubectl get applications -n argocd

# Detailed status
argocd app get chatapp-dev

# Continuous watch
watch argocd app get chatapp-dev
```

### **Manual Sync**

```bash
# Sync application
argocd app sync chatapp-prod

# Sync and wait for completion
argocd app sync chatapp-prod --wait

# Dry-run (preview changes)
argocd app sync chatapp-prod --dry-run
```

### **Diff Before Sync**

```bash
# See what will change
argocd app diff chatapp-prod

# Shows:
# + Added resources
# - Deleted resources
# ~ Modified resources
```

### **Rollback**

```bash
# View deployment history
argocd app history chatapp-prod

# Example output:
# ID  DATE                  REVISION
# 5   2026-01-17 10:30:00   abc123 (HEAD)
# 4   2026-01-17 09:15:00   def456
# 3   2026-01-17 08:00:00   ghi789

# Rollback to previous version
argocd app rollback chatapp-prod 4

# Verify rollback
argocd app get chatapp-prod
```

### **Refresh & Hard Refresh**

```bash
# Normal refresh (re-check Git)
argocd app get chatapp-dev --refresh

# Hard refresh (force re-compare)
argocd app get chatapp-dev --hard-refresh
```

---

## 📊 Monitoring & Observability

### **Prometheus Metrics**

ArgoCD exports metrics to Prometheus (already configured):

```yaml
# Key metrics:
argocd_app_info - Application metadata
argocd_app_sync_total - Sync operation counts
argocd_app_sync_status - Current sync status
argocd_app_health_status - Application health
```

### **Grafana Dashboards**

Import official ArgoCD dashboards:

```bash
# Dashboard IDs:
14584 - ArgoCD Operational Dashboard
19993 - ArgoCD Application Metrics
```

### **Slack Notifications**

Configure in `infra-tf/helm/argocd/values.yaml`:

```yaml
notifications:
  notifiers:
    service.slack: |
      token: $slack-token
```

---

## 🔐 Security Best Practices

### **1. Rotate Admin Password**

```bash
argocd account update-password
```

### **2. Enable SSO (Production)**

```yaml
# In argocd values.yaml
configs:
  cm:
    dex.config: |
      connectors:
      - type: github
        id: github
        name: GitHub
```

### **3. Use RBAC**

Already configured in `argocd/projects/chatapp-project.yaml`:
- **Dev team:** Can sync dev only
- **Ops team:** Can sync all environments
- **Viewers:** Read-only

### **4. Audit Logging**

```bash
# View ArgoCD audit logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server | grep audit
```

---

## 🚨 Troubleshooting

### **Application Not Syncing**

```bash
# Check application status
argocd app get chatapp-dev

# Check repo access
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server

# Force refresh
argocd app get chatapp-dev --refresh
```

### **Sync Failed**

```bash
# View sync errors
argocd app get chatapp-dev

# Check application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Validate manifests locally
kubectl apply --dry-run=client -f /path/to/CompanyGitOps/applications/chatapp/dev/
```

### **Application Stuck Progressing**

```bash
# Check resource health
kubectl get pods -n chatapp-dev

# Describe application
kubectl describe application chatapp-dev -n argocd

# Check events
kubectl get events -n chatapp-dev --sort-by='.lastTimestamp'
```

---

## 📚 Staff-Level Best Practices

### **Why This is Staff-Level:**

1. ✅ **Separation of Concerns**
   - Infrastructure repo (Observability)
   - GitOps repo (CompanyGitOps)
   - Application repos (ChatApplication)

2. ✅ **Progressive Delivery**
   - Dev (auto) → Staging (auto) → Prod (manual)
   - Safety gates at each stage

3. ✅ **Git as Source of Truth**
   - All changes tracked
   - Easy rollback
   - Audit trail

4. ✅ **Self-Healing**
   - Cluster drift automatically corrected
   - No configuration drift

5. ✅ **RBAC & Security**
   - Least privilege access
   - Prod requires approval

6. ✅ **Observability**
   - Metrics to Prometheus
   - Notifications to Slack
   - Audit logs

---

## 📖 Related Documentation

- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [CompanyGitOps README](../../CompanyGitOps/README.md)
- [ArgoCD Apps README](../../CompanyGitOps/argocd/README.md)
- [GitOps Best Practices](https://www.weave.works/technologies/gitops/)

---

## ✅ Success Criteria

- [x] ArgoCD installed and accessible
- [x] Admin password changed
- [x] Project created with RBAC
- [x] Applications deployed
- [ ] Dev auto-syncing
- [ ] Staging auto-syncing
- [ ] Prod manual sync working
- [ ] Metrics flowing to Prometheus
- [ ] Notifications to Slack (optional)
- [ ] Team trained



