# Code Review Command

You are conducting a comprehensive code review for a GitHub Pull Request.

## Arguments

The command accepts: `$ARGUMENTS`

This can be:

- A PR number (e.g., `123`)
- A GitHub PR URL (e.g., `https://github.com/owner/repo/pull/123`)

## Step 1: Fetch PR Information

Extract the PR number from the arguments:

- If it's a URL, parse the number from the end
- If it's just a number, use it directly

Use these commands to gather PR context:

```bash
gh pr view <PR_NUMBER> --json title,body,author,headRefName,baseRefName,url,number
gh pr diff <PR_NUMBER>
```

## Step 2: Perform Code Review

Analyze the PR diff thoroughly. Focus on:

### Code Quality

- Logic errors and bugs
- Performance issues
- Security vulnerabilities
- Error handling gaps
- Race conditions or concurrency issues

### Best Practices

- Code style and consistency
- Naming conventions
- Code duplication
- Function/component complexity
- Proper abstraction levels

### Architecture & Design

- Design patterns usage
- Separation of concerns
- SOLID principles adherence
- API design quality
- State management

### Testing

- Test coverage gaps
- Edge cases not handled
- Missing test scenarios

### Documentation

- Missing or unclear comments (only where logic isn't self-evident)
- Outdated documentation
- Unclear variable/function names

### Specific Technology Concerns

Based on the file types, apply language/framework-specific best practices.

## Step 3: Present Review Comments

Format each review comment as a numbered item with:

- **File path and line number** (if applicable)
- **Severity**: Critical | High | Medium | Low
- **Category**: Bug | Security | Performance | Style | Best Practice |
  Testing | Documentation
- **Description**: Clear explanation of the issue
- **Suggestion**: Specific recommendation for improvement

Present ALL review comments to the user.

## Step 4: Filter Comments

Use the AskUserQuestion tool to ask the user which review comments
they want to keep in the final review.

Present the comments as options (multi-select) where each option shows:

- Comment number
- File and severity
- Brief description

Allow the user to select which comments are valid and should be
included in the final review.

## Step 5: Display Final Review

After filtering, display the final review in a clean format with only
the selected comments.

Format the final review as markdown suitable for GitHub, including:

- Summary statement
- Selected review comments (well-formatted)
- Overall assessment

## Step 6: Post Review to PR

Add the final review as a comment to the PR using:

```bash
gh pr review <PR_NUMBER> --comment --body "<REVIEW_MARKDOWN>"
```

Note: Properly escape the markdown content for the shell command.
Use a heredoc or temporary file if needed for complex content.

After posting, confirm to the user with the PR URL.

## Step 7: Ask About Addressing Items

Use the AskUserQuestion tool to ask the user if they want to address
the review items now.

Provide options:

- Yes, create a plan to address all items
- Yes, but let me choose which items to address
- No, I'll address them later

If the user wants to address items:

- Create a plan using the TodoWrite tool
- Break down the work by file and issue type
- Implement the fixes as requested
