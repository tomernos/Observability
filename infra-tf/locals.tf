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
  
  # Dynamic Helm configuration - resolves dynamic values from modules
  helm_configs = {
    for name, config in var.helm : name => merge(config, 
      # Handle dynamic authentication for Karpenter
      lookup(config, "use_dynamic_auth", false) ? {
        repository_username = data.aws_ecrpublic_authorization_token.token.user_name
        repository_password = data.aws_ecrpublic_authorization_token.token.password
      } : {},
      # Handle dynamic values for Karpenter
      lookup(config, "use_dynamic_values", false) ? {
        values = [yamlencode(merge(
          lookup(config, "values_template", {}),
          {
            settings = {
              clusterName = module.eks.cluster_name
              clusterEndpoint = module.eks.cluster_endpoint
              interruptionQueue = module.karpenter.queue_name
            }
          }
        ))]
      } : {}
    )
  }
}
