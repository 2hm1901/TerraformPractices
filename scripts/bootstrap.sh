#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — Chạy 1 lần bởi Admin để tạo S3 + DynamoDB
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/../terraform/bootstrap"

echo "CDO08 -- Khoi tao Terraform Backend"
echo "====================================="

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
echo ""

# Guard: kiem tra neu bootstrap da duoc chay truoc do
if aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
  echo "INFO: Backend da duoc khoi tao truoc do (bucket '$BUCKET_NAME' da ton tai)."
  echo "      Script nay chi can chay 1 lan boi Admin."
  echo "      Neu ban la user moi, hay chay: bash scripts/init.sh"
  exit 0
fi

cd "$BOOTSTRAP_DIR"

echo "Initializing Terraform bootstrap..."
terraform init

echo ""
echo "Planning bootstrap resources..."
terraform plan -var="aws_region=$REGION"

echo ""
read -p "Tao S3 bucket va DynamoDB table? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Da huy."
  exit 0
fi

echo ""
echo "Applying bootstrap..."
terraform apply -var="aws_region=$REGION" -auto-approve

echo ""
echo "Bootstrap hoan tat!"
echo ""
echo "Cap nhat backend.tf voi thong tin sau:"
terraform output backend_config
