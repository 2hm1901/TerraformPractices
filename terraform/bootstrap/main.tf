# ============================================================
# Bootstrap: Tao S3 bucket cho Terraform backend
# Chay 1 lan boi Admin truoc khi team bat dau su dung.
#
# State locking: dung S3 native lockfile (use_lockfile=true)
# khong can DynamoDB nua ke tu Terraform >= 1.10
# ============================================================

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${var.project_name}-terraform-state-${local.account_id}"
}

# -----------------------------------------------------------
# S3 Bucket — luu Terraform state files
# -----------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name

  # Ngan xoa nham bucket khi co state files
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = local.bucket_name
  }
}

# Bat versioning — cho phep rollback state file neu bi hong
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Ma hoa state files khi luu tru
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chan moi public access vao bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------
# IAM Policy — Cap quyen cho team members truy cap backend
# Chi can quyen S3 — khong can DynamoDB nua
# -----------------------------------------------------------
resource "aws_iam_policy" "terraform_state_access" {
  name        = "${var.project_name}-terraform-state-access"
  description = "Allows IAM users to read/write Terraform state on S3 (locking via S3 native lockfile)"

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
      }
    ]
  })
}

# Attach policy cho cac IAM users/roles duoc chi dinh
resource "aws_iam_user_policy_attachment" "terraform_state_access" {
  for_each = toset(var.additional_iam_arns)

  # Lay username tu ARN (arn:aws:iam::123456789012:user/alice → alice)
  user       = split("/", each.value)[1]
  policy_arn = aws_iam_policy.terraform_state_access.arn
}
