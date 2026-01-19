# Runbooks

**Operational guides for responding to alerts and incidents.**

---

## 📚 Available Runbooks

| Runbook | Alert | Severity | SLO Impact |
|---------|-------|----------|------------|
| [HIGH-ERROR-RATE.md](./HIGH-ERROR-RATE.md) | `ChatappHighErrorRate` | Critical | Direct |
| [HIGH-LATENCY.md](./HIGH-LATENCY.md) | `ChatappHighLatency` | Critical | Direct |
| [SERVICE-DOWN.md](./SERVICE-DOWN.md) | `ChatappServiceDown` | Critical | Complete Outage |

---

## 🎯 How to Use Runbooks

### **When an Alert Fires:**

1. **Click runbook link** in Slack alert notification
2. **Follow investigation steps** in order
3. **Try common solutions** for your symptoms
4. **Check resolution checklist** before closing
5. **Escalate** if unable to resolve in time
6. **Document** findings and update runbook if needed

### **Runbook Structure:**

```
📊 Symptoms          → What you'll see
🔍 Investigation     → How to debug
🛠️ Common Causes    → Known issues & fixes
✅ Resolution        → Checklist before closing
📞 Escalation       → When/who to contact
📚 Related Docs     → Additional resources
```

---

## 🚀 Quick Access Commands

### **Grafana (Metrics & Logs):**
```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Open: http://localhost:3000
```

### **Prometheus (Metrics & Alerts):**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090
```

### **Jaeger (Traces):**
```bash
kubectl port-forward -n default svc/jaeger-query 16686:16686
# Open: http://localhost:16686
```

### **AlertManager (Alert Status):**
```bash
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# Open: http://localhost:9093
```

---

## 🔧 Common Commands

### **Pod Operations:**
```bash
# Check pod status
kubectl get pods -n chatapp-dev -l app=backend

# View logs
kubectl logs -n chatapp-dev -l app=backend --tail=100

# View logs from crashed pod
kubectl logs -n chatapp-dev -l app=backend --previous

# Describe pod (see events)
kubectl describe pod -n chatapp-dev -l app=backend

# Execute command in pod
kubectl exec -n chatapp-dev deployment/backend -- curl localhost:8080/health
```

### **Deployment Operations:**
```bash
# Rollback deployment
kubectl rollout undo deployment/backend -n chatapp-dev

# Check rollout status
kubectl rollout status deployment/backend -n chatapp-dev

# Scale deployment
kubectl scale deployment/backend -n chatapp-dev --replicas=3

# Restart deployment
kubectl rollout restart deployment/backend -n chatapp-dev
```

### **Resource Monitoring:**
```bash
# Pod resource usage
kubectl top pods -n chatapp-dev -l app=backend

# Node resource usage
kubectl top nodes

# Check Karpenter provisioning
kubectl get nodeclaims
```

---

## 🆘 Emergency Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| **Production Outage** | On-Call Engineer | Immediate |
| **Infrastructure** | DevOps Team Lead | 15 min |
| **Application** | Backend Team Lead | 30 min |
| **Database** | Database Team | 30 min |

---

## 📝 Creating New Runbooks

When creating a new runbook, include:

1. ✅ **Alert name** and severity
2. ✅ **Symptoms** users will see
3. ✅ **Step-by-step investigation** guide
4. ✅ **Common causes** and solutions
5. ✅ **Resolution checklist**
6. ✅ **Escalation contacts**
7. ✅ **Copy-paste commands** (no guessing!)

**Template:** Copy an existing runbook and modify.

---

## 📊 Runbook Effectiveness

**Good runbook indicators:**
- ✅ Junior engineer can follow without help
- ✅ Reduces MTTR (Mean Time To Resolution)
- ✅ Copy-paste commands work immediately
- ✅ Updated after each incident

**After every incident:**
1. Review runbook effectiveness
2. Add missing steps
3. Update commands if changed
4. Add new symptoms/causes discovered

---

## 📚 Related Documentation

- [SLI/SLO Definitions](../SLI-SLO-DEFINITION.md)
- [Staff-Level Observability](../STAFF-LEVEL-OBSERVABILITY.md)
- [Architecture Overview](../ARCHITECTURE.md)
- [Alert Configuration](../../grafana-tf/alerts/)



