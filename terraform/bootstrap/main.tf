# ============================================================
# Bootstrap: Tạo S3 bucket + DynamoDB table cho Terraform backend
# Chạy 1 lần bởi Admin trước khi team bắt đầu sử dụng.
# ============================================================

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  bucket_name  = "${var.project_name}-terraform-state-${local.account_id}"
  table_name   = "${var.project_name}-terraform-locks"
}

# -----------------------------------------------------------
# S3 Bucket — lưu Terraform state files
# -----------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name

  # Ngăn xóa nhầm bucket khi có state files
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = local.bucket_name
  }
}

# Bật versioning — cho phép rollback state file nếu bị hỏng
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Mã hoá state files khi lưu trữ
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chặn mọi public access vào bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------
# DynamoDB Table — State locking (tránh concurrent apply)
# -----------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.table_name
  }
}

# -----------------------------------------------------------
# IAM Policy — Cấp quyền cho team members truy cập backend
# -----------------------------------------------------------
resource "aws_iam_policy" "terraform_state_access" {
  name        = "${var.project_name}-terraform-state-access"
  description = "Allows IAM users to read/write Terraform state on S3 and lock via DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.terraform_state.arn]
      },
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.terraform_state.arn}/*"]
      },
      {
        Sid    = "DynamoDBLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [aws_dynamodb_table.terraform_locks.arn]
      }
    ]
  })
}

# Attach policy cho các IAM users/roles được chỉ định
resource "aws_iam_user_policy_attachment" "terraform_state_access" {
  for_each = toset(var.additional_iam_arns)

  # Lấy username từ ARN (arn:aws:iam::123456789012:user/alice → alice)
  user       = split("/", each.value)[1]
  policy_arn = aws_iam_policy.terraform_state_access.arn
}
