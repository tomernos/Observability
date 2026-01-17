# Distributed Tracing Setup Guide

## 🎯 Overview

Complete distributed tracing with OpenTelemetry + Jaeger, deployed via Terraform (TIER6 best practice).

## 📋 Prerequisites

- ✅ EKS cluster running
- ✅ Terraform configured
- ✅ Helm provider working

## 🚀 Deployment

### Step 1: Deploy via Terraform

```bash
cd Observability/infra-tf

# Initialize (if needed)
terraform init

# Plan to see what will be created
terraform plan

# Apply - deploys monitoring, jaeger, otel-collector
terraform apply
```

**What gets deployed:**
- ✅ Prometheus + Grafana (kube-prometheus-stack)
- ✅ Jaeger (trace storage)
- ✅ OpenTelemetry Collector (trace collection)

### Step 2: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Should see:
# - prometheus-*
# - grafana-*
# - alertmanager-*
# - jaeger-*
# - otel-collector-*
```

### Step 3: Get Service URLs

```bash
# Grafana
kubectl get svc -n monitoring grafana -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}'

# Jaeger UI (if LoadBalancer enabled)
kubectl get svc -n monitoring jaeger-query -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}'

# Or port-forward:
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
# Visit: http://localhost:16686
```

## 🔧 Instrument Backend Application

### Step 1: Install OpenTelemetry Packages

**File**: `ChatApplication/backend-service/requirements.txt`

```python
# Add these lines:
opentelemetry-api==1.24.0
opentelemetry-sdk==1.24.0
opentelemetry-instrumentation==0.45b0
opentelemetry-instrumentation-flask==0.45b0
opentelemetry-exporter-otlp==1.24.0
```

### Step 2: Configure OpenTelemetry

**File**: `ChatApplication/backend-service/app/__init__.py`

Add at the top (before Flask app creation):

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor

# Initialize OpenTelemetry
trace.set_tracer_provider(TracerProvider())

# Configure OTLP exporter (sends to OTEL Collector)
otlp_exporter = OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector.monitoring.svc.cluster.local:4317"),
    insecure=True  # For dev, use TLS in prod
)

# Add span processor
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Auto-instrument Flask
FlaskInstrumentor().instrument_app(app)
```

### Step 3: Add Environment Variable

**File**: `ChatApplication/helm-chart/charts/backend/values.yaml`

```yaml
env:
  # ... existing env vars ...
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.monitoring.svc.cluster.local:4317"
  OTEL_SERVICE_NAME: "chatapp-backend"
  OTEL_RESOURCE_ATTRIBUTES: "service.name=chatapp-backend,service.namespace=chatapp-dev"
```

## ✅ Verify Tracing Works

### 1. Generate Some Traffic

```bash
# Port-forward to backend
kubectl port-forward -n chatapp-dev svc/chatapp-backend 5000:5000

# Make some requests
for i in {1..10}; do
  curl http://localhost:5000/api/health
  sleep 1
done
```

### 2. Check Jaeger UI

```bash
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
```

Visit: **http://localhost:16686**

1. Select service: `chatapp-backend`
2. Click "Find Traces"
3. Should see traces!

### 3. Check Grafana Integration

1. Login to Grafana
2. Go to **Configuration → Data Sources**
3. Add **Jaeger** data source:
   - URL: `http://jaeger-query.monitoring.svc.cluster.local:16686`
4. Create trace dashboard or explore traces

## 🎯 Next Steps

1. ✅ Traces flowing to Jaeger
2. ✅ Jaeger UI showing traces
3. ✅ Grafana can query traces
4. ⏭️ Create trace dashboards in Grafana
5. ⏭️ Add custom spans for business logic

---

**Tracing is now part of your infrastructure-as-code!** 🚀

