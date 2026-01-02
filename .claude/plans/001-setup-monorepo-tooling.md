# Implementation Plan: Setup mise and pre-commit Framework

## Goal
Configure mise for tool version management and pre-commit framework with three
validation hooks: commit message format, branch naming, and markdown linting.

## File Structure
```
.
├── .mise.toml                    # Tool version management
├── .pre-commit-config.yaml       # Pre-commit hooks configuration
├── .markdownlint.json           # Markdown linting rules (88 char limit)
└── scripts/
    ├── validate-commit-msg      # Commit message validation
    └── check-branch-name        # Branch naming validation
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

### 5. Setup Graphite Authentication
Before submitting PRs with Graphite:
```bash
# Check if authenticated
gt auth status

# If not authenticated, login with token
gt auth --token

# Verify repository access (sync with remote)
gt sync
```

If repository access fails:
- Authorize at: https://app.graphite.dev/settings
- Sync repository at: https://app.graphite.dev/settings/synced-repos

### 6. Install and Activate
```bash
# Install all tools via mise
mise install

# Install pre-commit hooks (run before commit is created)
pre-commit install --hook-type pre-commit

# Install commit-msg hooks (run after commit message is written)
pre-commit install --hook-type commit-msg

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
