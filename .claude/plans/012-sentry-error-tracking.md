# Plan: Sentry Error Tracking

Issue: #12 - Take-Home: Sentry Error Tracking

## Overview

Integrate Sentry for error tracking in both the Rails API backend and React
frontend, with source maps, environment tagging, and custom error context.

## Backend Implementation

### Backend Files

1. **api/Gemfile** - Add `sentry-ruby` and `sentry-rails` gems
2. **api/config/initializers/sentry.rb** - Sentry configuration
3. **api/app/controllers/concerns/sentry_context.rb** - User/request context
4. **api/app/controllers/application_controller.rb** - Include Sentry concern

### Configuration

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV.fetch("RAILS_ENV", "development")
  config.release = ENV["GIT_SHA"] || `git rev-parse HEAD`.strip
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f
  config.send_default_pii = false
end
```

### Context Enrichment

- Add `request_id` from Rails request headers
- Add `user_id` when available (placeholder for future auth)
- Filter sensitive params (already in filter_parameter_logging.rb)

## Frontend Implementation

### Frontend Files

1. **web/package.json** - Add `@sentry/react` and `@sentry/vite-plugin`
2. **web/src/sentry.ts** - Sentry initialization module
3. **web/src/main.tsx** - Initialize Sentry before React renders
4. **web/src/components/ErrorBoundary.tsx** - Error boundary with Sentry
5. **web/src/App.tsx** - Wrap app with ErrorBoundary
6. **web/vite.config.ts** - Add Sentry Vite plugin for source maps

### Sentry Initialization

```typescript
// src/sentry.ts
import * as Sentry from "@sentry/react";

export function initSentry() {
  if (!import.meta.env.VITE_SENTRY_DSN) return;

  Sentry.init({
    dsn: import.meta.env.VITE_SENTRY_DSN,
    environment: import.meta.env.MODE,
    release: import.meta.env.VITE_GIT_SHA,
    integrations: [Sentry.browserTracingIntegration()],
    tracesSampleRate: 0.1,
  });
}
```

### Error Boundary

```typescript
// src/components/ErrorBoundary.tsx
import * as Sentry from "@sentry/react";
import { Component, ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    Sentry.captureException(error, { extra: errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? <h1>Something went wrong.</h1>;
    }
    return this.props.children;
  }
}
```

## Infrastructure Changes

### Infrastructure Files

1. **terraform/modules/ecs/variables.tf** - Add Sentry DSN variables
2. **terraform/modules/ecs/main.tf** - Add SENTRY_DSN to task definitions
3. **terraform/modules/ecs/secrets.tf** (new) - Parameter Store for Sentry
4. **.github/workflows/deploy.yml** - Add GIT_SHA env var, source map upload

### Secret Management

- Store Sentry DSNs in AWS Parameter Store:
  - `/${project_name}/SENTRY_DSN` (backend)
  - `/${project_name}/SENTRY_DSN_WEB` (frontend - build-time)
  - `/${project_name}/SENTRY_AUTH_TOKEN` (CI/CD source map upload)

### Source Map Upload (CI/CD)

```yaml
# In deploy.yml, after web build
- name: Upload source maps to Sentry
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: your-org
    SENTRY_PROJECT: rewards-web
  run: |
    npx @sentry/cli sourcemaps upload \
      --release=${{ github.sha }} \
      ./web/dist
```

## Environment Configuration

| Environment | Backend DSN | Frontend DSN | Source Maps |
|-------------|-------------|--------------|-------------|
| Development | Optional    | Optional     | No          |
| Production  | Required    | Required     | Yes         |

## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

1. **Backend: Add sentry-ruby gem and initializer**
   - Add gems to Gemfile
   - Create config/initializers/sentry.rb
   - Run bundle install

2. **Backend: Add request context enrichment**
   - Create app/controllers/concerns/sentry_context.rb
   - Include concern in ApplicationController

3. **Frontend: Add @sentry/react package**
   - Add dependencies to package.json
   - Run bun install

4. **Frontend: Initialize Sentry and add ErrorBoundary**
   - Create src/sentry.ts initialization module
   - Create src/components/ErrorBoundary.tsx
   - Update main.tsx to initialize Sentry
   - Update App.tsx to wrap with ErrorBoundary

5. **Frontend: Configure source map upload in Vite**
   - Add @sentry/vite-plugin to vite.config.ts
   - Configure for release tracking

6. **Infrastructure: Add Sentry DSN to ECS task definitions**
   - Add Parameter Store secrets for Sentry DSNs
   - Update ECS task definitions with environment variables

7. **CI/CD: Add source map upload to deploy workflow**
   - Add Sentry CLI step after web build
   - Pass GIT_SHA to build

## Verification

### Local Testing

Run services with Sentry DSNs from `.env`:

```bash
# Backend
source .env
cd api && SENTRY_DSN=$SENTRY_DSN_API bin/rails server

# Frontend (separate terminal)
source .env
cd web && VITE_SENTRY_DSN=$SENTRY_DSN_WEB bun run dev
```

Errors appear in Sentry with `development` environment tag.
Frontend stack traces will be minified (source maps only in production).

### Test Error Endpoints

**Backend** - add to `api/config/routes.rb`:

```ruby
get "/sentry-test", to: ->(_env) { raise "Sentry test error from Rails API" }
```

**Frontend** - add to `web/src/App.tsx`:

```tsx
<button onClick={() => { throw new Error("Sentry test error from React"); }}>
  Test Sentry
</button>
```

### Trigger Errors

```bash
# Backend
curl http://localhost:3000/sentry-test

# Frontend
# Click "Test Sentry" button in browser
```

### Verification Checklist

Local:

- [ ] Backend error appears in Sentry `rewards-api` project
- [ ] Frontend error appears in Sentry `rewards-web` project
- [ ] Errors tagged with `development` environment

Production (after deploy):

- [ ] Errors tagged with `production` environment
- [ ] Errors tagged with git SHA release
- [ ] Frontend stack trace shows `.tsx` files (source maps working)
