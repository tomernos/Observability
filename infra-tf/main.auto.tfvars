project     = "observability"
environment = "dev"
aws_region  = "eu-central-1"

vpcs = {
    hub = {
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
        cluster_version            = "1.31"
        cluster_endpoint_public_access = true
        cluster_endpoint_private_access = false
        cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
        enable_cluster_creator_admin_permissions = true
        #enable_irsa = true
        
        # Karpenter - Modern node autoscaling
        # Karpenter is AWS's next-generation autoscaler that's more efficient than traditional node groups
        enable_karpenter = true
        karpenter_enable_v1_permissions = true
        karpenter_enable_pod_identity = true
        
        # Node groups configuration - COST-OPTIMIZED FOR LEARNING
        # Simple setup: 2 nodes total for system workloads + Karpenter
        eks_managed_node_groups = {
            # System node group - 2 nodes (one for system, one for Karpenter)
            system = {
                instance_types  = ["t3.medium", "m5.large"]  # Multiple types for better spot availability t3,small - # $0.0208/hour, 2 vCPU, 2GB RAM
                min_size        = 2
                desired_size    = 2
                max_size        = 10
                capacity_type   = "ON_DEMAND"   # Reliable for system workloads
                ami_type        = "BOTTLEROCKET_x86_64"
                disk_size       = 20
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
        cluster_addons = {
            # CoreDNS - simplified configuration
            coredns = {
                most_recent                 = true
                resolve_conflicts_on_update = "OVERWRITE"
                #configuration_values = "{\"tolerations\":[{\"key\":\"observability.io/system\",\"operator\":\"Equal\",\"value\":\"true\",\"effect\":\"NoSchedule\"}],\"nodeSelector\":{\"observability.io/node-type\":\"system\"}}"
            }
            # REQUIRED for Pod Identity - modern AWS authentication
            eks-pod-identity-agent = {
                most_recent                 = true
                resolve_conflicts_on_update = "OVERWRITE"
            }
            kube-proxy = {
                most_recent                 = true
                resolve_conflicts_on_update = "OVERWRITE"
            }
            # vpc-cni = {
            #     most_recent                 = true
            #     resolve_conflicts_on_update = "OVERWRITE"
            # }
            # aws-ebs-csi-driver = {
            #     most_recent                 = true
            #     resolve_conflicts_on_update = "OVERWRITE"
            #     # service_account_role_arn = "arn:aws:iam::ACCOUNT:role/AmazonEKS_EBS_CSI_DriverRole"
            # }
        }
        
        tags = { Environment = "dev", Purpose = "observability-cluster" }
    }
}

helm = {
    argocd = {
        chart            = "argo-cd"
        repository       = "https://argoproj.github.io/argo-helm"
        version          = "7.8.8"
        create_namespace = true
        namespace        = "argocd"
    }
}

eks_namespaces = {
    # argocd = {
    #     labels = {
    #         name = "argocd"
    #     }
    # }
}
