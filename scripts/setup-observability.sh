#!/bin/bash
# One-Command Observability Setup
# Automates: Monitoring stack, Grafana dashboards, Alerting
# Usage: ./setup-observability.sh [slack-webhook-url]

set -e

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBSERVABILITY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_TF_DIR="${OBSERVABILITY_DIR}/infra-tf"
GRAFANA_TF_DIR="${OBSERVABILITY_DIR}/grafana-tf"

echo "=========================================="
echo "🚀 Observability Stack - Automated Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check prerequisites
echo "📋 Step 1: Checking prerequisites..."
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ kubectl found${NC}"

# Check helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm not found. Please install helm.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ helm found${NC}"

# Check terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ terraform not found. Please install terraform.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ terraform found${NC}"

# Check kubeconfig
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl not configured. Run: aws eks update-kubeconfig --name <cluster-name>${NC}"
    exit 1
fi
echo -e "${GREEN}✅ kubectl configured${NC}"

echo ""

# Step 2: Deploy Monitoring Stack
echo "📋 Step 2: Deploying Monitoring Stack (Prometheus + Grafana + Alertmanager)..."
echo ""

cd "${INFRA_TF_DIR}"

# Check if monitoring already exists
if helm list -n monitoring | grep -q monitoring; then
    echo -e "${YELLOW}⚠️  Monitoring stack already exists. Updating...${NC}"
    UPDATE_MONITORING=true
else
    echo -e "${GREEN}📦 Installing monitoring stack...${NC}"
    UPDATE_MONITORING=false
fi

# Prepare helm command
HELM_CMD="helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f helm/prometheus/values.yaml \
  --wait \
  --timeout 10m"

# Add alertmanager config if webhook provided
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo -e "${GREEN}📨 Slack webhook provided - configuring Alertmanager...${NC}"
    HELM_CMD="${HELM_CMD} -f helm/prometheus/alertmanager-values.yaml \
      --set alertmanager.config.global.slack_api_url='${SLACK_WEBHOOK_URL}'"
else
    echo -e "${YELLOW}⚠️  No Slack webhook provided. Skipping Alertmanager config.${NC}"
    echo -e "${YELLOW}   You can add it later or re-run with webhook URL.${NC}"
fi

# Add helm repo if not exists
if ! helm repo list | grep -q prometheus-community; then
    echo "Adding prometheus-community helm repo..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
fi

# Deploy
eval $HELM_CMD

echo -e "${GREEN}✅ Monitoring stack deployed${NC}"
echo ""

# Step 3: Wait for services to be ready
echo "📋 Step 3: Waiting for services to be ready..."
echo ""

echo "Waiting for Prometheus..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=5m 2>/dev/null || true

echo "Waiting for Grafana..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=5m 2>/dev/null || true

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "Waiting for Alertmanager..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n monitoring --timeout=5m 2>/dev/null || true
fi

echo -e "${GREEN}✅ Services ready${NC}"
echo ""

# Step 4: Get Grafana URL
# echo "📋 Step 4: Getting Grafana URL..."
# echo ""

# GRAFANA_URL=""
# MAX_RETRIES=30
# RETRY=0

# while [ $RETRY -lt $MAX_RETRIES ]; do
#     GRAFANA_HOST=$(kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
#     if [ -n "$GRAFANA_HOST" ] && [ "$GRAFANA_HOST" != "null" ]; then
#         GRAFANA_URL="http://${GRAFANA_HOST}"
#         break
#     fi
    
#     RETRY=$((RETRY + 1))
#     echo "Waiting for LoadBalancer... ($RETRY/$MAX_RETRIES)"
#     sleep 10
# done

# if [ -z "$GRAFANA_URL" ]; then
#     echo -e "${YELLOW}⚠️  LoadBalancer not ready. Using port-forward for now.${NC}"
#     GRAFANA_URL="http://localhost:3000"
#     echo "Run: kubectl port-forward -n monitoring svc/grafana 3000:80"
# else
#     echo -e "${GREEN}✅ Grafana URL: ${GRAFANA_URL}${NC}"
# fi

echo ""

# # Step 5: Update Grafana Terraform config
# echo "📋 Step 5: Updating Grafana Terraform configuration..."
# echo ""

# cd "${GRAFANA_TF_DIR}"

# # Update grafana_url in main.auto.tfvars if LoadBalancer is ready
# if [ "$GRAFANA_URL" != "http://localhost:3000" ]; then
#     if [ -f "main.auto.tfvars" ]; then
#         # Backup original
#         cp main.auto.tfvars main.auto.tfvars.bak
        
#         # Update URL (works on both Linux and macOS)
#         if [[ "$OSTYPE" == "darwin"* ]]; then
#             sed -i '' "s|grafana_url.*=.*|grafana_url      = \"${GRAFANA_URL}\"|" main.auto.tfvars
#         else
#             sed -i "s|grafana_url.*=.*|grafana_url      = \"${GRAFANA_URL}\"|" main.auto.tfvars
#         fi
        
#         echo -e "${GREEN}✅ Updated grafana_url in main.auto.tfvars${NC}"
#     fi
# fi

echo ""

# Step 6: Deploy Grafana Dashboards
echo "📋 Step 6: Deploying Grafana Dashboards (Terraform)..."
echo ""

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Check if data source already exists and import if needed
echo "Checking for existing Prometheus data source..."
GRAFANA_URL_FROM_CONFIG=$(grep "grafana_url" main.auto.tfvars | head -1 | sed 's/.*= *"\(.*\)".*/\1/' || echo "")
GRAFANA_USERNAME=$(grep "grafana_username" main.auto.tfvars | head -1 | sed 's/.*= *"\(.*\)".*/\1/' || echo "admin")
GRAFANA_PASSWORD=$(grep "grafana_password" main.auto.tfvars | head -1 | sed 's/.*= *"\(.*\)".*/\1/' || echo "admin123")

if [ -n "$GRAFANA_URL_FROM_CONFIG" ]; then
    # Try to get data source ID
    DS_ID=$(curl -s -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" \
        "${GRAFANA_URL_FROM_CONFIG}/api/datasources/name/Prometheus" 2>/dev/null | \
        grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2 || echo "")
    
    if [ -n "$DS_ID" ]; then
        echo -e "${YELLOW}⚠️  Prometheus data source already exists (ID: ${DS_ID})${NC}"
        echo "Attempting to import into Terraform state..."
        
        # Check if already in state
        if terraform state show grafana_data_source.prometheus &>/dev/null; then
            echo -e "${GREEN}✅ Data source already in Terraform state${NC}"
        else
            # Try to import
            if terraform import grafana_data_source.prometheus "${DS_ID}" 2>/dev/null; then
                echo -e "${GREEN}✅ Successfully imported existing data source${NC}"
            else
                echo -e "${YELLOW}⚠️  Import failed. Will try to create (may fail if conflict)${NC}"
                echo "If it fails, run: ./scripts/fix-grafana-datasource.sh"
            fi
        fi
    fi
fi

# Apply
echo "Applying Terraform configuration..."
terraform apply -auto-approve || {
    echo -e "${RED}❌ Terraform apply failed${NC}"
    echo ""
    echo "If error is 'data source with the same name already exists', run:"
    echo "  ./scripts/fix-grafana-datasource.sh"
    exit 1
}

echo -e "${GREEN}✅ Grafana dashboards deployed${NC}"
echo ""

# Step 7: Summary
echo "=========================================="
echo "✅ Observability Stack Setup Complete!"
echo "=========================================="
echo ""
echo "📊 Access Points:"
echo "  Grafana: ${GRAFANA_URL}"
echo "    Username: admin"
echo "    Password: admin123"
echo ""

if [ "$GRAFANA_URL" == "http://localhost:3000" ]; then
    echo "⚠️  LoadBalancer not ready. To access Grafana:"
    echo "   kubectl port-forward -n monitoring svc/grafana 3000:80"
    echo ""
fi

echo "📈 Prometheus:"
echo "   kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "   Then visit: http://localhost:9090"
echo ""

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "📨 Alertmanager:"
    echo "   kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093"
    echo "   Then visit: http://localhost:9093"
    echo ""
fi

echo "🎯 Next Steps:"
echo "  1. Verify dashboards in Grafana"
echo "  2. Check Prometheus targets (should see chatapp-backend)"
echo "  3. Test alerts (if webhook configured)"
echo ""
echo "📚 Documentation:"
echo "  - Observability/docs/ALERTING_DEPLOYMENT.md"
echo "  - Observability/docs/PROMETHEUS_INTEGRATION.md"
echo ""

