# Fix Prometheus ServiceMonitor Discovery

## 🎯 Problem

Prometheus only discovers ServiceMonitors in `monitoring` namespace, not `chatapp-dev`.

**Current state:**
- Prometheus `serviceMonitorSelector`: `{"matchLabels":{"release":"monitoring"}}`
- ServiceMonitor has label: `release: kube-prometheus-stack`
- **Mismatch!** Prometheus won't discover it.

## ✅ Solution

### Option 1: Update Prometheus to Discover All (Recommended - TIER6)

**File**: `Observability/infra-tf/helm/monitoring/values.yaml`

```yaml
prometheus:
  enabled: true
  prometheusSpec:
    serviceMonitorSelector: {}  # Empty = all ServiceMonitors
    serviceMonitorNamespaceSelector: {}  # All namespaces
```

**Redeploy:**
```bash
cd Observability/infra-tf

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  --wait \
  --timeout 10m
```

**Wait 30-60 seconds** for Prometheus to reload config and discover targets.

### Option 2: Update ServiceMonitor Label (Quick Fix)

**File**: `ChatApplication/helm-chart/charts/backend/templates/servicemonitor.yaml`

Change:
```yaml
release: kube-prometheus-stack
```

To:
```yaml
release: monitoring
```

Then redeploy chatapp:
```bash
helm upgrade --install chatapp ./helm-chart \
  --namespace chatapp-dev \
  -f ./helm-chart/values-dev.yaml
```

## 🔍 Verify Fix

### 1. Check Prometheus Configuration
```bash
kubectl get prometheus -n monitoring -o jsonpath='{.items[0].spec.serviceMonitorSelector}'
```

**Should show:** `{}` (empty = all)

### 2. Check Prometheus Targets
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Visit: **http://localhost:9090/targets**

**Should see:**
- `serviceMonitor/chatapp-dev/chatapp-backend/0` ✅
- Status: **UP** (green)

### 3. Test Query
In Prometheus UI:
```
up{job="chatapp-backend"}
```

Should return: `1` (target is UP)

## 🎯 Recommended: Option 1

**Why?** TIER6 pattern - supports multiple apps across namespaces:
- ✅ Works for all current apps
- ✅ Works for future apps automatically
- ✅ No per-app configuration needed
- ✅ True multi-tenant observability

## ⚡ Quick Fix Script

```bash
#!/bin/bash
# Fix Prometheus discovery

cd Observability/infra-tf

echo "Updating Prometheus to discover all ServiceMonitors..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  --wait \
  --timeout 10m

echo "Waiting 30s for Prometheus to reload..."
sleep 30

echo "Check targets:"
echo "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "Then visit: http://localhost:9090/targets"
```

---

**After fix**: Prometheus will discover ServiceMonitors in ALL namespaces, and dashboards will populate with data! 🎉

