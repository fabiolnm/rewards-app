# Review Commit History Command

You are analyzing commit history to detect issues, extract lessons learned,
and update implementation plans.

## Arguments

The command accepts: `$ARGUMENTS`

This can be:

- Nothing (analyze current branch against main/base branch)
- A PR number (e.g., `123`)
- A GitHub PR URL (e.g., `https://github.com/owner/repo/pull/123`)
- A branch name (e.g., `feat-11-deploy-aws-ecs`)
- A commit range (e.g., `main..HEAD` or `abc123..def456`)

## Analysis Process

This command follows these steps:

1. **Determine Scope and Fetch Data** - Parse arguments, get commits,
   find plan file
2. **Analyze Commits and Detect Issues** - Find multiple fixes, scope drift,
   missing refs; extract lessons
3. **Present Findings and Update Plan** - Show analysis, update plan file,
   suggest rebase strategy

## Step 1: Determine Scope and Fetch Commit Data

### 1.1 Parse Arguments

Parse `$ARGUMENTS` to determine what to analyze:

**If no arguments provided:**

```bash
# Use current branch
headRefName=$(git branch --show-current)

# Get main branch name
baseRefName=$(git symbolic-ref refs/remotes/origin/HEAD | \
  sed 's@^refs/remotes/origin/@@')
```

**If PR number or URL provided:**

```bash
# Extract PR number from URL if needed
pr_number=$(echo "$ARGUMENTS" | grep -oE '[0-9]+$')

# Fetch PR data
gh pr view $pr_number --json headRefName,baseRefName,title,number
```

Extract `headRefName` and `baseRefName` from the JSON output.

**If branch name provided:**

```bash
headRefName="$ARGUMENTS"
baseRefName="main"  # or detect main branch
```

**If commit range provided (contains '..'):**

```bash
# Parse range like "main..HEAD" or "abc123..def456"
baseRefName=$(echo "$ARGUMENTS" | cut -d'.' -f1)
headRefName=$(echo "$ARGUMENTS" | cut -d'.' -f3)
```

### 1.2 Fetch Commit Data

```bash
# Get all commits with full details (pipe-delimited)
git log --format="%H|%an|%ae|%ai|%s|%b" ${baseRefName}..${headRefName}

# Get commit count
commit_count=$(git rev-list --count ${baseRefName}..${headRefName})
```

Parse each commit line to extract:

- SHA (column 1)
- Author name (column 2)
- Author email (column 3)
- Date (column 4)
- Subject (column 5)
- Body (column 6+, may span multiple lines)

From subject, extract using regex
`^(fixup!|squash!)?([a-z][a-z0-9_-]*)\(#([0-9]+)\): (.+)$`:

- Prefix (fixup!/squash! or empty)
- Type (feat, fix, chore, docs, etc.)
- Issue number
- Description

**Handle edge case:** If single commit or no commits, skip analysis:

```python
if commit_count <= 1:
    print("Single commit or no commits to analyze. Skipping.")
    exit
```

### 1.3 Find and Parse Plan File

Extract issue number from branch name or first commit:

```bash
# Try branch name first
issue_number=$(echo "${headRefName}" | grep -oE '^[a-z]+-([0-9]+)-' | grep -oE '[0-9]+')

# If not found, try first commit subject
if [ -z "$issue_number" ]; then
    issue_number=$(git log --format="%s" ${baseRefName}..${headRefName} | \
      tail -n 1 | grep -oE '#([0-9]+)' | grep -oE '[0-9]+')
fi

# Find plan file
plan_file=$(find .claude/plans -name "${issue_number}-*.md" 2>/dev/null | head -n 1)
```

If plan file exists, extract "Commits Plan" section:

```bash
if [ -f "$plan_file" ]; then
    # Extract section between "## Commits Plan" and next "##"
    planned_commits=$(sed -n '/^## Commits Plan/,/^## /p' "$plan_file" | head -n -1)

    # Count planned commits (numbered or bulleted items)
    planned_count=$(echo "$planned_commits" | grep -cE '^(### |[0-9]+\.) ')
fi
```

If plan file not found:

```text
print("No plan file found for issue #${issue_number}. Skipping plan comparison.")
print("Will still analyze commits for common issues.")
```

## Step 2: Analyze Commits and Detect Issues

### 2.1 Detect Common Issues

Run heuristics on the parsed commits:

**a) Multiple fix commits for same issue:**

```python
fix_commits = filter(commits, type="fix", issue=issue_number)

if len(fix_commits) > 1:
    issues.append({
        "type": "multiple_fixes",
        "severity": "high",
        "count": len(fix_commits),
        "commits": fix_commits,
        "suggestion": (f"Found {len(fix_commits)} fix commits. Consider "
                       f"squashing into related feat commits using fixup "
                       f"workflow.")
    })
```

**b) Iterative debugging commits:**

```python
debug_keywords = ["fix", "debug", "diagnostic", "troubleshoot"]

for commit in commits:
    if (commit.type in ["fix", "chore"] and
        any(kw in commit.description.lower() for kw in debug_keywords)):
        # This is a debugging/fix commit
        # Could suggest squashing into original feat commit
        issues.append({
            "type": "debugging",
            "commit": commit,
            "suggestion": ("Consider squashing this into the original "
                           "implementation commit.")
        })
```

**c) Scope drift (if plan file exists):**

```python
if plan_file_exists:
    for commit in commits:
        if commit.type in ["feat", "chore"]:
            # Fuzzy match against planned commits
            matched = fuzzy_match(commit.description, planned_commits, threshold=0.7)

            if not matched:
                issues.append({
                    "type": "scope_drift",
                    "severity": "medium",
                    "commit": commit,
                    "suggestion": "Not in original plan. Update plan file to document."
                })
```

**d) Missing issue references:**

```python
for commit in commits:
    # Skip special commits
    if commit.subject.startswith(('Merge', 'Revert', 'fixup!', 'squash!')):
        continue

    if not commit.issue_number:
        issues.append({
            "type": "missing_ref",
            "severity": "low",
            "commit": commit,
            "suggestion": "Add issue reference to subject line."
        })
```

### 2.2 Extract Lessons Learned

**Technical Challenges (from fix commits):**

```python
technical_challenges = []

for commit in commits:
    if commit.type == "fix" and commit.date > first_feat_commit.date:
        # Extract title from subject (after "fix(#N): ")
        title = commit.description

        # Extract first paragraph from body
        body_lines = commit.body.split('\n')
        description = next((line for line in body_lines if line.strip()), "")

        # Extract bullet points if present
        bullets = [line for line in body_lines if line.strip().startswith('-')]

        lesson = {
            "title": title,
            "description": description,
            "bullets": bullets
        }
        technical_challenges.append(lesson)
```

**Process Improvements (from chore/docs commits not in plan):**

```python
process_improvements = []

for commit in commits:
    if commit.type in ["chore", "docs"]:
        # Check if in original plan (if plan exists)
        if plan_file_exists:
            in_plan = fuzzy_match(commit.description, planned_commits, threshold=0.7)
            if in_plan:
                continue  # Skip if it was planned

        title = commit.description
        body_lines = commit.body.split('\n')
        description = next((line for line in body_lines if line.strip()), "")

        lesson = {
            "title": title,
            "description": description
        }
        process_improvements.append(lesson)
```

### 2.3 Generate Analysis Report

Create structured markdown summary combining all findings.

## Step 3: Present Findings and Update Plan File

### 3.1 Present Analysis to User

Display the analysis report in conversational markdown:

```markdown
I've analyzed the commit history for [branch/PR].

## Commit Summary
- **Branch:** ${headRefName}
- **Base:** ${baseRefName}
- **Total commits:** ${commit_count}
[If plan file exists:]
- **Planned commits:** ${planned_count}
- **Deviation:** +/- N commits (X% increase/decrease)

[If commits deviate significantly:]
The additional commits consist of fixes and process improvements discovered
during implementation.

## Key Findings

[For each issue category with findings:]

### N. [Issue Category] ([Priority])

[Description of issues found]

**Commits:**
- `[commit SHA short]` [commit subject]
- ...

**Recommendation:** [Specific suggestion]

---

[If lessons learned extracted:]

## Lessons Learned

### Technical Challenges

[For each technical challenge:]
N. **[Title]:** [Description]
   [Bullet points if any]

### Process Improvements

[For each process improvement:]
N. **[Title]:** [Description]

---

Would you like me to:
1. Update the plan file with these lessons learned? [If plan file exists]
2. Generate a rebase strategy to clean up the commit history? [If issues found]
```

### 3.2 Ask User for Confirmation

If plan file exists, use AskUserQuestion tool:

```text
Question: "Would you like me to update the plan file with these lessons learned?"
Options:
- Yes, update the plan file (Recommended)
- No, skip this step
- Let me review the lessons first
```

### 3.3 Update Plan File

If user selects "Yes, update the plan file":

**Check if "Lessons Learned" section exists:**

```bash
has_lessons=$(grep -q "^## Lessons Learned" "$plan_file" && echo "yes" || echo "no")
```

**If section doesn't exist, append at end:**

```bash
cat >> "$plan_file" << 'EOF'

## Lessons Learned (Post-Implementation)

### Technical Challenges

[formatted technical challenges]

### Process Improvements

[formatted process improvements]
EOF
```

Format lessons as markdown:

```text
N. **[Title]:** [Description]
   - [Bullet point 1]
   - [Bullet point 2]
```

**If section exists, merge intelligently:**

- Read existing lessons
- Compare titles (case-insensitive)
- Only append lessons with unique titles
- Preserve existing formatting

**Commit the plan file update:**

```bash
git add "$plan_file"
git commit -m "docs(#${issue_number}): Update plan with lessons learned

Post-implementation analysis identified technical challenges and process
improvements. Updated plan file to reflect actual implementation scope.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

Confirm to user:

```text
✓ Plan file updated: ${plan_file}
✓ Changes committed
```

### 3.4 Optionally Present Rebase Strategy

If issues detected (multiple fixes, debugging commits), use AskUserQuestion:

```text
Question: "Would you like help creating a rebase plan to clean up the commit history?"
Options:
- Yes, show me the rebase commands
- No, the commit history is fine as-is
```

If user selects "Yes":

Generate rebase strategy using **fixup workflow from CLAUDE.md**:

```markdown
## Rebase Strategy Using Fixup Workflow

Based on the analysis, here's how to clean up the commit history using the
**fixup workflow from CLAUDE.md**.

### Fixup Workflow Reminder

1. Create fixup commit: `git commit -m "fixup! <target commit message>"`
2. Run autosquash rebase: `git rebase -i --autosquash ${baseRefName}`
3. Git automatically marks fixup commits to squash into target commits

### Recommended Squashes

[For each fix commit that should be squashed:]

**Fix #N: [Title]** → Squash into `[target feat commit]`

[Explanation of why this fix belongs in that feat commit]

```bash
# Map the fix to its target
# Target: [target commit subject]
# Fix: [fix commit subject]
```

### Step-by-Step Instructions

#### Option A: Using fixup commits (Recommended from CLAUDE.md)

If you haven't already committed the fixes, you would create them like this:

```bash
# 1. Create fixup commits for each fix
[For each fix→feat mapping:]
git commit -m "fixup! [target feat commit subject]"

# 2. Run autosquash rebase
git rebase -i --autosquash ${baseRefName}

# 3. Git will automatically mark fixup commits to squash
# The rebase editor will show (no editing needed):
[Show example rebase todo list with fixup commits auto-marked]

# 4. Save and exit - git does the squashing automatically

# 5. Force push (after verifying)
gt submit --force
```

#### Option B: Manual interactive rebase

If the fix commits already exist (not using fixup! prefix), you can still
squash manually:

```bash
git rebase -i ${baseRefName}

# In the editor, move fix commits below their targets and change 'pick' to 'fixup':
[Show example with specific commits from the analysis]
```

### Result

**Before:** ${commit_count} commits
**After:** [calculated new count] commits
([N] fix commits squashed into their related feat commits)

The commit history will now tell a clearer story where each feature commit
is complete and correct, rather than having separate "oops, forgot this" fix
commits.

**Important:** Display the instructions but DO NOT execute the rebase automatically.

## Error Handling

Throughout the command, handle errors gracefully:

### No Plan File

```python
if not plan_file_exists:
    print(f"No plan file found for issue #{issue_number}.")
    print("Skipping plan comparison. Will still analyze commits for common issues.")
    # Continue with commit analysis
```

### Git Commands Fail

```python
try:
    result = run_git_command(...)
except GitError as e:
    print(f"Git command failed: {e}")
    print("Unable to complete commit analysis.")
    exit
```

### No Issue Number Found

```python
if not issue_number:
    print("Could not extract issue number from branch name or commits.")
    print("Skipping plan file operations. Continuing with commit analysis only.")
    # Continue without plan file features
```

### Empty Commit Range

```python
if commit_count == 0:
    print("No commits found in the specified range.")
    exit
```

## Implementation Notes

### Commit Message Parsing

Use regex from `scripts/validate-commit-msg`:

```regex
^(fixup!|squash!)?([a-z][a-z0-9_-]*)\(#([0-9]+)\): (.+)$
```

Capture groups:

1. Prefix (fixup!/squash! or empty)
2. Type (feat, fix, chore, docs, style, test, etc.)
3. Issue number
4. Description

### Fuzzy Matching for Scope Drift

Compare commit description against planned item descriptions:

```python
def fuzzy_match(text1, text2, threshold=0.7):
    # Extract words (lowercase, remove common words)
    stop_words = ["add", "the", "a", "to", "for", "and", "with", "in", "on"]

    words1 = set(w.lower() for w in text1.split() if w.lower() not in stop_words)
    words2 = set(w.lower() for w in text2.split() if w.lower() not in stop_words)

    # Calculate Jaccard similarity
    intersection = len(words1 & words2)
    union = len(words1 | words2)

    similarity = intersection / union if union > 0 else 0

    return similarity >= threshold
```

### Lesson Formatting

Format lessons consistently:

```markdown
1. **[Title]:** [Description paragraph]
   - [Bullet point 1 if exists]
   - [Bullet point 2 if exists]
```

Ensure consistent numbering and indentation.

## Summary

This command provides automated commit history analysis to:

- Detect common issues (multiple fixes, scope drift, missing refs)
- Extract lessons learned from fix and chore commits
- Update plan files with post-implementation insights
- Suggest rebase strategies using fixup workflow from CLAUDE.md

It works standalone or can be invoked at the end of code review to complete
the PR analysis workflow.
