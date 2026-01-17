#!/bin/bash
# Verify Prometheus is scraping chatapp-dev metrics

set -e

NAMESPACE="chatapp-dev"
PROMETHEUS_NS="monitoring"

echo "=== Prometheus Integration Verification ==="
echo ""

# 1. Check ServiceMonitor exists
echo "1. Checking ServiceMonitor..."
if kubectl get servicemonitor -n ${NAMESPACE} 2>/dev/null | grep -q backend; then
    echo "✅ ServiceMonitor exists"
    kubectl get servicemonitor -n ${NAMESPACE}
else
    echo "❌ ServiceMonitor NOT FOUND"
    echo "   Fix: Enable monitoring in Helm values and redeploy"
    exit 1
fi

# 2. Check backend service
echo ""
echo "2. Checking backend service..."
if kubectl get svc -n ${NAMESPACE} chatapp-backend &>/dev/null; then
    echo "✅ Backend service exists"
else
    echo "❌ Backend service NOT FOUND"
    exit 1
fi

# 3. Test metrics endpoint
echo ""
echo "3. Testing /metrics endpoint..."
POD=$(kubectl get pod -n ${NAMESPACE} -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD" ]; then
    if kubectl exec -n ${NAMESPACE} ${POD} -- curl -s http://localhost:5000/metrics 2>/dev/null | grep -q "http_requests_total"; then
        echo "✅ Metrics endpoint working"
    else
        echo "⚠️  Metrics endpoint not responding (pod might be starting)"
    fi
else
    echo "⚠️  No backend pods found"
fi

# 4. Check Prometheus targets
echo ""
echo "4. Checking Prometheus targets..."
echo "   (Port-forward Prometheus to check: kubectl port-forward -n ${PROMETHEUS_NS} svc/prometheus-operated 9090:9090)"
echo "   Then visit: http://localhost:9090/targets"
echo "   Look for: chatapp-backend endpoints with Status: UP"

# 5. Test Prometheus query
echo ""
echo "5. To test Prometheus query:"
echo "   kubectl port-forward -n ${PROMETHEUS_NS} svc/prometheus-operated 9090:9090"
echo "   Then query: http_requests_total{namespace=\"${NAMESPACE}\"}"

echo ""
echo "=== Next Steps ==="
echo "1. If ServiceMonitor missing: Enable backend.monitoring.enabled=true in values-dev.yaml"
echo "2. Redeploy: helm upgrade --install chatapp ./helm-chart -n ${NAMESPACE} -f values-dev.yaml"
echo "3. Wait 30s for Prometheus discovery"
echo "4. Check Prometheus targets (should show UP status)"

