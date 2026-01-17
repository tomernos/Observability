# Tracing via Terraform - Best Practices

## 🎯 Why Terraform Instead of Scripts?

### Problems with Scripts
- ❌ Manual execution required
- ❌ Not idempotent (can't re-run safely)
- ❌ No state management
- ❌ Hard to version control
- ❌ Difficult to rollback

### Benefits of Terraform
- ✅ Infrastructure as Code
- ✅ Idempotent (safe to re-run)
- ✅ State management
- ✅ Version controlled
- ✅ Easy rollback
- ✅ Same pattern as rest of infrastructure

## 📋 What Gets Deployed

### 1. Monitoring Stack (Prometheus + Grafana)
- **Chart**: `kube-prometheus-stack`
- **Namespace**: `monitoring`
- **Config**: `helm/monitoring/values.yaml`

### 2. Jaeger
- **Chart**: `jaeger`
- **Namespace**: `monitoring`
- **Config**: `helm/jaeger/values.yaml`

### 3. OpenTelemetry Collector
- **Chart**: `opentelemetry-collector`
- **Namespace**: `monitoring`
- **Config**: `helm/otel-collector/values.yaml` + `config.yaml`

## 🚀 Deployment

```bash
cd Observability/infra-tf

# Plan
terraform plan

# Apply
terraform apply
```

**That's it!** All observability components deployed via Terraform.

## 🔄 Updates

To update any component:

1. Edit values file: `helm/{component}/values.yaml`
2. Run: `terraform apply`
3. Terraform updates the Helm release automatically

## 📊 Structure

```
infra-tf/
├── main.tf                    # Helm releases defined here
├── main.auto.tfvars          # Chart versions, repos
└── helm/
    ├── monitoring/
    │   ├── values.yaml       # Prometheus/Grafana config
    │   └── alertmanager-values.yaml
    ├── jaeger/
    │   └── values.yaml       # Jaeger config
    └── otel-collector/
        ├── values.yaml       # OTEL Collector deployment
        └── config.yaml       # Collector pipeline config
```

## ✅ Benefits

1. **Consistency**: Same deployment method for all components
2. **Reliability**: Terraform manages state
3. **Scalability**: Easy to add more charts
4. **Maintainability**: All config in one place
5. **TIER6 Pattern**: Infrastructure as Code

---

**No more manual scripts - everything via Terraform!** 🚀

