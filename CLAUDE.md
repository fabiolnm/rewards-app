Uses graphite for branch management.

Commands:

- Use: gt sync, gt restack, gt submit
- Don't use: gt repo sync (deprecated), git push (use gt submit)

Editing commits:

- **Latest commit**: Use `git commit --amend --no-edit` (or with `-m` for new message)
- **Older commits**: Use fixup workflow (see below)

Fixup workflow:

1. Target commit: chore(#123): Example
2. Edit commit: fixup! chore(#123): Example
3. Run git rebase -i --autosquash to merge fixup into target
