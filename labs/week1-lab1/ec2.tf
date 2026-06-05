# ============================================================
# EC2: Cai dat minikube qua user_data
# SSH Key: generate tu tls provider (provider #3)
# ============================================================

# Provider: tls — generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Ghi private key ra file de SSH vao EC2
resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/ssh_private_key.pem"
  file_permission = "0400"
}

# -----------------------------------------------------------
# AMI: Ubuntu 22.04 LTS (moi nhat)
# -----------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------
resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  # 30GB du cho Docker images + minikube
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # user_data cai dat Docker + minikube tu dong
  user_data = file("${path.module}/scripts/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}
