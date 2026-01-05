# Implementation Plan: Deploy to AWS ECS/Fargate

**Issue:** #11
**Goal:** Deploy workflow for main branch with ECR image publishing and ECS/Fargate deployment

## Architecture Overview

**Services:**

- Web (React/Nginx): Port 80, public-facing Fargate service
- API (Rails/Puma): Port 3000, public-facing Fargate service
- Database: RDS PostgreSQL 15

**Key Infrastructure:**

- VPC with public/private subnets (single AZ for simplicity)
- ECS Fargate cluster with task definitions (awsvpc networking)
- ECS services with public IPs (simplified routing)
- RDS PostgreSQL (private subnet)
- ECR repositories for images
- CloudWatch Logs for monitoring
- Systems Manager Parameter Store for secrets

**Why Fargate?**

AWS Fargate is serverless compute for containers. Unlike ECS on EC2 (where you
manage instances), Fargate manages infrastructure automatically.

**Fargate Benefits:**

- No EC2 instances to patch or maintain
- Pay only for container runtime (not idle servers)
- Automatic scaling and high availability
- Secure by default (task isolation)
- Industry standard for containerized workloads

**Deployment Flow:**

1. GitHub Actions triggers on push to deploy branch
2. Build and push Docker images to ECR (tagged with git SHA)
3. Run database migrations (one-off Fargate task)
4. Update ECS services with new Fargate task definitions
5. Wait for health checks and graceful deployment

## Technical Decisions

- **Infrastructure:** Terraform (Infrastructure as Code)
- **Compute:** AWS Fargate (serverless containers)
- **Database:** RDS PostgreSQL with automated backups
- **Migrations:** Auto-run via Fargate task before deployment
- **Secrets:** AWS Systems Manager Parameter Store (free tier)
- **Networking:** Single AZ with public IPs (simplified for demo)
- **CI/CD:** OIDC authentication (no long-lived credentials)
- **Deployment:** Blue/green via ECS service updates

## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

### 1. Bootstrap and Terraform foundation

**Files:** `scripts/bootstrap.sh`, `scripts/setup-github-secrets.sh`,
`terraform/main.tf`, `terraform/variables.tf`, `terraform/outputs.tf`,
`terraform/backend.tf`, `terraform/oidc.tf`, `terraform/budget.tf`,
`terraform/modules/vpc/*.tf`

Create bootstrap script to setup S3 backend and DynamoDB table. Set up Terraform
project with S3 backend, OIDC provider for GitHub Actions, cost budget alerts,
and VPC module. VPC includes single public subnet and single private subnet
(single AZ), Internet Gateway, route tables, and security groups.
Add script to automate GitHub secrets setup. Tag all resources for easy cleanup.

### 2. Terraform data layer (ECR, RDS, and secrets)

**Files:** `terraform/modules/ecr/*.tf`, `terraform/modules/rds/*.tf`,
`terraform/secrets.tf`

Create ECR repositories with lifecycle policies and RDS PostgreSQL 15 (db.t4g.micro
for cost optimization, single-AZ) with security groups. Add Rails master key and
other secrets to Parameter Store via Terraform (using TF_VAR_rails_master_key
environment variable).

### 3. Terraform compute layer (ECS Fargate)

**Files:** `terraform/modules/ecs/*.tf`

Create ECS Fargate cluster with task definitions (using Fargate Spot for cost
savings), services with public IPs (1 task per service initially), IAM roles,
security groups for web/api access, and CloudWatch Logs. Configure awsvpc
networking mode for Fargate.

### 4. Rails production configuration

**Files:** `api/config/database.yml`, `api/config/environments/production.rb`,
`api/bin/run-migrations`

Configure Rails for production deployment: DATABASE_URL from RDS, allowed hosts
from env, STDOUT logging, Solid Queue/Cache/Cable for shared database, and migration
runner script.

### 5. Web production configuration

**Files:** `web/vite.config.ts`

Configure Vite to use API_URL environment variable for API endpoint (will point
to separate Fargate service URL).

### 6. GitHub Actions workflows (deploy and cleanup)

**Files:** `.github/workflows/deploy.yml`, `.github/workflows/cleanup.yml`

Complete deployment workflow: build and push images to ECR with OIDC auth, run
migrations as one-off Fargate task, deploy to ECS services with stability checks,
output Fargate service public IPs/URLs. Trigger on push to **deploy** branch (not
main) to allow controlled deployments. Add cleanup workflow with manual trigger
and daily reminder to check if infrastructure is still running.

### 7. Terraform documentation

**Files:** `terraform/README.md`, `docs/aws-setup.md`

Document automated setup process, Terraform usage, cost estimates, and cleanup
procedures. Include instructions for bootstrap script and GitHub secrets automation.

### 8. Deployment documentation

**Files:** `docs/deployment.md`, `README.md`

Document complete deployment process, rollback procedures, troubleshooting, and
add deployment section to main README.

## Setup and Deployment (Mostly Automated)

### One-Time Setup

1. **Bootstrap Terraform backend:**

   ```bash
   ./scripts/bootstrap.sh
   ```

   Creates S3 bucket and DynamoDB table for Terraform state. These are the only
   resources not managed by Terraform itself. Cost: <$1/month.

2. **Configure AWS credentials:**

   ```bash
   aws configure  # or set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
   ```

3. **Set Rails master key:**

   ```bash
   export TF_VAR_rails_master_key="your-master-key-here"
   ```

4. **Deploy infrastructure:**

   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

   This creates: OIDC provider, VPC, RDS, ECR, ALB, ECS, secrets, budget alerts.
   All tagged with `Project=rewards-app` for easy identification.

5. **Setup GitHub secrets (automated):**

   ```bash
   ./scripts/setup-github-secrets.sh
   ```

   Reads Terraform outputs and configures GitHub repository secrets.

6. **Deploy application:**

   ```bash
   git push origin main  # Triggers deployment workflow
   ```

### Cleanup (Single Command)

```bash
cd terraform
terraform destroy -auto-approve
```

Removes ALL infrastructure except S3/DynamoDB backend (can reuse or delete manually).

### Cost Monitoring

- Budget alert configured at $10/month (email notification)
- Daily cleanup reminder via GitHub Actions
- All resources tagged for AWS Cost Explorer filtering

## Cost Estimate (Optimized for Demo)

**Cost Optimizations Applied:**

- Single AZ architecture (simplified networking)
- No load balancer (direct Fargate public IPs)
- No NAT Gateway (RDS doesn't need internet access)
- RDS db.t4g.micro ARM instance (cheaper than t3)
- Single-AZ RDS (no Multi-AZ)
- 1 task per service (instead of 2+)
- Fargate Spot pricing (70% discount, suitable for demo)
- Resource tagging for easy identification and cleanup

**Monthly Costs:**

- ECS Fargate Spot (2 tasks @ 0.25 vCPU, 0.5 GB): ~$9/month
- RDS db.t4g.micro (single-AZ): ~$12/month
- CloudWatch Logs + Data Transfer: ~$5/month
- S3 + DynamoDB (state backend): <$1/month
- **Total: ~$27/month**

**Note:** Budget alert set at $10/month will catch cost overruns early.

**Production Upgrade Path** (when scaling up):

- Switch to Fargate On-Demand for reliability
- Multi-AZ RDS for high availability
- Move ECS tasks to private subnets with NAT Gateway (security best practice)
- Add Application Load Balancer
- Auto-scaling (2-10 tasks per service)
- Estimated production cost: ~$200-300/month

## Preventing Orphaned Resources

### Primary Strategy: Everything in Terraform

All application infrastructure (OIDC, VPC, ECR, RDS, ECS Fargate, secrets, budgets)
is defined in Terraform. Running `terraform destroy` removes everything in one
command.

**Additional Safeguards:**

1. **Resource Tagging:** All resources tagged with:
   - `Project=rewards-app`
   - `ManagedBy=terraform`
   - `Environment=demo`
   - Can filter in AWS Cost Explorer or delete via AWS CLI by tag

2. **Budget Alerts:** $10/month threshold sends email notification

3. **Daily Reminder:** GitHub Actions workflow runs daily to check if
   infrastructure is still running

4. **Bootstrap Backend:** S3 + DynamoDB (state storage) are the ONLY resources
   not in Terraform. These are intentionally separate for reusability. Cost:
   <$1/month. Can delete manually after destroying main infrastructure.

**Cleanup Workflow:**

```bash
# Destroy all application infrastructure
cd terraform
terraform destroy -auto-approve

# Optional: Delete backend (one-time, only after all projects done)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://rewards-app-tf-state-${ACCOUNT_ID} --force
aws dynamodb delete-table --table-name rewards-app-tf-locks
```

## Success Criteria

- Infrastructure deployed via Terraform
- Docker images built and pushed to ECR
- ECS Fargate services running with healthy tasks
- Fargate tasks accessible via public IPs
- Web and API applications responding to requests
- Deployment workflow runs on push to deploy branch
- Database migrations run successfully
- Budget alerts and cleanup workflows configured

## Lessons Learned (Post-Implementation)

### Technical Challenges

1. **Nginx as non-root:** Fargate requires careful permission setup for non-root containers
   - Must create and chown cache directories before switching to nginx user
   - Use port 8080 (unprivileged) instead of port 80
   - Map container port 8080 to host (Fargate awsvpc networking)

2. **Database password YAML escaping:** Passwords with special characters
   (`:`, `@`, `{}`) must be quoted in database.yml

3. **Deployment diagnostics:** Essential for production debugging
   - CloudWatch log fetching on migration/deployment failures
   - Service status output before wait commands
   - 15-minute timeout to prevent hanging workflows

### Process Improvements

1. **AWS SSO:** Documentation should include SSO setup as prerequisite (not access keys)

2. **Terraform validation:** Should be part of CI from the start to catch errors early

3. **Deploy branch strategy:** Using separate deploy branch (not main) allows:
   - Testing deployments without affecting main branch
   - Controlled production releases
   - Easier rollback if deployment fails
