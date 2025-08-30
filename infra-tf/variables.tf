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
  type = map(object({
    cidr                              = string
    public_subnet_bits                = number         # newbits for cidrsubnet for public subnets
    private_subnet_bits               = number         # newbits for cidrsubnet for private subnets
    enable_dns_hostnames              = optional(bool, true)
    enable_dns_support                = optional(bool, true)
    tags                              = optional(map(string), {})
  }))
  default = {}
}

variable "ecr_repositories" {
  description = "Map of ECR repository definitions keyed by logical name"
  type = map(object({
    repository_read_write_access_arns       = optional(list(string), [])
    create_lifecycle_policy                 = optional(bool, true)
    max_image_count                         = optional(number, 30)
    tag_prefix_list                         = optional(list(string), ["v"])
    tags                                    = optional(map(string), {})
  }))
  default = {}
}

variable "eks_clusters" {
  description = "Map of EKS cluster definitions keyed by logical name"
  type = map(object({
    vpc_name                                 = string
    cluster_version                          = optional(string, "1.31")
    cluster_endpoint_public_access           = optional(bool, true)
    cluster_endpoint_private_access          = optional(bool, false)
    cluster_endpoint_public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    enable_cluster_creator_admin_permissions = optional(bool, true)
    enable_irsa                              = optional(bool, true)
    
    # Karpenter configuration
    enable_karpenter                         = optional(bool, false)
    karpenter_enable_v1_permissions          = optional(bool, true)
    karpenter_enable_pod_identity            = optional(bool, true)
    karpenter_node_iam_policy_arns           = optional(list(string), [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ])
    
    # Node groups configuration
    eks_managed_node_groups                 = optional(map(object({
      instance_types                          = list(string)
      min_size                                = number
      max_size                                = number
      desired_size                            = number
      capacity_type                           = optional(string, "ON_DEMAND")
      ami_type                                = optional(string, "AL2023_x86_64_STANDARD")
      disk_size                               = optional(number, 20)
      labels                                  = optional(map(string), {})
      taints                                  = optional(list(object({
        key                                     = string
        value                                   = optional(string, "")
        effect                                  = string
      })), [])

      tags                                    = optional(map(string), {})
    })), {})
    
    # Cluster addons
    cluster_addons = optional(map(object({
      most_recent                 = optional(bool, true)
      resolve_conflicts_on_update = optional(string, "OVERWRITE")
      service_account_role_arn    = optional(string, null)
    })), {})
    
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "helm" {
  description = "Map of Helm chart configurations keyed by logical name"
  type = map(object({
    name             = optional(string, null)
    repository       = optional(string, null)
    chart            = optional(string, null)
    version          = optional(string, null)
    create_namespace = optional(bool, false)
    namespace        = optional(string, null)
  }))
  default = {}
}

variable "eks_namespaces" {
  description = "Map of Kubernetes namespace configurations for EKS clusters"
  type = map(object({
    labels = optional(map(string), {})
  }))
  default = {}
}
