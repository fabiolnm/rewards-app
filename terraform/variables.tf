variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ca-west-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "rewards-app"
}

variable "environment" {
  description = "Environment name (demo, staging, production)"
  type        = string
  default     = "demo"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "fabiolnm"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "rewards-app"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment (minimum 2 required for RDS)"
  type        = list(string)
  default     = ["ca-west-1a", "ca-west-1b"]
}

# RDS Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # x86-based, widely available
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "rewards_production"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "rewards_admin"
}

# ECS Configuration
variable "web_cpu" {
  description = "Fargate vCPU units for web service (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "web_memory" {
  description = "Fargate memory for web service in MB"
  type        = number
  default     = 512
}

variable "api_cpu" {
  description = "Fargate vCPU units for API service (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Fargate memory for API service in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks per service"
  type        = number
  default     = 1
}

# Budget Configuration
variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 10
}

variable "budget_email" {
  description = "Email address for budget notifications (set via TF_VAR_budget_email)"
  type        = string
}

# Sentry Configuration
variable "sentry_dsn" {
  description = "Sentry DSN for API error tracking (set via TF_VAR_sentry_dsn)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "git_sha" {
  description = "Git commit SHA for release tracking (set via TF_VAR_git_sha in CI/CD)"
  type        = string
  default     = ""
}
