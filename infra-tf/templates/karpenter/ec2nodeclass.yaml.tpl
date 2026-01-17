# =========================================
# Karpenter EC2NodeClass Template
# =========================================
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${node_class_name}
spec:
  role: ${node_role}
  amiSelectorTerms:
    - alias: bottlerocket@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
