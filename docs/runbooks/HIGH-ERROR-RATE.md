# Runbook: High Error Rate

**Alert:** `ChatappHighErrorRate` / `ChatappWarningErrorRate`  
**Severity:** Critical (>5%) / Warning (>1%)  
**SLO Impact:** Directly affects availability SLO

---

## 📊 Symptoms

- 5xx HTTP errors exceed threshold
- Error rate spike visible in Grafana dashboard
- Users may be experiencing service failures

---

## 🔍 Investigation Steps

### 1. **Check Grafana Dashboard**
```bash
# Port-forward Grafana (if needed)
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```
- Open: http://localhost:3000
- Go to: **ChatApp - Staff-Level Observability Triad**
- Look at: **Service Availability** and **Error Rate** panels

### 2. **Check Recent Deployments**
```bash
# Check if recent deployment caused issues
kubectl rollout history deployment/backend -n chatapp-dev
kubectl rollout history deployment/backend -n chatapp-prod

# Check pod restart count
kubectl get pods -n chatapp-dev -l app=backend
```

### 3. **Search Traces in Jaeger**
```bash
# Port-forward Jaeger
kubectl port-forward -n default svc/jaeger-query 16686:16686
```
- Open: http://localhost:16686
- Service: `chatapp-backend`
- Filter: Status = `error` or Tags = `http.status_code=500`
- Look for patterns: which endpoints are failing?

### 4. **Check Application Logs**
```bash
# View recent error logs
kubectl logs -n chatapp-dev -l app=backend --tail=100 | grep -i error

# Or use Loki in Grafana (Explore → Loki)
{namespace="chatapp-dev", app="backend"} |= "error"
```

---

## 🛠️ Common Causes & Solutions

### **Cause 1: Database Connection Issues**
**Symptoms:** Logs show connection timeouts, database errors  
**Solution:**
```bash
# Check database connectivity
kubectl exec -n chatapp-dev deployment/backend -- curl -v your-db-endpoint:5432

# Check database pod (if internal)
kubectl get pods -n database
kubectl logs -n database <db-pod>
```

### **Cause 2: Recent Bad Deployment**
**Symptoms:** Error rate spiked after deployment  
**Solution:**
```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n chatapp-dev

# Verify rollback
kubectl rollout status deployment/backend -n chatapp-dev
```

### **Cause 3: External Service Dependency**
**Symptoms:** Timeouts calling external APIs  
**Solution:**
- Check external service status
- Implement circuit breaker
- Add retry logic with exponential backoff

### **Cause 4: Resource Exhaustion**
**Symptoms:** OOMKilled, CPU throttling  
**Solution:**
```bash
# Check resource usage
kubectl top pods -n chatapp-dev -l app=backend

# Increase resources temporarily
kubectl set resources deployment/backend -n chatapp-dev \
  --limits=cpu=1000m,memory=1Gi \
  --requests=cpu=500m,memory=512Mi
```

---

## ✅ Resolution Checklist

- [ ] Error rate returned to normal (<1%)
- [ ] No recent errors in logs
- [ ] Users can access the application
- [ ] Grafana dashboard shows green health
- [ ] Root cause identified and documented
- [ ] Postmortem created (if critical incident)

---

## 📞 Escalation

**If unable to resolve in 30 minutes:**
- Contact: DevOps Team Lead
- Escalate to: Senior Backend Engineer
- Page: On-call engineer (for production)

---

## 📚 Related Documentation

- [Architecture Overview](../ARCHITECTURE.md)
- [SLI/SLO Definitions](../SLI-SLO-DEFINITION.md)
- [Deployment Procedures](../DEPLOYMENT.md)



