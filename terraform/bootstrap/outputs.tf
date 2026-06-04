output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy to attach to team members"
  value       = aws_iam_policy.terraform_state_access.arn
}

output "backend_config" {
  description = "Thong tin backend de tham khao. Gia tri thuc te duoc truyen vao qua scripts/init.sh"
  value = <<-EOT
    S3 Bucket  : ${aws_s3_bucket.terraform_state.id}
    Region     : ${var.aws_region}
    Locking    : S3 native lockfile (use_lockfile=true)
    State Key (dev)  : dev/main/terraform.tfstate
    State Key (prod) : prod/main/terraform.tfstate

    Chay lenh sau de ket noi:
      bash scripts/init.sh dev
      bash scripts/init.sh prod
  EOT
}
