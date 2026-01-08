# Architecture

Technical architecture, design decisions, and implementation details for the
Rewards Redemption App.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React, TypeScript (.tsx), Redux Toolkit, Vite |
| Backend | Ruby on Rails 8 API |
| Infrastructure | Docker, AWS ECS/Fargate |
| CI/CD | GitHub Actions |
| Quality | Mise, Pre-commit, Markdownlint, RuboCop, ESLint, Prettier, Hadolint |
| Observability | Sentry |
| Testing | Minitest (Rails), Vitest (React) |

## Architectural Decisions

### Monorepo Structure

Single repository with `api/` and `web/` directories. Enables atomic commits
across stack, shared CI/CD, and simpler dependency management for a small team.

```text
rewards-app/
├── README.md                     # Architecture + shipping plan
├── .gitignore
├── .mise.toml                    # Tool version management
├── .pre-commit-config.yaml       # Git hooks
├── .markdownlint.json            # Markdown linting rules
├── docker-compose.yml
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── api/                          # Rails API
│   ├── Dockerfile
│   ├── .rubocop.yml
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   ├── models/
│   │   ├── services/
│   │   └── serializers/
│   └── test/
└── web/                          # React Frontend
    ├── Dockerfile
    ├── nginx.conf
    ├── .eslintrc.json
    ├── .prettierrc
    ├── src/
    │   ├── components/
    │   ├── hooks/
    │   ├── store/
    │   └── services/
    └── vite.config.ts
```

### Backend: Ruby on Rails 8 API

- **API-only mode:** JSON responses, no view layer
- **Service objects:** Business logic extracted from controllers
- **Minitest:** Rails default test framework
- **RuboCop:** Ruby style enforcement with Rails cops

### Frontend: React + TypeScript + Vite

- **TypeScript:** Type safety, compile-time error checking
- **Vite:** Fast dev server with native ES modules
- **Redux Toolkit:** Predictable state management
- **ESLint + Prettier:** Code quality and formatting
- **Vitest:** Fast unit testing with Vite integration

### Infrastructure: Docker + PostgreSQL

- **Docker Compose:** Consistent dev environment, mirrors production
- **PostgreSQL:** Production-grade database
- **Multi-stage builds:** Smaller production images, cached layers
- **Hadolint:** Dockerfile linting for best practices

### CI/CD: GitHub Actions + AWS

- **GitHub Actions:** CI pipeline with linting and tests
- **AWS ECS/Fargate:** Serverless container deployment with auto-scaling

### Quality: Mise + Pre-commit + Linters + Tests

- **Mise:** Polyglot tool version manager
- **Pre-commit hooks:** Catch issues before commit
- **Markdownlint:** Markdown style enforcement
- **RuboCop:** Ruby style enforcement (with Rails)
- **ESLint:** TypeScript/React style enforcement (with React)
- **Prettier:** Code formatting (with React)
- **Hadolint:** Dockerfile best practices (with Dockerfiles)
- **Minitest + Vitest:** Unit and integration tests

### Observability: Sentry

- **Error tracking:** Capture exceptions with context
- **Source maps:** Readable stack traces for frontend errors

## Shipping Plan

### Phase 1: Foundation

#### Monorepo Setup

- [x] #1 Monorepo Root (mise, pre-commit, markdownlint, README, .gitignore)

#### Infrastructure

- [x] #3 Docker Compose + Postgres + Hadolint

#### Backend

- [x] #4 Rails API Skeleton
- [x] #5 RuboCop + Minitest pre-commit hooks
- [x] #6 Rails API Dockerfile

#### Frontend

- [x] #7 React + TypeScript Skeleton
- [x] #8 ESLint + Prettier + Vitest pre-commit hooks
- [x] #9 React Dockerfile

#### DevOps

- [x] #10 GitHub Actions CI
- [x] #11 Deploy to AWS ECS/Fargate (CD)

#### Observability

- [ ] #12 Sentry Error Tracking

### Phase 2: Features (Vertical Slices)

- [ ] #13 Feature - List Available Rewards
- [ ] #14 Feature - User Points Balance
- [ ] #15 Feature - Redeem a Reward
- [ ] #16 Feature - Redemption History

## Design Decisions & Trade-offs

### Quality Gates Integrated from Day One

Linters and formatters are added alongside their respective frameworks rather
than as a separate phase. This ensures code quality from the first line of
production code.

### CI/CD Pipeline in Foundation

Deploy pipeline is built in the foundation phase to enable continuous delivery
from the start. This allows iterative feature deployment and real-world testing
early.

### Observability Early

Sentry integration in Phase 1 ensures error tracking is available from the
first deployed code, providing visibility into production issues immediately.

### Pre-commit in Monorepo Root

Markdownlint is configured at the monorepo root level. Framework-specific
linters (RuboCop, ESLint, Prettier, Hadolint) extend the root pre-commit
configuration in their respective sub-issues.
