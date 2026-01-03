# Implementation Plan: Setup mise and pre-commit Framework

## Goal

Configure mise for tool version management and pre-commit framework with three
validation hooks: commit message format, branch naming, and markdown linting.

## File Structure

```text
.
├── .mise.toml                    # Tool version management
├── .pre-commit-config.yaml       # Pre-commit hooks configuration
├── .markdownlint.json           # Markdown linting rules (88 char limit)
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI workflow
└── scripts/
    ├── validate-commit-msg      # Commit message validation
    ├── check-branch-name        # Branch naming validation
    ├── validate-commit-author   # Commit author validation (local)
    └── ci-validate-pr-commits   # PR commits validation (CI)
```

## Commit Strategy

### Commit 1: Setup mise and validation hooks

- Create `.mise.toml`
- Create `scripts/validate-commit-msg` (commit message validation)
- Create `scripts/check-branch-name` (branch name validation)
- Create `.pre-commit-config.yaml` (hooks configuration)
- Test hooks and fix any issues in this commit

### Commit 2: Add markdown linting

- Create `.markdownlint.json`
- Test markdown linting and fix any issues in this commit

### Commit 3: Add author validation

- Create `scripts/validate-commit-author` (local author validation)
- Update `.pre-commit-config.yaml` (add author validation hook)
- Test author validation locally with valid/invalid git configs

### Commit 4: Add GitHub Actions CI

- Create `scripts/ci-validate-pr-commits` (CI PR validation)
- Create `.github/workflows/ci.yml` (GitHub Actions workflow)
- Test CI workflow by creating PR

## Implementation Steps

### 1. Create mise Configuration

**File: `.mise.toml`**

- Configure mise to install pre-commit

### 2. Create Validation Scripts

**File: `scripts/validate-commit-msg`** (executable)

- Enforce pattern: `type(#issue): message`
- Example: `feat(#1): Add feature`

**File: `scripts/check-branch-name`** (executable)

- Enforce pattern: `{type}-{issue}-{slug}`
- Example: `chore-1-setup-monorepo-tooling`
- Skip validation for main/master branches
- Accepts `BRANCH_NAME` environment variable (for CI) or uses git command (local)

### 3. Configure Markdown Linting

**File: `.markdownlint.json`**

- Line length: 88 characters
- Exclude tables from length check
- Include code blocks in length validation

### 4. Configure Pre-commit Hooks

**File: `.pre-commit-config.yaml`**

- Local hooks: commit message and branch name validation
- Remote hook: markdownlint-cli for markdown files
- Additional: trailing whitespace, EOF, YAML validation

### 5. Create Author Validation Script (Commit 3)

**File: `scripts/validate-commit-author`** (executable)

Validates `git config user.name` and `git config user.email`:

- **Name**: Must contain 2+ words (first and last name)
  - Reject: "fabio", "root"
  - Accept: "Fabio Miranda", "Fabio Luiz Nery de Miranda"
- **Email**: Must be valid email format (contains @, has domain)

**Design Decision:** Runs at `pre-commit` stage (before user writes message) to
fail fast on git config issues. Separate from commit message validation which runs
at `commit-msg` stage (after message written).

Script validates using patterns:

- Name: `^[[:alpha:]][[:alpha:][:space:].'\''()-]+[[:alpha:]]$` + word count >= 2
- Email: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`

Add to `.pre-commit-config.yaml` after branch name validation:

```yaml
  # Commit author validation
  - repo: local
    hooks:
      - id: validate-commit-author
        name: Validate commit author
        entry: scripts/validate-commit-author
        language: script
        stages: [pre-commit]
        pass_filenames: false
        always_run: true
```

### 6. Create CI Validation Scripts (Commit 4)

**File: `scripts/ci-validate-pr-commits`** (executable)

Validates all commits in PR range (from base to head):

- Iterates through all commits using `git rev-list`
- Validates author name/email for each commit
- Reports all failures, not just first one
- Uses `BASE_REF` and `HEAD_REF` environment variables

**File: `.github/workflows/ci.yml`**

GitHub Actions workflow that runs on PRs:

1. Validate branch name (fast fail)
2. Validate all PR commit authors
3. Run pre-commit checks (markdown lint, YAML, file checks)

**Workflow Configuration:**

```yaml
on:
  pull_request:  # Runs on ALL PRs (no branch restriction)
```

**Important:** Workflow runs on ALL pull requests, not just PRs to main/master.
This is required for Graphite stacked PRs where PRs target other feature branches.

**Environment Variables:**

- `BRANCH_NAME: ${{ github.head_ref }}` - Passed to check-branch-name script
- `BASE_REF/HEAD_REF` - Used by ci-validate-pr-commits for commit range
- `SKIP: check-branch-name,validate-commit-author` - Skips local-only hooks in
  pre-commit run (these are validated in dedicated CI steps)

**Notes:**

- `fetch-depth: 0` needed for full commit history
- `--hook-stage pre-commit` runs only pre-commit stage hooks
- Uses `actions/checkout@v4` and `actions/setup-python@v5`

### 7. Graphite Stacked PRs

**Overview:** This project uses Graphite for stacked pull requests, allowing multiple
dependent PRs to be developed and reviewed in parallel.

**Why Stacked PRs:**

- Break large features into smaller, reviewable chunks
- Each PR in the stack targets the previous PR's branch
- PRs can be reviewed and iterated independently
- Final PR merges cascade down to main

**Example Stack:**

```text
main
  └─ PR #2: chore-1-setup-monorepo-tooling
      └─ PR #18: docs-17-take-home-coding-challenge
          └─ PR #19: feat-3-docker-compose-postgres
              └─ PR #21: feat-4-rails-api-skeleton
```

**GitHub Actions Compatibility:** CI workflow runs on ALL PRs (not just PRs to
main) to validate stacked PRs at every level.

**Setup Graphite Authentication:**

```bash
# Check if authenticated
gt auth status

# If not authenticated, login with token
gt auth --token

# Verify repository access (sync with remote)
gt sync
```

If repository access fails:

- Authorize at: <https://app.graphite.dev/settings>
- Sync repository at: <https://app.graphite.dev/settings/synced-repos>

### 8. Install and Activate

```bash
# Install all tools via mise
mise install

# Install pre-commit hooks (run before commit is created)
pre-commit install --hook-type pre-commit

# Install commit-msg hooks (run after commit message is written)
pre-commit install --hook-type commit-msg

# Make scripts executable
chmod +x scripts/validate-commit-author
chmod +x scripts/ci-validate-pr-commits

pre-commit run --all-files
```

## Testing Plan

### Test 1: Invalid Commit Message

- Attempt commit without issue format
- Should fail validation

### Test 2: Valid Commit Message

- Commit with proper format: `feat(#1): message`
- Should pass validation

### Test 3: Invalid Branch Name

- Create temp branch: `git checkout -b invalid_branch`
- Attempt commit
- Should fail validation
- Cleanup: return to original branch and delete temp branch

### Test 4: Valid Branch Name

- Current branch `chore-1-setup-monorepo-tooling` should pass

### Test 5: Markdown Line Length

- Add long line to plan file (>88 chars)
- Should fail linter
- Fix line length
- Should pass linter

### Test 6: Invalid Author Name (Commit 3)

- Set invalid git config: `git config user.name "fabio"`
- Attempt commit
- Should fail with "must contain first and last name" error
- Restore valid name: `git config user.name "Fabio Luiz Nery de Miranda"`

### Test 7: Invalid Author Email (Commit 3)

- Set invalid email: `git config user.email "invalid-email"`
- Attempt commit
- Should fail with "Invalid author email format" error
- Restore valid email: `git config user.email "fabio@miranti.net.br"`

### Test 8: Valid Author (Commit 3)

- Ensure git config has valid name (2+ words) and email
- Commit should pass author validation
- Verify success message: "✓ Commit author is valid"

### Test 9: CI Validation Script Locally (Commit 4)

- Test script with current branch: `BASE_REF=main HEAD_REF=HEAD scripts/ci-validate-pr-commits`
- Should validate all commits in current branch
- All commits should pass (current author is valid)

### Test 10: GitHub Actions Workflow (Commit 4)

- Create PR to main branch
- Verify workflow runs automatically
- Check all steps pass: branch name, commit authors, pre-commit checks
- Verify workflow badge in PR
