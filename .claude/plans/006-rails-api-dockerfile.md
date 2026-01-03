# Issue #6: Rails API Dockerfile

## Scope

- Create Hadolint configuration for Dockerfile linting
- Add Rails API service to docker-compose.yml
- Verify existing Dockerfile passes linting

## Current State

- ✅ `api/Dockerfile` exists (multi-stage, production-ready)
- ✅ `docker-compose.yml` has `db` service (PostgreSQL 15)
- ❌ No `.hadolint.yaml` configuration
- ❌ No `api` service in docker-compose

## Implementation Plan

### 1. Create `.hadolint.yaml`

Configure Hadolint at the root to lint all Dockerfiles with shared rules.

**Root placement rationale:** This is a monorepo with multiple Dockerfiles
(`api/Dockerfile` now, `web/Dockerfile` in issue #9). Hadolint automatically
discovers `.hadolint.yaml` in the project root, allowing both services to
share the same linting rules without duplication.

Configuration:

- Set failure threshold to warning level
- Ignore DL3008 (apt-get pin versions - acceptable for slim images)
- Configure trusted registries (docker.io)

### 2. Update `api/config/database.yml`

Add environment variable support for database host:

```yaml
host: <%= ENV.fetch("DB_HOST", "localhost") %>
```

This allows Docker override while preserving localhost default for local dev.

### 3. Add API service to `docker-compose.yml`

Insert after `db` service:

```yaml
api:
  build:
    context: ./api
  container_name: rewards-app-api
  restart: unless-stopped
  ports:
    - "3001:80"
  environment:
    RAILS_ENV: development
    RAILS_LOG_TO_STDOUT: "1"
    DB_HOST: db
  depends_on:
    db:
      condition: service_healthy
  volumes:
    - ./api:/rails
```

**Key points:**

- Port 3001:80 (Thruster listens on 80 in container)
  - Thruster is Rails 8's default HTTP/2 proxy (sits in front of Puma)
  - Provides asset caching, compression, and X-Sendfile acceleration
  - Eliminates need for separate nginx/reverse proxy in production
- DB_HOST=db overrides database.yml localhost
- Wait for db health check before starting
- Mount source for development hot-reload

### 4. Verify Hadolint

Run `hadolint api/Dockerfile` to ensure it passes.

## Files to Modify

- `.hadolint.yaml` (create in root)
- `api/config/database.yml` (update host line)
- `docker-compose.yml` (add api service)

## Commits Plan

1. **Add Hadolint configuration**
   - Create `.hadolint.yaml` in root with linting rules
   - Verify Dockerfile passes `hadolint` check

2. **Configure database for Docker**
   - Update `api/config/database.yml` with `DB_HOST` env support

3. **Add API service to docker-compose**
   - Add `api` service with build context, port mapping, and db dependency
   - Test with `docker-compose up api`

## Acceptance Criteria

- `hadolint api/Dockerfile` passes
- `docker-compose up api` starts Rails
- Health check at `http://localhost:3001/health` returns `{"status":"ok"}`
