# Start Issue Command

Start work on GitHub issue: **$ARGUMENTS**

Parse arguments:

- First argument: Issue ID (e.g., `42` or `#42`)
- Second argument (optional): Starting point - `main` or `stack`
  (default: `stack`)

## Workflow

### 1. Validate Starting State

**If starting from `main` worktree:**

- Run `gt sync` to ensure clean state

**If starting from `stack` (default):**

- Ask the user to confirm: "You're stacking on top of the current branch.
  Is this correct, or should we stack on a different branch?"
- Once confirmed, run `gt sync` to ensure clean state

### 2. Fetch Issue Details

Use `gh` to fetch the issue details:

```bash
gh issue view <issue-number>
```

Extract:

- Issue title
- Issue description

Generate branch name from issue type and title:

- Pattern: `{type}-{issue}-{slug}` (e.g., `feat-42-add-login`)
- Types: feat, fix, docs, style, refactor, test, chore

### 3. Create Worktree

Create a new worktree:

```bash
git worktree add -b <branch-name> ../<type>-<issue>-<slug> <parent>
```

Where parent is `main` or the current branch name.

Navigate to the new worktree:

```bash
cd ../<type>-<issue>-<slug>
```

Trust the mise configuration:

```bash
mise trust .
```

Track with Graphite:

```bash
gt track
```

### 4. Initial Commit

Create `.claude/` directory if needed:

```bash
mkdir -p .claude
```

**Write `.claude/plans/NNN-title.md`:**
Create an implementation plan (example 001-initial-setup.md)
based on the issue requirements.
Use EnterPlanMode to properly analyze and plan the work.

The plan must include a **Commits Plan** section that breaks down the
implementation into logical commits with an upfront directive:

```markdown
## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

1. [Task description]
2. [Next task description]
```

The commits must be MECE (Mutually Exclusive, Collectively Exhaustive):

- Each commit addresses distinct changes with no overlap
- All commits together deliver the complete task
- Each commit is reviewable and testable independently where possible
- Commits follow a logical sequence (dependencies before dependents)

**WHY INCREMENTAL COMMITS:** If multiple steps modify the same files, waiting
until the end makes changes indistinguishable and defeats the purpose of
logical commit separation.

**Commit and submit:**

Commit the implementation plan:

- Pattern: `docs(#{issue}): Plan {issue-title}`
- Use "docs" type (conventional commits compliant) with "Plan" prefix in description
- Example: `docs(#7): Plan React rewards app skeleton`

```bash
git add .claude/plans/NNN-title.md
git commit -m "docs(#{issue}): Plan {issue-title}"
gt submit
```

This creates the PR with the original issue context and plan visible.
