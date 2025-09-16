# External DNS Configuration Template
provider: aws

aws:
  region: ${aws_region}
  zoneType: public

domainFilters:
  - ${domain_name}

sources:
  - service
  - ingress

policy: upsert-only
registry: txt
txtOwnerId: ${txt_owner_id}

serviceAccount:
  create: true
  name: external-dns
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}

logLevel: info
interval: 1m

resources:
  requests:
    cpu: 10m
    memory: 50Mi
  limits:
    cpu: 50m
    memory: 100Mi

rbac:
  create: true
