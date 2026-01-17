# Alerting Deployment Guide

## 🎯 Quick Deploy

### Option 1: Using Script (Recommended)

```bash
cd Observability

# Get Slack webhook URL first (see Step 1 below)
# Then deploy:
./scripts/deploy-alerts.sh https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Option 2: Manual Deploy

#### Step 1: Get Slack Webhook URL

1. Go to: https://api.slack.com/apps
2. **Create New App** → **From scratch**
3. Name: `Alertmanager`, Workspace: Select yours
4. **Incoming Webhooks** → Toggle **ON**
5. **Add New Webhook to Workspace**
6. Select channel: `#alerts` (or create new)
7. **Copy Webhook URL**

#### Step 2: Deploy Alert Rules

```bash
cd Observability/grafana-tf

terraform init  # If not already done
terraform apply
```

#### Step 3: Configure Alertmanager

```bash
cd Observability/infra-tf

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  -f helm/monitoring/alertmanager-values.yaml \
  --set alertmanager.config.global.slack_api_url='YOUR_SLACK_WEBHOOK_URL' \
  --wait \
  --timeout 10m
```

## ✅ Verify Deployment

### 1. Check Alert Rules

```bash
kubectl get prometheusrule -A | grep chatapp
```

Should show: `chatapp-alerts` in monitoring namespace

### 2. Check Alertmanager

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
```

Visit: **http://localhost:9093**

### 3. Check Prometheus Alerts

```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Visit: **http://localhost:9090/alerts**

Should see:
- ChatappHighErrorRate
- ChatappWarningErrorRate
- ChatappHighLatency
- ChatappServiceDown
- etc.

## 🧪 Test Alerts (Dev Only)

### Test 1: High Error Rate

```bash
# Port-forward backend
kubectl port-forward -n chatapp-dev svc/chatapp-backend 5000:5000

# Generate errors (in another terminal)
for i in {1..200}; do
  curl -X GET http://localhost:5000/api/test-error 2>/dev/null || true
  sleep 0.05
done
```

**Wait 5 minutes** → Alert should fire if error rate > 5%

### Test 2: Service Down

```bash
# Scale down backend
kubectl scale deployment chatapp-backend -n chatapp-dev --replicas=0

# Wait 2 minutes → Alert should fire

# Scale back up
kubectl scale deployment chatapp-backend -n chatapp-dev --replicas=2
```

### Test 3: Verify Slack Notification

Check your Slack channel - should receive alert notification.

## 📊 Alert Rules Summary

| Alert | Condition | Severity | Duration |
|-------|-----------|----------|----------|
| High Error Rate | > 5% | Critical | 5m |
| Warning Error Rate | > 1% | Warning | 5m |
| High Latency | P95 > 1.0s | Critical | 5m |
| Warning Latency | P95 > 0.5s | Warning | 5m |
| Service Down | up == 0 | Critical | 2m |
| No Requests | 0 requests | Warning | 10m |

## 🔧 Troubleshooting

### Alerts Not Showing in Prometheus

1. **Check PrometheusRule exists**:
   ```bash
   kubectl get prometheusrule -n monitoring chatapp-alerts -o yaml
   ```

2. **Check Prometheus is loading rules**:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator | grep rule
   ```

3. **Reload Prometheus** (if needed):
   ```bash
   kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus
   ```

### Slack Notifications Not Working

1. **Check webhook URL**:
   ```bash
   kubectl get secret -n monitoring alertmanager-monitoring-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | grep slack
   ```

2. **Test webhook manually**:
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test alert"}' \
     YOUR_SLACK_WEBHOOK_URL
   ```

3. **Check Alertmanager logs**:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
   ```

### Alert Firing But Not Resolving

- Alerts auto-resolve when condition clears
- Check `send_resolved: true` in alertmanager config
- Wait for `repeat_interval` (12h default)

## 🎯 Next Steps

After alerts work in dev:
1. ✅ Verify staging/prod (already configured in alerts)
2. ✅ Add more alert rules as needed
3. ✅ Set up on-call rotation
4. ✅ Create runbooks for each alert type
5. ✅ Move to advanced features (tracing, etc.)

---

**Once alerts are working, you're ready for advanced features!** 🚀

