#!/bin/bash
set -euo pipefail

# Bootstrap Terraform backend (S3 bucket and DynamoDB table)
# This script creates the infrastructure needed to store Terraform state
# These resources are NOT managed by Terraform itself

echo "🚀 Bootstrapping Terraform backend..."

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# Use AWS CLI configured region or default to ca-west-1
REGION="${AWS_DEFAULT_REGION:-$(aws configure get region || echo 'ca-west-1')}"
BUCKET_NAME="rewards-app-tf-state-${ACCOUNT_ID}"
TABLE_NAME="rewards-app-tf-locks"

echo "Using AWS region: ${REGION}"

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket: ${BUCKET_NAME}"
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
  echo "  ✓ Bucket already exists"
else
  aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"

  # Enable versioning for state history
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  # Block public access
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "  ✓ Bucket created and configured"
fi

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table: ${TABLE_NAME}"
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "  ✓ Table already exists"
else
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" \
    --tags "Key=Project,Value=rewards-app" "Key=ManagedBy,Value=manual" "Key=Environment,Value=demo"

  echo "  ⏳ Waiting for table to be active..."
  aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${REGION}"
  echo "  ✓ Table created"
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. cd terraform"
echo "  2. terraform init"
echo "  3. export TF_VAR_rails_master_key=\"your-master-key-here\""
echo "  4. terraform apply"
echo ""
echo "Backend configuration:"
echo "  Bucket: ${BUCKET_NAME}"
echo "  Table:  ${TABLE_NAME}"
echo "  Region: ${REGION}"
