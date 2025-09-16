project     = "observability"
environment = "dev"
aws_region  = "eu-central-1"

vpcs = {
    hub = {
        vpc_version        = "~> 6.0"
        cidr                 = "10.10.0.0/16"
        public_subnet_bits   = 8   # /24 per AZ for public
        private_subnet_bits  = 8   # /24 per AZ for private
        enable_dns_hostnames = true
        enable_dns_support   = true
        tags = { Purpose = "core-network" }
    }
}

ecr_repositories = {
    acr = {
        max_image_count = 30
        tag_prefix_list = ["v", "latest"]
        tags = { Component = "application" }
    }
}

eks_clusters = {
    eks = {
        vpc_name                    = "hub"
        kubernetes_version          = "1.33"
        enable_cluster_creator_admin_permissions = true
        cluster_endpoint_public_access = true

        # Node groups configuration - COST-OPTIMIZED FOR LEARNING
        # Simple setup: 2 nodes total for system workloads + Karpenter
        
        eks_managed_node_groups = {
            # System node group - 2 nodes (one for system, one for Karpenter)
            system = {
                instance_types  = ["t3.medium"]  # Multiple types for better spot availability t3,small - # $0.0208/hour, 2 vCPU, 2GB RAM
                min_size        = 1
                desired_size    = 1
                max_size        = 2
                capacity_type   = "ON_DEMAND"   # Reliable for system workloads
                ami_type        = "BOTTLEROCKET_x86_64"
                #max_pods        = 50            # Increase from default ~17 to 50 pods per node
                # Enable SSM access for node management
                iam_role_additional_policies = {
                    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
                }
                # Optional: Add SSH key for direct SSH access (create key pair first)
                # key_name = "my-eks-key"
                labels = { 
                    # "observability.io/node-type" = "system"
                    # "observability.io/capacity-type" = "spot"
                    # "observability.io/os" = "linux"
                    "karpenter.sh/controller" = "true"
                }
                taints = {}  # No taints for simplicity
                tags = { NodeGroup = "system" }
            }
        }
  
        # Essential cluster addons - COMMENTED OUT FOR LEARNING
        # We'll enable these one by one to understand their purpose
        addons = {
            coredns = {}
            eks-pod-identity-agent = { before_compute = true }
            kube-proxy = {}
            vpc-cni = { before_compute = true }
        }
        
        tags = { Environment = "dev", Purpose = "observability-cluster" }
    }
}

helm = {
    secrets-store-csi-driver = {
        chart      = "secrets-store-csi-driver"
        repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
        version    = "1.5.3"
        namespace = "kube-system"
        upgrade          = true
    }
    secrets-provider-aws = {
        chart            = "secrets-store-csi-driver-provider-aws"
        repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
        version          = "2.0.0" 
        namespace        = "kube-system"
        upgrade          = true
    }
    karpenter = {
        chart            = "karpenter"
        repository       = "oci://public.ecr.aws/karpenter"
        version          = "1.6.0"
        namespace        = "kube-system"
        wait             = false
        upgrade          = true
        # Dynamic values will be handled in locals
        use_dynamic_auth = true
        # Template for Karpenter values - will be populated by locals
    }
    external-dns = {
        chart            = "external-dns"
        repository       = "https://kubernetes-sigs.github.io/external-dns/"
        version          = "1.18.0"
        namespace        = "kube-system"
        wait             = false
        upgrade          = true
    }
    metric-server = {
        chart            = "metrics-server"
        repository       = "https://kubernetes-sigs.github.io/metrics-server/"
        version          = "3.13.0"
        namespace        = "kube-system"
        wait             = false
        upgrade          = true
        values = []
    }
    argocd = {
        chart            = "argo-cd"
        repository       = "https://argoproj.github.io/argo-helm"
        version          = "7.8.8"
        create_namespace = true
        namespace        = "argocd"
        wait             = false
        upgrade          = true
        values = []
    }
    cert-manager = {
        chart            = "cert-manager"
        repository       = "https://charts.jetstack.io"
        version          = "v1.18.2"
        create_namespace = true
        namespace        = "cert-manager"
        wait             = false
        upgrade          = true
    }
    ingress-nginx = {
        chart            = "ingress-nginx"
        repository       = "https://kubernetes.github.io/ingress-nginx"
        version          = "4.13.2"
        create_namespace = true
        namespace        = "ingress-nginx"
        wait             = false
        upgrade          = true
    }
}

eks_namespaces = {
    external-dns = {
        labels = {
            name = "external-dns"
        }
    }
}

# Route 53 Configuration
route53_zones = {
  "tomernos.xyz" = {
    comment = "Main domain for observability project"
    tags = {
      Environment = "dev"
      Purpose     = "observability"
    }
  }
}

route53_records = [
  # A record for the root domain (optional - points to a fixed IP)
  {
    name    = ""
    type    = "A"
    ttl     = 300
    records = ["1.2.3.4"]  # Replace with your actual IP
    alias = {}
  },
  # CNAME for www subdomain
  {
    name    = "www"
    type    = "CNAME"
    ttl     = 300
    records = ["tomernos.xyz"]
  },
  # A records for services (external-dns will manage these automatically)
  # Wildcard for subdomains
  {
    name    = "*"
    type    = "A"
    ttl     = 300
    records = ["10.0.0.100"]  # Placeholder - external-dns will manage
  }
]
