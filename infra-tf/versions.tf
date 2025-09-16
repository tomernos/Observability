terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"  # Use stable version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  
  #required_version = ">= 1.0"
}
