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
  type = any
}

variable "ecr_repositories" {
  description = "Map of ECR repository definitions keyed by logical name"
  type = any
}

variable "eks_clusters" {
  description = "Map of EKS cluster definitions keyed by logical name"
  type = any
}

variable "helm" {
  description = "Map of Helm chart configurations keyed by logical name"
  type = any
}

variable "eks_namespaces" {
  description = "Map of Kubernetes namespace configurations for EKS clusters"
  type = any
  default = {}
}

variable "route53_zones" {
  description = "Map of Route53 zones to create"
  type = any
  default = {}
}

variable "route53_records" {
  description = "List of Route53 records to create"
  type = any
  default = []
}

# variable "karpenter_version" {
#   description = "Version of Karpenter Helm chart to deploy"
#   type        = string
#   default     = "1.6.0"
# }
