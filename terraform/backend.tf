# ============================================================
# Remote Backend — S3 (Partial Configuration)
#
# File nay chi khai bao loai backend la S3.
# Cac gia tri thuc te duoc truyen dong vao qua scripts/init.sh.
#
# De biet state dang duoc luu o dau, chay:
#   cat .terraform/terraform.tfstate
#
# -----------------------------------------------------------
# Thong tin backend (sau khi chay bootstrap.sh):
#
#   S3 Bucket  : cdo08-terraform-state-{AWS_ACCOUNT_ID}
#   Region     : ap-southeast-2
#   State Key  : {environment}/main/terraform.tfstate
#   Locking    : S3 native lockfile (use_lockfile=true, yeu cau Terraform >= 1.10)
#   Encryption : AES256
#
# Vi du state file cho tung moi truong:
#   dev  -> s3://cdo08-terraform-state-{account_id}/dev/main/terraform.tfstate
#   prod -> s3://cdo08-terraform-state-{account_id}/prod/main/terraform.tfstate
#
# -----------------------------------------------------------
# Cach khoi tao (chay 1 lan tren moi may):
#   bash scripts/init.sh dev    <- moi truong dev
#   bash scripts/init.sh prod   <- moi truong prod
#
# Neu chua co S3 bucket, admin chay truoc:
#   bash scripts/bootstrap.sh
# ============================================================

terraform {
  backend "s3" {}
}
