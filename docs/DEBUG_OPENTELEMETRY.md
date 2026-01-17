# Debug OpenTelemetry in Backend Pod

## 🔍 How to Check OpenTelemetry

### Step 1: Get Pod Name
```bash
kubectl get pods -n chatapp-dev -l app.kubernetes.io/name=backend
```

### Step 2: Exec Into Pod
```bash
kubectl exec -it -n chatapp-dev <pod-name> -- /bin/bash
```

### Step 3: Inside Pod - Check OpenTelemetry

```bash
# Check if packages are installed
pip list | grep opentelemetry

# Should show:
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation
# opentelemetry-instrumentation-flask
# opentelemetry-exporter-otlp

# Test import
python -c "from opentelemetry import trace; print('OpenTelemetry OK')"

# Check environment variables
env | grep OTEL

# Should show:
# OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc.cluster.local:4317
# OTEL_SERVICE_NAME=chatapp-backend
# OTEL_SERVICE_NAMESPACE=chatapp-dev

# Test if can reach OTEL Collector
curl -v http://otel-collector.monitoring.svc.cluster.local:4317

# Check if initialization function exists
python -c "import sys; sys.path.insert(0, '/app'); from app import __init__ as app_init; print(hasattr(app_init, '_initialize_opentelemetry'))"
```

## 🐛 Common Issues

### Issue 1: Packages Not Installed
**Symptom**: `pip list | grep opentelemetry` shows nothing

**Fix**: Rebuild Docker image - CI should install packages from `requirements.txt`

### Issue 2: Initialization Failing Silently
**Symptom**: No logs about OpenTelemetry initialization

**Check**: Look for error logs:
```bash
kubectl logs -n chatapp-dev <pod-name> | grep -i "opentelemetry\|otel\|error\|warning"
```

### Issue 3: Cannot Reach OTEL Collector
**Symptom**: `curl` to OTEL Collector fails

**Fix**: Check network connectivity and service name

## ✅ Expected Behavior

When OpenTelemetry initializes correctly, you should see in logs:
```
✅ OpenTelemetry initialized: chatapp-backend -> http://otel-collector.monitoring.svc.cluster.local:4317
   Service namespace: chatapp-dev
✅ Flask OpenTelemetry instrumentation enabled
```

If you don't see these, initialization is failing silently.


