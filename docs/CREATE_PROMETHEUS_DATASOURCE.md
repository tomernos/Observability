# Create Prometheus Data Source in Grafana

## 🎯 Problem

Terraform error: `[GET /datasources/name/{name}] getDataSourceByName (status 404): {}`

**Cause**: Terraform is trying to **read** a Prometheus data source that doesn't exist yet.

## ✅ Solution

Changed from `data` (read) to `resource` (create):

**Before:**
```hcl
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}
```

**After:**
```hcl
resource "grafana_data_source" "prometheus" {
  type          = "prometheus"
  name          = "Prometheus"
  url           = "http://prometheus-operated.monitoring.svc.cluster.local:9090"
  is_default    = true
  access_mode   = "proxy"
  
  json_data {
    http_method = "POST"
    time_interval = "15s"
  }
}
```

## 🚀 Apply

```bash
cd Observability/grafana-tf
terraform init
terraform plan
terraform apply
```

## 🔍 Verify

1. **Check in Grafana UI:**
   - Login to Grafana
   - Go to: **Configuration → Data Sources**
   - Should see: **Prometheus** (default)

2. **Test Connection:**
   - Click on Prometheus data source
   - Click **Save & Test**
   - Should show: **Data source is working**

## 📋 Configuration Details

- **URL**: Internal Kubernetes service URL
  - `prometheus-operated.monitoring.svc.cluster.local:9090`
  - This is the Prometheus service in the monitoring namespace

- **Access Mode**: `proxy` (Grafana proxies requests to Prometheus)

- **Default**: `true` (makes it the default data source)

## 🔧 Alternative: External URL

If Prometheus has LoadBalancer/Ingress:

```hcl
resource "grafana_data_source" "prometheus" {
  type          = "prometheus"
  name          = "Prometheus"
  url           = "http://prometheus.example.com"  # External URL
  is_default    = true
  access_mode   = "proxy"
  
  json_data {
    http_method = "POST"
  }
}
```

## ✅ After Fix

Once the data source is created:
- Terraform can reference it: `grafana_data_source.prometheus.uid`
- Dashboards will use it automatically
- No more 404 errors!

---

**TIER6 Pattern**: Manage everything with Terraform - data sources, dashboards, folders, all as code!

