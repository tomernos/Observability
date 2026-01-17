# Verify ServiceMonitor is Working

## ✅ ServiceMonitor EXISTS!

The ServiceMonitor **is deployed**:
```bash
kubectl get servicemonitor -n chatapp-dev
# Should show: chatapp-backend
```

## 🔍 Verify Configuration

### 1. Check ServiceMonitor Details
```bash
kubectl get servicemonitor chatapp-backend -n chatapp-dev -o yaml
```

**Should have:**
- `release: kube-prometheus-stack` label
- `path: /metrics`
- `port: http`
- Correct selector matching backend service

### 2. Check Backend Service Labels Match
```bash
# Get ServiceMonitor selector
kubectl get servicemonitor chatapp-backend -n chatapp-dev -o jsonpath='{.spec.selector.matchLabels}'

# Get backend service labels
kubectl get svc chatapp-backend -n chatapp-dev -o jsonpath='{.metadata.labels}'

# These should match!
```

### 3. Verify Service Port Name
```bash
kubectl get svc chatapp-backend -n chatapp-dev -o jsonpath='{.spec.ports[*].name}'
# Should include: http
```

## 🎯 Check Prometheus Discovery

### Option 1: Port-Forward Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Then visit: **http://localhost:9090/targets**

Look for:
- **chatapp-backend** endpoints
- **Status: UP** (green)
- **Last Scrape** timestamp

### Option 2: Check Prometheus Pod Logs
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator | grep servicemonitor
```

### Option 3: Query Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Then query:
```
up{job="chatapp-backend"}
```

Should return: `1` (target is UP)

## 🔧 Troubleshooting

### ServiceMonitor Exists But Not Discovered

**Check Prometheus configuration:**
```bash
kubectl get prometheus -n monitoring -o yaml | grep -A 5 serviceMonitorSelector
```

Should show:
```yaml
serviceMonitorSelector: {}
```

If not, update `Observability/infra-tf/helm/monitoring/values.yaml`:
```yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelector: {}
    serviceMonitorNamespaceSelector: {}
```

Then redeploy:
```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f Observability/infra-tf/helm/monitoring/values.yaml
```

### Service Labels Don't Match

**Check ServiceMonitor selector:**
```bash
kubectl get servicemonitor chatapp-backend -n chatapp-dev -o jsonpath='{.spec.selector.matchLabels}'
```

**Check backend service labels:**
```bash
kubectl get svc chatapp-backend -n chatapp-dev -o jsonpath='{.metadata.labels}'
```

If they don't match, update the ServiceMonitor template or service labels.

### Port Name Mismatch

ServiceMonitor expects port named `http`. Verify:
```bash
kubectl get svc chatapp-backend -n chatapp-dev -o yaml | grep -A 3 ports
```

If port name is different, update ServiceMonitor template:
```yaml
endpoints:
- port: <actual-port-name>  # Change from "http" if needed
```

## ✅ Success Criteria

- [x] ServiceMonitor exists in chatapp-dev
- [ ] ServiceMonitor has `release: kube-prometheus-stack` label
- [ ] Service labels match ServiceMonitor selector
- [ ] Service port name matches (should be `http`)
- [ ] Prometheus shows target as UP in /targets
- [ ] Prometheus query `up{job="chatapp-backend"}` returns 1
- [ ] Metrics endpoint `/metrics` returns data
- [ ] Grafana dashboard shows data

---

**Next**: Once Prometheus discovers the ServiceMonitor, metrics will flow and dashboards will populate!

