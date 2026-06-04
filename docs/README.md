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

## Project Structure
```
CDO08/
├── terraform/
│   ├── bootstrap/           # One-time setup: creates S3 bucket + DynamoDB table
│   ├── modules/
│   │   ├── networking/      # VPC, subnets, IGW, route tables
│   │   └── data/            # S3, DynamoDB, RDS (storage resources)
│   ├── environments/        # Per-environment variable files
│   │   ├── dev.tfvars
│   │   └── prod.tfvars
│   ├── main.tf              # Root module — calls all modules
│   ├── providers.tf         # AWS provider config
│   ├── backend.tf           # S3 remote backend config
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── versions.tf          # Provider version constraints
├── scripts/
│   ├── bootstrap.sh         # Run once to set up backend infrastructure
│   └── init.sh              # Run by each user to initialize Terraform
├── docs/
│   ├── README.md
│   ├── architecture.md
│   ├── onboarding.md        # How new users get access
│   └── requirements.md
```