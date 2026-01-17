# Service Level Indicators (SLIs) & Service Level Objectives (SLOs)
## ChatApp Platform - Staff-Level Observability

> **Document Purpose:** Define measurable reliability targets for ChatApp platform services  
> **Owner:** Platform Engineering Team  
> **Review Cycle:** Quarterly  
> **Last Updated:** 2026-01-17

---

## 📊 Executive Summary

This document defines the **Service Level Indicators (SLIs)**, **Service Level Objectives (SLOs)**, and **Service Level Agreements (SLAs)** for the ChatApp platform. These metrics guide our reliability engineering efforts and inform our incident response priorities.

---

## 🎯 Core SLI Definitions

### 1. **Availability SLI**
**Definition:** Percentage of time the service is reachable and responding to requests

```promql
# Prometheus Query
avg(up{job="chatapp-backend", namespace="chatapp-dev"}) * 100
```

**Target SLO:** 99.99% (Four Nines)
- **Monthly Downtime Budget:** 4.38 minutes
- **Measurement Window:** 30-day rolling
- **Alert Threshold:** < 99.9% over 5 minutes

**Why This Matters:**  
Availability is the foundational metric. If the service is down, no other metrics matter.

---

### 2. **Request Success Rate SLI**
**Definition:** Percentage of HTTP requests that complete successfully (2xx status)

```promql
# Prometheus Query
sum(rate(flask_http_request_total{namespace="chatapp-dev", status=~"2.."}[5m])) 
/ 
sum(rate(flask_http_request_total{namespace="chatapp-dev"}[5m])) * 100
```

**Target SLO:** 99.9% (Three Nines)
- **Monthly Error Budget:** 43.8 minutes of errors
- **Measurement Window:** 7-day rolling
- **Alert Threshold:** < 99.5% over 10 minutes

**Error Budget Policy:**
- ✅ **Within Budget:** Deploy new features, optimize, experiment
- ⚠️ **50% Consumed:** Slow down releases, focus on reliability
- 🔴 **Exceeded:** **FREEZE** all non-critical deployments, incident review required

---

### 3. **Latency SLI (P95)**
**Definition:** 95th percentile of request duration in milliseconds

```promql
# Prometheus Query
histogram_quantile(0.95, 
  sum(rate(flask_http_request_duration_seconds_bucket{namespace="chatapp-dev"}[5m])) by (le)
) * 1000
```

**Target SLO:** < 200ms (P95)
- **Measurement Window:** 5-minute rolling
- **Alert Threshold:** > 300ms for 5 minutes
- **Critical Threshold:** > 500ms for 2 minutes

**Latency Budget Breakdown:**
| Percentile | Target | Warning | Critical |
|------------|--------|---------|----------|
| P50        | < 50ms | 100ms   | 150ms    |
| P95        | < 200ms| 300ms   | 500ms    |
| P99        | < 500ms| 750ms   | 1000ms   |

---

### 4. **Error Rate SLI**
**Definition:** Number of 5xx errors per second

```promql
# Prometheus Query
sum(rate(flask_http_request_total{namespace="chatapp-dev", status=~"5.."}[5m]))
```

**Target SLO:** < 0.1 errors/sec (or 0.01% error rate)
- **Measurement Window:** 5-minute rolling
- **Alert Threshold:** > 0.5 errors/sec for 5 minutes
- **Page Threshold:** > 1 error/sec for 2 minutes

---

## 📋 SLA Commitments (Customer-Facing)

### Production Environment
- **Availability:** 99.9% uptime (monthly)
- **Response Time:** P95 < 300ms
- **Support Response:** < 15 minutes for P1 incidents

### Development/Staging Environments
- **Availability:** Best effort (no SLA)
- **Purpose:** Testing, experimentation, feature validation

---

## 🚨 Alert Severity Levels

### **P1 - Critical (Page Immediately)**
- Availability < 99% for > 5 minutes
- Error rate > 1/sec for > 2 minutes
- P95 latency > 500ms for > 2 minutes
- **Action:** Page on-call engineer, war room if not resolved in 15 min

### **P2 - High (Alert)**
- Availability < 99.9% for > 10 minutes
- Error rate > 0.5/sec for > 5 minutes
- P95 latency > 300ms for > 5 minutes
- **Action:** Slack alert, investigate within 30 minutes

### **P3 - Warning (Monitor)**
- SLO burn rate indicates budget exhaustion risk
- Trending toward threshold violations
- **Action:** Create ticket, investigate during business hours

---

## 📈 Observability Triad Integration

### **Metrics** (Prometheus)
- Real-time SLI calculation
- Historical trending
- Alert rule evaluation

### **Traces** (Jaeger)
- Request flow analysis for latency issues
- Error investigation and root cause
- Dependency mapping

### **Logs** (Loki)
- Detailed error context
- Audit trail
- Debug information

### **Cross-Correlation**
```
Metric Alert → Trace ID → Log Context
      ↓            ↓           ↓
   "What"      "Where"      "Why"
```

---

## 🔄 Review & Iteration Process

### Quarterly SLO Review
1. **Analyze:** Review SLI data, incident patterns
2. **Adjust:** Modify SLOs based on business needs
3. **Communicate:** Share changes with stakeholders
4. **Update:** Adjust alerts, dashboards, runbooks

### Error Budget Review (Monthly)
- Calculate error budget consumption
- Identify top contributors to budget burn
- Prioritize reliability improvements

---

## 📚 Related Documents

- [Runbook: SLO Violation Response](./runbooks/slo-violation-response.md)
- [Architecture: Observability Stack](./OBSERVABILITY_ARCHITECTURE.md)
- [Dashboard: Application Observability](https://grafana.tomercompany.com/d/chatapp-app-obs)

---

## 🎓 Staff-Level Considerations

### Why These SLOs?
- **Business Alignment:** Targets balance user experience with development velocity
- **Measurable:** Clear, automatable metrics
- **Actionable:** Direct link to engineering decisions
- **Realistic:** Based on system capabilities and historical data

### SLO vs SLA
- **SLO (Objective):** Internal target for engineering teams
- **SLA (Agreement):** External commitment to customers with penalties

### Error Budgets
Error budgets give teams **permission to fail** within acceptable limits. This encourages:
- Innovation and experimentation
- Rapid feature deployment
- Calculated risk-taking

When budgets are exceeded, we shift focus to **reliability work** until stability is restored.

---

**Document Version:** 1.0  
**Next Review:** 2026-04-17  
**Maintainer:** Platform Engineering Team

