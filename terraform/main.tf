# ============================================================
# Root Module — Goi cac modules
# ============================================================

module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

module "data" {
  source = "./modules/data"

  project_name = var.project_name
  environment  = var.environment
}
