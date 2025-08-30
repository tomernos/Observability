# Terraform Bootstrap Layer

This directory provides a reusable Terraform foundational layer.

## Files
- `backend.tf` – Declares S3 backend type only. Real values come from `*.s3.tfbackend` files.
- `versions.tf` – Pins Terraform & provider versions for reproducibility.
- `providers.tf` – AWS provider with unified default tags.
- `variables.tf` – Inputs (region, environment, project, etc.).
- `locals.tf` – Derived naming & tagging logic.
- `datasources.tf` – Identity, region & AZ lookups.
- `outputs.tf` – Basic outputs for sanity checks.
- `env/<region>/*.s3.tfbackend` – Backend config per environment.

## Why empty backend block?
Keeping `backend "s3" {}` empty lets you:
1. Reuse the module across regions/accounts.
2. Avoid committing bucket names/ARNs.
3. Supply all sensitive / varying params at init time.

## Backend config strategy
Each `*.s3.tfbackend` file typically includes:
```
bucket         = "your-terraform-state-bucket"
key            = "<scope>/<env>/terraform.tfstate"
region         = "eu-north-1"
encrypt        = true
# One of the locking approaches:
# use_lockfile  = true              # Requires S3 Object Lock (newer native option)
# dynamodb_table = "terraform-locks" # Classic DynamoDB locking
profile        = "default"
# kms_key_id    = "arn:aws:kms:..."   # (optional) for SSE-KMS
```

Initiate for dev:
```
terraform init -backend-config=env/eu-north-1/dev.s3.tfbackend \
  -reconfigure
```

## Locking options
- `use_lockfile = true`: Uses S3 object lock (bucket must be created with Object Lock enabled, immutable mode or governance). No DynamoDB needed.
- `dynamodb_table = "terraform-locks"`: Traditional lock. Table must exist with primary key `LockID` (string). Safe if Object Lock not available.

Prefer `use_lockfile` for simplicity if you control bucket creation and can enable Object Lock (must be at bucket creation time).

## Variables to supply (example tfvars)
`dev.auto.tfvars`:
```
project      = "observability"
environment  = "dev"
aws_region   = "eu-north-1"
aws_profile  = "default"
cost_center  = "1234"
```

## Recommended enhancements (future)
- Add remote state data sources for cross-layer references
- Introduce workspaces if needing ephemeral preview envs
- Add CI pipeline (fmt, validate, plan)
- Create a separate state bucket + locking table module

---
Generated scaffold. Adjust bucket names & locking method before first init.
