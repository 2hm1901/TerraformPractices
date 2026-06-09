terraform {
  required_version = ">= 1.10.0"

  # Lab nay co 2 nhom provider:
  # - aws/tls/local/null tao va bootstrap infrastructure.
  # - kubernetes ket noi vao minikube de deploy app that trong cluster.
  # Kubernetes provider lam lab nay khac voi cach chi dung random provider
  # de tao suffix/name ngau nhien.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Lab         = "week1-lab1"
    }
  }
}

# Kubernetes provider doc kubeconfig tu file.
#
# Ly do can placeholder:
# - Lan apply dau tien, EC2/minikube chua ton tai nen chua co kubeconfig.yaml that.
# - Terraform van can khoi tao provider, vi vay dung kubeconfig.placeholder.yaml.
#
# Ly do uu tien kubeconfig.yaml that khi file ton tai:
# - Khi destroy, Kubernetes resources van con trong state.
# - Terraform phai ket noi vao cluster that de xoa Deployment/Service truoc.
# - Neu ep provider ve placeholder 127.0.0.1:8443 thi destroy se fail connection refused.
provider "kubernetes" {
  config_path    = fileexists("${path.module}/kubeconfig.yaml") ? "${path.module}/kubeconfig.yaml" : "${path.module}/kubeconfig.placeholder.yaml"
  config_context = "minikube"
}
