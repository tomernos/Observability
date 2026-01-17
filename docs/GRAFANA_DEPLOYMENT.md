# Grafana Deployment Guide

## 🎯 Quick Steps

### 1. Deploy Monitoring Stack (Grafana + Prometheus)

```bash
cd Observability/infra-tf

# Ensure kubeconfig is configured
aws eks update-kubeconfig --region eu-central-1 --name tnt-eu-chatapp-dev-eks

# Deploy monitoring stack via Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f helm/monitoring/values.yaml \
  --wait \
  --timeout 10m
```

### 2. Get Grafana LoadBalancer URL

```bash
# Wait for LoadBalancer to be ready (takes 2-5 minutes)
kubectl get svc -n monitoring grafana -w

# Get the URL
kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or get full URL
GRAFANA_URL=$(kubectl get svc -n monitoring grafana -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}')
echo $GRAFANA_URL
```

### 3. Update Grafana Terraform Config

Edit `Observability/grafana-tf/main.auto.tfvars`:

```hcl
grafana_url = "http://<LOADBALANCER_HOSTNAME>"
```

Or use the output:
```bash
cd Observability/grafana-tf
# Update grafana_url in main.auto.tfvars with the URL from step 2
```

### 4. Verify Grafana is Accessible

```bash
# Test connectivity
curl http://<LOADBALANCER_HOSTNAME>/api/health

# Should return: {"commit":"...","database":"ok","version":"..."}
```

### 5. Deploy Dashboards

```bash
cd Observability/grafana-tf
terraform init
terraform plan
terraform apply
```

## 🔍 Troubleshooting

### LoadBalancer Not Ready
```bash
# Check service status
kubectl describe svc -n monitoring grafana

# Check pods
kubectl get pods -n monitoring | grep grafana

# Check logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### DNS Resolution Issues
- LoadBalancer takes 2-5 minutes to provision
- Wait for `EXTERNAL-IP` to be assigned
- Use `kubectl port-forward` for local testing:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Then use: http://localhost:3000
```

### Port-Forward Alternative (Quick Test)

If LoadBalancer isn't ready, use port-forward:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80

# Update grafana_url in terraform.tfvars:
grafana_url = "http://localhost:3000"
```

## 📋 Checklist

- [ ] Monitoring stack deployed
- [ ] Grafana service has EXTERNAL-IP
- [ ] Grafana URL accessible (curl test)
- [ ] Updated `grafana_url` in terraform.tfvars
- [ ] Terraform can connect to Grafana
- [ ] Dashboards deployed successfully

