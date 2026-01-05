# Rewards Redemption App

A full-stack rewards redemption web application demonstrating architecture,
coding quality, testing, and DevOps practices.

**Stack:** React + TypeScript + Ruby on Rails API + PostgreSQL + Docker +
AWS ECS/Fargate

See [architecture.md](architecture.md) for technical decisions, design
rationale, and shipping plan.

## Quick Start

### Prerequisites

- Docker and Docker Compose
- mise (tool version manager)

Install mise:

```bash
curl https://mise.run | sh
```

### Local Development

```bash
# Install project tools
mise install

# Start all services (database, API, web)
docker-compose up

# Setup pre-commit hooks
mise run setup
```

## Deployment to AWS

### First-Time Infrastructure Setup

⚠️ Read the [AWS Setup Guide](docs/aws-setup.md) for complete prerequisites
and follow the [Deployment Steps](docs/aws-setup.md#deployment-steps).

### Continuous Deployment

After infrastructure is set up, deployments are automatic on push to `main`:

```bash
git push origin main
```

GitHub Actions will:

1. Build and push Docker images to ECR
2. Run database migrations
3. Update ECS Fargate services
4. Output service URLs

### Cleanup

Destroy all AWS infrastructure:

```bash
cd terraform
AWS_PROFILE=admin terraform destroy -auto-approve
```

**Note**: Requires AdministratorAccess profile. See
[AWS Setup Guide](docs/aws-setup.md#iam-permissions-for-terraform) for
profile requirements.

## Documentation

### Getting Started

- **README.md** (this file) - Onboarding and quick start
- [architecture.md](architecture.md) - Technical architecture and design
  decisions

### Infrastructure & Deployment

- [docs/aws-setup.md](docs/aws-setup.md) - Complete AWS infrastructure setup
  guide
- [terraform/README.md](terraform/README.md) - Terraform modules and usage
- [docs/deployment.md](docs/deployment.md) - Deployment, monitoring, rollbacks,
  troubleshooting

### Application Components

- [api/README.md](api/README.md) - Rails API documentation
- [web/README.md](web/README.md) - React frontend documentation

## Contributing

Start work on a GitHub issue:

```bash
/start-issue <issue-number> [main|stack]
```

Creates a worktree, fetches issue details, generates a plan, and commits setup.

## Project Structure

```text
rewards-app/
├── README.md                     # This file - onboarding guide
├── architecture.md               # Technical architecture and decisions
├── .mise.toml                    # Tool version management
├── .pre-commit-config.yaml       # Git hooks
├── docker-compose.yml            # Local development services
├── .github/workflows/            # CI/CD pipelines
├── docs/                         # Documentation
│   ├── aws-setup.md             # AWS infrastructure setup
│   └── deployment.md            # Deployment operations
├── terraform/                    # Infrastructure as Code
│   ├── README.md
│   └── modules/
├── api/                          # Rails API backend
│   ├── Dockerfile
│   └── README.md
└── web/                          # React frontend
    ├── Dockerfile
    └── README.md
```

## Support

For issues or questions:

- Check [docs/deployment.md](docs/deployment.md) for troubleshooting
- Review [architecture.md](architecture.md) for design context
- Open a GitHub issue for bugs or feature requests
