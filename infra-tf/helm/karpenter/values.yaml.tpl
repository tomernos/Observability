# Karpenter Configuration Template
nodeSelector:
  karpenter.sh/controller: "true"

dnsPolicy: Default

settings:
  clusterName: ${cluster_name}
  clusterEndpoint: ${cluster_endpoint}
  interruptionQueue: ${interruption_queue}

webhook:
  enabled: false

#controller:
#  resources:
#    requests:
#      cpu: 1
#      memory: 1Gi
#    limits:
#      cpu: 1
#      memory: 1Gi
#
replicas: 1

#serviceAccount:
#  name: karpenter
