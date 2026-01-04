# =============================================================================
# Bootstrap Terraform State Backend (PowerShell)
# =============================================================================
# This script creates the S3 bucket and DynamoDB table required for Terraform
# remote state backend.
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - AWS credentials with permissions to create S3 buckets and DynamoDB tables
#   - Region: eu-central-1
#
# What it does:
#   1. Checks if S3 bucket exists, creates if missing
#   2. Enables versioning on S3 bucket
#   3. Checks if DynamoDB table exists, creates if missing
#   4. Validates both resources exist
#
# Usage:
#   .\bootstrap-state.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

# Configuration
$REGION = "eu-central-1"
$S3_BUCKET = "tnt-eu-observability-dev-tf"
$DYNAMODB_TABLE = "tnt-eu-observability-dev-tf-locks"

# Functions
function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Green
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Check-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check AWS CLI
    try {
        $null = Get-Command aws -ErrorAction Stop
    } catch {
        Write-Error "AWS CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check AWS credentials
    try {
        $null = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "AWS credentials not configured"
        }
    } catch {
        Write-Error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Test-S3Bucket {
    Write-Step "Checking S3 bucket: $S3_BUCKET"
    
    try {
        $null = aws s3 ls "s3://$S3_BUCKET" --region $REGION 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "S3 bucket already exists: $S3_BUCKET"
            return $true
        }
    } catch {
        # Bucket doesn't exist
    }
    
    Write-Warning "S3 bucket does not exist. Will create it."
    return $false
}

function New-S3Bucket {
    Write-Step "Creating S3 bucket: $S3_BUCKET"
    
    # Create bucket
    aws s3 mb "s3://$S3_BUCKET" --region $REGION
    if ($LASTEXITCODE -eq 0) {
        Write-Success "S3 bucket created: $S3_BUCKET"
    } else {
        Write-Error "Failed to create S3 bucket"
        exit 1
    }
    
    # Enable versioning
    Write-Step "Enabling versioning on S3 bucket..."
    $versioningConfig = @{
        Status = "Enabled"
    } | ConvertTo-Json
    
    aws s3api put-bucket-versioning `
        --bucket $S3_BUCKET `
        --versioning-configuration $versioningConfig `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Versioning enabled on S3 bucket"
    } else {
        Write-Warning "Failed to enable versioning (non-critical)"
    }
    
    # Enable encryption
    Write-Step "Enabling encryption on S3 bucket..."
    $encryptionConfig = @{
        Rules = @(
            @{
                ApplyServerSideEncryptionByDefault = @{
                    SSEAlgorithm = "AES256"
                }
            }
        )
    } | ConvertTo-Json -Depth 10
    
    aws s3api put-bucket-encryption `
        --bucket $S3_BUCKET `
        --server-side-encryption-configuration $encryptionConfig `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Encryption enabled on S3 bucket"
    } else {
        Write-Warning "Failed to enable encryption (non-critical)"
    }
}

function Test-DynamoDBTable {
    Write-Step "Checking DynamoDB table: $DYNAMODB_TABLE"
    
    try {
        $null = aws dynamodb describe-table `
            --table-name $DYNAMODB_TABLE `
            --region $REGION 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "DynamoDB table already exists: $DYNAMODB_TABLE"
            return $true
        }
    } catch {
        # Table doesn't exist
    }
    
    Write-Warning "DynamoDB table does not exist. Will create it."
    return $false
}

function New-DynamoDBTable {
    Write-Step "Creating DynamoDB table: $DYNAMODB_TABLE"
    
    aws dynamodb create-table `
        --table-name $DYNAMODB_TABLE `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "DynamoDB table created: $DYNAMODB_TABLE"
        
        # Wait for table to be active
        Write-Step "Waiting for table to become active..."
        aws dynamodb wait table-exists `
            --table-name $DYNAMODB_TABLE `
            --region $REGION
        Write-Success "DynamoDB table is active"
    } else {
        Write-Error "Failed to create DynamoDB table"
        exit 1
    }
}

function Test-Resources {
    Write-Step "Validating resources..."
    
    # Validate S3 bucket
    $null = aws s3 ls "s3://$S3_BUCKET" --region $REGION 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "S3 bucket validated: $S3_BUCKET"
    } else {
        Write-Error "S3 bucket validation failed"
        exit 1
    }
    
    # Validate DynamoDB table
    $null = aws dynamodb describe-table `
        --table-name $DYNAMODB_TABLE `
        --region $REGION 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "DynamoDB table validated: $DYNAMODB_TABLE"
    } else {
        Write-Error "DynamoDB table validation failed"
        exit 1
    }
}

# Main execution
Write-Host "============================================================================="
Write-Host "Bootstrap Terraform State Backend"
Write-Host "============================================================================="
Write-Host ""
Write-Host "This script will create:"
Write-Host "  - S3 bucket: $S3_BUCKET"
Write-Host "  - DynamoDB table: $DYNAMODB_TABLE"
Write-Host "  - Region: $REGION"
Write-Host ""

$response = Read-Host "Do you want to continue? (yes/no)"
if ($response -notmatch "^[Yy][Ee][Ss]$") {
    Write-Host "Aborted by user"
    exit 0
}

Write-Host ""

Check-Prerequisites
Write-Host ""

# S3 Bucket
if (-not (Test-S3Bucket)) {
    New-S3Bucket
}
Write-Host ""

# DynamoDB Table
if (-not (Test-DynamoDBTable)) {
    New-DynamoDBTable
}
Write-Host ""

# Validation
Test-Resources
Write-Host ""

Write-Host "============================================================================="
Write-Success "Bootstrap completed successfully!"
Write-Host "============================================================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run: cd .. && terraform init"
Write-Host "  2. Run: terraform validate"
Write-Host "  3. Run: terraform plan"
Write-Host ""

