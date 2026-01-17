# Alerting Setup Guide

## 🎯 Goal

Set up alerts for critical metrics (error rate, latency, availability).

## 📋 Prerequisites

- ✅ Prometheus scraping metrics
- ✅ Grafana dashboards working
- ✅ Slack workspace (or email SMTP)

## 🚀 Step 1: Create Alert Rules

**File**: `Observability/grafana-tf/alerts/chatapp-alerts.yaml`

```yaml
groups:
  - name: chatapp_alerts
    interval: 30s
    rules:
      # High Error Rate
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{namespace="chatapp-dev", status_code=~"5.."}[5m])) 
          / 
          sum(rate(http_requests_total{namespace="chatapp-dev"}[5m])) 
          * 100 > 5
        for: 5m
        labels:
          severity: critical
          app: chatapp
          environment: dev
        annotations:
          summary: "High error rate in chatapp-dev"
          description: "Error rate is {{ $value }}% (threshold: 5%)"

      # High Latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, 
            sum(rate(http_request_duration_seconds_bucket{namespace="chatapp-dev"}[5m])) by (le)
          ) > 1.0
        for: 5m
        labels:
          severity: warning
          app: chatapp
          environment: dev
        annotations:
          summary: "High latency in chatapp-dev"
          description: "P95 latency is {{ $value }}s (threshold: 1.0s)"

      # Service Down
      - alert: ServiceDown
        expr: up{job="chatapp-backend", namespace="chatapp-dev"} == 0
        for: 2m
        labels:
          severity: critical
          app: chatapp
          environment: dev
        annotations:
          summary: "chatapp-backend is down"
          description: "Service has been down for more than 2 minutes"
```

## 🚀 Step 2: Configure Alertmanager

**File**: `Observability/infra-tf/helm/monitoring/alertmanager-values.yaml`

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    
    route:
      group_by: ['alertname', 'app', 'environment']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack-notifications'
      routes:
        - match:
            severity: critical
          receiver: 'slack-critical'
          continue: true
        - match:
            severity: warning
          receiver: 'slack-warning'
    
    receivers:
      - name: 'slack-notifications'
        slack_configs:
          - channel: '#alerts'
            title: '{{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      
      - name: 'slack-critical'
        slack_configs:
          - channel: '#alerts-critical'
            title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      
      - name: 'slack-warning'
        slack_configs:
          - channel: '#alerts'
            title: '⚠️ WARNING: {{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

## 🚀 Step 3: Apply Alert Rules via Terraform

**Add to**: `Observability/grafana-tf/main.tf`

```hcl
# PrometheusRule for alerts
resource "kubectl_manifest" "chatapp_alerts" {
  yaml_body = file("${path.module}/alerts/chatapp-alerts.yaml")
  
  depends_on = [
    grafana_data_source.prometheus
  ]
}
```

## 🚀 Step 4: Get Slack Webhook

1. Go to: https://api.slack.com/apps
2. Create new app → Incoming Webhooks
3. Enable webhooks
4. Add to workspace
5. Copy webhook URL

## 🚀 Step 5: Deploy

```bash
# 1. Update alertmanager values with webhook URL
vim Observability/infra-tf/helm/monitoring/alertmanager-values.yaml

# 2. Redeploy monitoring with alertmanager config
cd Observability/infra-tf
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/monitoring/values.yaml \
  -f helm/monitoring/alertmanager-values.yaml \
  --wait

# 3. Apply alert rules
cd ../grafana-tf
terraform apply
```

## ✅ Verify

1. **Check Alertmanager**:
   ```bash
   kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
   # Visit: http://localhost:9093
   ```

2. **Trigger Test Alert**:
   ```bash
   # Simulate high error rate
   # Or wait for real alert condition
   ```

3. **Check Slack**:
   - Should receive alert in configured channel

## 📊 Alert Dashboard

Create Grafana dashboard to visualize alerts:
- Active alerts
- Alert history
- Alert frequency

---

**Next**: Once alerts work, expand to staging/prod and add more alert rules!

