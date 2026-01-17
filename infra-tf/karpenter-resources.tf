# =========================================
# Karpenter Resources - Terraform Managed
# =========================================
# EC2NodeClass and NodePool resources managed by Terraform using templates
# 
# Architecture:
#   1. Variables defined in variables.tf (structured with node_class + node_pool)
#   2. Configuration values in main.auto.tfvars (user-friendly)
#   3. This file transforms simple config → template variables → YAML manifests
#   4. Templates in templates/karpenter/*.tpl (clean YAML structure)
#
# Flow:
#   main.auto.tfvars → locals (transformation) → templatefile() → local_file → kubectl apply

# -----------------------------------------------------------------------------
# Template Variables - Simplified
# -----------------------------------------------------------------------------
locals {
  # EC2NodeClass variables (minimal - Bottlerocket only)
  ec2nodeclass_vars = {
    node_class_name = var.karpenter.node_class.name
    node_role       = module.karpenter.node_iam_role_name
    cluster_name    = local.cluster_name
  }

  # NodePool requirements
  node_requirements = [
    {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = var.karpenter.node_pool.capacity_types
    },
    {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = [var.karpenter.node_pool.architecture]
    },
    {
      key      = "node.kubernetes.io/instance-type"
      operator = "In"
      values   = var.karpenter.node_pool.instance_types
    }
  ]

  # NodePool variables
  nodepool_vars = {
    node_pool_name       = var.karpenter.node_pool.name
    node_class_name      = var.karpenter.node_class.name
    node_requirements    = local.node_requirements
    limits               = var.karpenter.node_pool.limits
    consolidation_policy = var.karpenter.node_pool.disruption.consolidation_policy
    consolidate_after    = var.karpenter.node_pool.disruption.consolidate_after
    weight               = var.karpenter.node_pool.weight
  }
}

# -----------------------------------------------------------------------------
# Rendered YAML Files (written to disk)
# -----------------------------------------------------------------------------
# Generate the YAML files from templates
resource "local_file" "karpenter_ec2nodeclass" {
  content = templatefile(
    "${path.module}/templates/karpenter/ec2nodeclass.yaml.tpl",
    local.ec2nodeclass_vars
  )
  filename = "${path.module}/generated/karpenter-ec2nodeclass.yaml"
}

resource "local_file" "karpenter_nodepool" {
  content = templatefile(
    "${path.module}/templates/karpenter/nodepool.yaml.tpl",
    local.nodepool_vars
  )
  filename = "${path.module}/generated/karpenter-nodepool.yaml"
}

# -----------------------------------------------------------------------------
# Apply Resources Using kubectl
# -----------------------------------------------------------------------------
# Apply EC2NodeClass using kubectl (more reliable than kubernetes_manifest)
resource "null_resource" "apply_karpenter_ec2nodeclass" {
  triggers = {
    manifest_sha      = sha256(local_file.karpenter_ec2nodeclass.content)
    filename          = local_file.karpenter_ec2nodeclass.filename
    node_class_name   = var.karpenter.node_class.name
    cluster_name      = local.cluster_name
    aws_region        = var.aws_region
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${local.cluster_name} --region ${var.aws_region}
      kubectl apply -f ${self.triggers.filename}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws eks update-kubeconfig --name ${self.triggers.cluster_name} --region ${self.triggers.aws_region} || true
      kubectl delete ec2nodeclass ${self.triggers.node_class_name} --ignore-not-found=true || true
    EOT
  }

  depends_on = [
    helm_release.this,
    local_file.karpenter_ec2nodeclass
  ]
}

# Apply NodePool using kubectl
resource "null_resource" "apply_karpenter_nodepool" {
  triggers = {
    manifest_sha    = sha256(local_file.karpenter_nodepool.content)
    filename        = local_file.karpenter_nodepool.filename
    node_pool_name  = var.karpenter.node_pool.name
    cluster_name    = local.cluster_name
    aws_region      = var.aws_region
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${local.cluster_name} --region ${var.aws_region}
      kubectl apply -f ${self.triggers.filename}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws eks update-kubeconfig --name ${self.triggers.cluster_name} --region ${self.triggers.aws_region} || true
      kubectl delete nodepool ${self.triggers.node_pool_name} --ignore-not-found=true || true
    EOT
  }

  depends_on = [
    null_resource.apply_karpenter_ec2nodeclass,
    local_file.karpenter_nodepool
  ]
}

# Wait for NodePool to be ready (other resources can depend on this)
resource "time_sleep" "wait_for_nodepool_ready" {
  create_duration = "30s"
  depends_on      = [null_resource.apply_karpenter_nodepool]
}
