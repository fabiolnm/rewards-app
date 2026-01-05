# AWS Systems Manager Parameter Store for secrets
# Free tier: 10,000 parameters

# Rails master key (for encrypted credentials)
resource "aws_ssm_parameter" "rails_master_key" {
  name        = "/${var.project_name}/rails/master-key"
  description = "Rails master key for encrypted credentials"
  type        = "SecureString"
  value       = var.rails_master_key

  tags = {
    Name = "${var.project_name}-rails-master-key"
  }
}
