# Sentry DSN stored in Parameter Store
resource "aws_ssm_parameter" "sentry_dsn" {
  count = var.sentry_dsn != "" ? 1 : 0

  name        = "/${var.project_name}/SENTRY_DSN"
  description = "Sentry DSN for ${var.project_name} API"
  type        = "SecureString"
  value       = var.sentry_dsn

  tags = {
    Name = "${var.project_name}-sentry-dsn"
  }
}
