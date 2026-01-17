# Grafana Dashboards - TIER6 Multi-App System

## 🎯 Developer-Friendly Dashboard Creation

**Pattern**: Simple tfvars → Auto-generated dashboards  
**Benefit**: Add dashboard in 5 lines, not 50

## 📝 How to Add Dashboard

### Simple Structure (No Grid Math!)

```hcl
apps = {
  myapp = {
    name            = "myapp"
    display_name    = "My Application"
    environments    = ["dev", "prod"]
    namespace_prefix = "myapp"
    
    panels = [
      {
        title  = "Request Rate"
        type   = "timeseries"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m]))"
            legend = "Total"
          }
        ]
      },
      {
        title  = "Error Rate"
        type   = "gauge"
        unit   = "percent"
        queries = [
          {
            expr   = "sum(rate(http_requests_total{namespace=\"__NAMESPACE__\", status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total{namespace=\"__NAMESPACE__\"}[5m])) * 100"
            legend = "Errors"
          }
        ]
        alert_thresholds = [
          { level = "warning", value = 1 },
          { level = "critical", value = 5 }
        ]
      }
    ]
  }
}
```

## ✨ Auto-Features

### Grid Positions (Auto-Calculated)
- **Stat panels**: 6x6 grid, 4 per row
- **Timeseries/Gauge**: 12x8, 2 per row
- **No manual x/y/w/h needed!**

### RefIds (Auto-Generated)
- First query: `A`
- Second query: `B`
- Third query: `C`
- And so on...

### Namespace Substitution
- Use `__NAMESPACE__` in expressions
- Auto-replaced per environment:
  - `myapp-dev` → dev dashboard
  - `myapp-prod` → prod dashboard

## 📊 Panel Types

### Timeseries
```hcl
{
  title  = "My Metric"
  type   = "timeseries"
  unit   = "reqps"  # optional
  queries = [...]
}
```

### Gauge
```hcl
{
  title  = "Error Rate"
  type   = "gauge"
  unit   = "percent"
  queries = [...]
  alert_thresholds = [
    { level = "warning", value = 1 },
    { level = "critical", value = 5 }
  ]
}
```

### Stat
```hcl
{
  title  = "Total Requests"
  type   = "stat"
  queries = [...]
}
```

## 🚀 Usage

```bash
cd Observability/grafana-tf
terraform init
terraform plan
terraform apply
```

## 🎯 Key Benefits

1. **Simple**: Just title, type, queries
2. **Auto**: Grid positions, refIds calculated
3. **Clean**: No verbose configs
4. **Reusable**: Same structure for all apps

---

**TIER6 Pattern**: Developer-friendly, auto-calculated, minimal config.
