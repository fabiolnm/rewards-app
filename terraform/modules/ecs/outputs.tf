output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "web_service_name" {
  description = "Web service name"
  value       = aws_ecs_service.web.name
}

output "web_service_id" {
  description = "Web service ID"
  value       = aws_ecs_service.web.id
}

output "api_service_name" {
  description = "API service name"
  value       = aws_ecs_service.api.name
}

output "api_service_id" {
  description = "API service ID"
  value       = aws_ecs_service.api.id
}

output "web_task_family" {
  description = "Web task definition family"
  value       = aws_ecs_task_definition.web.family
}

output "api_task_family" {
  description = "API task definition family"
  value       = aws_ecs_task_definition.api.family
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}
