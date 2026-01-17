# Quick Jenkins Infrastructure Pipeline Setup

## TL;DR - Configure Jenkins Job

1. **Create Pipeline Job**:
   - Name: `chatapp-infrastructure`
   - Type: **Pipeline**

2. **Pipeline Configuration**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/tomernos/Observability.git`
   - **Branch**: `*/develop` (or `*/main`)
   - **Script Path**: `Jenkinsfile.infrastructure`
   - **Lightweight checkout**: ❌ Uncheck

3. **Required Credentials**:
   - `aws-creds` (Username/Password)
     - Username: AWS Access Key ID
     - Password: AWS Secret Access Key

4. **Save and Build**

## Key Differences from ChatApplication Pipeline

✅ **Simpler**: No need to checkout multiple repos  
✅ **Direct**: Pipeline runs directly in Observability repo  
✅ **Cleaner**: All infrastructure code in one place  

## Pipeline Location

```
Observability/
├── Jenkinsfile.infrastructure  ← Use this file
└── infra-tf/                  ← Terraform code (auto-detected)
```

## That's It!

The pipeline will:
1. Checkout Observability repo
2. Install Terraform & AWS CLI
3. Run Terraform init/validate/plan/apply
4. Output cluster information

See [JENKINS_INFRASTRUCTURE_SETUP.md](./JENKINS_INFRASTRUCTURE_SETUP.md) for detailed documentation.

