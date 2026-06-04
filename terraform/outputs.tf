# -----------------------------------------------------------
# Networking outputs
# -----------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.networking.private_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# -----------------------------------------------------------
# Storage outputs
# -----------------------------------------------------------
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.data.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.data.bucket_arn
}

# -----------------------------------------------------------
# General outputs
# -----------------------------------------------------------
output "aws_region" {
  description = "AWS region being used"
  value       = var.aws_region
}

output "environment" {
  description = "Current deployment environment"
  value       = var.environment
}
