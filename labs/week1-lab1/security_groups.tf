# ============================================================
# Security Groups
# ============================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}-lab1"
}

# -----------------------------------------------------------
# ALB Security Group: Nhan HTTP tu Internet
# -----------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP from Internet to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# -----------------------------------------------------------
# EC2 Security Group
#   - NodePort 30080: nhan tu ALB
#   - Port 8443:      nhan tu Terraform machine (K8s API)
#   - Port 22:        SSH de fetch kubeconfig
# -----------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "EC2 ports for minikube lab"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    # Chi ALB security group duoc goi vao NodePort.
    # Khong mo 30080 ra Internet truc tiep de traffic public di qua ALB.
    description     = "NodePort from ALB only"
    from_port       = var.app_node_port
    to_port         = var.app_node_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    # Mo K8s API de Terraform Kubernetes provider tren may local co the connect.
    # Lab de 0.0.0.0/0 cho don gian; production nen gioi han IP nguoi chay Terraform.
    description = "K8s API for Terraform kubernetes provider"
    from_port   = var.k8s_api_port
    to_port     = var.k8s_api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # SSH can cho null_resource.wait_for_k8s copy kubeconfig va cho viec debug.
    # Production nen gioi han CIDR thay vi 0.0.0.0/0.
    description = "SSH for kubeconfig fetch"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}
