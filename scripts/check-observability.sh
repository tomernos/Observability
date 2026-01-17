#!/bin/bash
# Check Observability Stack Status
# Quick health check of all components

set -e

echo "=========================================="
echo "🔍 Observability Stack - Health Check"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Monitoring Namespace
echo "📋 Checking Monitoring Namespace..."
if kubectl get namespace monitoring &>/dev/null; then
    echo -e "${GREEN}✅ monitoring namespace exists${NC}"
else
    echo -e "${RED}❌ monitoring namespace not found${NC}"
    exit 1
fi
echo ""

# Check Prometheus
echo "📋 Checking Prometheus..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ Prometheus running${NC}"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
else
    echo -e "${RED}❌ Prometheus not running${NC}"
fi
echo ""

# Check Grafana
echo "📋 Checking Grafana..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ Grafana running${NC}"
    GRAFANA_URL=$(kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$GRAFANA_URL" ] && [ "$GRAFANA_URL" != "null" ]; then
        echo -e "${GREEN}   URL: http://${GRAFANA_URL}${NC}"
    else
        echo -e "${YELLOW}   LoadBalancer not ready. Use port-forward.${NC}"
    fi
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
else
    echo -e "${RED}❌ Grafana not running${NC}"
fi
echo ""

# Check Alertmanager
echo "📋 Checking Alertmanager..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ Alertmanager running${NC}"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager
else
    echo -e "${YELLOW}⚠️  Alertmanager not running (may not be configured)${NC}"
fi
echo ""

# Check ServiceMonitors
echo "📋 Checking ServiceMonitors..."
SERVICEMONITORS=$(kubectl get servicemonitor -A --no-headers 2>/dev/null | wc -l)
if [ "$SERVICEMONITORS" -gt 0 ]; then
    echo -e "${GREEN}✅ Found ${SERVICEMONITORS} ServiceMonitor(s)${NC}"
    kubectl get servicemonitor -A
else
    echo -e "${YELLOW}⚠️  No ServiceMonitors found${NC}"
fi
echo ""

# Check PrometheusRules
echo "📋 Checking PrometheusRules..."
RULES=$(kubectl get prometheusrule -A --no-headers 2>/dev/null | wc -l)
if [ "$RULES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found ${RULES} PrometheusRule(s)${NC}"
    kubectl get prometheusrule -A
else
    echo -e "${YELLOW}⚠️  No PrometheusRules found${NC}"
fi
echo ""

# Check Prometheus Targets
echo "📋 Checking Prometheus Targets..."
echo "   (Run: kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090)"
echo "   Then visit: http://localhost:9090/targets"
echo ""

echo "=========================================="
echo "✅ Health Check Complete"
echo "=========================================="

