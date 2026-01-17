# Alerting Quick Start Guide

## 🎯 Goal

Set up alerts for chatapp (dev/staging/prod) with Slack notifications.

## 📋 Prerequisites

- ✅ Prometheus scraping metrics
- ✅ Grafana dashboards working
- ✅ Slack workspace (for webhook)

## 🚀 Step 1: Get Slack Webhook URL

1. Go to: https://api.slack.com/apps
2. Click **Create New App** → **From scratch**
3. Name: `Alertmanager` → Workspace: Select yours
4. Go to **Incoming Webhooks** → Toggle **Activate Incoming Webhooks** ON
5. Click **Add New Webhook to Workspace**
6. Select channel: `#alerts` (or create new)
7. Copy the **Webhook URL**

## 🚀 Step 2: Deploy Alert Rules

```bash
cd Observability/grafana-tf

# Apply alert rules
terraform init
terraform apply
```

This creates PrometheusRule with alerts for:
- High error rate (critical/warning)
- High latency (critical/warning)
- Service down
- Resource usage (CPU/Memory)

## 🚀 Step 3: Configure Alertmanager

**Option A: Using Helm values file**

1. Edit `Observability/infra-tf/helm/monitoring/alertmanager-values.yaml`
2. Replace `${SLACK_WEBHOOK_URL}` with your webhook URL
3. Or use `--set` flag (see Option B)

**Option B: Using --set flag (Recommended)**

```bash
cd Observability/infra-tf

# Deploy with Slack webhook
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  -f helm/monitoring/alertmanager-values.yaml \
  --set alertmanager.config.global.slack_api_url='YOUR_SLACK_WEBHOOK_URL' \
  --wait \
  --timeout 10m
```

## 🚀 Step 4: Verify Alertmanager

```bash
# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Visit: http://localhost:9093
# Should see Alertmanager UI
```

## 🧪 Step 5: Test Alerts (Dev Only)

### Test 1: Simulate High Error Rate

```bash
# Port-forward to backend
kubectl port-forward -n chatapp-dev svc/chatapp-backend 5000:5000

# Generate errors (in another terminal)
for i in {1..100}; do
  curl -X GET http://localhost:5000/api/test-error || true
  sleep 0.1
done
```

**Expected**: Alert fires after 5 minutes if error rate > 5%

### Test 2: Check Active Alerts

```bash
# Check Prometheus alerts
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Visit: http://localhost:9090/alerts
```

### Test 3: Verify Slack Notification

Check your Slack channel - should receive alert notification.

## ✅ Verification Checklist

- [ ] Alert rules created (check Prometheus UI → Alerts)
- [ ] Alertmanager configured (check Alertmanager UI)
- [ ] Slack webhook URL set correctly
- [ ] Test alert fired (simulate error rate)
- [ ] Slack notification received
- [ ] Alert resolved when condition clears

## 🔧 Troubleshooting

### Alerts Not Firing

1. **Check Prometheus alerts**:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
   # Visit: http://localhost:9090/alerts
   ```

2. **Check Alertmanager logs**:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
   ```

3. **Verify metrics exist**:
   ```bash
   # In Prometheus UI, query:
   http_requests_total{namespace="chatapp-dev"}
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

3. **Check Alertmanager config**:
   ```bash
   kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
   # Visit: http://localhost:9093/#/status
   ```

## 📊 Alert Rules Summary

| Alert | Threshold | Severity | For |
|-------|-----------|----------|-----|
| High Error Rate | > 5% | Critical | 5m |
| Warning Error Rate | > 1% | Warning | 5m |
| High Latency | P95 > 1.0s | Critical | 5m |
| Warning Latency | P95 > 0.5s | Warning | 5m |
| Service Down | up == 0 | Critical | 2m |
| No Requests | 0 requests | Warning | 10m |

## 🎯 Next Steps

After alerts work in dev:
1. ✅ Verify staging/prod alerts (already configured)
2. ✅ Add more alert rules as needed
3. ✅ Set up on-call rotation
4. ✅ Create runbooks for each alert

---

**Once alerts work, you're ready for advanced features!** 🚀

