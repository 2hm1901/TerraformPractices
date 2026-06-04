# Yêu cầu dự án — CDO08

## Mục tiêu
Xây dựng hạ tầng AWS bằng Terraform với khả năng quản lý state tập trung cho nhiều người dùng.

## Yêu cầu chức năng

### FR-01: Shared State Management
- [x] State được lưu trên S3 (không dùng local state)
- [x] State versioning được bật để hỗ trợ rollback
- [x] Tất cả members trong team đều đọc/ghi cùng 1 state file

### FR-02: State Locking
- [x] Sử dụng DynamoDB để lock state khi đang apply
- [x] Ngăn chặn 2 người apply cùng lúc (race condition)
- [x] Hỗ trợ force-unlock khi cần thiết (emergency)

### FR-03: Multi-User Access
- [x] Mỗi IAM user có quyền truy cập S3 bucket và DynamoDB table
- [x] Không cần chia sẻ credentials giữa các users
- [x] Admin có thể thêm/xóa quyền của từng user độc lập

### FR-04: Environment Separation
- [x] Hỗ trợ nhiều môi trường: dev, staging, prod
- [x] Mỗi môi trường có state key riêng biệt (`dev/main/`, `prod/main/`)
- [x] Biến cấu hình riêng cho từng môi trường (`dev.tfvars`, `prod.tfvars`)

### FR-05: Resource Idempotency
- [x] Terraform apply không tạo lại resources đã tồn tại (nhờ shared state)
- [x] Tất cả resources có tags chuẩn: `Name`, `Environment`, `ManagedBy`, `Component` (via `default_tags` trong providers.tf)

## Yêu cầu phi chức năng

### NFR-01: Security
- Không hardcode credentials trong code
- Không commit `.tfvars` chứa secrets
- S3 bucket phải có encryption và block public access

### NFR-02: Maintainability
- [x] Sử dụng modules để tái sử dụng code (`modules/networking`, `modules/data`)
- [ ] Mỗi module có README riêng
- [x] Variables phải có description và type rõ ràng

### NFR-03: Reliability
- S3 versioning bật → có thể rollback state
- DynamoDB locking → tránh state corruption
- Backup plan khi state bị lock (force-unlock procedure)

## AWS Region
- Primary: `ap-southeast-2` (Sydney)

## Môi trường
| Môi trường | Mục đích |
|---|---|
| `dev` | Development, testing |
| `staging` | Pre-production |
| `prod` | Production |
