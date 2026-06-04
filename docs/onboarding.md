# Onboarding — Thêm user mới vào dự án

## Điều kiện tiên quyết
- User đã có IAM account trong root AWS account
- Admin đã chạy `terraform/bootstrap` để tạo S3 + DynamoDB

## Bước 1: Admin cấp quyền cho user mới

Admin attach IAM policy sau vào user (hoặc group):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::cdo08-terraform-state-{ACCOUNT_ID}",
        "arn:aws:s3:::cdo08-terraform-state-{ACCOUNT_ID}/*"
      ]
    },
    {
      "Sid": "TerraformLockAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/cdo08-terraform-locks"
    }
  ]
}
```

> Thay `{ACCOUNT_ID}` bằng AWS Account ID thực tế (12 số).

## Bước 2: User tự thiết lập môi trường

```bash
# 1. Cài AWS CLI và cấu hình credentials
aws configure
# Nhap: Access Key, Secret Key, Region (ap-southeast-2)

# 2. Clone repo
git clone <repo_url>
cd CDO08

# 3. Init Terraform (kết nối với shared S3 backend)
bash scripts/init.sh

# 4. Kiểm tra state hiện tại
terraform state list

# 5. Plan trước khi apply
terraform plan -var-file=environments/dev.tfvars
```

## Bước 3: Verify quyền truy cập

```bash
# Kiểm tra có thể đọc S3 state bucket
aws s3 ls s3://cdo08-terraform-state-{ACCOUNT_ID}/

# Kiểm tra DynamoDB table tồn tại
aws dynamodb describe-table --table-name cdo08-terraform-locks
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|---|---|---|
| `Error: AccessDenied S3` | Chưa có policy S3 | Admin cần attach policy |
| `Error: LockTableNotFound` | Chưa có DynamoDB table | Admin chạy bootstrap |
| `Error: State is locked` | Người khác đang apply | Đợi hoặc xem lock info |
| `Error: state data in S3` | State file bị corrupt | Xem S3 versioning để rollback |

## Xử lý State bị lock (emergency)

```bash
# Xem thông tin lock
terraform force-unlock -help

# Force unlock (CHỈ dùng khi chắc chắn không ai đang apply)
terraform force-unlock {LOCK_ID}
```
