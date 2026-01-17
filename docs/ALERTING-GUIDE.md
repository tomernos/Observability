# Alerting Guide - Staff-Level Incident Response

**Complete guide to our production-ready alerting system.**

---

## 🎯 Alerting Architecture Overview

```
┌─────────────────┐
│  Prometheus     │ ──► Scrapes metrics from apps
│  (Metrics)      │     Evaluates alert rules
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AlertManager   │ ──► Routes alerts to channels
│  (Alert Router) │     Groups & deduplicates
└────────┬────────┘     Applies inhibition rules
         │
         ├──────────────┬──────────────┬─────────────┐
         ▼              ▼              ▼             ▼
    Slack          Slack Dev      Slack Prod    Email (opt)
   #alerts         #alerts-dev    #alerts-prod
```

---

## 📊 Alert Types & Coverage

| Alert | Severity | Threshold | SLO Impact | Runbook |
|-------|----------|-----------|------------|---------|
| **ChatappServiceDown** | Critical | 2min down | Complete | [SERVICE-DOWN](./runbooks/SERVICE-DOWN.md) |
| **ChatappHighErrorRate** | Critical | >5% errors | Direct | [HIGH-ERROR-RATE](./runbooks/HIGH-ERROR-RATE.md) |
| **ChatappWarningErrorRate** | Warning | >1% errors | Partial | [HIGH-ERROR-RATE](./runbooks/HIGH-ERROR-RATE.md) |
| **ChatappHighLatency** | Critical | P95 >1s | Direct | [HIGH-LATENCY](./runbooks/HIGH-LATENCY.md) |
| **ChatappWarningLatency** | Warning | P95 >0.5s | Partial | [HIGH-LATENCY](./runbooks/HIGH-LATENCY.md) |
| **ChatappNoRequests** | Warning | 0 req/10min | Potential | [SERVICE-DOWN](./runbooks/SERVICE-DOWN.md) |
| **ChatappHighMemoryUsage** | Warning | >90% | Indirect | Standard troubleshooting |
| **ChatappHighCPUUsage** | Warning | >80% | Indirect | Standard troubleshooting |

---

## 🔔 Alert Routing Strategy

### **By Severity:**

```yaml
Critical (immediate action):
  → #alerts-critical
  → Repeat every 1 hour
  → Include runbook link
  → Page on-call (if configured)

Warning (monitor closely):
  → #alerts
  → Repeat every 6 hours
  → Background investigation
```

### **By Environment:**

```yaml
Production:
  → #alerts-prod
  → High priority
  → Immediate response

Staging:
  → #alerts-staging
  → Medium priority
  → Business hours response

Dev:
  → #alerts-dev
  → Low priority
  → Optional response
```

---

## 🔇 Inhibition Rules (Reduce Noise)

**Smart alert suppression** - If a critical alert is firing, suppress related lower-priority alerts.

### **Rule 1: Service Down suppresses everything else**
```yaml
If: Service is DOWN
Then: Suppress latency & error rate alerts
Why: No point alerting on errors if service is down
```

**Example:**
- `ChatappServiceDown` fires (CRITICAL)
- `ChatappHighErrorRate` suppressed (redundant)
- `ChatappHighLatency` suppressed (redundant)

### **Rule 2: Critical suppresses Warning**
```yaml
If: Critical alert firing
Then: Suppress warning alert of same type
Why: Already aware of the issue
```

**Example:**
- `ChatappHighErrorRate` fires (>5%)
- `ChatappWarningErrorRate` suppressed (already covered)

---

## 📈 Alert Grouping

Alerts are grouped by:
- `alertname` - Same alert type
- `app` - Same application
- `namespace` - Same environment
- `severity` - Same priority

**Benefit:** Receive ONE notification for multiple similar alerts.

---

## ⏱️ Alert Timing

| Phase | Duration | Purpose |
|-------|----------|---------|
| **Group Wait** | 10s | Wait for similar alerts before sending |
| **Group Interval** | 10s | Wait before adding new alerts to existing group |
| **Repeat Interval** | 12h (default) | Re-send if still firing |
| **Repeat (Critical)** | 1h | More frequent for urgent issues |
| **Repeat (Warning)** | 6h | Less frequent for non-urgent |

---

## 🚀 Quick Access

### **Check Active Alerts:**
```bash
# Port-forward AlertManager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Open: http://localhost:9093
# View: Active alerts, silences, inhibitions
```

### **Check Alert Rules:**
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Open: http://localhost:9090/alerts
# View: All alert rules and their state
```

---

## 🔧 Alert Configuration Files

```
Observability/
├── infra-tf/helm/prometheus/
│   └── alertmanager-values.yaml    # AlertManager routing & receivers
├── grafana-tf/alerts/
│   └── chatapp-alerts.yaml         # Prometheus alert rules
└── docs/runbooks/
    ├── HIGH-ERROR-RATE.md          # Error troubleshooting
    ├── HIGH-LATENCY.md             # Performance troubleshooting
    ├── SERVICE-DOWN.md             # Availability troubleshooting
    └── README.md                   # Runbook guide
```

---

## 📝 Responding to Alerts

### **1. Receive Alert in Slack:**
```
🚨 CRITICAL: ChatappHighErrorRate

Alert: ChatappHighErrorRate
App: chatapp
Namespace: chatapp-prod
Severity: critical

Description: Error rate is 8.5% (threshold: 5%) for chatapp-prod
Runbook: [link]
```

### **2. Acknowledge & Investigate:**
- React with 👀 emoji (investigating)
- Click runbook link
- Follow investigation steps
- Check Grafana dashboard
- Search Jaeger traces
- Review Loki logs

### **3. Resolve & Document:**
- Apply fix from runbook
- Verify resolution in Grafana
- React with ✅ emoji (resolved)
- Write postmortem if needed
- Update runbook if gaps found

---

## 🔕 Silencing Alerts

**Use silences for planned maintenance:**

```bash
# Access AlertManager UI
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Create silence:
# - Matcher: namespace=chatapp-dev, alertname=ChatappServiceDown
# - Duration: 2 hours
# - Comment: "Deploying new version"
```

**Best Practices:**
- ✅ Use short durations (1-2 hours max)
- ✅ Add detailed comment with reason
- ✅ Announce in Slack before silencing
- ❌ Never silence production alerts indefinitely

---

## 📊 Alert Quality Metrics

**Track these to improve alerting:**

| Metric | Target | Current |
|--------|--------|---------|
| **Alert-to-Incident Ratio** | >0.8 | TBD |
| **False Positive Rate** | <10% | TBD |
| **MTTR (Mean Time to Resolution)** | <30min | TBD |
| **Runbook Usage Rate** | >90% | TBD |

**After each incident, ask:**
1. Did alert fire at right time?
2. Was severity appropriate?
3. Did runbook help?
4. Any false positives?

---

## 🎓 Staff-Level Practices

### **✅ What Makes This Staff-Level:**

1. **SLO-Aware Alerts**
   - Alerts tied to SLIs (availability, latency, errors)
   - Thresholds based on SLO targets

2. **Actionable Runbooks**
   - Copy-paste commands
   - Clear investigation paths
   - Root cause → solution mapping

3. **Intelligent Routing**
   - By severity (critical vs warning)
   - By environment (prod vs dev)
   - Inhibition rules reduce noise

4. **Operational Maturity**
   - Alert grouping & deduplication
   - Tuned repeat intervals
   - Silence capabilities

5. **Feedback Loop**
   - Postmortems improve runbooks
   - Alert tuning based on data
   - Continuous improvement

---

## 🔗 Integration with Observability Stack

```
Alert fires in Prometheus
    ↓
Routed by AlertManager
    ↓
Investigate in Grafana:
    ├─► Metrics: Identify scope & severity
    ├─► Traces: Find slow/failing requests  (Jaeger)
    └─► Logs: See error details            (Loki)
    ↓
Follow runbook
    ↓
Resolve issue
    ↓
Update postmortem & runbook
```

---

## 📚 Next Steps

To further improve alerting:

1. **Add More Runbooks**
   - High memory usage
   - Database connection issues
   - External API failures

2. **Implement On-Call Rotation**
   - PagerDuty integration
   - Escalation policies
   - On-call schedule

3. **Add Alert Testing**
   - Chaos engineering
   - Alert simulation
   - Validate runbooks work

4. **Track Alert Metrics**
   - Dashboard for alert effectiveness
   - Alert fatigue monitoring
   - MTTR tracking

---

## 📖 Related Documentation

- [SLI/SLO Definitions](./SLI-SLO-DEFINITION.md)
- [Staff-Level Observability](./STAFF-LEVEL-OBSERVABILITY.md)
- [Runbooks](./runbooks/)
- [Grafana Dashboards](../grafana-tf/dashboards/)

