// Useful data sources

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# // OIDC provider for IRSA (IAM Roles for Service Accounts)
# data "aws_iam_openid_connect_provider" "eks" {
#   url = module.eks.cluster_oidc_issuer_url
# }