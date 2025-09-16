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
  # version  = "21.1.5"
  kubernetes_version = var.eks_clusters.eks.kubernetes_version

  name               = local.cluster_name

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

# Karpenter - Modern node autoscaling for Kubernetes
# This creates the IAM roles and policies needed for Karpenter
module "karpenter" {                                          
  source   = "terraform-aws-modules/eks/aws//modules/karpenter"
  version  = "21.1.5"

  cluster_name = module.eks.cluster_name
  
  # Enable spot instance permissions - REQUIRED for spot pricing data
  enable_spot_termination = true
  
  node_iam_role_name = "${local.cluster_name}"
  node_iam_role_use_name_prefix = false

  # Enable EKS Pod Identity for Karpenter (modern way vs IRSA)
  #enable_pod_identity    = each.value.karpenter_enable_pod_identity
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  
  tags = merge(local.tags, { Component = "karpenter" })
}

#Kubernetes namespaces for EKS clusters
resource "kubernetes_namespace" "this" {
  for_each = var.eks_namespaces
  
  metadata {
    name   = each.key
    labels = each.value.labels
  }
}

#Helm charts deployment - ArgoCD and other charts
resource "helm_release" "this" {
  for_each         = var.helm
  name             = lookup(each.value,"name", each.key) 
  repository       = lookup(each.value, "repository", null)
  repository_username = each.key == "karpenter" ? data.aws_ecrpublic_authorization_token.token.user_name : lookup(each.value, "repository_username", null)
  repository_password = each.key == "karpenter" ? data.aws_ecrpublic_authorization_token.token.password : lookup(each.value, "repository_password", null)
  chart            = lookup(each.value, "chart", null)
  version          = lookup(each.value, "version", null)
  create_namespace = lookup(each.value, "create_namespace", false)
  namespace        = lookup(each.value,"namespace", "kube-system")
  wait             = lookup(each.value,"wait", true)
  #upgrade_install     = lookup(each.value,"upgrade", true)
  replace          = lookup(each.value,"replace", true)
  # Values from locals (handles both static and dynamic)
  #values = each.key == "karpenter" ? [local.karpenter_values] : each.key == "external-dns" ? [local.external_dns_values] : lookup(each.value, "values", [])
  # values = length(fileset("${path.module}/../helm/${each.key}", "*.yaml")) > 0 ? [
  #   for file in fileset("${path.module}/../helm/${each.key}", "*.yaml") :
  #   file("${path.module}/../helm/${each.key}/${file}")
  # ] : []
  # Clean template-based values loading
  values = (
    each.key == "karpenter" ? [
      templatefile("${path.module}/helm/${each.key}/values.yaml.tpl", {
        cluster_name      = module.eks.cluster_name
        cluster_endpoint  = module.eks.cluster_endpoint
        interruption_queue = module.karpenter.queue_name
      })
    ] : each.key == "external-dns" ? [
      templatefile("${path.module}/helm/${each.key}/values.yaml.tpl", {
        txt_owner_id = "external-dns-${random_id.external_dns.hex}"
        role_arn     = aws_iam_role.external_dns.arn
        aws_region   = var.aws_region
        domain_name  = keys(var.route53_zones)[0]
      })
    ] : length(fileset("${path.module}/helm/${each.key}", "*.yaml")) > 0 ? [
      # Static values files for other charts
      for file in fileset("${path.module}/helm/${each.key}", "*.yaml") :
      file("${path.module}/helm/${each.key}/${file}")
    ] : []
  )

  lifecycle {
    ignore_changes = [
      # Ignore values only for Karpenter (dynamic values issue)
      #values,
      # Ignore ECR auth token changes
      repository_password,
      # Ignore metadata changes that don't affect functionality
      #metadata[0].revision,
      metadata[0].app_version,
    ]
  }
}
## external dns

data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${module.eks.cluster_arn}"]
    }
  }
}

resource "aws_iam_policy" "external_dns_r53" {
  name        = "${local.cluster_name}-external-dns-policy"
  description = "Allow ExternalDNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      }
    ]
  })
}

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "5.0.0"

  zones = var.route53_zones

  tags = local.common_tags
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "5.0.0"

  zone_name = keys(var.route53_zones)[0]  # Use first zone
  zone_id   = module.zones.route53_zone_zone_id[keys(var.route53_zones)[0]]

  records = var.route53_records

  depends_on = [module.zones]
}

# External DNS Resources
resource "random_id" "external_dns" {
  byte_length = 4
}

resource "aws_iam_role" "external_dns" {
  name               = "${local.cluster_name}-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns_r53.arn
}

# Pod Identity Association for External DNS
resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn
  
  tags = local.common_tags
}
#   }
# }

# resource "aws_eks_pod_identity_association" "external_dns" {
#   cluster_name    = local.cluster_name
#   namespace       = kubernetes_namespace.external_dns.metadata[0].name
#   service_account = kubernetes_service_account.external_dns.metadata[0].name
#   role_arn        = aws_iam_role.external_dns.arn
# } 