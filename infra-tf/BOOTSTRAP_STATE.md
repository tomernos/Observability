# Bootstrap Terraform State Backend

## Overview

Before running Terraform, you need to create the S3 bucket and DynamoDB table for remote state.

## Option 1: Manual Creation (Quick)

### Create S3 Bucket
```bash
aws s3 mb s3://tnt-eu-observability-dev-tf --region eu-central-1
aws s3api put-bucket-versioning \
  --bucket tnt-eu-observability-dev-tf \
  --versioning-configuration Status=Enabled \
  --region eu-central-1
```

### Create DynamoDB Table
```bash
aws dynamodb create-table \
  --table-name tnt-eu-observability-dev-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

## Option 2: Bootstrap Terraform (Recommended)

Create a bootstrap Terraform configuration:

```hcl
# bootstrap-state/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "tnt-eu-observability-dev-tf"
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  tags = {
    Name        = "Terraform State"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_dynamodb_table" "tfstate_locks" {
  name         = "tnt-eu-observability-dev-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "Terraform State Locks"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

Then run:
```bash
cd bootstrap-state
terraform init
terraform plan
terraform apply
```

## Verification

After creation, verify:
```bash
# Check S3 bucket
aws s3 ls s3://tnt-eu-observability-dev-tf

# Check DynamoDB table
aws dynamodb describe-table --table-name tnt-eu-observability-dev-tf-locks --region eu-central-1
```

## Notes

- The S3 bucket name must be globally unique
- The DynamoDB table is used for state locking (prevents concurrent modifications)
- Both resources should be in the same region as your infrastructure
- Keep these resources even if you destroy the main infrastructure

