output "dashboard_url" {
  description = "URL to access the ChatApp Backend dashboard"
  value       = "${var.grafana_url}/d/chatapp-backend"
}

output "folder_name" {
  description = "Grafana folder containing ChatApp dashboards"
  value       = grafana_folder.chatapp.title
}
