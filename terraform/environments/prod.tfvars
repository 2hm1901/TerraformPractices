# Prod environment variables
aws_region   = "ap-southeast-2"
project_name = "cdo08"
environment  = "prod"

# Networking — dung CIDR rieng de tranh overlap voi dev
vpc_cidr            = "10.1.0.0/16"
public_subnet_cidr  = "10.1.1.0/24"
private_subnet_cidr = "10.1.2.0/24"
availability_zone   = "ap-southeast-2a"
