# Observability Triad Implementation Plan
## Modular, Reusable, TIER6 Pattern

## Overview

Complete the observability triad (Metrics ✅ + Traces + Logs) following the existing TIER6 modular pattern.

**Execution Order:**
1. Frontend Instrumentation (OTEL for React)
2. Grafana Trace Dashboards (TIER6 pattern)
3. Log Aggregation (Loki + Promtail)
4. Grafana Log Dashboards (TIER6 pattern)

---

## Phase 1: Frontend Instrumentation

### Goal
Add OpenTelemetry to React frontend for end-to-end tracing (Frontend → Backend).

### Architecture
```
React App → OTEL SDK → OTEL Collector (HTTP) → Jaeger
```

### Implementation

#### 1.1 Add OTEL Packages
**File**: `ChatApplication/frontend-service/package.json`
- Add: `@opentelemetry/api@^1.7.0`
- Add: `@opentelemetry/sdk-web@^0.45.0`
- Add: `@opentelemetry/instrumentation@^0.45.0`
- Add: `@opentelemetry/instrumentation-fetch@^0.45.0`
- Add: `@opentelemetry/instrumentation-xml-http-request@^0.45.0`
- Add: `@opentelemetry/exporter-otlp-http@^0.45.0`

#### 1.2 Create OTEL Initialization Module
**File**: `ChatApplication/frontend-service/src/instrumentation.js` (NEW)
- Initialize OTEL SDK
- Configure HTTP exporter (OTEL Collector endpoint)
- Auto-instrument fetch and XMLHttpRequest
- Set service name from env: `REACT_APP_OTEL_SERVICE_NAME`
- Set service namespace from env: `REACT_APP_OTEL_SERVICE_NAMESPACE`
- Export tracer for manual spans

**Pattern**: Follow backend pattern (`app/__init__.py` lines 30-70)

#### 1.3 Initialize in Entry Point
**File**: `ChatApplication/frontend-service/src/index.js`
- Import instrumentation module at top
- Initialize before React render

#### 1.4 Instrument API Service
**File**: `ChatApplication/frontend-service/src/services/api.js`
- Add manual spans for API calls
- Add trace context propagation
- Add span attributes (endpoint, method, status)

#### 1.5 Update Helm Chart
**File**: `ChatApplication/helm-chart/charts/frontend/values.yaml`
- Add env vars:
  - `REACT_APP_OTEL_SERVICE_NAME`: `chatapp-frontend`
  - `REACT_APP_OTEL_SERVICE_NAMESPACE`: `chatapp-{{ .Values.global.environment }}`
  - `REACT_APP_OTEL_EXPORTER_OTLP_ENDPOINT`: `http://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318` (HTTP endpoint)

**File**: `ChatApplication/helm-chart/charts/frontend/templates/deployment.yaml`
- Ensure env vars are injected (should already be there)

### Benefits
- End-to-end traces (Frontend → Backend)
- Frontend performance monitoring
- API call tracing
- Page load time tracking

---

## Phase 2: Grafana Trace Dashboards

### Goal
Visualize traces in Grafana (not just Jaeger UI) following TIER6 pattern.

### Architecture
```
Jaeger → Grafana Data Source → Trace Dashboards (TIER6)
```

### Implementation

#### 2.1 Add Jaeger Data Source
**File**: `Observability/grafana-tf/main.tf`
- Add data source for Jaeger (similar to Prometheus data source)
- Use: `jaeger.default.svc.cluster.local:16686`
- Type: `jaeger`
- Name: `Jaeger`

**Pattern**: Follow Prometheus data source pattern (lines 19-21)

#### 2.2 Create Trace Dashboard Template
**File**: `Observability/grafana-tf/templates/trace-dashboard.tpl` (NEW)
- Template for trace visualization dashboard
- Panels:
  - Trace duration over time (timeseries)
  - Trace count by service (stat)
  - Error trace rate (gauge)
  - Trace list (traces panel)
- Use namespace substitution like metrics dashboards

#### 2.3 Add Trace Dashboard Config
**File**: `Observability/grafana-tf/main.auto.tfvars`
- Add trace panels to app config (similar to metrics panels)
- Structure:
  ```hcl
  trace_panels = [
    {
      title = "Trace Duration (p95)"
      type = "timeseries"
      queries = [
        {
          expr = "histogram_quantile(0.95, sum(rate(trace_duration_seconds_bucket{namespace=\"__NAMESPACE__\"}[5m])) by (le, service))"
          legend = "{{service}}"
        }
      ]
    }
  ]
  ```

#### 2.4 Update Main Terraform
**File**: `Observability/grafana-tf/main.tf`
- Add trace dashboard generation (similar to metrics dashboards)
- Use trace template
- Process trace panels with namespace substitution
- Create dashboards per app×env

### Benefits
- Unified observability in Grafana
- Correlate traces with metrics
- Better visualization
- Multi-app support

---

## Phase 3: Log Aggregation (Loki + Promtail)

### Goal
Complete observability triad with centralized logging.

### Architecture
```
Pods → Promtail → Loki → Grafana
```

### Implementation

#### 3.1 Deploy Loki via Terraform
**File**: `Observability/infra-tf/main.auto.tfvars`
- Add Loki to helm releases:
  ```hcl
  loki = {
    repository = "https://grafana.github.io/helm-charts"
    chart = "loki"
    version = "6.0.0"
    namespace = "monitoring"
    create_namespace = false
  }
  ```

**File**: `Observability/infra-tf/helm/loki/values.yaml` (NEW)
- Configure Loki storage (S3 or local)
- Set resource limits
- Configure retention
- Enable multi-tenancy if needed

**File**: `Observability/infra-tf/main.tf`
- Add Loki to helm_release loop (will auto-load values.yaml)

#### 3.2 Deploy Promtail via Terraform
**File**: `Observability/infra-tf/main.auto.tfvars`
- Add Promtail to helm releases:
  ```hcl
  promtail = {
    repository = "https://grafana.github.io/helm-charts"
    chart = "promtail"
    version = "6.0.0"
    namespace = "monitoring"
    create_namespace = false
  }
  ```

**File**: `Observability/infra-tf/helm/promtail/values.yaml` (NEW)
- Configure Loki endpoint: `http://loki.monitoring.svc.cluster.local:3100`
- Configure scrape configs:
  - Scrape all pods in all namespaces
  - Add labels: namespace, pod, container, app
  - Parse JSON logs if needed

**File**: `Observability/infra-tf/main.tf`
- Add Promtail to helm_release loop

#### 3.3 Add Loki Data Source
**File**: `Observability/grafana-tf/main.tf`
- Add Loki data source (similar to Prometheus)
- Use: `http://loki.monitoring.svc.cluster.local:3100`
- Type: `loki`
- Name: `Loki`

### Benefits
- Centralized logging
- Log-based alerting
- Log correlation with traces
- Full observability triad

---

## Phase 4: Grafana Log Dashboards

### Goal
Visualize logs in Grafana following TIER6 pattern.

### Implementation

#### 4.1 Create Log Dashboard Template
**File**: `Observability/grafana-tf/templates/log-dashboard.tpl` (NEW)
- Template for log visualization
- Panels:
  - Log volume over time (timeseries)
  - Error log rate (stat)
  - Log level distribution (pie chart)
  - Log explorer (logs panel)
  - Recent errors (table)

#### 4.2 Add Log Dashboard Config
**File**: `Observability/grafana-tf/main.auto.tfvars`
- Add log panels to app config:
  ```hcl
  log_panels = [
    {
      title = "Log Volume"
      type = "timeseries"
      queries = [
        {
          expr = "sum(count_over_time({namespace=\"__NAMESPACE__\"}[1m]))"
          legend = "Logs/min"
        }
      ]
    },
    {
      title = "Error Log Rate"
      type = "stat"
      queries = [
        {
          expr = "sum(rate({namespace=\"__NAMESPACE__\", level=\"error\"}[5m]))"
          legend = "Errors/s"
        }
      ]
    }
  ]
  ```

#### 4.3 Update Main Terraform
**File**: `Observability/grafana-tf/main.tf`
- Add log dashboard generation
- Use log template
- Process log panels with namespace substitution
- Create dashboards per app×env

### Benefits
- Unified log visualization
- Log-based alerting
- Log correlation with metrics/traces
- Multi-app support

---

## Modular Structure

### File Organization
```
Observability/
├── infra-tf/
│   ├── helm/
│   │   ├── loki/
│   │   │   └── values.yaml          # NEW
│   │   └── promtail/
│   │       └── values.yaml          # NEW
│   └── main.tf                      # MODIFY (add Loki/Promtail)
├── grafana-tf/
│   ├── templates/
│   │   ├── trace-dashboard.tpl      # NEW
│   │   └── log-dashboard.tpl        # NEW
│   ├── main.tf                      # MODIFY (add trace/log dashboards)
│   └── main.auto.tfvars             # MODIFY (add trace/log panels)

ChatApplication/
├── frontend-service/
│   ├── src/
│   │   ├── instrumentation.js      # NEW
│   │   ├── index.js                # MODIFY
│   │   └── services/
│   │       └── api.js               # MODIFY
│   └── package.json                 # MODIFY
└── helm-chart/
    └── charts/
        └── frontend/
            └── values.yaml          # MODIFY
```

---

## Best Practices

### 1. Reusability
- Use templates for dashboards (like metrics)
- Namespace substitution pattern
- Multi-app support from start

### 2. Modularity
- Separate instrumentation from app code
- Terraform modules for each component
- Clear separation: infra-tf vs grafana-tf

### 3. Consistency
- Follow existing TIER6 pattern
- Same structure for metrics/traces/logs
- Consistent naming conventions

### 4. Environment Variables
- Use env vars for configuration
- Support dev/staging/prod
- No hardcoded values

### 5. Documentation
- Document each phase
- Add usage guides
- Include troubleshooting

---

## Testing Checklist

### Phase 1: Frontend Instrumentation
- [ ] Frontend sends traces to OTEL Collector
- [ ] Traces appear in Jaeger
- [ ] Frontend spans linked to backend spans
- [ ] Service name/namespace correct

### Phase 2: Trace Dashboards
- [ ] Jaeger data source works in Grafana
- [ ] Trace dashboards show data
- [ ] Multi-app support works
- [ ] Namespace substitution works

### Phase 3: Log Aggregation
- [ ] Loki deployed and running
- [ ] Promtail collecting logs
- [ ] Logs appear in Loki
- [ ] Loki data source works in Grafana

### Phase 4: Log Dashboards
- [ ] Log dashboards show data
- [ ] Log queries work
- [ ] Multi-app support works
- [ ] Log correlation with traces works

---

## Execution Order

1. **Frontend Instrumentation** (Phase 1)
   - Add packages
   - Create instrumentation module
   - Update Helm chart
   - Test in dev

2. **Grafana Trace Dashboards** (Phase 2)
   - Add Jaeger data source
   - Create trace template
   - Add trace panels config
   - Generate dashboards

3. **Log Aggregation** (Phase 3)
   - Deploy Loki
   - Deploy Promtail
   - Add Loki data source
   - Verify logs flowing

4. **Grafana Log Dashboards** (Phase 4)
   - Create log template
   - Add log panels config
   - Generate dashboards
   - Test correlation

---

## Success Criteria

- ✅ Frontend traces visible in Jaeger
- ✅ End-to-end traces (Frontend → Backend)
- ✅ Trace dashboards in Grafana
- ✅ Logs collected and stored
- ✅ Log dashboards in Grafana
- ✅ All following TIER6 pattern
- ✅ Multi-app ready
- ✅ Reusable and modular

---

## Next Steps After Completion

1. Add trace ID to application logs (correlation)
2. Create alert rules for traces/logs
3. Add custom business metrics
4. Expand to more applications
5. Add SLO/SLI tracking


