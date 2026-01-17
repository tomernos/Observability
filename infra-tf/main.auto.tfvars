project     = "chatapp"
environment = "dev"
aws_region  = "eu-central-1"

# =========================================
# Karpenter Configuration
# =========================================
# Terraform-managed EC2NodeClass and NodePool
karpenter = {
  # EC2NodeClass: Defines how nodes are provisioned
  node_class = {
    name      = "default"
    ami_family = "bottlerocket"  # Options: "bottlerocket", "al2", "ubuntu", "custom"
    # ami_id   = null             # Only needed if ami_family = "custom"
    node_tags = {
      Environment = "dev"
      ManagedBy   = "karpenter"
    }
  }

  # NodePool: Defines scheduling constraints and instance types
  node_pool = {
    name        = "default"
    description = "General purpose NodePool for generic workloads"
    
    # Instance configuration
    instance_types = ["t3.medium", "t3.large"]  # Allowed instance types
    capacity_types = ["spot", "on-demand"]      # Allow both spot and on-demand
    architecture   = "amd64"                     # CPU architecture
    
    # Resource limits (removed - no limits on node scaling)
    limits = null
    
    # Disruption policy (when/how to consolidate nodes)
    disruption = {
      consolidation_policy = "WhenEmptyOrUnderutilized"  # Options: "WhenEmpty", "WhenEmptyOrUnderutilized", "Never"
      consolidate_after    = "30s"                       # Wait 30s before consolidating
    }
    
    # Node labels (optional - applied to all nodes)
    node_labels = {}
    
    # Taints (optional - prevent pods from scheduling unless they tolerate)
    # taints = null
    
    # Weight (for multiple NodePools - higher = preferred)
    weight = 10
  }
}

# =========================================
# VPC Configuration
# =========================================
vpcs = {
  hub = {
    vpc_version          = "~> 6.0"
    cidr                 = "10.10.0.0/16"
    public_subnet_bits   = 8 # /24 per AZ for public
    private_subnet_bits  = 8 # /24 per AZ for private
    enable_nat_gateway   = true
    single_nat_gateway   = true
    tags                 = { Purpose = "core-network" }
  }
}

# =========================================
# ECR Repositories
# =========================================
ecr_repositories = {
  chatapp = {
    max_image_count = 30
    tag_prefix_list = ["v", "latest"]
    tags            = { Application = "chatapp", Environment = "dev" }
  }
}

# =========================================
# EKS Cluster Configuration
# =========================================
eks_clusters = {
  eks = {
    vpc_name                                 = "hub"
    kubernetes_version                       = "1.33"
    enable_cluster_creator_admin_permissions = true
    cluster_endpoint_public_access           = true

    # Node groups configuration 
    eks_managed_node_groups = {
      system = {
        instance_types = ["t3.large"] # $0.0208/hour, 2 vCPU, 2GB RAM
        min_size       = 1
        desired_size   = 1
        max_size       = 2
        capacity_type  = "ON_DEMAND"
        ami_type       = "BOTTLEROCKET_x86_64"
        # Enable SSM access for node management
        iam_role_additional_policies = {
          AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }
        labels = {
          "karpenter.sh/controller" = "true"
        }
        taints = {} # No taints for simplicity
        tags   = { NodeGroup = "system" }
      }
    }

    # Essential cluster addons 
    addons = {
      coredns                = {}
      eks-pod-identity-agent = { before_compute = true }
      kube-proxy             = {}
      vpc-cni                = { before_compute = true }
    }

    tags = { Environment = "dev", Purpose = "observability-cluster" }
  }
}

# =========================================
# Helm Charts Configuration
# =========================================
helm = {
  karpenter = {
    chart            = "karpenter"
    repository       = "oci://public.ecr.aws/karpenter"
    version          = "1.6.0"
    namespace        = "kube-system"
    upgrade          = true
    use_dynamic_auth = true # Dynamic values will be handled in locals
  }
  secrets-store-csi-driver = {
    chart      = "secrets-store-csi-driver"
    repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
    version    = "1.5.3"
    namespace  = "kube-system"
    upgrade    = true
  }
  secrets-provider-aws = {
    chart      = "secrets-store-csi-driver-provider-aws"
    repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
    version    = "2.0.0"
    namespace  = "kube-system"
    upgrade    = true
  }
  external-dns = {
    chart      = "external-dns"
    repository = "https://kubernetes-sigs.github.io/external-dns/"
    version    = "1.18.0"
    namespace  = "kube-system"
    wait       = false
    upgrade    = true
  }
  metric-server = {
    chart      = "metrics-server"
    repository = "https://kubernetes-sigs.github.io/metrics-server/"
    version    = "3.13.0"
    namespace  = "kube-system"
    wait       = false
    upgrade    = true
    values     = []
  }
  argocd = {
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "7.8.8"
    create_namespace = true
    namespace        = "argocd"
    wait             = false
    upgrade          = true
    values           = []
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
  # Observability Stack - Deployed via Terraform (Best Practice)
  prometheus = {
    chart            = "kube-prometheus-stack"
    repository       = "https://prometheus-community.github.io/helm-charts"
    version          = "59.0.0"
    create_namespace = true
    namespace        = "monitoring"
    wait             = true
    timeout          = 600
    upgrade          = true
  }
  jaeger = {
    chart            = "jaeger"
    repository       = "https://jaegertracing.github.io/helm-charts"
    version          = "4.3.4"
    create_namespace = true
    namespace        = "monitoring"
    wait             = true
    timeout          = 300
    upgrade          = true
  }
  otel-collector = {
    chart            = "opentelemetry-collector"
    repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
    version          = "0.143.0"
    create_namespace = true
    namespace        = "monitoring"
    wait             = true
    timeout          = 300
    upgrade          = true
  }
  loki = {
    chart            = "loki"
    repository       = "https://grafana.github.io/helm-charts"
    version          = "6.49.0"
    create_namespace = true
    namespace        = "monitoring"
    wait             = true
    timeout          = 600
    upgrade          = true
  }
  promtail = {
    chart            = "promtail"
    repository       = "https://grafana.github.io/helm-charts"
    version          = "6.16.6"
    create_namespace = true
    namespace        = "monitoring"
    wait             = true
    timeout          = 300
    upgrade          = true
  }
}

# =========================================
# Kubernetes Namespaces
# =========================================
eks_namespaces = {
  external-dns = {
    labels = {
      name = "external-dns"
    }
  }
}

# =========================================
# Route53 Configuration
# =========================================
route53_zones = {
  "tomernos.xyz" = {
    comment = "Main domain for observability project"
    tags = {
      Environment = "dev"
      Purpose     = "observability"
    }
    # In v6.1.1, records are configured within zones as a map
    records = {
      # A record for the root domain (optional - points to a fixed IP)
      root = {
        name    = "@"  # "@" represents the root domain (apex)
        type    = "A"
        ttl     = 300
        records = ["1.2.3.4"] # Replace with your actual IP
      }
      # CNAME for www subdomain
      www = {
        name    = "www"
        type    = "CNAME"
        ttl     = 300
        records = ["tomernos.xyz"]
      }
      # Wildcard for subdomains (external-dns will manage service records)
      wildcard = {
        name    = "*"
        type    = "A"
        ttl     = 300
        records = ["10.0.0.100"] # Placeholder - external-dns will manage
      }
    }
  }
}

# route53_records variable kept for backward compatibility but not used in v6.1.1
# Records are now configured within route53_zones
route53_records = []
