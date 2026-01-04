# =============================================================================
# Validate Terraform Configuration (PowerShell)
# =============================================================================
# This script validates Terraform configuration without making changes.
#
# What it does:
#   1. Formats Terraform files
#   2. Initializes Terraform (connects to S3 backend)
#   3. Validates syntax and configuration
#   4. Runs terraform plan (dry-run)
#   5. Reports results
#
# Usage:
#   .\validate-terraform.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

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

# Change to terraform directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$TERRAFORM_DIR = Split-Path -Parent $SCRIPT_DIR

Set-Location $TERRAFORM_DIR

Write-Host "============================================================================="
Write-Host "Terraform Validation"
Write-Host "============================================================================="
Write-Host ""
Write-Host "Working directory: $TERRAFORM_DIR"
Write-Host ""

# Step 1: Format
Write-Step "Formatting Terraform files..."
terraform fmt -recursive
if ($LASTEXITCODE -eq 0) {
    Write-Success "Terraform files formatted"
} else {
    Write-Warning "Some files needed formatting (non-critical)"
}
Write-Host ""

# Step 2: Initialize
Write-Step "Initializing Terraform (connecting to S3 backend)..."
terraform init
if ($LASTEXITCODE -eq 0) {
    Write-Success "Terraform initialized successfully"
} else {
    Write-Error "Terraform initialization failed"
    Write-Host ""
    Write-Host "Common issues:"
    Write-Host "  - S3 bucket doesn't exist (run bootstrap-state.ps1 first)"
    Write-Host "  - DynamoDB table doesn't exist (run bootstrap-state.ps1 first)"
    Write-Host "  - AWS credentials not configured"
    exit 1
}
Write-Host ""

# Step 3: Validate
Write-Step "Validating Terraform configuration..."
terraform validate
if ($LASTEXITCODE -eq 0) {
    Write-Success "Terraform configuration is valid"
} else {
    Write-Error "Terraform validation failed"
    exit 1
}
Write-Host ""

# Step 4: Plan (dry-run)
Write-Step "Running terraform plan (dry-run - no changes will be made)..."
Write-Host ""
terraform plan -out=tfplan
if ($LASTEXITCODE -eq 0) {
    Write-Success "Terraform plan completed successfully"
    Write-Host ""
    Write-Host "Plan summary: Resources will be created/modified as shown above"
    Remove-Item -Force tfplan -ErrorAction SilentlyContinue
} else {
    Write-Error "Terraform plan failed"
    exit 1
}
Write-Host ""

Write-Host "============================================================================="
Write-Success "Terraform validation completed successfully!"
Write-Host "============================================================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Review the plan output above"
Write-Host "  - If ready, run: terraform apply"
Write-Host "  - Or run the Jenkins pipeline to deploy automatically"
Write-Host ""

