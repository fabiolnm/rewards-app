# Deployment Guide

Complete guide for deploying and managing the Rewards App on AWS ECS Fargate.

## Deployment Process

### Automated Deployment (Recommended)

Deployments are automated via GitHub Actions on push to `main`:

```bash
git push origin main
```

The workflow:

1. Builds Docker images for web and API
2. Pushes images to ECR (tagged with git SHA and `latest`)
3. Runs database migrations as one-off Fargate task
4. Updates ECS services with new images
5. Waits for services to stabilize
6. Outputs public IPs for web and API

### Manual Deployment

For emergency deployments or testing:

```bash
# Trigger via GitHub Actions UI
# Actions > Deploy to AWS ECS > Run workflow
```

Or deploy locally with AWS credentials:

```bash
# Build and push images
aws ecr get-login-password --region ca-west-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ca-west-1.amazonaws.com

docker build -t <ecr-web-url>:latest web/
docker push <ecr-web-url>:latest

docker build -t <ecr-api-url>:latest api/
docker push <ecr-api-url>:latest

# Update services
aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-web \
  --force-new-deployment

aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-api \
  --force-new-deployment
```

## Database Migrations

### Automated Migrations

Migrations run automatically during GitHub Actions deployment:

1. New Fargate task spawned with API image
2. Task runs `bin/run-migrations` script
3. Workflow waits for task completion
4. Deployment fails if migrations fail

### Manual Migrations

Run migrations manually via ECS:

```bash
# Get network configuration from API service
SERVICE_CONFIG=$(aws ecs describe-services \
  --cluster rewards-app-cluster \
  --services rewards-app-api \
  --query 'services[0].networkConfiguration.awsvpcConfiguration')

SUBNETS=$(echo $SERVICE_CONFIG | jq -r '.subnets | join(",")')
SECURITY_GROUPS=$(echo $SERVICE_CONFIG | jq -r '.securityGroups | join(",")')

# Run migrations
aws ecs run-task \
  --cluster rewards-app-cluster \
  --task-definition rewards-app-api \
  --launch-type FARGATE \
  --network-configuration \
    "awsvpcConfiguration={subnets=[$SUBNETS],\
securityGroups=[$SECURITY_GROUPS],assignPublicIp=ENABLED}" \
  --overrides '{
    "containerOverrides": [{
      "name": "api",
      "command": ["bundle", "exec", "ruby", "bin/run-migrations"]
    }]
  }'
```

## Rollback Procedures

### Rollback to Previous Version

#### Option 1: Redeploy Previous Commit

```bash
# Find previous working commit
git log --oneline

# Reset to previous commit
git reset --hard <commit-sha>

# Force push (requires --force)
git push origin main --force
```

#### Option 2: Tag-Based Rollback

```bash
# Get previous image SHA from ECR
aws ecr describe-images \
  --repository-name rewards-app/api \
  --query 'sort_by(imageDetails,&imagePushedAt)[-2].imageTags[0]'

# Update task definition with previous image
# (Create new revision with previous image tag)

# Update service to use previous revision
aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-api \
  --task-definition rewards-app-api:<previous-revision>
```

### Emergency Rollback

Scale down to zero tasks to stop serving traffic:

```bash
aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-api \
  --desired-count 0
```

Restore after fix:

```bash
aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-api \
  --desired-count 1
```

## Monitoring

### CloudWatch Logs

View logs for web and API services:

```bash
# API logs
aws logs tail /ecs/rewards-app/api --follow

# Web logs
aws logs tail /ecs/rewards-app/web --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /ecs/rewards-app/api \
  --filter-pattern "ERROR"
```

### Service Health

Check service status:

```bash
# Service status
aws ecs describe-services \
  --cluster rewards-app-cluster \
  --services rewards-app-api rewards-app-web

# Task health
aws ecs list-tasks --cluster rewards-app-cluster
```

### Database Health

Check RDS status:

```bash
aws rds describe-db-instances \
  --db-instance-identifier rewards-app-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'
```

## Troubleshooting

### Service Fails to Start

#### Check task logs

```bash
aws logs tail /ecs/rewards-app/api --since 10m
```

Common issues:

- **Database connection failure**: Verify RDS is running and security groups allow access
- **Missing secrets**: Check Parameter Store has required secrets
- **Health check failing**: Verify `/health` endpoint responds
- **Image pull failure**: Ensure ECR repository exists and has images

#### Check task stopped reason

```bash
TASK_ARN=$(aws ecs list-tasks --cluster rewards-app-cluster \
  --query 'taskArns[0]' --output text)

aws ecs describe-tasks --cluster rewards-app-cluster --tasks $TASK_ARN \
  --query 'tasks[0].stoppedReason'
```

### Migrations Fail

Check migration task logs:

```bash
# Find migration task
TASK_ARN=$(aws ecs list-tasks \
  --cluster rewards-app-cluster \
  --query 'taskArns[?contains(@, `migration`)] | [0]' \
  --output text)

# Get logs
aws logs get-log-events \
  --log-group-name /ecs/rewards-app/api \
  --log-stream-name <stream-name>
```

Common issues:

- **Schema conflict**: Someone deployed migrations out of order
- **Database locked**: Previous migration task still running
- **Connection timeout**: Database not accessible from ECS tasks

### High Response Times

Check Fargate CPU/memory usage:

```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster rewards-app-cluster \
  --service-name rewards-app-api \
  --query 'taskArns[0]' --output text)

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=rewards-app-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

Solutions:

- Increase Fargate CPU/memory in `terraform/variables.tf`
- Scale up desired task count
- Optimize slow database queries

### Out of Memory (OOM) Errors

Task stops with "OutOfMemoryError":

1. Increase memory in task definition:

   ```hcl
   # terraform/variables.tf
   variable "api_memory" {
     default = 1024  # Increase from 512
   }
   ```

2. Apply Terraform changes:

   ```bash
   cd terraform
   AWS_PROFILE=admin terraform apply
   ```

   **Note**: Requires AdministratorAccess profile for IAM permissions.

3. Force new deployment:

   ```bash
   aws ecs update-service \
     --cluster rewards-app-cluster \
     --service rewards-app-api \
     --force-new-deployment
   ```

## Scaling

### Vertical Scaling (CPU/Memory)

Update task resources:

```hcl
# terraform/variables.tf
variable "api_cpu" {
  default = 512  # Increase from 256
}

variable "api_memory" {
  default = 1024  # Increase from 512
}
```

Apply changes:

```bash
cd terraform
AWS_PROFILE=admin terraform apply
```

**Note**: Requires AdministratorAccess profile for IAM permissions.

### Horizontal Scaling (Task Count)

Scale task count:

```bash
# Manual scaling
aws ecs update-service \
  --cluster rewards-app-cluster \
  --service rewards-app-api \
  --desired-count 3

# Or update in Terraform
# terraform/variables.tf
variable "desired_count" {
  default = 3  # Increase from 1
}
```

Note: Costs increase linearly with task count.

## Maintenance

### Scheduled Downtime

1. Announce maintenance window
2. Scale services to 0:

   ```bash
   aws ecs update-service --cluster rewards-app-cluster \
     --service rewards-app-web --desired-count 0
   aws ecs update-service --cluster rewards-app-cluster \
     --service rewards-app-api --desired-count 0
   ```

3. Perform maintenance (database upgrades, etc.)
4. Restore services:

   ```bash
   aws ecs update-service --cluster rewards-app-cluster \
     --service rewards-app-web --desired-count 1
   aws ecs update-service --cluster rewards-app-cluster \
     --service rewards-app-api --desired-count 1
   ```

### Database Backups

RDS automated backups are enabled:

- Retention: 7 days
- Backup window: 3:00-4:00 AM UTC
- Maintenance window: Monday 4:00-5:00 AM UTC

Manual snapshot:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier rewards-app-db \
  --db-snapshot-identifier rewards-app-manual-$(date +%Y%m%d-%H%M%S)
```

Restore from snapshot:

```bash
# This requires updating Terraform to use snapshot
# See terraform/modules/rds/main.tf
```

### Rotate Secrets

Update Rails master key:

```bash
# Generate new key
NEW_KEY=$(openssl rand -hex 32)

# Update in Parameter Store
aws ssm put-parameter \
  --name /rewards-app/rails/master-key \
  --value "$NEW_KEY" \
  --type SecureString \
  --overwrite

# Redeploy services
aws ecs update-service --cluster rewards-app-cluster \
  --service rewards-app-api --force-new-deployment
```

## Cost Monitoring

### View Current Costs

```bash
# Get month-to-date costs for project
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter '{
    "Tags": {
      "Key": "Project",
      "Values": ["rewards-app"]
    }
  }'
```

### Budget Alerts

Budget is configured at $10/month with alerts at:

- 80% of budget (~$8)
- 100% of budget ($10)
- Forecasted 100%

Update budget:

```hcl
# terraform/variables.tf
variable "budget_limit" {
  default = 50  # Increase from 10
}
```

## Production Checklist

Before going to production:

- [ ] Enable Multi-AZ RDS for high availability
- [ ] Switch from Fargate Spot to On-Demand
- [ ] Add Application Load Balancer
- [ ] Enable WAF for security
- [ ] Configure custom domain with Route 53
- [ ] Enable CloudFront CDN for web
- [ ] Set up proper backup procedures
- [ ] Configure alerting (SNS, PagerDuty, etc.)
- [ ] Enable RDS Performance Insights
- [ ] Add auto-scaling policies
- [ ] Review security groups (principle of least privilege)
- [ ] Enable AWS GuardDuty
- [ ] Configure log retention policies
- [ ] Set up disaster recovery procedures
