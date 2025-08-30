module "vpc" {
  for_each = var.vpcs
  source   = "terraform-aws-modules/vpc/aws"
  version  = "5.19.0"

  # Details
  name            = "${local.region_prefix}-vpc"
  cidr      = lookup(each.value, "cidr", "10.0.0.0/16")
  azs             = lookup(each.value, "azs", local.azs) // local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k + 2)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k)]
  # database_subnets                   = lookup(each.value,"database_subnets",null)
  # create_database_subnet_group       = lookup(each.value,"create_database_subnet_group",null)
  # create_database_subnet_route_table = lookup(each.value,"create_database_subnet_route_table",null)
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = lookup(each.value, "enable_nat_gateway", true)
  single_nat_gateway = lookup(each.value, "single_nat_gateway", true)


  # DNS Parameters in VPC
  enable_dns_hostnames = lookup(each.value, "enable_dns_hostnames", true)
  enable_dns_support   = lookup(each.value, "enable_dns_support", true)
  # Additional tags for the VPC
  tags     = lookup(each.value, "tags", local.tags)
  vpc_tags = lookup(each.value, "vpc_tags", {})
  
  # Karpenter discovery tags for subnets
  public_subnet_tags = {
    "karpenter.sh/discovery" = "${local.cluster_name}"
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "karpenter.sh/discovery" = "${local.cluster_name}"
    "kubernetes.io/role/internal-elb" = 1
  }

  # Additional tags for the database subnets
  #   database_subnet_tags = {
  #     Name = local.name
  #   }
  # Instances launched into the Public subnet should be assigned a public IP address. Specify true to indicate that instances launched into the subnet should be assigned a public IP address
  #   map_public_ip_on_launch = true
}

module "ecr" {
  for_each = var.ecr_repositories
  source   = "terraform-aws-modules/ecr/aws"
  version  = "2.3.1"
  
  repository_name                   = "${local.region_prefix}-${each.key}"
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  create_lifecycle_policy           = each.value.create_lifecycle_policy
  
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last ${each.value.max_image_count} images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = each.value.tag_prefix_list,
          countType     = "imageCountMoreThan",
          countNumber   = each.value.max_image_count
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  tags = merge(local.tags, each.value.tags)
}

module "eks" {
  for_each = var.eks_clusters
  source   = "terraform-aws-modules/eks/aws"
  version  = "20.33.1"
  
  cluster_name    = "${local.region_prefix}-${each.key}"
  cluster_version = each.value.cluster_version
  
  # Cluster endpoint configuration
  cluster_endpoint_public_access       = each.value.cluster_endpoint_public_access
  cluster_endpoint_private_access      = each.value.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = each.value.cluster_endpoint_public_access_cidrs
  
  # Admin permissions
  enable_cluster_creator_admin_permissions = each.value.enable_cluster_creator_admin_permissions
  enable_irsa                              = each.value.enable_irsa
  
  # Network configuration
  vpc_id     = module.vpc[each.value.vpc_name].vpc_id
  subnet_ids = module.vpc[each.value.vpc_name].private_subnets

  # EKS Addons - using configuration from tfvars
  cluster_addons = each.value.cluster_addons
  
  # EKS Managed Node Groups - using configuration from tfvars
  eks_managed_node_groups = {
    for ng_name, ng_config in each.value.eks_managed_node_groups : ng_name => {
      instance_types = ng_config.instance_types
      min_size      = ng_config.min_size
      max_size      = ng_config.max_size
      desired_size  = ng_config.desired_size
      capacity_type = ng_config.capacity_type
      ami_type      = ng_config.ami_type
      disk_size     = ng_config.disk_size
      
      # Labels and taints for node specialization - Kubernetes standard approach
      labels = ng_config.labels
      taints = ng_config.taints
      
  #     # This is not required - demonstrates how to pass additional configuration to nodeadm
  #     # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
  #     cloudinit_pre_nodeadm = [
  #       {
  #         content_type = "application/node.eks.aws"
  #         content      = <<-EOT
  #           ---
  #           apiVersion: node.eks.aws/v1alpha1
  #           kind: NodeConfig
  #           spec:
  #             kubelet:
  #               config:
  #                 shutdownGracePeriod: 30s
  #                 featureGates:
  #                   DisableKubeletCloudCredentialProviders: true
  #         EOT
  #       }
  #     ]
      
      tags = merge(local.tags, ng_config.tags)
    }
  }

  # Tag the shared node security group for Karpenter securityGroupSelectorTerms discovery
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  tags = merge(local.tags, each.value.tags, { Component = "kubernetes" })
}

# Karpenter - Modern node autoscaling for Kubernetes
# This creates the IAM roles and policies needed for Karpenter
module "karpenter" {
  for_each = { for k, v in var.eks_clusters : k => v if v.enable_karpenter }
  source   = "terraform-aws-modules/eks/aws//modules/karpenter"
  version  = "20.33.1"

  cluster_name = module.eks[each.key].cluster_name
  
  enable_v1_permissions  = each.value.karpenter_enable_v1_permissions
  
  # Enable EKS Pod Identity for Karpenter (modern way vs IRSA)
  enable_pod_identity    = each.value.karpenter_enable_pod_identity
  create_pod_identity_association = true
  
  # Enable spot instance permissions - REQUIRED for spot pricing data
  enable_spot_termination = true
  
  # Create interruption queue with proper tags
  create_instance_profile = true
  
  # Rely on module's built-in v1 policy (no extra statements to stay under 6 KB limit)
  
  # Shorten IAM role names to avoid 38-char limit
  # Use abbreviated naming: karp-<tenant>-<region>-<env>-<cluster_key>
  node_iam_role_name = "karp-${var.tenant_prefix}-${substr(var.aws_region, 0, 2)}-${substr(var.environment, 0, 1)}-${each.key}"
  node_iam_role_use_name_prefix = false

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  
  tags = merge(local.tags, { Component = "karpenter" })
}

# Data source for ECR public authentication
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

# Kubernetes namespaces for EKS clusters
resource "kubernetes_namespace_v1" "this" {
  for_each = var.eks_namespaces
  
  metadata {
    name   = each.key
    labels = each.value.labels
  }
}

# Helm charts deployment - ArgoCD and other charts
resource "helm_release" "this" {
  for_each         = var.helm
  name             = lookup(each.value,"name",null) == null ? each.key : each.value.name
  repository       = lookup(each.value, "repository", null)
  chart            = lookup(each.value, "chart", null)
  version          = lookup(each.value, "version", null)
  create_namespace = lookup(each.value, "create_namespace",false)
  namespace        = lookup(each.value,"namespace",null)
  
  # Use default values for now
  values = []
}