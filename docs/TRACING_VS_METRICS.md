# Tracing vs Metrics - Key Differences

## 📊 Metrics (Current)

### What They Are
- **Aggregated data**: Counters, gauges, histograms
- **Time-series**: Values over time
- **Always on**: Every request measured

### What They Tell You
- ✅ Request rate: "100 req/s"
- ✅ Error rate: "5% errors"
- ✅ Latency distribution: "P95 = 500ms"
- ✅ Resource usage: "CPU 80%"

### Limitations
- ❌ Can't see individual requests
- ❌ Can't see request path through services
- ❌ Can't debug specific failures
- ❌ Aggregated = lose detail

### Example Query
```
rate(http_requests_total[5m])
→ Returns: 100 (aggregated count)
```

## 🔍 Traces (New)

### What They Are
- **Individual requests**: Each request = one trace
- **Detailed spans**: Each operation = one span
- **Sampled**: Not every request (e.g., 10%)

### What They Tell You
- ✅ Exact request path: "Frontend → Backend → DB"
- ✅ Operation timing: "DB query took 2s"
- ✅ Service dependencies: "Backend calls 3 services"
- ✅ Error location: "Failed at span #3"

### Limitations
- ❌ Sampled (not 100% of requests)
- ❌ More storage needed
- ❌ More complex setup

### Example Trace
```
Trace ID: abc123
├─ Span 1: HTTP GET /api/users (100ms)
│  ├─ Span 2: Database query (80ms)
│  └─ Span 3: Redis get (20ms)
```

## 🎯 When to Use What

### Use Metrics For
- ✅ Monitoring overall health
- ✅ Alerting on thresholds
- ✅ Capacity planning
- ✅ Performance trends

### Use Traces For
- ✅ Debugging specific issues
- ✅ Understanding request flow
- ✅ Finding bottlenecks
- ✅ Service dependency mapping

## 🔗 Together = Complete Picture

**Metrics**: "System is slow" (P95 latency high)
**Traces**: "Database queries are slow" (see exact query in trace)

**Metrics**: "Error rate is 5%"
**Traces**: "Errors happen in payment service" (see failed span)

## 📈 Example

### Problem: High Latency

**Metrics show:**
```
P95 latency: 2s
```

**Traces show:**
```
Request breakdown:
- API handler: 50ms
- Auth check: 100ms
- Database query: 1800ms ← Problem!
- Response: 50ms
```

**Action**: Optimize database query (found via trace!)

