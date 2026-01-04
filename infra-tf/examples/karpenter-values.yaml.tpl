# Karpenter Helm Values Template
# This file contains the Helm values for Karpenter deployment
# Variables will be interpolated by Terraform
#
# REQUIRED PLACEHOLDERS (must be provided by Terraform templatefile()):
#   - cluster_name: EKS cluster name (e.g., "tnt-eu-observability-dev-eks")
#   - cluster_endpoint: EKS cluster API endpoint URL
#   - interruption_queue: SQS queue name for spot instance interruption handling
#   - pod_identity_association_arn: ARN of the EKS Pod Identity Association for Karpenter service account
#
# Usage in Terraform:
#   templatefile("${path.module}/examples/karpenter-values.yaml.tpl", {
#     cluster_name                = module.eks.cluster_name
#     cluster_endpoint            = module.eks.cluster_endpoint
#     interruption_queue          = module.karpenter.queue_name
#     pod_identity_association_arn = module.karpenter.pod_identity_association_arn
#   })

settings:
  # Cluster identification - CRITICAL for Karpenter discovery
  clusterName: ${cluster_name}
  clusterEndpoint: ${cluster_endpoint}
  # Interruption handling for spot instances
  interruptionQueue: ${interruption_queue}
  
# Service account configuration (uses modern Pod Identity)
# Pod Identity is the new AWS approach, replacing IRSA
serviceAccount:
  name: karpenter
  # Pod Identity uses association ARN instead of role ARN
  annotations:
    eks.amazonaws.com/pod-identity-association-arn: ${pod_identity_association_arn}

# Node placement - ensure Karpenter runs on system nodes with custom labels
nodeSelector:
  "observability.io/node-type": "system"
  "observability.io/os": "linux"

# Tolerate system node taints - using custom observability labels
tolerations:
  - key: "observability.io/system"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  - key: "CriticalAddonsOnly"
    operator: "Exists"

# Resource requests/limits for production
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# DNS policy for service discovery
dnsPolicy: Default

# Webhook disabled for simplicity (can enable later)
webhook:
  enabled: false

# Logging configuration
logLevel: info

# Metrics configuration
metrics:
  port: 8080

# Health check configuration
health:
  healthProbeBindAddress: :8081
