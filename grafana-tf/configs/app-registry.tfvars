# Application Registry - TIER6 Multi-App Support
# Add new applications here - dashboard auto-generated from this config

apps = {
  chatapp = {
    name        = "chatapp"
    display_name = "Chat Application"
    environments = ["dev", "staging", "prod"]
    namespace_prefix = "chatapp"
    
    # Standard RED metrics (Rate, Errors, Duration)
    metrics = {
      request_total_metric = "http_requests_total"
      request_duration_metric = "http_request_duration_seconds"
      request_in_progress_metric = "http_requests_in_progress"
    }
    
    # Alert thresholds (standardized across apps)
    thresholds = {
      error_rate_warning  = 1.0   # 1% errors
      error_rate_critical = 5.0   # 5% errors
      latency_warning    = 0.5    # 500ms
      latency_critical   = 1.0    # 1s
      request_rate_warning = 10   # 10 req/s
    }
  }
  
  # Template for next app - just copy and modify
  # app2 = {
  #   name = "app2"
  #   display_name = "Application 2"
  #   environments = ["dev", "prod"]
  #   namespace_prefix = "app2"
  #   metrics = {
  #     request_total_metric = "http_requests_total"
  #     request_duration_metric = "http_request_duration_seconds"
  #     request_in_progress_metric = "http_requests_in_progress"
  #   }
  #   thresholds = {
  #     error_rate_warning  = 1.0
  #     error_rate_critical = 5.0
  #     latency_warning    = 0.5
  #     latency_critical   = 1.0
  #   }
  # }
}

