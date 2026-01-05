# AWS Account Information
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# OIDC Configuration
output "oidc_role_arn" {
  description = "ARN of the OIDC role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

# ECR Repositories
output "ecr_web_repository" {
  description = "ECR repository URL for web service"
  value       = module.ecr.web_repository_url
}

output "ecr_api_repository" {
  description = "ECR repository URL for API service"
  value       = module.ecr.api_repository_url
}

# ECS Cluster and Services
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_web_service" {
  description = "ECS web service name"
  value       = module.ecs.web_service_name
}

output "ecs_api_service" {
  description = "ECS API service name"
  value       = module.ecs.api_service_name
}

output "ecs_web_task_definition" {
  description = "ECS web task definition family"
  value       = module.ecs.web_task_family
}

output "ecs_api_task_definition" {
  description = "ECS API task definition family"
  value       = module.ecs.api_task_family
}

# Database
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.database_name
}

# Application URLs (will be available after first deployment)
output "web_url" {
  description = "Web application URL (check ECS console for public IP after deployment)"
  value       = "Check ECS console for Fargate task public IP"
}

output "api_url" {
  description = "API URL (check ECS console for public IP after deployment)"
  value       = "Check ECS console for Fargate task public IP"
}
