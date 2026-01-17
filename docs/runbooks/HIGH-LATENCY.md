# Runbook: High Latency

**Alert:** `ChatappHighLatency` / `ChatappWarningLatency`  
**Severity:** Critical (P95 >1s) / Warning (P95 >0.5s)  
**SLO Impact:** Affects latency SLO

---

## 📊 Symptoms

- P95 latency exceeds threshold
- Users experiencing slow response times
- Request duration spike in Grafana

---

## 🔍 Investigation Steps

### 1. **Identify Slow Endpoints**
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```
- Open: **ChatApp - Staff-Level Observability Triad**
- Check: **Request Latency (P50, P95, P99)** panel
- Identify: Which endpoints are slow?

### 2. **Find Slow Traces in Jaeger**
```bash
# Port-forward Jaeger
kubectl port-forward -n default svc/jaeger-query 16686:16686
```
- Open: http://localhost:16686
- Service: `chatapp-backend`
- **Min Duration:** 500ms (or adjust based on alert)
- Find longest traces and analyze spans

### 3. **Check Resource Usage**
```bash
# CPU and memory usage
kubectl top pods -n chatapp-dev -l app=backend

# Check if pods are being throttled
kubectl describe pod -n chatapp-dev -l app=backend | grep -A 5 "Limits"
```

### 4. **Check Database Performance**
```bash
# View database-related logs
kubectl logs -n chatapp-dev -l app=backend --tail=100 | grep -i "query\|database\|sql"

# Check for slow queries in traces (Jaeger)
# Look for spans tagged: db.statement, db.type
```

---

## 🛠️ Common Causes & Solutions

### **Cause 1: Slow Database Queries**
**Symptoms:** 
- Long database spans in Jaeger traces
- High query execution time

**Solution:**
```bash
# Identify slow queries in traces
# Then optimize:
# - Add database indexes
# - Optimize query (avoid N+1 queries)
# - Add query caching
# - Use connection pooling
```

### **Cause 2: CPU Throttling**
**Symptoms:**
- CPU usage near limits
- High CPU wait time

**Solution:**
```bash
# Temporarily increase CPU limits
kubectl set resources deployment/backend -n chatapp-dev \
  --limits=cpu=1000m \
  --requests=cpu=500m

# Monitor improvement
kubectl top pods -n chatapp-dev -l app=backend
```

### **Cause 3: Memory Pressure / Garbage Collection**
**Symptoms:**
- Periodic latency spikes
- Memory usage near limits

**Solution:**
```bash
# Check memory usage
kubectl top pods -n chatapp-dev -l app=backend

# Increase memory limits
kubectl set resources deployment/backend -n chatapp-dev \
  --limits=memory=1Gi \
  --requests=memory=512Mi
```

### **Cause 4: External API Calls**
**Symptoms:**
- Traces show long spans for external HTTP calls
- Timeout waiting for external services

**Solution:**
- Check external service health
- Reduce timeout values
- Implement caching for external API responses
- Add circuit breaker pattern

### **Cause 5: High Traffic / Load**
**Symptoms:**
- Request rate spike
- All endpoints slow simultaneously

**Solution:**
```bash
# Scale up replicas
kubectl scale deployment/backend -n chatapp-dev --replicas=5

# Verify scaling
kubectl get pods -n chatapp-dev -l app=backend

# Check if Karpenter is scaling nodes
kubectl get nodes
kubectl get nodeclaims
```

---

## ✅ Resolution Checklist

- [ ] P95 latency returned to normal (<500ms)
- [ ] No slow traces in Jaeger
- [ ] Resource usage stable
- [ ] User experience back to normal
- [ ] Root cause identified
- [ ] Long-term fix planned (if temporary mitigation applied)

---

## 📞 Escalation

**If unable to resolve in 30 minutes:**
- Contact: DevOps Team Lead
- Backend Team: For application-level optimization
- Database Team: For database performance issues

---

## 📚 Related Documentation

- [Performance Optimization Guide](../PERFORMANCE.md)
- [SLI/SLO Definitions](../SLI-SLO-DEFINITION.md)
- [Database Optimization](../DATABASE-TUNING.md)

