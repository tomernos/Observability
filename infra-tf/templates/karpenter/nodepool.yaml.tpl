# =========================================
# Karpenter NodePool Template
# =========================================
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${node_pool_name}
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${node_class_name}
      requirements:
%{ for req in node_requirements ~}
        - key: ${req.key}
          operator: ${req.operator}
          values:
%{ for value in req.values ~}
            - ${value}
%{ endfor ~}
%{ endfor ~}
%{ if limits != null && (limits.cpu != null || limits.memory != null) ~}
  limits:
%{ if limits.cpu != null ~}
    cpu: ${limits.cpu}
%{ endif ~}
%{ if limits.memory != null ~}
    memory: ${limits.memory}
%{ endif ~}
%{ endif ~}
  disruption:
    consolidationPolicy: ${consolidation_policy}
    consolidateAfter: ${consolidate_after}
  weight: ${weight}
