// Basic outputs for validation & reference
output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID"
}

# output "region" {
# 	value       = data.aws_region.current.name
# 	description = "AWS Region"
# }

output "availability_zones" {
  value       = data.aws_availability_zones.available.names
  description = "AWS Availability Zones"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name for kubeconfig and Jenkins pipeline"
}

# Route 53 Outputs
output "route53_zones" {
  value = {
    for zone_name, zone_module in module.zones : zone_name => {
      zone_id      = zone_module.id
      name_servers = zone_module.name_servers
    }
  }
  description = "Route53 zones with their IDs and name servers"
}

output "route53_zone_name_servers" {
  value = {
    for zone_name, zone_module in module.zones : zone_name => zone_module.name_servers
  }
  description = "Name servers for the Route53 zones - Configure these in your domain registrar"
}

# output "karpenter" {
# 	value = {
# 		for k, v in module.karpenter : k => {
# 			service_account = v.service_account
# 			iam_role_arn = v.iam_role_arn
# 			pod_identity_association_arn = try(v.pod_identity_association_arn, "not_available")
# 			queue_name = try(v.queue_name, "not_available")
# 			node_instance_profile_name = try(v.node_instance_profile_name, "not_available")
# 		}
# 	}
# 	description = "Karpenter module outputs"
# }

# output "aws_ecrpublic_authorization_token" {
# 	value = data.aws_ecrpublic_authorization_token.token
# }


# # Debug outputs for Karpenter module (temporary)
# output "karpenter_outputs" {
#   value = try({
#     for k, v in module.karpenter : k => {
#       queue_name = try(v.queue_name, "not_available")
#       service_account_role_arn = try(v.service_account_role_arn, "not_available")
#       node_instance_profile_name = try(v.node_instance_profile_name, "not_available")
#       iam_role_arn = try(v.iam_role_arn, "not_available")
#       pod_identity_association_arn = try(v.pod_identity_association_arn, "not_available")
#     }
#   }, {})
#   description = "Available Karpenter module outputs for debugging"
# }

# ChatApp Secrets Manager IAM Role
output "chatapp_secrets_role_arn" {
  value       = aws_iam_role.chatapp_secrets.arn
  description = "IAM Role ARN for ChatApp to access AWS Secrets Manager - Use this in ServiceAccount annotation"
}

output "chatapp_pod_identity_association" {
  value = {
    namespace       = aws_eks_pod_identity_association.chatapp_secrets.namespace
    service_account = aws_eks_pod_identity_association.chatapp_secrets.service_account
    role_arn        = aws_eks_pod_identity_association.chatapp_secrets.role_arn
  }
  description = "ChatApp Pod Identity Association details (PROD)"
}

output "chatapp_pod_identity_association_dev" {
  value = {
    namespace       = aws_eks_pod_identity_association.chatapp_secrets_dev.namespace
    service_account = aws_eks_pod_identity_association.chatapp_secrets_dev.service_account
    role_arn        = aws_eks_pod_identity_association.chatapp_secrets_dev.role_arn
  }
  description = "ChatApp Pod Identity Association details (DEV)"
}

# ECR Repository Outputs
output "ecr_repositories" {
  value = {
    for repo_name, repo_module in module.ecr : repo_name => {
      repository_url = repo_module.repository_url
      repository_arn = repo_module.repository_arn
      repository_name = repo_module.repository_name
    }
  }
  description = "ECR repository URLs and ARNs - Use these in CI/CD pipelines"
}