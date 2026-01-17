#!/bin/bash
# Deploy Alerting System
# Usage: ./deploy-alerts.sh [slack-webhook-url]

set -e

SLACK_WEBHOOK_URL="${1:-}"

echo "=== Alerting Deployment Script ==="
echo ""

# Step 1: Deploy Alert Rules
echo "📋 Step 1: Deploying Alert Rules..."
cd Observability/grafana-tf

if [ ! -f "terraform.tfstate" ]; then
    echo "⚠️  Terraform not initialized. Running terraform init..."
    terraform init
fi

echo "Applying alert rules..."
terraform apply -auto-approve

echo "✅ Alert rules deployed"
echo ""

# Step 2: Configure Alertmanager
echo "📋 Step 2: Configuring Alertmanager..."

if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "⚠️  No Slack webhook URL provided"
    echo "   Please provide webhook URL:"
    echo "   ./deploy-alerts.sh https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    echo ""
    echo "   Or set it manually in alertmanager-values.yaml"
    exit 1
fi

cd ../infra-tf

echo "Updating monitoring stack with Alertmanager config..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/prometheus/values.yaml \
  -f helm/prometheus/alertmanager-values.yaml \
  --set alertmanager.config.global.slack_api_url="${SLACK_WEBHOOK_URL}" \
  --wait \
  --timeout 10m

echo "✅ Alertmanager configured"
echo ""

# Step 3: Verify
echo "📋 Step 3: Verifying deployment..."
echo ""
echo "Checking PrometheusRule..."
kubectl get prometheusrule -A | grep chatapp || echo "⚠️  PrometheusRule not found (may take a moment)"

echo ""
echo "Checking Alertmanager..."
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Port-forward Alertmanager: kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093"
echo "2. Visit: http://localhost:9093"
echo "3. Test alerts by simulating errors in dev"
echo ""
echo "Full guide: Observability/docs/ALERTING_QUICK_START.md"

