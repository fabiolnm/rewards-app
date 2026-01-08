# AWS Setup Guide

Complete guide for deploying the Rewards App to AWS ECS Fargate.

## Prerequisites

1. **AWS Account**: Active AWS account with billing enabled
2. **AWS SSO**: IAM Identity Center configured with appropriate permissions
3. **Budget email**: Set environment variable for cost alerts:

   ```bash
   # Bash/Zsh (temporary, current session only)
   export TF_VAR_budget_email="your-email@example.com"

   # Fish (persistent, stored in ~/.config/fish/fish_variables)
   set -Ux TF_VAR_budget_email "your-email@example.com"
   ```

4. **mise**: Tool version manager (installs AWS CLI, Terraform, etc.)
5. **GitHub CLI**: For automated secrets setup
6. **Docker**: For local image builds (optional)

All required tools (AWS CLI, Terraform) are defined in `.mise.toml` and installed automatically.

## Tool Installation

### Install mise and tools

```bash
# Install mise (if not already installed)
curl https://mise.run | sh

# Install all project tools (AWS CLI, Terraform, etc.)
mise install
```

## AWS SSO Setup

### Configure SSO on AWS Console

If your AWS account doesn't have SSO configured yet:

1. **Navigate to AWS IAM Identity Center** (formerly AWS SSO):
   - Open AWS Console
   - Search for "IAM Identity Center" or "AWS Single Sign-On"

2. **Enable IAM Identity Center**:
   - Click "Enable" if not already enabled
   - Choose your region (typically `ca-west-1`)

3. **Configure Identity Source**:
   - Go to "Settings" in IAM Identity Center
   - Under "Identity source", confirm the identity source type:
     - **Identity Center directory** (default): Built-in directory for managing users
     - **Active Directory**: Connect to your on-premises or AWS Managed Microsoft AD
     - **External identity provider**: Connect to SAML 2.0 IdP (Okta, Azure AD, etc.)
   - For most cases, use **Identity Center directory**

4. **Customize AWS Access Portal URL**:
   - In "Settings", locate "AWS access portal"
   - Click "Customize" next to the default portal URL
   - Enter a custom subdomain (e.g., `rewards-app` or your company name)
   - The URL will become: `https://<your-custom-name>.awsapps.com/start`
   - Click "Save changes"
   - Note: This can only be set once and cannot be changed later

5. **Create Permission Sets**:

   Create separate permission sets for different access levels:

   **a. Superuser/Administrator Permission Set**:
   - Go to "Permission sets"
   - Click "Create permission set"
   - Choose "Predefined permission set"
   - Select `AdministratorAccess`
   - Name: `SuperuserAccess`
   - Description: "Full administrative access to AWS account"
   - Session duration: 12 hours (or as per security policy)
   - Click "Next" and "Create"

   **b. Developer Permission Set**:
   - Click "Create permission set"
   - Choose "Predefined permission set"
   - Select `PowerUserAccess` (full access except IAM/Organizations)
   - Name: `DeveloperAccess`
   - Description: "Developer access with limited IAM permissions"
   - Session duration: 8 hours
   - Click "Next" and "Create"

   **c. Read-Only Permission Set** (Optional):
   - Click "Create permission set"
   - Choose "Predefined permission set"
   - Select `ViewOnlyAccess`
   - Name: `ReadOnlyAccess`
   - Description: "Read-only access for auditing and monitoring"
   - Session duration: 4 hours
   - Click "Next" and "Create"

6. **Create Users**:

   Create users for each team member:

   - Go to "Users" in IAM Identity Center
   - Click "Add user"
   - Enter user details:
     - **Username**: firstname.lastname
     - **Email address**: User's work email
     - **First name**: User's first name
     - **Last name**: User's last name
     - **Display name**: Full name
   - Click "Next"
   - Choose "Add user to groups" (optional) or skip
   - Click "Next" and "Add user"
   - User receives an email invitation to set up password

   Repeat for each team member

7. **Assign Users to AWS Account with Appropriate Roles**:

   Assign users to your AWS account with the appropriate permission set:

   **Assign Superuser Access**:
   - Go to "AWS accounts"
   - Select your AWS account
   - Click "Assign users or groups"
   - Select the "Users" tab
   - Check the box next to superuser/admin users
   - Click "Next"
   - Select the `SuperuserAccess` permission set
   - Click "Next" and "Submit"

   **Assign Developer Access**:
   - Repeat the above steps
   - Select developer users
   - Choose the `DeveloperAccess` permission set
   - Click "Submit"

   **Assign Read-Only Access** (if applicable):
   - Repeat for users who need read-only access
   - Choose the `ReadOnlyAccess` permission set

8. **Get SSO Start URL**:
   - Go to "Dashboard" in IAM Identity Center
   - Copy the "AWS access portal URL" (e.g., `https://rewards-app.awsapps.com/start`)
   - Share this URL with your team
   - Users will use this URL to access AWS accounts

## AWS CLI Setup

### Configure AWS SSO

```bash
aws configure sso
```

Enter:

- SSO session name: `rewards-app` (or your preferred name)
- SSO start URL: Your AWS SSO portal URL from previous step (e.g., `https://rewards-app.awsapps.com/start`)
- SSO region: The region where your SSO is configured (e.g., `ca-west-1`)
- SSO registration scopes: `sso:account:access` (default)

The CLI will open your browser to authenticate. After authentication:

- Select your AWS account from the list
- Choose the appropriate IAM role (e.g., `AdministratorAccess`)
- Default region: `ca-west-1`
- Default output format: `json`
- CLI profile name: `default` (or your preferred profile name)

### Login to SSO Session

SSO credentials expire after a period. To refresh:

```bash
aws sso login
```

Or, if using a named profile:

```bash
aws sso login --profile rewards-app
```

### Verify Configuration

```bash
aws sts get-caller-identity
```

Should output your account ID and ARN.

## IAM Permissions for Terraform

### Permission Requirements

Terraform infrastructure deployment requires different permission levels
depending on the operation:

**PowerUserAccess** (sufficient for):

- `terraform init` - Backend setup
- `terraform plan` - State validation
- `terraform output` - Reading outputs
- `terraform state` - State management

**AdministratorAccess** (required for):

- `terraform apply` - Creates IAM roles and OIDC providers
- `terraform destroy` - Deletes IAM resources

PowerUserAccess excludes IAM and Organizations management, which prevents
creation of:

- ECS task execution roles
- ECS task application roles
- GitHub Actions OIDC provider

### Configure Admin Profile

If you only have PowerUserAccess configured, add an AdministratorAccess profile:

```bash
aws configure sso --profile admin
```

Enter:

- SSO session name: `rewards-app-admin`
- SSO start URL: Your AWS SSO portal URL (e.g., `https://rewards-app.awsapps.com/start`)
- SSO region: `ca-west-1`
- Select the **AdministratorAccess** permission set
- Default region: `ca-west-1`
- Default output format: `json`

### Verify Permissions

Check current profile:

```bash
aws sts get-caller-identity
```

Test IAM permissions:

```bash
# Should succeed with AdministratorAccess, fail with PowerUserAccess
aws iam list-roles --max-items 1
```

### Using Admin Profile

Set for entire session:

```bash
export AWS_PROFILE=admin
```

Or use inline for specific commands:

```bash
AWS_PROFILE=admin terraform apply tfplan
```

## Cost Management

### Budget Setup

Terraform automatically creates a budget alert at $10/month threshold.

Set your email via environment variable:

```bash
export TF_VAR_budget_email="your-email@example.com"
```

### Cost Monitoring

1. **AWS Cost Explorer**: Filter by `Project=rewards-app` tag
2. **Budget Alerts**: Email notifications at 80%, 100%, and forecasted 100%

### Expected Costs

**Demo/Testing** (~$27/month):

- ECS Fargate Spot (2 tasks): ~$9/month
- RDS db.t4g.micro: ~$12/month
- CloudWatch + Data Transfer: ~$5/month
- S3 + DynamoDB: <$1/month

**Production** (~$200-300/month):

- Fargate On-Demand (4-10 tasks): ~$100-150/month
- RDS Multi-AZ: ~$50/month
- Dual NAT Gateways: ~$65/month
- Enhanced monitoring: ~$10/month

## Deployment Steps

### 1. Bootstrap Infrastructure

Create Terraform state backend and initialize:

```bash
cd terraform
./bootstrap.sh
```

This creates:

- S3 bucket for Terraform state
- DynamoDB table for state locking
- Initializes Terraform with backend configuration

**Cost**: <$1/month

### 2. Plan and Apply

```bash
terraform plan -out=tfplan
AWS_PROFILE=admin terraform apply tfplan
```

**Note**: `terraform apply` requires AdministratorAccess to create IAM
roles and OIDC providers. See
[IAM Permissions for Terraform](#iam-permissions-for-terraform).

Review the plan carefully before applying.

**Deployment time**: 10-15 minutes (RDS takes longest)

### 3. Setup GitHub Secrets

Automatically configure GitHub repository secrets:

```bash
./setup-github-secrets.sh
```

This configures:

- AWS region and account ID
- OIDC role ARN
- ECR repository URLs
- ECS cluster and service names

### 4. Trigger Deployment

Push to deploy branch or manually trigger workflow:

```bash
git push origin deploy
```

Or via GitHub Actions UI: `Actions > Deploy to AWS ECS > Run workflow`

## Verification

### Check Infrastructure

```bash
# ECS cluster
aws ecs describe-clusters --clusters rewards-app-cluster

# Running tasks
aws ecs list-tasks --cluster rewards-app-cluster

# RDS instance
aws rds describe-db-instances --db-instance-identifier rewards-app-db
```

### Get Service URLs

After deployment, GitHub Actions outputs public IPs:

```text
🌐 Web URL: http://1.2.3.4
🚀 API URL: http://5.6.7.8:3000
```

Or fetch manually:

```bash
# Get web task IP
WEB_TASK_ARN=$(aws ecs list-tasks \
  --cluster rewards-app-cluster \
  --service-name rewards-app-web \
  --query 'taskArns[0]' --output text)

WEB_ENI=$(aws ecs describe-tasks \
  --cluster rewards-app-cluster \
  --tasks $WEB_TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

aws ec2 describe-network-interfaces \
  --network-interface-ids $WEB_ENI \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

### Test Endpoints

```bash
# Health check
curl http://<api-ip>:3000/health

# Web app
curl http://<web-ip>
```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform
AWS_PROFILE=admin terraform destroy -auto-approve
```

**Note**: Requires AdministratorAccess to delete IAM resources.

Removes:

- ECS cluster and tasks
- RDS database
- ECR repositories and images
- VPC and networking
- IAM roles and security groups
- Secrets and parameters
- Budget alerts

**Time**: 5-10 minutes

### Delete Backend (Optional)

Only after destroying main infrastructure:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://rewards-app-tf-state-${ACCOUNT_ID} --force
aws dynamodb delete-table --table-name rewards-app-tf-locks
```

## Troubleshooting

### Terraform Errors

#### Error: AccessDenied for IAM operations

Symptoms:

```text
Error: creating IAM Role: operation error IAM: CreateRole,
AccessDenied: User is not authorized to perform: iam:CreateRole

Error: creating IAM OIDC Provider:
AccessDenied: User is not authorized to perform: iam:CreateOpenIDConnectProvider
```

Solution:

Use AdministratorAccess profile for `terraform apply` and `terraform destroy`:

```bash
# Configure admin profile if not already done
aws configure sso --profile admin

# Verify profile has IAM permissions
aws iam list-roles --max-items 1 --profile admin

# Apply with admin profile
AWS_PROFILE=admin terraform apply tfplan
```

PowerUserAccess cannot create IAM resources. See [IAM Permissions for Terraform](#iam-permissions-for-terraform).

#### Error: Backend initialization failed

Ensure bootstrap script ran successfully:

```bash
aws s3 ls | grep rewards-app-tf-state
```

#### Error: Invalid credentials

Reconfigure AWS CLI:

```bash
aws configure
aws sts get-caller-identity
```

### Deployment Failures

#### Migration task failed

Check CloudWatch Logs:

```bash
aws logs tail /ecs/rewards-app/api --follow
```

#### Service not stabilizing

Check task status:

```bash
TASK_ARN=$(aws ecs list-tasks --cluster rewards-app-cluster \
  --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster rewards-app-cluster --tasks $TASK_ARN
```

Common issues:

- Health check failing (check `/health` endpoint)
- Database connection issues (verify security groups)
- Missing secrets (check Parameter Store)

### Cost Overruns

#### Fargate costs high

- Ensure Fargate Spot is enabled (70% cheaper)
- Reduce task count to 1 for testing
- Scale down CPU/memory if possible

## Security Considerations

### Secrets Management

- Database password: Auto-generated, stored in Parameter Store
- GitHub Actions: OIDC (no long-lived credentials)

### Network Security

- RDS in private subnet (no internet access)
- ECS tasks in public subnet (for simplified demo)
- Security groups limit access to necessary ports

### Production Hardening

For production, consider:

1. **Private ECS tasks** with Application Load Balancer
2. **Multi-AZ** RDS for high availability
3. **WAF** for web application firewall
4. **Secrets rotation** via AWS Secrets Manager
5. **VPC Flow Logs** for network monitoring
6. **GuardDuty** for threat detection

## Resource Limits

Default AWS limits may affect deployment:

- **Fargate tasks**: 50 per region (request increase if needed)
- **ECR storage**: 500 GB free tier
- **RDS storage**: 20 GB free tier (first year)
- **NAT Gateway**: 5 per AZ

Check limits:

```bash
aws service-quotas list-service-quotas --service-code ecs
```

Request increases via AWS Support if needed.
