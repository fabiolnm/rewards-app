# Terraform Infrastructure

Infrastructure as Code for deploying the Rewards App to AWS ECS Fargate.

## Architecture

- **Compute**: AWS Fargate (serverless containers)
- **Database**: RDS PostgreSQL 15
- **Container Registry**: Amazon ECR
- **Networking**: VPC with public/private subnets (single AZ)
- **Secrets**: AWS Systems Manager Parameter Store
- **CI/CD**: GitHub Actions with OIDC authentication
- **Monitoring**: CloudWatch Logs and budget alerts

## Prerequisites

- mise (installs AWS CLI, Terraform automatically via `.mise.toml`)
- AWS credentials configured (`aws configure`)
- **AdministratorAccess** permission set for `terraform apply` and
  `terraform destroy` (creates/deletes IAM resources)
  - PowerUserAccess sufficient for `terraform init`, `terraform plan`,
    `terraform output`
  - See [AWS Setup Guide](../docs/aws-setup.md#iam-permissions-for-terraform)
    for profile configuration
- GitHub CLI (for automated secrets setup)

Install tools:

```bash
mise install  # Installs AWS CLI, Terraform, etc.
```

## Quick Start

### 1. Bootstrap Terraform Backend

Creates S3 bucket and DynamoDB table for Terraform state:

```bash
./bootstrap.sh
```

This creates:

- S3 bucket: `rewards-app-tf-state-{account-id}`
- DynamoDB table: `rewards-app-tf-locks`

### 2. Initialize Terraform

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform init -backend-config="bucket=rewards-app-tf-state-${ACCOUNT_ID}"
```

### 3. Set Environment Variables

```bash
# Budget alert email
export TF_VAR_budget_email="your-email@example.com"
```

### 4. Deploy Infrastructure

```bash
terraform plan
AWS_PROFILE=admin terraform apply
```

**Note**: Requires AdministratorAccess to create IAM roles and OIDC providers.

This creates:

- VPC with public/private subnets
- RDS PostgreSQL instance
- ECR repositories
- ECS Fargate cluster
- IAM roles and security groups
- Budget alerts

### 5. Setup GitHub Secrets

Automates GitHub repository secret configuration:

```bash
./setup-github-secrets.sh
```

## Module Structure

```text
terraform/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # S3 backend configuration
├── oidc.tf             # GitHub Actions OIDC provider
├── budget.tf           # Cost monitoring
├── secrets.tf          # Parameter Store secrets
└── modules/
    ├── vpc/            # Networking (VPC, subnets, NAT)
    ├── ecr/            # Container registries
    ├── rds/            # PostgreSQL database
    └── ecs/            # Fargate cluster and services
```

## Cost Optimization

Infrastructure is optimized for demo/testing:

- Single AZ deployment (~50% cheaper than Multi-AZ)
- No load balancer (direct Fargate public IPs)
- Single NAT Gateway
- RDS db.t4g.micro ARM instance
- Fargate Spot pricing (70% discount)
- 1 task per service initially

**Estimated monthly cost**: ~$59/month

See plan documentation for detailed cost breakdown.

## Cleanup

### Destroy All Infrastructure

```bash
AWS_PROFILE=admin terraform destroy -auto-approve
```

**Note**: Requires AdministratorAccess to delete IAM resources.

### Delete Backend (Optional)

Only after destroying main infrastructure:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://rewards-app-tf-state-${ACCOUNT_ID} --force
aws dynamodb delete-table --table-name rewards-app-tf-locks
```

## Resource Tagging

All resources are tagged:

- `Project=rewards-app`
- `ManagedBy=terraform`
- `Environment=demo`

Use AWS Cost Explorer to filter by these tags.

## Outputs

After applying, Terraform outputs:

- ECR repository URLs
- ECS cluster and service names
- RDS endpoint
- OIDC role ARN

Use these values in GitHub Actions or retrieve with:

```bash
terraform output <output-name>
```

## Troubleshooting

### IAM Permission Errors

Error creating IAM roles or OIDC providers:

```text
Error: creating IAM Role: AccessDenied: User is not authorized to perform: iam:CreateRole
```

Solution:

```bash
# Verify current profile
aws sts get-caller-identity

# Test IAM permissions
aws iam list-roles --max-items 1

# If AccessDenied, switch to admin profile
AWS_PROFILE=admin terraform apply
```

Resources requiring IAM permissions:

- `aws_iam_openid_connect_provider.github` - GitHub Actions OIDC authentication
- `aws_iam_role.ecs_task_execution` - ECS task execution role
- `aws_iam_role.ecs_task` - ECS application runtime role

See [AWS Setup Guide](../docs/aws-setup.md#iam-permissions-for-terraform) for detailed instructions.

### Backend Configuration

If `terraform init` fails, ensure the S3 bucket exists:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 ls s3://rewards-app-tf-state-${ACCOUNT_ID}
```

### State Lock Issues

If Terraform state is locked:

```bash
# List locks
aws dynamodb scan --table-name rewards-app-tf-locks

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Module Dependencies

Modules have dependencies enforced through Terraform:

1. VPC → RDS, ECS
2. ECR → ECS (task definitions)
3. RDS → ECS (database credentials)

Ensure all modules are applied together.
