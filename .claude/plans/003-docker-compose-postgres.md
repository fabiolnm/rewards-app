# Implementation Plan: Docker Compose + Postgres + Hadolint

## Overview

Add Docker Compose infrastructure with PostgreSQL 15 database and Hadolint linting.

## Deliverables

1. `docker-compose.yml` - Postgres service with volume and trust auth
2. `.pre-commit-config.yaml` - Add Hadolint hook
3. `.gitignore` - Protect Docker override files
4. `.dockerignore` - Future-proof for Dockerfile builds

## Implementation Steps

### 1. Update .gitignore

Add entries to protect:

- docker-compose.override.yml
- .docker/ directory

### 2. Create docker-compose.yml

Postgres 15 service with:

- `postgres:15-alpine` image
- Named volume `postgres_data` for persistence
- Port mapping to 5432
- Healthcheck using pg_isready

Environment variables:

- POSTGRES_USER=rewards
- POSTGRES_DB=rewards_development
- POSTGRES_HOST_AUTH_METHOD=trust

Trust authentication setup:

- POSTGRES_HOST_AUTH_METHOD=trust configures pg_hba.conf automatically
- Allows connections without password (development only)
- Equivalent to "host all all all trust" in pg_hba.conf
- No POSTGRES_PASSWORD needed

### 3. Create .dockerignore

Exclude from Docker build context:

- .git
- Documentation (*.md, docs/)
- CI/CD config
- IDE files
- Dependencies (node_modules, vendor)

### 4. Add Hadolint to .pre-commit-config.yaml

Add hook entry with comment explaining version pinning rules:

- Repo: <https://github.com/hadolint/hadolint>
- Version: v2.14.0
- Hook: hadolint-docker
- Files: Dockerfile.*

Add YAML comment above hook explaining:

- DL3008: Enforces version pinning for apt-get install (Debian/Ubuntu)
- DL3018: Enforces version pinning for apk add (Alpine)
- Purpose: Ensure reproducible builds

## Testing

1. **Start database**: `docker-compose up db`
2. **Test connection**: `psql -h localhost -U rewards -d rewards_development` (no password)
3. **Test persistence**: Create table, restart container, verify data exists
4. **Test Hadolint**: `pre-commit run hadolint-docker --all-files`

## Issue Drift

Original issue scope needs update:

- Remove `.env.example` deliverable (not needed with trust auth)
- Update "database credentials" to "database configuration"

## Critical Files

- `docker-compose.yml` - Service definitions with trust auth
- `.pre-commit-config.yaml` - Hadolint hook
- `.gitignore` - Protect Docker override files
- `.dockerignore` - Exclude files from Docker context
