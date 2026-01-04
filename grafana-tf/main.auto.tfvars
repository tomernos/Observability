grafana_url      = "http://a33829831536347a18210b60edf502c7-859654207.eu-central-1.elb.amazonaws.com"
grafana_username = "admin"
grafana_password = "admin123"


dashboards = {
  chatapp_backend = {
    title     = "ChatApp Backend - RED Metrics"
    uid       = "chatapp-backend-red"
    tags      = ["chatapp", "backend", "RED"]
    refresh   = "10s"
    namespace = "chatapp-prod"
    
    panels = [
      {
        title  = "Request Rate (req/s)"
        type   = "timeseries"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"chatapp-prod\"}[5m])) by (endpoint)"
            legend = "{{endpoint}}"
          }
        ]
      },
      {
        title  = "Total Request Rate"
        type   = "gauge"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"chatapp-prod\"}[5m]))"
            legend = "Total"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 5 },
          { level = "critical", value = 10 }
        ]
      },
      {
        title  = "Error Rate (4xx/5xx)"
        type   = "timeseries"
        unit   = "percent"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"chatapp-prod\", status_code=~\"4..|5..\"}[5m])) by (status_code) / sum(rate(http_requests_total{namespace=\"chatapp-prod\"}[5m]))"
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
            expr   = "sum(rate(http_requests_total{namespace=\"chatapp-prod\", status_code=~\"4..|5..\"}[5m])) / sum(rate(http_requests_total{namespace=\"chatapp-prod\"}[5m]))"
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
            expr   = "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{namespace=\"chatapp-prod\"}[5m])) by (le, endpoint))"
            legend = "p50 - {{endpoint}}"
          },
          {
            expr   = "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace=\"chatapp-prod\"}[5m])) by (le, endpoint))"
            legend = "p95 - {{endpoint}}"
          },
          {
            expr   = "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace=\"chatapp-prod\"}[5m])) by (le, endpoint))"
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
            expr   = "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace=\"chatapp-prod\"}[5m])) by (le))"
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
            expr   = "sum(http_requests_in_progress{namespace=\"chatapp-prod\"}) by (endpoint)"
            legend = "{{endpoint}}"
          }
        ]
      }
    ]
  }
  
  # Node Metrics Dashboard
  node_metrics = {
    title     = "Kubernetes Node Metrics"
    uid       = "k8s-node-metrics"
    tags      = ["kubernetes", "nodes", "infrastructure"]
    refresh   = "30s"
    namespace = ""
    
    panels = [
      {
        title  = "CPU Usage by Node"
        type   = "timeseries"
        unit   = "percent"
        queries = [
          {
            expr   = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
            legend = "{{instance}}"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 70 },
          { level = "critical", value = 90 }
        ]
      },
      {
        title  = "Average CPU Usage"
        type   = "gauge"
        unit   = "percent"
        queries = [
          {
            expr   = "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
            legend = "CPU"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 70 },
          { level = "critical", value = 90 }
        ]
      },
      {
        title  = "Node Count"
        type   = "stat"
        queries = [
          {
            expr   = "count(up{job=\"node-exporter\"})"
            legend = "Nodes"
          }
        ]
      },
      {
        title  = "Memory Usage by Node"
        type   = "timeseries"
        unit   = "percent"
        queries = [
          {
            expr   = "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))"
            legend = "{{instance}}"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 80 },
          { level = "critical", value = 95 }
        ]
      },
      {
        title  = "Average Memory Usage"
        type   = "gauge"
        unit   = "percent"
        queries = [
          {
            expr   = "100 * (1 - (avg(node_memory_MemAvailable_bytes) / avg(node_memory_MemTotal_bytes)))"
            legend = "Memory"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 80 },
          { level = "critical", value = 95 }
        ]
      }
    ]
  }
}
