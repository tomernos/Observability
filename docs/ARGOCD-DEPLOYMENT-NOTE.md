# ArgoCD Deployment - Terraform Managed

**ArgoCD is deployed via Terraform - no manual scripts needed.**

---

## ✅ Already Deployed

ArgoCD is automatically deployed when you run `terraform apply` in `infra-tf/`.

**Configuration Files:**
- **Terraform Config:** `infra-tf/main.auto.tfvars` (line 163)
- **Helm Values:** `infra-tf/helm/argocd/values.yaml`
- **Base Values:** `infra-tf/values/base.yaml`

---

## 📋 Applying ArgoCD Applications (One-Time)

After ArgoCD is deployed via Terraform, apply the ArgoCD Project and Applications:

```bash
cd CompanyGitOps

# 1. Apply Project (RBAC and allowed resources)
kubectl apply -f argocd/projects/chatapp-project.yaml

# 2. Apply Applications (per environment)
kubectl apply -f argocd/applications/chatapp-dev.yaml
kubectl apply -f argocd/applications/chatapp-staging.yaml
kubectl apply -f argocd/applications/chatapp-prod.yaml

# 3. Verify
kubectl get applications -n argocd
```

---

## 🔑 Access ArgoCD UI

```bash
# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080
# Login: admin / <password>
```

---

## 📚 Documentation

- **Complete GitOps Workflow:** [GITOPS-WORKFLOW.md](./GITOPS-WORKFLOW.md)
- **ArgoCD Setup Details:** [ARGOCD-SETUP.md](./ARGOCD-SETUP.md)
- **CompanyGitOps README:** [../../CompanyGitOps/README.md](../../CompanyGitOps/README.md)

---

## ⚠️ Note: No Scripts

**We don't use deployment scripts.** Everything is managed via:
1. **Infrastructure:** Terraform (`terraform apply`)
2. **Applications:** ArgoCD (GitOps)
3. **CI/CD:** Jenkins pipelines

This is the **best practice approach** for production systems.

