# Distributed Tracing Architecture

## 🏗️ Component Flow

```
Application (Flask)
    ↓ (OpenTelemetry SDK)
OpenTelemetry Collector
    ↓ (OTLP protocol)
Jaeger
    ↓ (Query API)
Grafana (Trace Dashboard)
```

## 📦 Components Explained

### 1. OpenTelemetry SDK (in your app)
- **Language**: Python (`opentelemetry-instrumentation-flask`)
- **What it does**: 
  - Auto-instruments Flask routes
  - Creates spans for each request
  - Adds context (trace ID, span ID)
  - Sends to collector
- **No code changes**: Just install and configure!

### 2. OpenTelemetry Collector
- **Deployment**: Kubernetes DaemonSet (one per node)
- **What it does**:
  - Receives traces from all pods
  - Processes (filtering, batching)
  - Routes to Jaeger
- **Why separate**: 
  - Decouples app from Jaeger
  - Can add processing logic
  - Supports multiple backends

### 3. Jaeger
- **Deployment**: Kubernetes StatefulSet
- **Components**:
  - **Collector**: Receives traces
  - **Query**: Search/visualize traces
  - **Storage**: Stores traces (in-memory or persistent)
- **UI**: Built-in trace viewer

### 4. Grafana Integration
- **Data Source**: Jaeger
- **Dashboards**: Trace visualization
- **Correlation**: Link traces with metrics/logs

## 🔄 Request Flow Example

```
User Request → Frontend
    ↓ (creates trace: trace-id=abc123)
Frontend → Backend API
    ↓ (continues trace: trace-id=abc123, parent-span=1)
Backend → Database Query
    ↓ (child span: trace-id=abc123, parent-span=2)
Backend → Redis Cache
    ↓ (child span: trace-id=abc123, parent-span=2)
Backend → Response
    ↓ (all spans sent to collector)
Collector → Jaeger
    ↓ (stored and indexed)
Grafana → Visualize trace
```

## 🎯 Key Concepts

### Trace
- **Definition**: Complete request journey
- **Contains**: Multiple spans
- **ID**: Unique identifier (trace-id)

### Span
- **Definition**: Single operation (e.g., "database query")
- **Contains**: Start time, duration, tags, logs
- **Relationships**: Parent-child (nested operations)

### Context Propagation
- **What**: Passing trace-id between services
- **How**: HTTP headers (`traceparent`)
- **Why**: Link spans from different services

