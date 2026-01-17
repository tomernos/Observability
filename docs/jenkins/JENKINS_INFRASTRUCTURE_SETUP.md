# Jenkins Infrastructure Pipeline Setup

This guide explains how to configure Jenkins to run the infrastructure pipeline directly from the **Observability** repository.

## Overview

The infrastructure pipeline (`Jenkinsfile.infrastructure`) is located in the **Observability** repository root and works directly with the Terraform code in `infra-tf/`. This eliminates the need to checkout multiple repositories.

## Prerequisites

1. **Jenkins Shared Library**: Ensure the `jenkins-shared-library` is configured in Jenkins
2. **AWS Credentials**: Create Jenkins credential `aws-creds` (Username/Password type)
   - Username: AWS Access Key ID
   - Password: AWS Secret Access Key
3. **Git Access**: Jenkins needs access to the Observability repository

## Jenkins Job Configuration

### Step 1: Create New Pipeline Job

1. In Jenkins, click **New Item**
2. Enter name: `chatapp-infrastructure` (or your preferred name)
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

1. **General Settings**:
   - ✅ **GitHub project**: (Optional) Enter your Observability repo URL
   - ✅ **Build Triggers**: Configure as needed (e.g., GitHub webhook, polling)

2. **Pipeline Definition**:
   - Select: **Pipeline script from SCM**
   - **SCM**: Select **Git**
   - **Repository URL**: `https://github.com/tomernos/Observability.git` (or your repo URL)
   - **Credentials**: (Optional) If repo is private, select your Git credentials
   - **Branches to build**: 
     - Branch Specifier: `*/develop` (or `*/main` for production)
   - **Script Path**: `Jenkinsfile.infrastructure`
   - **Lightweight checkout**: ❌ Uncheck this (we need full checkout)

3. **Advanced Settings** (if needed):
   - **Additional Behaviours**: None required

### Step 3: Save and Run

1. Click **Save**
2. Click **Build Now** to test the pipeline

## Pipeline Structure

```
Observability/
├── Jenkinsfile.infrastructure  ← Pipeline definition
└── infra-tf/                  ← Terraform code
    ├── main.tf
    ├── backend.tf
    ├── variables.tf
    └── ...
```

## Pipeline Stages

1. **Checkout**: Checks out the Observability repository
2. **Install Tools**: Installs Terraform 1.14.3 and AWS CLI v2
3. **Terraform Init**: Initializes Terraform with S3 backend
4. **Terraform Validate**: Validates Terraform configuration
5. **Terraform Plan**: Creates execution plan
6. **Terraform Apply**: Applies changes (only on `main` or `develop` branches)
7. **Output Cluster Info**: Displays cluster information

## Environment Variables

The pipeline uses these environment variables (configured in `Jenkinsfile.infrastructure`):

- `AWS_REGION`: `eu-central-1`
- `AWS_CREDENTIALS_ID`: `aws-creds` (Jenkins credential ID)
- `CLUSTER_NAME`: `tnt-eu-observability-dev-eks`
- `TF_STATE_BUCKET`: `tnt-eu-observability-dev-tf`
- `TF_STATE_KEY`: `tnt-eu-observability-dev-tf.tfstate`
- `TF_STATE_REGION`: `eu-central-1`
- `TF_LOCK_TABLE`: `tnt-eu-observability-dev-tf-locks`

## Troubleshooting

### Pipeline can't find `main.tf`

**Error**: `main.tf not found in infra-tf`

**Solution**: 
- Verify the `infra-tf` directory exists in the Observability repository
- Check that you're building from the correct branch
- Ensure the Script Path is set to `Jenkinsfile.infrastructure`

### AWS credentials not working

**Error**: `Failed to get AWS account ID`

**Solution**:
- Verify the `aws-creds` credential exists in Jenkins
- Check that the Access Key ID and Secret Access Key are correct
- Ensure the AWS credentials have necessary permissions

### Terraform state lock error

**Error**: `Error acquiring the state lock`

**Solution**:
- Another pipeline run might be in progress
- Wait for the previous run to complete
- Or manually unlock: `terraform force-unlock <LOCK_ID>`

## Benefits of This Approach

✅ **Simpler**: No need to checkout multiple repositories  
✅ **Faster**: Single repository checkout  
✅ **Cleaner**: Infrastructure code and pipeline in the same repo  
✅ **Easier to maintain**: All infrastructure-related code in one place  

## Next Steps

After the infrastructure pipeline runs successfully:

1. **CI Pipeline**: Configure `chatapp-ci` pipeline in ChatApplication repo
2. **CD Pipeline**: Configure `chatapp-cd` pipeline in ChatApplication repo
3. **Verify**: Check that the EKS cluster is created and accessible

## Related Documentation

- [Terraform Backend Setup](../infra-tf/BOOTSTRAP_STATE.md)
- [Jenkins Shared Library](../../JenkinsSharedLibrary/README.md)

