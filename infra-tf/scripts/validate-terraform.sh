#!/bin/bash

# =============================================================================
# Validate Terraform Configuration
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
#   chmod +x validate-terraform.sh
#   ./validate-terraform.sh
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

cd "$TERRAFORM_DIR"

echo "============================================================================="
echo "Terraform Validation"
echo "============================================================================="
echo ""
echo "Working directory: $TERRAFORM_DIR"
echo ""

# Step 1: Format
print_step "Formatting Terraform files..."
if terraform fmt -recursive; then
    print_success "Terraform files formatted"
else
    print_warning "Some files needed formatting (non-critical)"
fi
echo ""

# Step 2: Initialize
print_step "Initializing Terraform (connecting to S3 backend)..."
if terraform init; then
    print_success "Terraform initialized successfully"
else
    print_error "Terraform initialization failed"
    echo ""
    echo "Common issues:"
    echo "  - S3 bucket doesn't exist (run bootstrap-state.sh first)"
    echo "  - DynamoDB table doesn't exist (run bootstrap-state.sh first)"
    echo "  - AWS credentials not configured"
    exit 1
fi
echo ""

# Step 3: Validate
print_step "Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    exit 1
fi
echo ""

# Step 4: Plan (dry-run)
print_step "Running terraform plan (dry-run - no changes will be made)..."
echo ""
if terraform plan -out=tfplan; then
    print_success "Terraform plan completed successfully"
    echo ""
    echo "Plan summary:"
    terraform show -json tfplan | grep -o '"type":"[^"]*"' | sort -u | sed 's/"type":"//;s/"//' | while read -r resource; do
        echo "  - $resource"
    done
    rm -f tfplan
else
    print_error "Terraform plan failed"
    exit 1
fi
echo ""

echo "============================================================================="
print_success "Terraform validation completed successfully!"
echo "============================================================================="
echo ""
echo "Next steps:"
echo "  - Review the plan output above"
echo "  - If ready, run: terraform apply"
echo "  - Or run the Jenkins pipeline to deploy automatically"
echo ""

