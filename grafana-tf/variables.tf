variable "grafana_url" {
  description = "Grafana URL"
  type        = string
}

variable "grafana_username" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "dashboards" {
  description = "Map of dashboards to create (simplified for developers)"
  type = any
}
  
#   map(object({
#     title     = string
#     uid       = string
#     tags      = list(string)
#     refresh   = string
#     namespace = string
#     panels = list(object({
#       title = string
#       type  = string
#       unit  = optional(string, "short")
#       queries = list(object({
#         expr   = string
#         legend = string
#       }))
#       alert_thresholds = optional(list(object({
#         level = string  # "warning" or "critical"
#         value = number
#       })), [])
#     }))
#   }))
# }