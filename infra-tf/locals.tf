// Local values for consistent naming & tagging
locals {
  project_name = var.project
  name_prefix  = coalesce(var.name_prefix, join("-", compact([var.project, var.environment])))
  # Prefix convention: <tenant>-<region-short>-<project>-<env>
  # Example: tnt-eu-observability-dev
  region_prefix = join("-", [var.tenant_prefix, substr(var.aws_region, 0, 2), var.project, var.environment])
  
  # Cluster name for Karpenter discovery
  cluster_name = "${local.region_prefix}-eks"

  common_tags = merge({
    Environment = var.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
  })

  # AZs for VPC module
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Tags alias for backward compatibility
  tags = local.common_tags
  
  # Simple dynamic values for modules (no complex logic)
  karpenter_values = yamlencode({
    nodeSelector = {
      "karpenter.sh/controller" = "true"
    }
    dnsPolicy = "Default"
    settings = {
      clusterName = module.eks.cluster_name
      clusterEndpoint = module.eks.cluster_endpoint
      interruptionQueue = module.karpenter.queue_name
    }
    webhook = {
      enabled = false
    }
  })

  # External DNS values with proper interpolation
  external_dns_values = yamlencode({
    provider = "aws"
    aws = {
      region = var.aws_region
      zoneType = "public"
    }
    domainFilters = [
      keys(var.route53_zones)[0]  # Use first domain
    ]
    txtOwnerId = "external-dns-${random_id.external_dns.hex}"
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
      }
    }
    logLevel = "info"
    policy = "upsert-only"  # Only create records, don't delete
  })
}
