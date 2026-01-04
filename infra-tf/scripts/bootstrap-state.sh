#!/bin/bash

# =============================================================================
# Bootstrap Terraform State Backend
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
#   chmod +x bootstrap-state.sh
#   ./bootstrap-state.sh
# =============================================================================

set -e  # Exit on error

# Configuration
REGION="eu-central-1"
S3_BUCKET="tnt-eu-observability-dev-tf"
DYNAMODB_TABLE="tnt-eu-observability-dev-tf-locks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
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

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

check_s3_bucket() {
    print_step "Checking S3 bucket: ${S3_BUCKET}"
    
    if aws s3 ls "s3://${S3_BUCKET}" --region "${REGION}" &> /dev/null; then
        print_success "S3 bucket already exists: ${S3_BUCKET}"
        return 0
    else
        print_warning "S3 bucket does not exist. Will create it."
        return 1
    fi
}

create_s3_bucket() {
    print_step "Creating S3 bucket: ${S3_BUCKET}"
    
    # Create bucket
    if aws s3 mb "s3://${S3_BUCKET}" --region "${REGION}"; then
        print_success "S3 bucket created: ${S3_BUCKET}"
    else
        print_error "Failed to create S3 bucket"
        exit 1
    fi
    
    # Enable versioning
    print_step "Enabling versioning on S3 bucket..."
    if aws s3api put-bucket-versioning \
        --bucket "${S3_BUCKET}" \
        --versioning-configuration Status=Enabled \
        --region "${REGION}"; then
        print_success "Versioning enabled on S3 bucket"
    else
        print_warning "Failed to enable versioning (non-critical)"
    fi
    
    # Enable encryption
    print_step "Enabling encryption on S3 bucket..."
    if aws s3api put-bucket-encryption \
        --bucket "${S3_BUCKET}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --region "${REGION}" &> /dev/null; then
        print_success "Encryption enabled on S3 bucket"
    else
        print_warning "Failed to enable encryption (non-critical)"
    fi
}

check_dynamodb_table() {
    print_step "Checking DynamoDB table: ${DYNAMODB_TABLE}"
    
    if aws dynamodb describe-table \
        --table-name "${DYNAMODB_TABLE}" \
        --region "${REGION}" &> /dev/null; then
        print_success "DynamoDB table already exists: ${DYNAMODB_TABLE}"
        return 0
    else
        print_warning "DynamoDB table does not exist. Will create it."
        return 1
    fi
}

create_dynamodb_table() {
    print_step "Creating DynamoDB table: ${DYNAMODB_TABLE}"
    
    if aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}" &> /dev/null; then
        print_success "DynamoDB table created: ${DYNAMODB_TABLE}"
        
        # Wait for table to be active
        print_step "Waiting for table to become active..."
        aws dynamodb wait table-exists \
            --table-name "${DYNAMODB_TABLE}" \
            --region "${REGION}"
        print_success "DynamoDB table is active"
    else
        print_error "Failed to create DynamoDB table"
        exit 1
    fi
}

validate_resources() {
    print_step "Validating resources..."
    
    # Validate S3 bucket
    if aws s3 ls "s3://${S3_BUCKET}" --region "${REGION}" &> /dev/null; then
        print_success "S3 bucket validated: ${S3_BUCKET}"
    else
        print_error "S3 bucket validation failed"
        exit 1
    fi
    
    # Validate DynamoDB table
    if aws dynamodb describe-table \
        --table-name "${DYNAMODB_TABLE}" \
        --region "${REGION}" &> /dev/null; then
        print_success "DynamoDB table validated: ${DYNAMODB_TABLE}"
    else
        print_error "DynamoDB table validation failed"
        exit 1
    fi
}

# Main execution
main() {
    echo "============================================================================="
    echo "Bootstrap Terraform State Backend"
    echo "============================================================================="
    echo ""
    echo "This script will create:"
    echo "  - S3 bucket: ${S3_BUCKET}"
    echo "  - DynamoDB table: ${DYNAMODB_TABLE}"
    echo "  - Region: ${REGION}"
    echo ""
    read -p "Do you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted by user"
        exit 0
    fi
    
    check_prerequisites
    echo ""
    
    # S3 Bucket
    if ! check_s3_bucket; then
        create_s3_bucket
    fi
    echo ""
    
    # DynamoDB Table
    if ! check_dynamodb_table; then
        create_dynamodb_table
    fi
    echo ""
    
    # Validation
    validate_resources
    echo ""
    
    echo "============================================================================="
    print_success "Bootstrap completed successfully!"
    echo "============================================================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run: cd ../.. && terraform init"
    echo "  2. Run: terraform validate"
    echo "  3. Run: terraform plan"
    echo ""
}

# Run main function
main

