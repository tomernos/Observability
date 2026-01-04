# =========================================
# Grafana Dashboards - Generic Template Approach
# =========================================

data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

resource "grafana_folder" "chatapp" {
  title = "ChatApp"
}


resource "grafana_dashboard" "dashboards" {
  for_each = var.dashboards
  
  folder = grafana_folder.chatapp.id

  config_json = templatefile(
    "${path.module}/templates/generic-dashboard.json.tpl",
    {
      dashboard_title = each.value.title
      dashboard_uid   = each.value.uid
      tags            = each.value.tags
      refresh         = each.value.refresh
      prometheus_uid  = data.grafana_data_source.prometheus.uid
      panels          = each.value.panels
    }
  )
}

# # Local variables for dashboard configuration
# locals {
#   dashboard_config = {
#     namespace      = "chatapp-prod"
#     prometheus_uid = data.grafana_data_source.prometheus.uid
#   }
# }

# # Dashboard using templatefile function
# resource "grafana_dashboard" "chatapp_backend_template" {
#   folder = grafana_folder.chatapp.id

#   config_json = templatefile(
#     "${path.module}/templates/chatapp-backend-dashboard.json.tpl",
#     local.dashboard_config
#   )
# }
