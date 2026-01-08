# Rails 8 API Skeleton - Issue #4

## Objective

Create Rails 8 API-only application in `api/` subdirectory that connects to
Docker Compose PostgreSQL and includes a health check endpoint.

## Important Notes

**Thruster Removal:** Rails 8 includes Thruster by default, but it's unnecessary
for API-only applications. Thruster's main benefits (static asset caching,
X-Sendfile acceleration) don't apply to pure JSON APIs. For Rails API + React
SPA architectures, industry best practice recommends Nginx for React frontend
static files and Puma directly for Rails API. See issue #26 for full analysis.

**Files to exclude/remove:**

- `api/Gemfile` - Remove thruster gem (lines 29-30)
- `api/bin/thrust` - Delete this file
- `api/Gemfile.lock` - Will auto-update when running bundle install

## Prerequisites

- Docker Compose PostgreSQL is running (from issue #3)
- Ruby 4.0.0 installed (Rails 8 requirement)
- Mise configured for tool management

## Commit Structure

1. **Commit 1:** Update .mise.toml (add Ruby 4.0.0 and enhance setup task)
2. **Commit 2:** Generate Rails 8 API and configure database.yml
3. **Commit 3:** Add RuboCop pre-commit hook

## Implementation Steps

### Commit 1: Add Ruby to Mise and Enhance Setup Task

**File:** `.mise.toml`

Add Ruby version to tools section and update setup task:

```toml
[tools]
ruby = "4.0.0"
"pipx:pre-commit" = "4.5.1"

[tasks.setup]
description = "Install dependencies and pre-commit hooks"
run = '''
  gem install rails
  pre-commit install --hook-type pre-commit
  pre-commit install --hook-type commit-msg
'''

[tasks.lint]
description = "Run all pre-commit hooks"
run = "pre-commit run --all-files"
```

Run `mise install` to install Ruby, then `mise run setup` to install Rails and hooks.

**Commit message:**

```text
chore(#4): Add Ruby 4.0.0 and enhance setup task
```

### Commit 2: Generate Rails 8 API Application and Configure Database

Generate Rails application:

```bash
rails new api --api -d postgresql --skip-git
```

Flags:

- `--api`: API-only mode (no views, helpers, assets)
- `-d postgresql`: PostgreSQL adapter
- `--skip-git`: Skip git init (we're in a monorepo)

Move Rails-generated GitHub Actions to monorepo root and copy .gitignore:

```bash
# Rails generates api/.github/workflows/ci.yml
# Move it to .github/workflows/rails-ci.yml in monorepo root
mkdir -p .github/workflows
mv api/.github/workflows/ci.yml .github/workflows/rails-ci.yml
rm -rf api/.github

# Rails --skip-git doesn't create .gitignore, so copy from a reference Rails app
cp /tmp/rails-gitignore-test/.gitignore api/.gitignore
```

**Configure workflow for monorepo structure:**

GitHub Actions requires several monorepo-specific configurations that Rails doesn't generate:

1. **Define Ruby version as environment variable** (line 8-9):

   ```yaml
   env:
     RUBY_VERSION: '4.0.0'
   ```

2. **Add working directory to each job** (applies to `scan_ruby`, `lint`, and `test` jobs):

   ```yaml
   jobs:
     scan_ruby:
       defaults:
         run:
           working-directory: api
   ```

3. **Add working directory to setup-ruby steps**:

   ```yaml
   - name: Set up Ruby
     uses: ruby/setup-ruby@v1
     with:
       ruby-version: ${{ env.RUBY_VERSION }}
       bundler-cache: true
       working-directory: api
   ```

4. **Override working directory for pre-checkout steps** (test job only):

   ```yaml
   - name: Install packages
     working-directory: .
     run: sudo apt-get update && sudo apt-get install --no-install-recommends -y libpq-dev
   ```

5. **Update cache paths and file globs** (lint job):

   ```yaml
   - name: Prepare RuboCop cache
     env:
       DEPENDENCIES_HASH: ${{ hashFiles(
         'api/.ruby-version',
         'api/**/.rubocop.yml',
         'api/**/.rubocop_todo.yml',
         'api/Gemfile.lock'
       ) }}
     with:
       path: api/${{ env.RUBOCOP_CACHE_ROOT }}
   ```

**Remove Thruster (unnecessary for API-only apps):**

Rails 8 generates Thruster by default, but it's not needed for API-only applications:

```bash
# Remove from Gemfile (lines 29-30)
# Delete bin/thrust file
rm api/bin/thrust

# Update Gemfile.lock
cd api && bundle install
```

**File:** `api/config/database.yml`

Update with DRY configuration using YAML anchors:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: rewards
  password:
  host: localhost
  port: 5432

development:
  <<: *default
  database: rewards_development

test:
  <<: *default
  database: rewards_test
```

**Commit message:**

```text
feat(#4): Generate Rails 8 API with PostgreSQL config
```

### Note on Health Endpoint

Rails 8 includes a built-in health check endpoint at `/up` (provided by `rails/health#show`).
This endpoint returns HTTP 200 if the app boots successfully, HTTP 500 otherwise.
No custom health controller is needed for the API skeleton.

## Verification Steps

### Create Databases and Run Tests

```bash
# Start PostgreSQL
docker-compose up -d db

# Create databases
cd api
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Run tests
bin/rails test
```

### Verify Health Endpoint

```bash
# Start server
cd api
bin/rails server

# In another terminal
curl http://localhost:3000/up
# Expected: HTTP 200 if application boots successfully
```

## Acceptance Criteria

- [ ] `bin/rails db:create` succeeds
- [ ] `bin/rails db:migrate` runs successfully
- [ ] `bin/rails test` passes
- [ ] `curl localhost:3000/up` returns HTTP 200

## Critical Files Modified

**Commit 1:**

- `.mise.toml`

**Commit 2:**

- `api/` (entire directory generated by Rails)
- `api/.gitignore` (copied from official Rails template)
- `.github/workflows/rails-ci.yml` (moved from `api/.github/workflows/ci.yml`)
- `api/config/database.yml` (modified for Docker Compose PostgreSQL)
- `api/Gemfile` (added minitest-rails, removed thruster)
- `api/bin/thrust` (deleted - not needed for API-only apps)
- `api/Gemfile.lock` (regenerated after thruster removal)
- `api/test/test_helper.rb` (added require "minitest/rails")

**Commit 3:**

- `.pre-commit-config.yaml` (add RuboCop hook for Rails linting)
- `.github/workflows/ci.yml` (skip RuboCop in general pre-commit, runs
  separately in Rails CI)
