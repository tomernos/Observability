// Input variables
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use for credentials"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod"
  }
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
  default     = null
}

variable "project" {
  description = "Project canonical short name"
  type        = string
}

variable "default_tags_extra" {
  description = "Extra default tags map merged with core tags"
  type        = map(string)
  default     = {}
}

variable "tenant_prefix" {
  description = "Top-level org / tenant identifier used in naming (e.g. tnt)"
  type        = string
  default     = "tnt"
}

variable "vpcs" {
  description = "Map of VPC definitions keyed by logical name"
  type        = any
}

variable "ecr_repositories" {
  description = "Map of ECR repository definitions keyed by logical name"
  type        = any
}

variable "eks_clusters" {
  description = "Map of EKS cluster definitions keyed by logical name"
  type        = any
}

variable "helm" {
  description = "Map of Helm chart configurations keyed by logical name"
  type        = any
}

variable "eks_namespaces" {
  description = "Map of Kubernetes namespace configurations for EKS clusters"
  type        = any
  default     = {}
}

variable "route53_zones" {
  description = "Map of Route53 zones to create"
  type        = any
  default     = {}
}

variable "route53_records" {
  description = "List of Route53 records to create"
  type        = any
  default     = []
}

# =========================================
# Karpenter Configuration
# =========================================
variable "karpenter" {
  description = "Karpenter configuration for EC2NodeClass and NodePool"
  type = object({
    # =========================================
    # EC2NodeClass Configuration
    # =========================================
    node_class = object({
      name = optional(string, "default")
      # AMI selection - use alias for Bottlerocket (recommended) or specify AMI ID
      ami_family = optional(string, "bottlerocket") # Options: "bottlerocket", "al2", "ubuntu", "custom"
      ami_id      = optional(string, null)          # Custom AMI ID (if ami_family = "custom")
      # Additional tags applied to nodes
      node_tags = optional(map(string), {})
    })

    # =========================================
    # NodePool Configuration
    # =========================================
    node_pool = object({
      name        = optional(string, "default")
      description = optional(string, "General purpose NodePool for generic workloads")
      
      # Instance configuration
      instance_types = list(string) # e.g., ["t3.medium", "t3.large", "t3.xlarge"]
      capacity_types = list(string) # e.g., ["spot", "on-demand"] or ["on-demand"]
      architecture   = optional(string, "amd64") # Options: "amd64", "arm64"
      
      # Resource limits (optional - prevents runaway scaling)
      limits = optional(object({
        cpu    = optional(string, null)    # e.g., "1000" (total CPU cores)
        memory = optional(string, null)    # e.g., "1000Gi" (total memory)
      }), null)
      
      # Disruption policy (when/how to consolidate nodes)
      disruption = optional(object({
        consolidation_policy = optional(string, "WhenEmptyOrUnderutilized") # Options: "WhenEmpty", "WhenEmptyOrUnderutilized", "Never"
        consolidate_after    = optional(string, "30s")                     # Wait time before consolidating
      }), {
        consolidation_policy = "WhenEmptyOrUnderutilized"
        consolidate_after    = "30s"
      })
      
      # Node labels (optional - applied to all nodes in this pool)
      node_labels = optional(map(string), {})
      
      # Taints (optional - prevent pods from scheduling unless they tolerate)
      taints = optional(list(object({
        key    = string
        value  = optional(string, null)
        effect = string # Options: "NoSchedule", "PreferNoSchedule", "NoExecute"
      })), null)
      
      # Weight (for multiple NodePools - higher weight = preferred for scheduling)
      weight = optional(number, 10)
    })
  })

  default = {
    node_class = {
      name      = "default"
      ami_family = "bottlerocket"
      ami_id     = null
      node_tags  = {}
    }
    node_pool = {
      name          = "default"
      description   = "General purpose NodePool for generic workloads"
      instance_types = ["t3.medium", "t3.large"]
      capacity_types = ["spot", "on-demand"]
      architecture   = "amd64"
      limits         = null
      disruption = {
        consolidation_policy = "WhenEmptyOrUnderutilized"
        consolidate_after    = "30s"
      }
      node_labels = {}
      taints      = null
      weight      = 10
    }
  }
}
