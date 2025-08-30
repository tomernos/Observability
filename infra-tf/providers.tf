// Single AWS provider. Version pin lives in versions.tf (keep only one required_providers block in the project).
provider "aws" {
  region = var.aws_region
}

# AWS provider for ECR Public (must be us-east-1)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# EKS cluster authentication token - generated dynamically from the cluster
data "aws_eks_cluster_auth" "main" {
  name = module.eks["eks"].cluster_name
}

# Kubernetes provider - uses EKS module outputs for authentication
provider "kubernetes" {
  host                   = module.eks["eks"].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks["eks"].cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Helm provider - uses EKS module outputs for authentication
provider "helm" {
  kubernetes = {
    host                   = module.eks["eks"].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks["eks"].cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}