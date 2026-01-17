# Terraform Module Versioning: Why Use Commit Refs?

## Current Approach vs. Commit Refs

### Your Current Configuration (Version Constraints)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"  # Allows 6.0.0 to 6.x.x (latest patch)
}
```

**Pros:**
- ✅ Automatic security patches
- ✅ Bug fixes included automatically
- ✅ Simpler to maintain

**Cons:**
- ⚠️ Can introduce breaking changes in minor versions
- ⚠️ Less predictable (different versions on different runs)
- ⚠️ Harder to reproduce exact infrastructure state

---

### Alternative: Commit Refs (Pinning)

```hcl
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=cf73787bc163944d63a82e0898aee2bc7ade27ca"
  # OR using Terraform Registry with tag:
  # source = "terraform-aws-modules/vpc/aws"
  # version = "6.5.1"  # Exact version pinning
}
```

**Pros:**
- ✅ **100% Reproducible** - Same code every time
- ✅ **Predictable** - No surprises from updates
- ✅ **Security** - No unexpected changes
- ✅ **Compliance** - Audit trail of exact versions
- ✅ **Stability** - Tested configuration stays tested

**Cons:**
- ⚠️ Manual updates required
- ⚠️ Security patches need manual application
- ⚠️ More maintenance overhead

---

## Why Commit Refs Are Used

### 1. **Reproducibility** 🔄
```hcl
# Same commit = Same infrastructure, every time
source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=cf73787bc163944d63a82e0898aee2bc7ade27ca"
```
- **Problem**: `version = "~> 6.0"` might resolve to `6.0.1` today, `6.0.5` tomorrow
- **Solution**: Commit ref ensures **exact same code** every run

### 2. **Stability** 🛡️
- Prevents breaking changes from newer versions
- Your infrastructure won't change unless you explicitly update
- Critical for production environments

### 3. **Security & Compliance** 🔒
- **Audit Trail**: Know exactly what code ran
- **No Surprises**: New commits can't accidentally deploy
- **Compliance**: Many regulations require version pinning

### 4. **Testing** ✅
- Test with specific commit
- Deploy same tested version to production
- No "works on my machine" issues

---

## Best Practices: Hybrid Approach

### Recommended: Use Exact Versions

```hcl
# Instead of version ranges, pin to exact versions
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"  # Exact version, not range
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.9.0"  # Exact version
}
```

**Benefits:**
- ✅ Reproducible (same version every time)
- ✅ Still uses Terraform Registry (faster downloads)
- ✅ Easy to update (change version number)
- ✅ Clear what version you're using

### When to Use Commit Refs

Use commit refs when:
1. **Testing unreleased features** (specific commit)
2. **Forked modules** (your own modifications)
3. **Git-based modules** (not in Terraform Registry)
4. **Temporary fixes** (hotfix commit before official release)

---

## Your Current Modules Analysis

Looking at your `main.tf`:

```hcl
# Current: Version ranges
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"  # ⚠️ Range - can change
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.9.0"  # ✅ Exact - good!
}
```

**Recommendation**: Update VPC module to exact version:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"  # Latest stable as of 2025
  # ... rest of config
}
```

---

## How to Find Latest Versions

### Method 1: Terraform Registry
Visit: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws

### Method 2: GitHub Releases
Visit: https://github.com/terraform-aws-modules/terraform-aws-vpc/releases

### Method 3: Terraform CLI
```bash
terraform init -upgrade  # Shows available updates
```

---

## Update Strategy

### Development Environment
- Use version ranges: `~> 6.0` (get latest patches)
- Test updates frequently

### Production Environment
- Use exact versions: `6.5.1` (reproducible)
- Update deliberately with testing
- Document version changes in commits

### Update Workflow
1. **Check latest version** in registry
2. **Update version** in `main.tf`
3. **Run `terraform plan`** to see changes
4. **Test in dev/staging** first
5. **Deploy to production** after validation
6. **Commit with message**: "Update VPC module to 6.5.1"

---

## Summary

| Approach | Use Case | Your Status |
|----------|----------|-------------|
| **Version Range** (`~> 6.0`) | Development, rapid iteration | ✅ VPC module |
| **Exact Version** (`6.5.1`) | Production, stability | ✅ EKS module |
| **Commit Ref** (`?ref=abc123`) | Testing, forks, unreleased | ❌ Not used |

**Recommendation**: Switch VPC module to exact version for production stability.

---

## References

- [Terraform Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
- [Terraform AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [Semantic Versioning](https://semver.org/)

