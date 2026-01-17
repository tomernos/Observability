# Distributed Tracing - Motivation & Overview

## 🎯 Why Add Tracing?

### Current State (Metrics Only)
- ✅ **What we know**: Request rate, error rate, latency averages
- ❌ **What we DON'T know**: 
  - Which service is slow?
  - What's the request path through services?
  - Why is latency high? (which operation?)
  - How do services interact?

### With Tracing
- ✅ **See full request journey**: Frontend → Backend → Database → Redis
- ✅ **Identify bottlenecks**: "Database query takes 2s"
- ✅ **Debug complex issues**: "Request fails at step 3 of 5"
- ✅ **Understand dependencies**: "Backend calls 3 external APIs"

## 📊 Metrics vs Traces

### Metrics (What We Have)
- **What**: Aggregated numbers (counters, histograms)
- **When**: Continuous, always collected
- **Answer**: "How many requests? What's the average latency?"
- **Example**: `http_requests_total{status="200"} = 1000`

### Traces (What We're Adding)
- **What**: Individual request journeys (spans)
- **When**: Sampled (e.g., 10% of requests)
- **Answer**: "What happened to THIS request? Where did it go?"
- **Example**: Request ID → 5 spans showing: API → Auth → DB → Cache → Response

## 🔧 Components

### OpenTelemetry
- **What**: Standard for instrumenting applications
- **Role**: Collects traces from your app
- **How**: Auto-instruments Flask (minimal code changes)
- **Output**: Sends traces to collector

### OpenTelemetry Collector
- **What**: Receives traces from apps
- **Role**: Processes, filters, routes traces
- **Output**: Sends to Jaeger

### Jaeger
- **What**: Trace storage and visualization
- **Role**: Stores traces, provides UI
- **UI**: See request flows, search traces, analyze latency

## 🎯 Benefits

1. **Debug faster**: See exact request path
2. **Optimize better**: Find slow operations
3. **Understand system**: Map service dependencies
4. **Complete observability**: Metrics + Logs + Traces = Full picture

## 📈 Example

**Without Tracing:**
- "P95 latency is 2s" ← But where? Which service?

**With Tracing:**
- Request takes 2s total:
  - Frontend: 50ms
  - Backend API: 100ms
  - Database query: 1800ms ← **Found the problem!**
  - Redis cache: 50ms

