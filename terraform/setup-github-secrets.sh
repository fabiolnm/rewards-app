#!/bin/bash
set -euo pipefail

# Setup GitHub repository secrets from Terraform outputs
# Requires: gh CLI authenticated, AWS credentials
# Usage: AWS_PROFILE=admin ./setup-github-secrets.sh

# Load .env from repo root if it exists (auto-export variables)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "${REPO_ROOT}/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/.env"
  set +a
fi

echo "🔐 Setting up GitHub repository secrets..."

# Get current directory (should be terraform/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo "❌ Error: GitHub CLI (gh) is not installed"
  echo "   Install: https://cli.github.com/"
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo "❌ Error: Not authenticated with GitHub CLI"
  echo "   Run: gh auth login"
  exit 1
fi

# Check if terraform directory exists
if [ ! -d "${TERRAFORM_DIR}" ]; then
  echo "❌ Error: Terraform directory not found: ${TERRAFORM_DIR}"
  exit 1
fi

cd "${TERRAFORM_DIR}"

# Get Terraform outputs
echo "📋 Reading Terraform outputs..."
AWS_REGION=$(terraform output -raw aws_region)
AWS_ACCOUNT_ID=$(terraform output -raw aws_account_id)
OIDC_ROLE_ARN=$(terraform output -raw oidc_role_arn)
ECR_WEB_REPOSITORY=$(terraform output -raw ecr_web_repository)
ECR_API_REPOSITORY=$(terraform output -raw ecr_api_repository)
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
ECS_WEB_SERVICE=$(terraform output -raw ecs_web_service)
ECS_API_SERVICE=$(terraform output -raw ecs_api_service)
ECS_WEB_TASK_DEFINITION=$(terraform output -raw ecs_web_task_definition)
ECS_API_TASK_DEFINITION=$(terraform output -raw ecs_api_task_definition)

# Set GitHub secrets
echo "🔧 Setting GitHub repository secrets..."

gh secret set AWS_REGION --body "${AWS_REGION}"
gh secret set AWS_ACCOUNT_ID --body "${AWS_ACCOUNT_ID}"
gh secret set OIDC_ROLE_ARN --body "${OIDC_ROLE_ARN}"
gh secret set ECR_WEB_REPOSITORY --body "${ECR_WEB_REPOSITORY}"
gh secret set ECR_API_REPOSITORY --body "${ECR_API_REPOSITORY}"
gh secret set ECS_CLUSTER_NAME --body "${ECS_CLUSTER_NAME}"
gh secret set ECS_WEB_SERVICE --body "${ECS_WEB_SERVICE}"
gh secret set ECS_API_SERVICE --body "${ECS_API_SERVICE}"
gh secret set ECS_WEB_TASK_DEFINITION --body "${ECS_WEB_TASK_DEFINITION}"
gh secret set ECS_API_TASK_DEFINITION --body "${ECS_API_TASK_DEFINITION}"

echo ""
echo "✅ AWS secrets configured successfully!"
echo ""

# Sentry configuration (optional)
# Can be set via environment variables or entered interactively
echo "🔍 Sentry Configuration (optional - press Enter to skip)"
echo "   Tip: Set SENTRY_* env vars to skip prompts"
echo ""

if [ -z "${SENTRY_DSN_API:-}" ]; then
  read -rp "SENTRY_DSN_API (backend API): " SENTRY_DSN_API
fi
if [ -n "${SENTRY_DSN_API:-}" ]; then
  gh secret set SENTRY_DSN_API --body "${SENTRY_DSN_API}"
  echo "  ✓ SENTRY_DSN_API set"
fi

if [ -z "${SENTRY_DSN_WEB:-}" ]; then
  read -rp "SENTRY_DSN_WEB (frontend): " SENTRY_DSN_WEB
fi
if [ -n "${SENTRY_DSN_WEB:-}" ]; then
  gh secret set SENTRY_DSN_WEB --body "${SENTRY_DSN_WEB}"
  echo "  ✓ SENTRY_DSN_WEB set"
fi

if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  read -rp "SENTRY_AUTH_TOKEN: " SENTRY_AUTH_TOKEN
fi
if [ -n "${SENTRY_AUTH_TOKEN:-}" ]; then
  gh secret set SENTRY_AUTH_TOKEN --body "${SENTRY_AUTH_TOKEN}"
  echo "  ✓ SENTRY_AUTH_TOKEN set"
fi

if [ -z "${SENTRY_ORG:-}" ]; then
  read -rp "SENTRY_ORG: " SENTRY_ORG
fi
if [ -n "${SENTRY_ORG:-}" ]; then
  gh secret set SENTRY_ORG --body "${SENTRY_ORG}"
  echo "  ✓ SENTRY_ORG set"
fi

if [ -z "${SENTRY_PROJECT_WEB:-}" ]; then
  read -rp "SENTRY_PROJECT_WEB: " SENTRY_PROJECT_WEB
fi
if [ -n "${SENTRY_PROJECT_WEB:-}" ]; then
  gh secret set SENTRY_PROJECT_WEB --body "${SENTRY_PROJECT_WEB}"
  echo "  ✓ SENTRY_PROJECT_WEB set"
fi

echo ""
echo "✅ GitHub secrets configured successfully!"
echo ""
echo "AWS secrets set:"
echo "  - AWS_REGION: ${AWS_REGION}"
echo "  - AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "  - OIDC_ROLE_ARN"
echo "  - ECR_WEB_REPOSITORY"
echo "  - ECR_API_REPOSITORY"
echo "  - ECS_CLUSTER_NAME"
echo "  - ECS_WEB_SERVICE"
echo "  - ECS_API_SERVICE"
echo "  - ECS_WEB_TASK_DEFINITION"
echo "  - ECS_API_TASK_DEFINITION"
echo ""
echo "Sentry secrets (if provided):"
echo "  - SENTRY_DSN_API"
echo "  - SENTRY_DSN_WEB"
echo "  - SENTRY_AUTH_TOKEN"
echo "  - SENTRY_ORG"
echo "  - SENTRY_PROJECT_WEB"
