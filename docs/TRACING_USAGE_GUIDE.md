# Distributed Tracing - Usage Guide

## 🎯 What You Just Built

You now have **complete observability**:
- ✅ **Metrics** (Prometheus) - "How many requests? What's the average latency?"
- ✅ **Traces** (Jaeger) - "What happened to THIS specific request?"
- ✅ **Dashboards** (Grafana) - Visualize everything

## 🔍 How to Use Tracing

### Step 1: Access Jaeger UI

```bash
# Port-forward to Jaeger (it's in default namespace)
kubectl port-forward -n default svc/jaeger 16686:16686

# Visit: http://localhost:16686
```

### Step 2: Generate Some Traffic

```bash
# Make some API requests to your backend
curl http://chatapp-dev.tomernos.xyz/api/health
curl http://chatapp-dev.tomernos.xyz/api/users
# Or use the frontend UI
```

### Step 3: View Traces in Jaeger

1. **Select Service**: Choose `chatapp-backend` from dropdown
2. **Click "Find Traces"**: See all traces
3. **Click a trace**: See the full request journey

## 📊 Understanding Traces

### What You'll See

```
Trace: abc123 (100ms total)
├─ Span 1: HTTP GET /api/users (100ms)
│  ├─ Span 2: Database query (80ms)
│  └─ Span 3: Redis cache lookup (20ms)
```

### Key Information

- **Trace ID**: Unique identifier for the request
- **Spans**: Individual operations (HTTP request, DB query, etc.)
- **Duration**: How long each operation took
- **Tags**: Metadata (HTTP method, status code, etc.)

## 🎓 What to Look For

### 1. **Slow Operations**
- Look for spans with long duration
- Example: "Database query: 2s" ← This is your bottleneck!

### 2. **Error Traces**
- Red spans indicate errors
- Click to see error message and stack trace

### 3. **Request Flow**
- See how request moves through your system
- Understand service dependencies

### 4. **Latency Distribution**
- Use "Trace Timeline" view
- See where time is spent

## 🔧 Common Use Cases

### Debugging High Latency

**Problem**: "API is slow (2s response time)"

**With Metrics**: You know it's slow, but not WHY

**With Traces**:
1. Find a slow trace in Jaeger
2. See breakdown:
   - HTTP handler: 50ms
   - Database query: 1800ms ← **Found it!**
   - Response: 50ms
3. **Action**: Optimize that database query

### Debugging Errors

**Problem**: "Users getting 500 errors"

**With Metrics**: You see error rate, but not which request failed

**With Traces**:
1. Filter by "Error" in Jaeger
2. Click failed trace
3. See exact error message and where it failed
4. **Action**: Fix the bug at that location

### Understanding Dependencies

**Question**: "What does my backend call?"

**With Traces**:
1. Look at trace spans
2. See all external calls:
   - Database queries
   - Redis calls
   - External APIs
3. **Action**: Map your service dependencies

## 📈 Next Steps

### 1. Add Custom Spans (Advanced)

Add custom spans for business logic:

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def process_payment():
    with tracer.start_as_current_span("process_payment") as span:
        span.set_attribute("payment.amount", 100)
        span.set_attribute("payment.currency", "USD")
        # Your payment logic here
```

### 2. Correlate Traces with Logs

- Add trace ID to your logs
- Search logs by trace ID
- See full picture: trace + logs

### 3. Create Trace Dashboards in Grafana

- Add Jaeger data source to Grafana
- Create dashboards showing:
  - Trace duration over time
  - Error rate by service
  - Service dependency graph

### 4. Set Up Trace-Based Alerts

- Alert on slow traces (P95 > 1s)
- Alert on error traces
- Alert on missing traces (service down)

## 🎯 Key Concepts to Remember

### Metrics vs Traces

- **Metrics**: Aggregated data (always on, every request)
- **Traces**: Individual requests (sampled, detailed)

### When to Use What

- **Metrics**: Monitoring, alerting, capacity planning
- **Traces**: Debugging, optimization, understanding flow

### Together = Complete Picture

- **Metrics**: "System is slow"
- **Traces**: "Database queries are slow" (specific!)

## 🚀 Practice Exercise

1. **Generate traffic**: Make 10 API requests
2. **Find traces**: Look for them in Jaeger
3. **Analyze one**: Click a trace, see all spans
4. **Identify bottleneck**: Which span takes longest?
5. **Optimize**: Fix the slow operation

## 📚 Resources

- **Jaeger UI**: http://localhost:16686 (after port-forward)
- **Grafana**: Your Grafana LoadBalancer URL
- **Prometheus**: `kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090`

---

**You now have production-grade observability!** 🎉

Use traces to debug issues, optimize performance, and understand your system better.

