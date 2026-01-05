provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

# Get current AWS account information
data "aws_caller_identity" "current" {}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ECR Repositories
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  ecs_security_group_id = module.ecs.ecs_security_group_id
}

# ECS Fargate
module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  web_cpu            = var.web_cpu
  web_memory         = var.web_memory
  api_cpu            = var.api_cpu
  api_memory         = var.api_memory
  desired_count      = var.desired_count
  web_repository_url = module.ecr.web_repository_url
  api_repository_url = module.ecr.api_repository_url
  db_endpoint        = module.rds.endpoint
  db_name            = module.rds.database_name
  db_username        = var.db_username
  db_password_arn    = module.rds.db_password_arn
  rails_master_key_arn = aws_ssm_parameter.rails_master_key.arn
  secret_key_base_arn = module.rds.secret_key_base_arn
}
