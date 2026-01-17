#!/bin/bash
# Quick script to check OpenTelemetry status in backend pod

set -e

NAMESPACE="chatapp-dev"
LABEL="app.kubernetes.io/name=backend"

echo "=== OpenTelemetry Diagnostic ==="
echo ""

# Get pod name
POD=$(kubectl get pods -n $NAMESPACE -l $LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
    echo "❌ No backend pod found"
    exit 1
fi

echo "Backend pod: $POD"
echo ""

echo "1. Checking OpenTelemetry packages..."
kubectl exec -n $NAMESPACE $POD -- pip list 2>/dev/null | grep -i opentelemetry || echo "  ❌ OpenTelemetry packages not found"
echo ""

echo "2. Checking environment variables..."
kubectl exec -n $NAMESPACE $POD -- env 2>/dev/null | grep OTEL || echo "  ❌ No OTEL env vars found"
echo ""

echo "3. Testing OpenTelemetry import..."
kubectl exec -n $NAMESPACE $POD -- python -c "from opentelemetry import trace; print('✅ OpenTelemetry import OK')" 2>&1 || echo "  ❌ Import failed"
echo ""

echo "4. Checking backend logs for OpenTelemetry..."
kubectl logs -n $NAMESPACE $POD 2>&1 | grep -i "opentelemetry\|otel\|trace\|instrumentation" | tail -5 || echo "  ⚠️  No OTEL messages in logs"
echo ""

echo "5. Checking for errors in logs..."
kubectl logs -n $NAMESPACE $POD 2>&1 | grep -i "error\|exception\|failed\|warning" | grep -i "otel\|trace" | tail -5 || echo "  ✅ No OTEL errors found"
echo ""

echo "6. Testing OTEL Collector connectivity..."
kubectl exec -n $NAMESPACE $POD -- sh -c "nc -zv otel-collector.monitoring.svc.cluster.local 4317 2>&1 || echo 'Cannot reach OTEL Collector'" || echo "  ⚠️  Cannot test connectivity"
echo ""

echo "=== Diagnostic Complete ==="


