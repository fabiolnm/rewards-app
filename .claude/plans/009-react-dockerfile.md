# Implementation Plan: React Dockerfile

**Issue:** #9 - <https://github.com/fabiolnm/rewards-app/issues/9>

## Overview

Add Docker containerization for the React frontend using multi-stage
builds (Bun + Nginx), SPA routing configuration, and docker-compose
integration.

## Context

**React App:**

- Build tool: Vite 7.2.4
- Package manager: Bun (bun.lockb present)
- Build command: `bun run build` → outputs to `dist/`
- No environment variables required (static app)

**Existing Docker Patterns (from api/Dockerfile):**

- Directives: `syntax=docker/dockerfile:1` and `check=error=true`
- Multi-stage: base → build → final
- Non-root user: uid/gid 1000
- Production-focused with minimal runtime dependencies

**docker-compose.yml Structure:**

- Services: db (postgres:15-alpine, port 5432), api (port 3001:3000)
- Container naming: `rewards-app-{service}`
- Restart policy: `unless-stopped`

**Requirements from Issue #9:**

- Multi-stage Dockerfile (build + nginx)
- nginx.conf for SPA routing
- Update docker-compose.yml with web service
- Must pass: `hadolint web/Dockerfile`
- Must work: `docker-compose up web` serves app at localhost:3000

## Implementation Steps

### 1. Create Nginx Configuration (web/nginx.conf)

**SPA Routing:**

- `try_files $uri $uri/ /index.html` - fallback for client-side routing
- Serve from `/usr/share/nginx/html`
- Listen on port 80

**Caching Headers:**

- `index.html`: `no-cache` (always revalidate)
- Hashed assets: `max-age=31536000, immutable` (Vite generates hashes)
- Other assets: `max-age=86400` (1 day)

**Additional:**

- Gzip compression for text assets
- Security headers (X-Frame-Options, X-Content-Type-Options)
- Health check endpoint `/health`

### 2. Create Multi-stage Dockerfile (web/Dockerfile)

**Build Stage:**

- Base: `oven/bun:1-slim` (official Bun image)
- Install: `bun install --frozen-lockfile`
- Build: `bun run build`
- Output: `dist/` directory

**Production Stage:**

- Base: `nginx:1.27-alpine` (minimal footprint)
- Copy `dist/` → `/usr/share/nginx/html`
- Copy `nginx.conf` → `/etc/nginx/conf.d/default.conf`
- Non-root: nginx user (uid 101, default in alpine)
- Expose: port 80

**Hadolint Compliance:**

- Pin all image versions
- Use `--frozen-lockfile` for reproducible builds
- Layer caching: dependencies before source
- Include `syntax` and `check` directives

### 3. Update docker-compose.yml

Add web service after api service:

```yaml
  web:
    build:
      context: ./web
    container_name: rewards-app-web
    restart: unless-stopped
    ports:
      - "3000:80"
```

## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

1. **docs(#9): Plan React Dockerfile**
   - Create `.claude/plans/009-react-dockerfile.md`
   - Submit to create PR with issue context

2. **feat(#9): Add Nginx configuration for SPA routing**
   - Create `web/nginx.conf`
   - Configure SPA fallback, caching, gzip, security headers

3. **feat(#9): Add multi-stage Dockerfile for React app**
   - Create `web/Dockerfile`
   - Build stage: Bun + Vite
   - Production stage: Nginx + static files
   - Verify: `hadolint web/Dockerfile` passes

4. **feat(#9): Add web service to docker-compose**
   - Update `docker-compose.yml`
   - Add web service with port mapping 3000:80
   - Verify: `docker-compose up web` works

## Verification

Full acceptance criteria:

- [ ] `hadolint web/Dockerfile` passes
- [ ] `docker-compose up web` serves React app
- [ ] App accessible at localhost:3000
- [ ] SPA routing works (all routes → index.html)
