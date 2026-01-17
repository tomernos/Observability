# =========================================
# Grafana Dashboards - Multi-App System
# =========================================

# Create Prometheus data source (if it doesn't exist, Terraform will create it)
# # Use lifecycle to ignore changes if it already exists
# resource "grafana_data_source" "prometheus" {
#   type          = "prometheus"
#   name          = "Prometheus"
#   url           = "http://prometheus-operated.monitoring.svc.cluster.local:9090"
#   is_default    = true
#   access_mode   = "proxy"
  
#   lifecycle {
#     ignore_changes = [url]  # Ignore URL changes if manually updated
#   }
# }

data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

# Loki data source (logs)
resource "grafana_data_source" "loki" {
  type       = "loki"
  name       = "Loki"
  url        = "http://loki.monitoring.svc.cluster.local:3100"
  access_mode = "proxy"
}

# Jaeger data source (traces)
resource "grafana_data_source" "jaeger" {
  type       = "jaeger"
  name       = "Jaeger"
  url        = "http://jaeger.default.svc.cluster.local:16686"
  access_mode = "proxy"
  
  json_data_encoded = jsonencode({
    tracesToLogsV2 = {
      datasourceUid = grafana_data_source.loki.uid
      tags          = ["service.name"]
    }
    tracesToMetrics = {
      datasourceUid = data.grafana_data_source.prometheus.uid
      tags          = [{ key = "service.name", value = "service" }]
    }
  })
}

# Create folder per application
resource "grafana_folder" "app_folders" {
  for_each = var.apps
  title    = each.value.display_name
}

# Generate dashboards per app per environment
locals {
  dashboard_configs = {
    for combo in flatten([
      for app_key, app in var.apps : [
        for env in app.environments : {
          key       = "${app_key}-${env}"
          app_key   = app_key
          app       = app
          env       = env
          namespace = "${app.namespace_prefix}-${env}"
        }
      ]
    ]) : combo.key => combo
  }
  
  # Process panels with namespace substitution in expressions
  processed_panels = {
    for key, config in local.dashboard_configs : key => [
      for panel in config.app.panels : merge(panel, {
        queries = [
          for query in panel.queries : merge(query, {
            expr = replace(query.expr, "__NAMESPACE__", config.namespace)
          })
        ]
      })
    ]
  }
}

resource "grafana_dashboard" "app_dashboards" {
  for_each = local.dashboard_configs
  
  folder = grafana_folder.app_folders[each.value.app_key].id

  config_json = templatefile(
    "${path.module}/templates/app-dashboard.tpl",
    {
      dashboard_title   = "${each.value.app.display_name} - ${upper(each.value.env)}"
      dashboard_uid     = each.key
      tags              = jsonencode([each.value.app_key, each.value.env, "RED"])
      refresh_interval   = try(each.value.app.refresh, "10s")
      time_from         = try(each.value.app.time_from, "now-1h")
      time_to           = try(each.value.app.time_to, "now")
      prometheus_uid    = data.grafana_data_source.prometheus.uid
      panels            = local.processed_panels[each.key]
    }
  )
}
