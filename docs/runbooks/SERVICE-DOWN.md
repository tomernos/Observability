# Runbook: Service Down

**Alert:** `ChatappServiceDown` / `ChatappNoRequests`  
**Severity:** Critical  
**SLO Impact:** Complete service outage - 0% availability

---

## 📊 Symptoms

- Service health check failing
- No HTTP requests being processed
- Users cannot access the application
- Prometheus shows `up{job="chatapp-backend"} == 0`

---

## 🔍 Investigation Steps

### 1. **Check Pod Status**
```bash
# Check if pods are running
kubectl get pods -n chatapp-dev -l app=backend

# Possible states:
# - Pending: Pod not scheduled
# - CrashLoopBackOff: Pod keeps crashing
# - ImagePullBackOff: Cannot pull container image
# - Running: Pod is up (but may be unhealthy)
```

### 2. **Check Pod Logs**
```bash
# View recent logs
kubectl logs -n chatapp-dev -l app=backend --tail=100

# View logs from crashed pod
kubectl logs -n chatapp-dev -l app=backend --previous

# Follow logs in real-time
kubectl logs -n chatapp-dev -l app=backend -f
```

### 3. **Describe Pod for Events**
```bash
# See detailed pod events
kubectl describe pod -n chatapp-dev -l app=backend

# Look for:
# - Failed health checks
# - OOMKilled (out of memory)
# - Image pull failures
# - Scheduling issues
```

### 4. **Check Service and Endpoints**
```bash
# Verify service exists
kubectl get svc -n chatapp-dev backend

# Check if endpoints are registered
kubectl get endpoints -n chatapp-dev backend

# If no endpoints, pods aren't healthy or labels don't match
```

---

## 🛠️ Common Causes & Solutions

### **Cause 1: Application Crash (CrashLoopBackOff)**
**Symptoms:** 
```
NAME                       READY   STATUS             RESTARTS
backend-xxx-yyy            0/1     CrashLoopBackOff   5
```

**Solution:**
```bash
# Check logs for error
kubectl logs -n chatapp-dev -l app=backend --previous

# Common issues:
# - Missing environment variables
# - Database connection failure
# - Port already in use
# - Application startup error

# Verify configuration
kubectl get configmap -n chatapp-dev
kubectl get secret -n chatapp-dev
kubectl describe deployment backend -n chatapp-dev
```

### **Cause 2: Image Pull Failure (ImagePullBackOff)**
**Symptoms:**
```
NAME                       READY   STATUS             RESTARTS
backend-xxx-yyy            0/1     ImagePullBackOff   0
```

**Solution:**
```bash
# Check image name in deployment
kubectl get deployment backend -n chatapp-dev -o yaml | grep image:

# Verify ECR credentials
kubectl get secret -n chatapp-dev regcred

# If image doesn't exist, check ECR
aws ecr describe-images --repository-name chatapp-backend --region eu-central-1

# Re-deploy with correct image
kubectl set image deployment/backend -n chatapp-dev \
  backend=<ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/chatapp-backend:latest
```

### **Cause 3: Out of Memory (OOMKilled)**
**Symptoms:**
```
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

**Solution:**
```bash
# Increase memory limits
kubectl set resources deployment/backend -n chatapp-dev \
  --limits=memory=1Gi \
  --requests=memory=512Mi

# Monitor memory usage after restart
kubectl top pods -n chatapp-dev -l app=backend
```

### **Cause 4: Failed Health Checks**
**Symptoms:**
```
Readiness probe failed: Get http://10.0.1.5:8080/health: dial tcp 10.0.1.5:8080: connect: connection refused
```

**Solution:**
```bash
# Check if application is listening on correct port
kubectl exec -n chatapp-dev deployment/backend -- netstat -tlnp

# Test health endpoint manually
kubectl exec -n chatapp-dev deployment/backend -- curl localhost:8080/health

# Adjust health check if needed (edit deployment)
kubectl edit deployment backend -n chatapp-dev
```

### **Cause 5: No Nodes Available / Pending Pods**
**Symptoms:**
```
NAME                       READY   STATUS    RESTARTS
backend-xxx-yyy            0/1     Pending   0

Events:
  Warning  FailedScheduling  pod has unbound immediate PersistentVolumeClaims
```

**Solution:**
```bash
# Check node availability
kubectl get nodes

# Check Karpenter provisioning
kubectl get nodeclaims
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Check pod events for scheduling issues
kubectl describe pod -n chatapp-dev -l app=backend | grep -A 10 Events
```

### **Cause 6: Recent Bad Deployment**
**Symptoms:** Service was working, stopped after deployment

**Solution:**
```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n chatapp-dev

# Check rollback status
kubectl rollout status deployment/backend -n chatapp-dev

# Verify pods are running
kubectl get pods -n chatapp-dev -l app=backend
```

---

## ✅ Resolution Checklist

- [ ] Pods are in `Running` state
- [ ] Pods pass health checks (READY = 1/1)
- [ ] Service endpoints are registered
- [ ] Prometheus shows `up{job="chatapp-backend"} == 1`
- [ ] HTTP requests are being processed
- [ ] Users can access the application
- [ ] Logs show no errors
- [ ] Root cause identified and documented

---

## 🚨 Emergency Actions

### **Immediate Impact Reduction:**
```bash
# Scale up replicas (if some pods are working)
kubectl scale deployment/backend -n chatapp-dev --replicas=5

# Restart deployment (if needed)
kubectl rollout restart deployment/backend -n chatapp-dev

# Force rollback if recent deployment
kubectl rollout undo deployment/backend -n chatapp-dev
```

### **Check Dependencies:**
```bash
# Database connectivity
kubectl exec -n chatapp-dev deployment/backend -- curl -v db-endpoint:5432

# Redis/Cache connectivity (if applicable)
kubectl exec -n chatapp-dev deployment/backend -- curl -v redis:6379

# External API connectivity
kubectl exec -n chatapp-dev deployment/backend -- curl -v https://external-api.com
```

---

## 📞 Escalation

**CRITICAL ALERT - Escalate immediately if:**
- Production environment affected
- Cannot resolve in 15 minutes
- Complete service outage

**Contacts:**
- **DevOps Team Lead** (Immediate)
- **Backend Team Lead** (Application issues)
- **Platform Team** (Infrastructure issues)

---

## 📝 Post-Incident

After resolving, create a postmortem:
1. Timeline of events
2. Root cause analysis
3. Impact assessment
4. Action items to prevent recurrence
5. Update this runbook if needed

---

## 📚 Related Documentation

- [Deployment Procedures](../DEPLOYMENT.md)
- [Health Check Configuration](../HEALTH-CHECKS.md)
- [Rollback Procedures](../ROLLBACK.md)
- [SLI/SLO Definitions](../SLI-SLO-DEFINITION.md)



