# Karpenter Resources - Terraform Managed

## Overview

This directory now manages Karpenter EC2NodeClass and NodePool resources via Terraform using `kubernetes_manifest` resources. No manual `kubectl apply` is required.

## Architecture

**Deployment Order**:
1. Karpenter Helm chart installs (via `helm_release.this["karpenter"]`)
2. EC2NodeClass is created (depends on Helm install)
3. NodePool is created (depends on EC2NodeClass)
4. Other workloads can depend on `time_sleep.wait_for_nodepool_ready`

## Files

- **`karpenter-resources.tf`**: Terraform resources for EC2NodeClass and NodePool
- **`variables.tf`**: Contains `karpenter` variable definition with defaults
- **`karpenter.tfvars.example`**: Example configuration (copy to `main.auto.tfvars`)

## Configuration

### Quick Start

Add to `main.auto.tfvars`:

```hcl
karpenter = {
  node_class_name = "default"
  ami_selector_terms = [
    {
      alias = "bottlerocket@latest"
    }
  ]
  node_pool_name = "default"
  node_requirements = [
    {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["spot", "on-demand"]
    },
    {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
    },
    {
      key      = "node.kubernetes.io/instance-type"
      operator = "In"
      values   = ["t3.medium", "t3.large"]
    }
  ]
  consolidation_policy = "WhenEmptyOrUnderutilized"
  consolidate_after    = "30s"
}
```

### Full Configuration Options

See `karpenter.tfvars.example` for all available options:
- AMI selection
- Instance type requirements
- Capacity types (spot/on-demand)
- Node limits (CPU/memory)
- Disruption policies
- Taints and labels

## Migration from Manual kubectl apply

**Before** (manual):
```bash
kubectl apply -f examples/karpenter-ec2nodeclass.yaml
kubectl apply -f examples/karpenter-nodepool.yaml
```

**After** (Terraform):
```bash
terraform init
terraform plan
terraform apply
```

The resources are now managed by Terraform state. No manual kubectl commands needed.

## Verification

After `terraform apply`, verify resources:

```bash
# Check EC2NodeClass
kubectl get ec2nodeclass

# Check NodePool
kubectl get nodepool

# Check Karpenter pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# Check node provisioning (after pods are scheduled)
kubectl get nodes
```

## Dependencies

- Karpenter Helm chart must be installed first
- EKS cluster must be ready
- VPC subnets must have `karpenter.sh/discovery` tags
- Security groups must have `karpenter.sh/discovery` tags

## Troubleshooting

### NodePool not creating nodes

1. Check EC2NodeClass:
   ```bash
   kubectl describe ec2nodeclass default
   ```

2. Check NodePool:
   ```bash
   kubectl describe nodepool default
   ```

3. Check Karpenter logs:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter
   ```

4. Verify subnet tags:
   ```bash
   aws ec2 describe-subnets --filters "Name=tag:karpenter.sh/discovery,Values=tnt-eu-observability-dev-eks"
   ```

### Terraform plan shows changes after apply

This is normal if Karpenter controller modifies the resources. Use lifecycle ignore_changes if needed (not recommended - let Karpenter manage its state).

## Best Practices

1. **Use Bottlerocket AMI**: Security-hardened, minimal OS
2. **Mix spot and on-demand**: Start with `["spot", "on-demand"]` for cost savings
3. **Set reasonable limits**: Prevent runaway node creation
4. **Use consolidation**: `WhenEmptyOrUnderutilized` saves costs
5. **Monitor node creation**: Check logs if nodes don't appear

