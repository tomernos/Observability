grafana_url      = "http://ac4db9e95e19c48c9bb73fcd758629c0-217960061.eu-central-1.elb.amazonaws.com"
grafana_username = "admin"
grafana_password = "admin123"

# =========================================
# Application Registry - TIER6 Multi-App System
# Developer-Friendly: Simple structure, auto-calculated positions
# =========================================

apps = {
  chatapp = {
    name            = "chatapp"
    display_name    = "Chat Application"
    environments    = ["dev", "staging", "prod"]
    namespace_prefix = "chatapp"
    refresh         = "10s"
    time_from       = "now-1h"
    time_to         = "now"
    
    panels = [
      {
        title  = "Request Rate (req/s)"
        type   = "timeseries"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m])) by (endpoint)"
            legend = "{{endpoint}}"
          }
        ]
      },
      {
        title  = "Total Request Rate"
        type   = "gauge"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m]))"
            legend = "Total"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 10 },
          { level = "critical", value = 20 }
        ]
      },
      {
        title  = "Error Rate (4xx/5xx)"
        type   = "timeseries"
        unit   = "percent"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\", status_code=~\"4..|5..\"}[5m])) by (status_code) / sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m])) * 100"
            legend = "{{status_code}}"
          }
        ]
      },
      {
        title  = "Overall Error Rate"
        type   = "gauge"
        unit   = "percent"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\", status_code=~\"4..|5..\"}[5m])) / sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m])) * 100"
            legend = "Errors"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 1 },
          { level = "critical", value = 5 }
        ]
      },
      {
        title  = "Response Time (Latency)"
        type   = "timeseries"
        unit   = "seconds"
        queries = [
          {
            expr   = "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{namespace=\"__NAMESPACE__\"}[5m])) by (le, endpoint))"
            legend = "p50 - {{endpoint}}"
          },
          {
            expr   = "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace=\"__NAMESPACE__\"}[5m])) by (le, endpoint))"
            legend = "p95 - {{endpoint}}"
          },
          {
            expr   = "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace=\"__NAMESPACE__\"}[5m])) by (le, endpoint))"
            legend = "p99 - {{endpoint}}"
          }
        ]
      },
      {
        title  = "P95 Latency"
        type   = "gauge"
        unit   = "seconds"
        queries = [
          {
            expr   = "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace=\"__NAMESPACE__\"}[5m])) by (le))"
            legend = "p95"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 0.5 },
          { level = "critical", value = 1 }
        ]
      },
      {
        title  = "Requests In Progress"
        type   = "timeseries"
        queries = [
          {
            expr   = "sum(http_requests_in_progress{namespace=\"__NAMESPACE__\"}) by (endpoint)"
            legend = "{{endpoint}}"
          }
        ]
      }
    ]
  }
}
