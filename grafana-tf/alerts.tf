# =========================================
# Prometheus Alert Rules - TIER6 Multi-App
# =========================================

# Create PrometheusRule for chatapp alerts
resource "kubectl_manifest" "chatapp_alerts" {
  yaml_body = file("${path.module}/alerts/chatapp-alerts.yaml")
  
  depends_on = [
    data.grafana_data_source.prometheus
  ]
}

