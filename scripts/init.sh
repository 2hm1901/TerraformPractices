#!/usr/bin/env bash
# ============================================================
# init.sh — Chạy bởi mỗi user để kết nối với shared backend
# Su dung: bash scripts/init.sh <environment>
# Vi du:   bash scripts/init.sh dev
#          bash scripts/init.sh prod
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "CDO08 -- Khoi tao Terraform"
echo "================================="

# Kiem tra AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
  echo "ERROR: AWS credentials chua duoc cau hinh. Chay: aws configure"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "ap-southeast-2")
BUCKET_NAME="cdo08-terraform-state-${ACCOUNT_ID}"

echo "AWS Account ID : $ACCOUNT_ID"
echo "Region         : $REGION"
echo "State Bucket   : $BUCKET_NAME"

# Kiem tra S3 bucket ton tai
if ! aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
  echo ""
  echo "ERROR: Bucket '$BUCKET_NAME' khong ton tai."
  echo "       Admin can chay: bash scripts/bootstrap.sh"
  exit 1
fi

echo ""

# Chon environment
ENV="${1:-dev}"
echo "Environment: $ENV"

cd "$TERRAFORM_DIR"

echo ""
echo "Initializing Terraform voi S3 backend..."
terraform init -reconfigure \
  -backend-config="bucket=$BUCKET_NAME" \
  -backend-config="key=$ENV/main/terraform.tfstate" \
  -backend-config="region=$REGION" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"

echo ""
echo "Init hoan tat! Chay cac lenh sau:"
echo ""
echo "  cd terraform"
echo "  terraform plan  -var-file=environments/$ENV.tfvars"
echo "  terraform apply -var-file=environments/$ENV.tfvars"
