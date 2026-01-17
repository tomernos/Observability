terraform {
  required_version = ">= 1.0"
  
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "grafana" {
  url      = var.grafana_url
  auth     = var.grafana_username != "" ? "${var.grafana_username}:${var.grafana_password}" : ""
}

provider "kubectl" {
  # Uses default kubeconfig (~/.kube/config)
  # Make sure kubectl is configured: aws eks update-kubeconfig --name <cluster-name>
}
