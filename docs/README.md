# CDO08 — Terraform Infrastructure

## Overview
Du an Terraform quan ly AWS resources cho nhieu nguoi dung IAM duoi cung mot root account, voi **shared remote state** de tranh tao lai resources da ton tai.

## Yeu cau he thong
- Terraform >= 1.5
- AWS CLI da cau hinh
- Quyen truy cap IAM vao S3 bucket va DynamoDB table (xem [onboarding.md](onboarding.md))

## Khoi tao lan dau (Admin)
```bash
# Buoc 1: Bootstrap — tao S3 + DynamoDB cho backend
bash scripts/bootstrap.sh

# Buoc 2: Init project chinh
bash scripts/init.sh dev
```

## Su dung hang ngay (moi user)
```bash
# Init ket noi backend (chay 1 lan duy nhat tren moi may)
bash scripts/init.sh dev

# Vao thu muc terraform roi chay
cd terraform
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## Cau truc thu muc
| Thu muc | Muc dich |
|---|---|
| `terraform/bootstrap/` | Tao S3 + DynamoDB backend (chay 1 lan) |
| `terraform/modules/networking/` | Module VPC, subnets, IGW, route tables |
| `terraform/modules/data/` | Module S3, DynamoDB, RDS |
| `terraform/environments/` | File bien theo moi truong |
| `scripts/` | Script tien ich |
| `docs/` | Tai lieu du an |

## Luu y quan trong
- **KHONG** commit file `.tfvars` chua credentials
- **KHONG** xoa DynamoDB table khi dang co nguoi apply
- Luon chay `terraform plan` truoc khi `apply`
- Chay `terraform destroy` rat nguy hiem — chi dung o dev
