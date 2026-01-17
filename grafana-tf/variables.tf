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

variable "apps" {
  description = "Application registry - dashboard definitions"
  type = map(object({
    name            = string
    display_name    = string
    environments    = list(string)
    namespace_prefix = string
    refresh         = optional(string, "10s")
    time_from       = optional(string, "now-1h")
    time_to         = optional(string, "now")
    panels = list(object({
      title  = string
      type   = string
      unit   = optional(string, "short")
      queries = list(object({
        expr   = string
        legend = string
      }))
      alert_thresholds = optional(list(object({
        level = string  # "warning" or "critical"
        value = number
      })), [])
    }))
  }))
}