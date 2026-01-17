# Fix: Module Source Using Git Commit Ref Instead of Version

## Problem

Terraform is trying to download modules using git commit refs:
```
Could not download module "vpc" source code from
"git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=cf73787bc163944d63a82e0898aee2bc7ade27ca"
```

But your `main.tf` correctly uses the Terraform Registry:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"
}
```

## Root Cause

The `.terraform.lock.hcl` file has cached the old git source reference. This happens when:
1. Modules were previously downloaded from git
2. Lock file wasn't updated after changing to registry source
3. Cached `.terraform` directory has old references

## Solution: Clear Cache and Reinitialize

### Step 1: Remove Cached Terraform Files

```bash
cd infra-tf
rm -rf .terraform .terraform.lock.hcl
```

### Step 2: Reinitialize Terraform

```bash
terraform init
```

This will:
- Download modules from Terraform Registry (not git)
- Create new `.terraform.lock.hcl` with correct sources
- Use version constraints from your `main.tf`

### Step 3: Verify

After `terraform init`, check the lock file:

```bash
grep -A 5 "vpc" .terraform.lock.hcl
```

You should see:
```
provider "registry.terraform.io/terraform-aws-modules/vpc/aws" {
  version     = "6.5.1"
  constraints = "6.5.1"
  hashes = [
    ...
  ]
}
```

**NOT** a git source like:
```
provider "git::https://github.com/..." {
```

## Why This Happens

### Terraform Registry vs Git Sources

**Registry Source** (Correct):
```hcl
source = "terraform-aws-modules/vpc/aws"
version = "6.5.1"
```
- Downloads from: `registry.terraform.io`
- Fast, cached, versioned
- Recommended for production

**Git Source** (What error shows):
```hcl
source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=cf73787bc163944d63a82e0898aee2bc7ade27ca"
```
- Downloads from: GitHub directly
- Slower, requires git access
- Used for testing/forks

## Prevention

1. **Always use Terraform Registry** for published modules
2. **Commit `.terraform.lock.hcl`** to git (for team consistency)
3. **Run `terraform init -upgrade`** when updating versions
4. **Never mix git and registry sources** for the same module

## Quick Fix Command

```bash
cd infra-tf
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform plan  # Verify it works
```

## For Jenkins Pipeline

If this happens in Jenkins, the pipeline should:
1. Always run `terraform init` (clears cache)
2. Use `-upgrade` flag to get latest versions: `terraform init -upgrade`
3. Cache `.terraform` directory between runs (optional optimization)

---

**Note**: The commit ref `cf73787bc163944d63a82e0898aee2bc7ade27ca` in the error is from an old cached reference. After clearing cache and reinitializing, Terraform will use the registry source with version `6.5.1` as specified in your `main.tf`.

