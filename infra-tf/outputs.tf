// Basic outputs for validation & reference
output "account_id" {
	value       = data.aws_caller_identity.current.account_id
	description = "AWS Account ID"
}

output "region" {
	value       = data.aws_region.current.name
	description = "AWS Region"
}

output "availability_zones" {
	value       = data.aws_availability_zones.available.names
	description = "AWS Availability Zones"
}

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