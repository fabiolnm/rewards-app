output "web_repository_url" {
  description = "Web ECR repository URL"
  value       = aws_ecr_repository.web.repository_url
}

output "web_repository_arn" {
  description = "Web ECR repository ARN"
  value       = aws_ecr_repository.web.arn
}

output "api_repository_url" {
  description = "API ECR repository URL"
  value       = aws_ecr_repository.api.repository_url
}

output "api_repository_arn" {
  description = "API ECR repository ARN"
  value       = aws_ecr_repository.api.arn
}
