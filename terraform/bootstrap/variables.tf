variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "cdo08"
}

variable "additional_iam_arns" {
  description = "List of IAM user/role ARNs to grant access to the state backend (e.g. team members)"
  type        = list(string)
  default     = []
  # Example:
  # ["arn:aws:iam::123456789012:user/alice", "arn:aws:iam::123456789012:user/bob"]
}
