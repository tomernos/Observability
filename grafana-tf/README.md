# Grafana Dashboards as Code

This Terraform module manages Grafana dashboards for the ChatApp backend monitoring stack.

## What It Does

- Creates a custom Grafana dashboard with **RED metrics** (Rate, Errors, Duration)
- Organizes dashboards in a dedicated "ChatApp" folder
- Manages dashboards as code for version control and GitOps

## Dashboard Panels

The `ChatApp Backend - RED Metrics` dashboard includes:

1. **Request Rate** - Requests per second by endpoint
2. **Total Request Rate** - Overall throughput (gauge)
3. **Error Rate** - 4xx/5xx error percentage by status code
4. **Overall Error Rate** - Total error percentage (gauge)
5. **Response Time** - p50, p95, p99 latency by endpoint
6. **P95 Latency** - 95th percentile response time (gauge)
7. **Requests In Progress** - Current load by endpoint

## Prerequisites

- Grafana accessible at LoadBalancer URL or via port-forward
- Prometheus datasource configured in Grafana
- Backend pods exposing `/metrics` endpoint with:
  - `http_requests_total` (Counter)
  - `http_request_duration_seconds` (Histogram)
  - `http_requests_in_progress` (Gauge)

## Usage

### 1. Initialize Terraform

```bash
cd Observability/grafana-tf
terraform init
```

### 2. Plan the deployment

```bash
terraform plan
```

### 3. Apply to create dashboard

```bash
terraform apply
```

### 4. Access the dashboard

Open the URL from outputs:
```bash
terraform output dashboard_url
```

Or manually go to: `http://<grafana-url>/d/chatapp-backend`

## Configuration

Edit `variables.tf` to customize:

- `grafana_url` - Grafana LoadBalancer or localhost URL
- `grafana_username` - Admin username (default: admin)
- `grafana_password` - Admin password (default: admin123)
- `prometheus_datasource_uid` - Prometheus datasource UID (default: prometheus)

## Dashboard Customization

To modify the dashboard:

1. Edit `dashboards/chatapp-backend.json`
2. Run `terraform apply` to update in Grafana
3. Commit changes to Git for version control

**Tip**: You can also export dashboards from Grafana UI (Share → Export → Save to file) and replace the JSON.

## Interview Talking Points

- **GitOps for Dashboards**: Dashboards stored in version control, deployed via Terraform
- **RED Metrics**: Industry-standard observability pattern (Rate, Errors, Duration)
- **Infrastructure as Code**: Grafana configuration managed declaratively
- **Separation of Concerns**: Dedicated Terraform module for monitoring configuration
