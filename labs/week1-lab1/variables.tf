variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cdo08"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type (need >= 4GB RAM for minikube)"
  type        = string
  default     = "t3.large" # 2 vCPU, 8GB RAM
}

variable "app_node_port" {
  description = "NodePort for the app (must match K8s service)"
  type        = number
  default     = 30080
}

variable "k8s_api_port" {
  description = "minikube API server port"
  type        = number
  default     = 8443
}

variable "app_replicas" {
  description = "Number of nginx replicas"
  type        = number
  default     = 1
}

variable "deploy_k8s" {
  description = "Deploy Kubernetes resources. Set false on first apply (stage 1)."
  type        = bool
  default     = true
}
