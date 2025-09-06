data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "vpc" {
  for_each = var.vpcs
  source   = "terraform-aws-modules/vpc/aws"
  version  = "~> 6.0"

  # Details
  name            = "${local.region_prefix}-vpc"
  cidr            = lookup(each.value, "cidr", "10.0.0.0/16")
  azs             = lookup(each.value, "azs", local.azs) // local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k + length(local.azs))]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k + (2 * length(local.azs)))]

  # database_subnets                   = lookup(each.value,"database_subnets",null)
  # create_database_subnet_group       = lookup(each.value,"create_database_subnet_group",null)
  # create_database_subnet_route_table = lookup(each.value,"create_database_subnet_route_table",null)
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = lookup(each.value, "enable_nat_gateway", true)
  single_nat_gateway = lookup(each.value, "single_nat_gateway", true)

  ## VPC Endpoints for EKS - speeds up private subnet communication
  #enable_vpn_gateway = false
  #enable_flow_log    = false

  # DNS Parameters in VPC
  enable_dns_hostnames = lookup(each.value, "enable_dns_hostnames", true)
  enable_dns_support   = lookup(each.value, "enable_dns_support", true)
  
  # Additional tags for the VPC
  tags     = lookup(each.value, "tags", local.tags)
  
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

# module "ecr" {
#   for_each = var.ecr_repositories
#   source   = "terraform-aws-modules/ecr/aws"
#   version  = "2.3.1"
  
#   repository_name                   = "${local.region_prefix}-${each.key}"
#   repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
#   create_lifecycle_policy           = true
  
#   repository_lifecycle_policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1,
#         description  = "Keep last ${each.value.max_image_count} images",
#         selection = {
#           tagStatus     = "tagged",
#           tagPrefixList = each.value.tag_prefix_list,
#           countType     = "imageCountMoreThan",
#           countNumber   = each.value.max_image_count
#         },
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
  
#   tags = merge(local.tags, each.value.tags)
# }

module "eks" {
  source   = "terraform-aws-modules/eks/aws"

  name               = local.cluster_name
  kubernetes_version = var.eks_clusters.eks.kubernetes_version

  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = var.eks_clusters.eks.enable_cluster_creator_admin_permissions
  endpoint_public_access                   = var.eks_clusters.eks.cluster_endpoint_public_access

  addons = var.eks_clusters.eks.addons

  vpc_id     = module.vpc["hub"].vpc_id
  subnet_ids = module.vpc["hub"].private_subnets
  control_plane_subnet_ids = module.vpc["hub"].intra_subnets

  eks_managed_node_groups = var.eks_clusters.eks.eks_managed_node_groups

  node_security_group_tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  })

  tags = local.tags
}
# module "eks" {
#   for_each = var.eks_clusters
#   source   = "terraform-aws-modules/eks/aws"
#   version  = "21.1.5"  # Match Karpenter module version
  
#   name    = "${local.region_prefix}-${each.key}"
#   kubernetes_version = each.value.cluster_version

#   endpoint_public_access       = each.value.cluster_endpoint_public_access
#   endpoint_private_access      = each.value.cluster_endpoint_private_access
#   endpoint_public_access_cidrs = each.value.cluster_endpoint_public_access_cidrs

#   # Admin permissions
#   enable_cluster_creator_admin_permissions  = each.value.enable_cluster_creator_admin_permissions
  
#   ## Enable Pod Identity authentication mode
#   #authentication_mode = "API_AND_CONFIG_MAP"
  
#   # Network configuration
#   vpc_id     = module.vpc[each.value.vpc_name].vpc_id
#   subnet_ids = module.vpc[each.value.vpc_name].private_subnets

#   # EKS Addons - using configuration from tfvars
#   addons = each.value.cluster_addons
  
#   # EKS Managed Node Groups - using configuration from tfvars
#   eks_managed_node_groups = {
#     for ng_name, ng_config in each.value.eks_managed_node_groups : ng_name => {
#       instance_types = ng_config.instance_types
#       min_size      = ng_config.min_size
#       max_size      = ng_config.max_size
#       desired_size  = ng_config.desired_size
#       capacity_type = ng_config.capacity_type
#       ami_type      = ng_config.ami_type
#       disk_size     = ng_config.disk_size
      
#       # Labels and taints for node specialization - Kubernetes standard approach
#       labels = ng_config.labels
#       #taints = ng_config.taints
      
#   #     # This is not required - demonstrates how to pass additional configuration to nodeadm
#   #     # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
#   #     cloudinit_pre_nodeadm = [
#   #       {
#   #         content_type = "application/node.eks.aws"
#   #         content      = <<-EOT
#   #           ---
#   #           apiVersion: node.eks.aws/v1alpha1
#   #           kind: NodeConfig
#   #           spec:
#   #             kubelet:
#   #               config:
#   #                 shutdownGracePeriod: 30s
#   #                 featureGates:
#   #                   DisableKubeletCloudCredentialProviders: true
#   #         EOT
#   #       }
#   #     ]
      
#       tags = merge(local.tags, ng_config.tags)
#     }
#   }

#   # Tag the shared node security group for Karpenter securityGroupSelectorTerms discovery
#   node_security_group_tags = merge(local.tags, {
#     "karpenter.sh/discovery" = "${local.cluster_name}"
#   })
#   tags = merge(local.tags, each.value.tags, { Component = "kubernetes" })
# }

# Karpenter - Modern node autoscaling for Kubernetes
# This creates the IAM roles and policies needed for Karpenter
module "karpenter" {                                          
  source   = "terraform-aws-modules/eks/aws//modules/karpenter"
  version  = "21.1.5"

  cluster_name = module.eks.cluster_name
  
  #enable_v1_permissions  = each.value.karpenter_enable_v1_permissions
  
  
  # Enable spot instance permissions - REQUIRED for spot pricing data
  enable_spot_termination = true
  
  # Create interruption queue with proper tags
  #create_instance_profile = true
  
  # Rely on module's built-in v1 policy (no extra statements to stay under 6 KB limit)
  
  # Shorten IAM role names to avoid 38-char limit
  # Use abbreviated naming: karp-<tenant>-<region>-<env>-<cluster_key>
  node_iam_role_name = "${local.cluster_name}"
  node_iam_role_use_name_prefix = false

  # Enable EKS Pod Identity for Karpenter (modern way vs IRSA)
  #enable_pod_identity    = each.value.karpenter_enable_pod_identity
  create_pod_identity_association = true

  #namespace       = "karpenter"
  #service_account = "karpenter"

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  
  tags = merge(local.tags, { Component = "karpenter" })
}

#Kubernetes namespaces for EKS clusters
resource "kubernetes_namespace_v1" "this" {
  for_each = var.eks_namespaces
  
  metadata {
    name   = each.key
    labels = each.value.labels
  }
}

#Helm charts deployment - ArgoCD and other charts
resource "helm_release" "this" {
  for_each         = local.helm_configs
  name             = lookup(each.value,"name",null) == null ? each.key : each.value.name
  repository       = lookup(each.value, "repository", null)
  repository_username = lookup(each.value, "repository_username", null)
  repository_password = lookup(each.value, "repository_password", null)
  chart            = lookup(each.value, "chart", null)
  version          = lookup(each.value, "version", null)
  create_namespace = lookup(each.value, "create_namespace",false)
  namespace        = lookup(each.value,"namespace",null)
  wait             = lookup(each.value,"wait", false)
  
  # Values from locals (handles both static and dynamic)
  values = lookup(each.value,"values",[])
}