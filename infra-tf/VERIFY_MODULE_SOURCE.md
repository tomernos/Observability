# Verify Module Source Configuration

## Problem: Git Commit Ref Error

If you see this error:
```
Error: Failed to download module "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=cf73787bc163944d63a82e0898aee2bc7ade27ca"
```

But your `main.tf` uses:
```hcl
source  = "terraform-aws-modules/vpc/aws"
version = "6.5.1"
```

## Root Cause

Terraform is using a cached git source reference instead of the registry source. This happens when:
1. `.terraform.lock.hcl` has old git references
2. `.terraform/` directory has cached modules
3. Jenkins workspace has stale cache

## Solution: Manual Verification

### Step 1: Check main.tf Source

```bash
cd infra-tf
grep -A 3 'module "vpc"' main.tf
```

Should show:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"
}
```

**NOT**:
```hcl
source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=..."
```

### Step 2: Clear All Cache

```bash
cd infra-tf
rm -rf .terraform .terraform.lock.hcl .terraform.lock.hcl.backup
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
```

### Step 3: Verify No Git Sources

```bash
grep -r "git::.*vpc" . || echo "✅ No git sources found"
grep -r "ref=cf73787" . || echo "✅ No commit refs found"
```

### Step 4: Reinitialize

```bash
terraform init -upgrade
```

The `-upgrade` flag forces Terraform to:
- Check for newer module versions
- Re-download from registry
- Create fresh lock file

### Step 5: Verify Lock File

```bash
grep -A 5 "vpc" .terraform.lock.hcl
```

Should show:
```
provider "registry.terraform.io/terraform-aws-modules/vpc/aws" {
  version     = "6.5.1"
  constraints = "6.5.1"
```

**NOT**:
```
provider "git::https://github.com/..." {
```

## Jenkins Pipeline Fix

The pipeline now:
1. ✅ Clears all Terraform cache
2. ✅ Verifies module source before init
3. ✅ Uses `-upgrade` flag to force fresh download
4. ✅ Fails fast if git source is detected

## If Error Persists

1. **Check Jenkins workspace**: The workspace might have cached files
   - Solution: Delete and recreate the Jenkins job, or manually clean workspace

2. **Check for multiple main.tf files**: There might be another config file
   ```bash
   find . -name "main.tf" -exec grep -l "git::.*vpc" {} \;
   ```

3. **Check Terraform version**: Older versions might behave differently
   ```bash
   terraform version
   ```

4. **Manual test**: Run locally to verify
   ```bash
   cd infra-tf
   rm -rf .terraform .terraform.lock.hcl
   terraform init -upgrade
   terraform plan
   ```

## Prevention

1. ✅ Never commit `.terraform.lock.hcl` with git sources
2. ✅ Always use Terraform Registry for published modules
3. ✅ Use exact versions (`6.5.1`) not ranges (`~> 6.0`)
4. ✅ Clear cache in CI/CD pipelines before init
5. ✅ Use `-upgrade` flag in pipelines to ensure fresh downloads

