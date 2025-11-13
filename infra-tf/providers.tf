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
  name = module.eks.cluster_name
}

# Kubernetes provider - uses EKS module outputs for authentication

provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
  token                  = try(data.aws_eks_cluster_auth.main.token, null)

}

# Helm provider - uses EKS module outputs for authentication

provider "helm" {
  kubernetes = {
    host                   = try(module.eks.cluster_endpoint, null)
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
    token                  = try(data.aws_eks_cluster_auth.main.token, null)
  }
}

# Kubectl provider - better for applying raw manifests (doesn't validate during plan)
provider "kubectl" {
  host                   = try(module.eks.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
  token                  = try(data.aws_eks_cluster_auth.main.token, null)
  load_config_file       = false
}
