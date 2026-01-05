variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for Fargate tasks"
  type        = list(string)
}

variable "web_cpu" {
  description = "Fargate vCPU units for web service"
  type        = number
}

variable "web_memory" {
  description = "Fargate memory for web service in MB"
  type        = number
}

variable "api_cpu" {
  description = "Fargate vCPU units for API service"
  type        = number
}

variable "api_memory" {
  description = "Fargate memory for API service in MB"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks per service"
  type        = number
}

variable "web_repository_url" {
  description = "ECR repository URL for web service"
  type        = string
}

variable "api_repository_url" {
  description = "ECR repository URL for API service"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_arn" {
  description = "ARN of database password in Parameter Store"
  type        = string
}

variable "rails_master_key_arn" {
  description = "ARN of Rails master key in Parameter Store"
  type        = string
}

variable "secret_key_base_arn" {
  description = "ARN of Rails secret key base in Parameter Store"
  type        = string
}
