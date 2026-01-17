# Prometheus Integration - Fix "No Data" Issue

## 🎯 Problem

Dashboards created but showing "No Data" because Prometheus isn't scraping chatapp metrics.

## 🔍 Root Cause

1. **ServiceMonitor not created** - `backend.monitoring.enabled=false` in values
2. **Prometheus not discovering** - Needs to watch all namespaces

## ✅ Solution Steps

### Step 1: Enable Monitoring in Helm Values

**File**: `ChatApplication/helm-chart/values-dev.yaml`

```yaml
backend:
  enabled: true
  monitoring:
    enabled: true  # ✅ Enable this!
    scrapeInterval: 15s
    scrapeTimeout: 10s
```

### Step 2: Configure Prometheus to Discover All Namespaces

**File**: `Observability/infra-tf/helm/monitoring/values.yaml`

```yaml
prometheus:
  enabled: true
  prometheusSpec:
    serviceMonitorSelector: {}  # Discover all ServiceMonitors
    serviceMonitorNamespaceSelector: {}  # In all namespaces
```

### Step 3: Redeploy Monitoring Stack

```bash
cd Observability/infra-tf

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f helm/monitoring/values.yaml \
  --wait \
  --timeout 10m
```

### Step 4: Redeploy ChatApp with Monitoring

```bash
cd ChatApplication

helm upgrade --install chatapp ./helm-chart \
  --namespace chatapp-dev \
  --create-namespace \
  -f ./helm-chart/values-dev.yaml \
  --wait
```

### Step 5: Verify ServiceMonitor Created

```bash
kubectl get servicemonitor -n chatapp-dev

# Should see: chatapp-backend
```

### Step 6: Check Prometheus Targets

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090

# Open: http://localhost:9090/targets
# Look for: chatapp-backend endpoints
# Status should be: UP (green)
```

### Step 7: Test Metrics Endpoint

```bash
# Port-forward to backend
kubectl port-forward -n chatapp-dev svc/chatapp-backend 5000:5000

# Test metrics
curl http://localhost:5000/metrics

# Should see:
# http_requests_total
# http_request_duration_seconds_bucket
# http_requests_in_progress
```

### Step 8: Test Prometheus Query

In Prometheus UI (http://localhost:9090):
```
http_requests_total{namespace="chatapp-dev"}
```

If this returns data → **Metrics are working!** ✅

## 🔧 Quick Fix Script

```bash
#!/bin/bash
# Quick fix for Prometheus integration

# 1. Update monitoring stack
cd Observability/infra-tf
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  --wait

# 2. Redeploy chatapp with monitoring
cd ../../ChatApplication
helm upgrade --install chatapp ./helm-chart \
  --namespace chatapp-dev \
  -f ./helm-chart/values-dev.yaml \
  --wait

# 3. Wait for discovery (30 seconds)
echo "Waiting 30s for Prometheus to discover targets..."
sleep 30

# 4. Verify
kubectl get servicemonitor -n chatapp-dev
echo ""
echo "Check Prometheus targets:"
echo "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "Then visit: http://localhost:9090/targets"
```

## 📊 Expected Metrics

Your backend exposes (matches dashboard queries):
- ✅ `http_requests_total` - Counter
- ✅ `http_request_duration_seconds` - Histogram  
- ✅ `http_requests_in_progress` - Gauge

## 🎯 Success Criteria

- [x] Monitoring enabled in values-dev.yaml
- [ ] Prometheus configured to discover all namespaces
- [ ] Monitoring stack redeployed
- [ ] ChatApp redeployed with monitoring enabled
- [ ] ServiceMonitor exists in chatapp-dev
- [ ] Prometheus shows chatapp-backend in targets (Status: UP)
- [ ] Prometheus query returns data
- [ ] Grafana dashboard shows data

## 🔄 Troubleshooting

### ServiceMonitor Not Found
```bash
# Check if it exists
kubectl get servicemonitor -n chatapp-dev

# If missing, check Helm values
helm get values chatapp -n chatapp-dev | grep monitoring
```

### Prometheus Not Discovering
```bash
# Check Prometheus config
kubectl get prometheus -n monitoring -o yaml | grep serviceMonitor

# Should show: serviceMonitorSelector: {}
```

### Metrics Endpoint Not Working
```bash
# Check pod logs
kubectl logs -n chatapp-dev -l app=backend | grep metrics

# Test directly
kubectl exec -n chatapp-dev <pod-name> -- curl http://localhost:5000/metrics
```

---

**Once metrics flow, dashboards will populate automatically!** 🎉
