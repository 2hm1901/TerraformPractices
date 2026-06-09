# ============================================================
# Networking: Su dung Default VPC va Subnets co san
# ============================================================

data "aws_vpc" "default" {
  default = true
}

# Lay tat ca public subnets trong default VPC (1 subnet/AZ)
# ALB can >= 2 subnets o 2 AZ khac nhau
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
