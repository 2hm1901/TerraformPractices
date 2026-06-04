# Kiến trúc hệ thống — CDO08

## Vấn đề cần giải quyết

```
User A (IAM)  --+
User B (IAM)  --+--> Tao resources tren cung 1 region
User C (IAM)  --+         AWS ap-southeast-2
```

**Nếu dùng local state:** Mỗi người có state riêng → người sau `apply` sẽ thấy resources chưa tồn tại → TẠO LẠI → conflict/duplicate.

**Giải pháp: Shared Remote State**

```
User A (IAM)  ──┐
User B (IAM)  ──┤──▶ S3 Bucket (shared state)  ◀──▶ AWS Resources
User C (IAM)  ──┘         │
                     DynamoDB (lock)
                    "chỉ 1 người apply tại 1 thời điểm"
```

## Luồng hoạt động

```
terraform apply
      │
      ▼
  Đọc state từ S3
      │
      ▼
  So sánh state vs reality
      │
      ├── Resource đã tồn tại? → SKIP (không tạo lại)
      └── Resource chưa có?   → CREATE
      │
      ▼
  Acquire lock (DynamoDB)
      │
      ▼
  Apply changes
      │
      ▼
  Write new state → S3
      │
      ▼
  Release lock (DynamoDB)
```

## Components

### 1. S3 Bucket (State Storage)
- Tên: `cdo08-terraform-state-{aws_account_id}`
- Versioning: BẬT (rollback nếu state bị hỏng)
- Encryption: SSE-S3
- Access: IAM Policy cho phép tất cả users trong root account

### 2. DynamoDB Table (State Locking)
- Tên: `cdo08-terraform-locks`
- Partition Key: `LockID` (String)
- Mục đích: Ngăn 2 người `apply` cùng lúc → tránh race condition

### 3. IAM Policy (Shared Access)
Mỗi IAM user cần policy cho phép:
- `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` — đọc/ghi state
- `s3:ListBucket` — list state files
- `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem` — lock/unlock

## State Key Structure
```
s3://cdo08-terraform-state-{account_id}/
├── dev/
│   └── main/
│       └── terraform.tfstate    <- tat ca resources dev
└── prod/
    └── main/
        └── terraform.tfstate    <- tat ca resources prod
```
