# Implementation Plan: ESLint + Prettier + Vitest Pre-commit Setup

**Issue:** #8 - Take-Home: React ESLint + Prettier + Vitest Pre-commit

## Current State

- React 19 + TypeScript app in `/web/` using Vite
- ESLint already installed with **modern flat config** (`eslint.config.js`)
- Prettier NOT installed
- Vitest NOT installed
- Pre-commit hooks exist at root but no JS/TS linting hooks
- npm scripts: `dev`, `build`, `lint`, `preview` (missing `format:check` and `test`)

## Key Decisions

1. **ESLint Config Format**: Keep flat config (`eslint.config.js`) instead
   of migrating to legacy `.eslintrc.cjs`. Flat config is modern and
   recommended by ESLint.

2. **Prettier Integration**: Add `eslint-config-prettier` to prevent rule
   conflicts

3. **Vitest Setup**: Configure with @testing-library/react for component
   testing

4. **Pre-commit Hooks**: Add separate hooks for ESLint, Prettier, and Vitest
   scoped to `/web/` directory

## Critical Files

**To Create:**

- `/web/.prettierrc` - Prettier configuration
- `/web/.prettierignore` - Files to exclude from formatting
- `/web/vitest.config.ts` - Vitest configuration for React testing
- `/web/src/App.test.tsx` - Sample test to validate setup

**To Modify:**

- `/web/package.json` - Add dependencies and npm scripts
- `/web/eslint.config.js` - Add Prettier integration
- `/.pre-commit-config.yaml` - Add ESLint, Prettier, Vitest hooks

## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

**WHY INCREMENTAL COMMITS:** If multiple steps modify the same files (like
`package.json` or `.pre-commit-config.yaml`), waiting until the end makes
changes indistinguishable and defeats the purpose of logical commit
separation.

These commits are MECE (Mutually Exclusive, Collectively Exhaustive):

- Each commit addresses distinct changes with no overlap
- All commits together deliver the complete task
- Each commit is reviewable and testable independently where possible
- Commits follow a logical sequence (dependencies before dependents)

---

### Commit 1: Add Prettier, Vitest, and testing dependencies

**Message:** `feat(#8): Add Prettier, Vitest, and testing dependencies`

**Actions:**

1. Navigate to `/web/` directory
2. Install dependencies:

   ```bash
   bun add --dev prettier eslint-config-prettier vitest \
     @testing-library/react @testing-library/jest-dom @vitest/ui jsdom
   ```

3. Verify `/web/package.json` updated with new devDependencies
4. **COMMIT IMMEDIATELY** with the message above

---

### Commit 2: Configure Prettier code formatter

**Message:** `feat(#8): Configure Prettier code formatter`

**Actions:**

1. Create `/web/.prettierrc`:

   ```json
   {
     "printWidth": 88,
     "tabWidth": 2,
     "useTabs": false,
     "semi": true,
     "singleQuote": true,
     "trailingComma": "es5",
     "bracketSpacing": true,
     "arrowParens": "always"
   }
   ```

2. Create `/web/.prettierignore`:

   ```text
   dist
   node_modules
   build
   *.local
   ```

3. Add scripts to `/web/package.json`:

   ```json
   "scripts": {
     "format": "prettier --write .",
     "format:check": "prettier --check ."
   }
   ```

4. Add Prettier pre-commit hook to `/.pre-commit-config.yaml`:

   ```yaml
     - repo: https://github.com/pre-commit/mirrors-prettier
       rev: v3.1.0
       hooks:
         - id: prettier
           files: '^web/.*\.(ts|tsx|json|css)$'
   ```

   **Note:** Using mirrors-prettier instead of local bunx hook because
   pre-commit creates isolated environments where bunx isn't available.
   This is the standard approach used by high-quality open source projects.

5. **COMMIT IMMEDIATELY** with the message above

---

### Commit 3: Format code with Prettier

**Message:** `fix(#8): Format code with Prettier`

**Actions:**

1. Navigate to `/web/` directory
2. Run: `bun run format`
3. Verify all files are formatted (check `git diff`)
4. **COMMIT IMMEDIATELY** with the message above

**Note:** Pre-commit hooks will enforce formatting on subsequent commits.

---

### Commit 4: Add Prettier-ESLint compatibility

**Message:** `feat(#8): Add Prettier-ESLint compatibility`

**Actions:**

1. Update `/web/eslint.config.js`:
   - Import `eslint-config-prettier`
   - Add as the last item in the config array to disable conflicting rules
   - Example:

     ```js
     import prettierConfig from 'eslint-config-prettier';

     export default [
       // ...existing configs
       prettierConfig, // Must be last
     ];
     ```

2. Add ESLint pre-commit hook to `/.pre-commit-config.yaml`:

   ```yaml
     - repo: https://github.com/pre-commit/mirrors-eslint
       rev: v9.17.0
       hooks:
         - id: eslint
           files: '^web/.*\.(ts|tsx)$'
           args: ['--fix']
           additional_dependencies:
             - eslint@9.39.1
             - typescript-eslint@8.46.4
             - eslint-plugin-react-hooks@7.0.1
             - eslint-plugin-react-refresh@0.4.24
             - globals@16.5.0
             - '@eslint/js@9.39.1'
   ```

3. **COMMIT IMMEDIATELY** with the message above

---

### Commit 5: Fix ESLint issues after integration (if needed)

**Message:** `fix(#8): Fix ESLint issues after integration`

**Actions:**

1. Navigate to `/web/` directory
2. Run: `bun run lint`
3. If there are issues:
   - Run: `bun run lint -- --fix` to auto-fix
   - Manually fix any remaining violations
   - Verify: `bun run lint` passes
   - **COMMIT IMMEDIATELY** with the message above
4. If no issues, **SKIP THIS COMMIT**

---

### Commit 6: Configure Vitest for React component testing

**Message:** `feat(#8): Configure Vitest for React component testing`

**Actions:**

1. Create `/web/vitest.config.ts`:

   ```ts
   import { defineConfig } from 'vitest/config';
   import react from '@vitejs/plugin-react';

   export default defineConfig({
     plugins: [react()],
     test: {
       globals: true,
       environment: 'jsdom',
       setupFiles: './src/setupTests.ts',
     },
   });
   ```

2. Create `/web/src/setupTests.ts`:

   ```ts
   import '@testing-library/jest-dom';
   ```

3. Create `/web/src/App.test.tsx`:

   ```tsx
   import { render, screen } from '@testing-library/react';
   import { describe, it, expect } from 'vitest';
   import App from './App';

   describe('App', () => {
     it('renders Rewards App heading', () => {
       render(<App />);
       expect(screen.getByText(/Rewards App/i)).toBeInTheDocument();
     });
   });
   ```

4. Add scripts to `/web/package.json`:

   ```json
   "scripts": {
     "test": "vitest",
     "test:ui": "vitest --ui"
   }
   ```

5. Add Vitest pre-commit hook to `/.pre-commit-config.yaml`:

   ```yaml
     - repo: local
       hooks:
         - id: web-vitest
           name: Vitest (web)
           entry: bash -c 'cd web && bun run test -- --run'
           language: system
           files: '^web/.*\.(ts|tsx)$'
           pass_filenames: false
   ```

   **Note:** Vitest hook uses bash + bun since vitest requires project
   dependencies. No official pre-commit mirror exists for vitest.

6. Verify tests pass: `bun run test -- --run`
7. **COMMIT IMMEDIATELY** with the message above

---

### Commit 7: Add frontend CI checks to GitHub Actions

**Message:** `feat(#8): Add frontend CI checks to GitHub Actions`

**Actions:**

1. Update `/.github/workflows/ci.yml` to add frontend CI jobs:
   - Add job for ESLint
   - Add job for TypeScript type checking
   - Add job for Vitest tests

2. Jobs should:
   - Run on pull requests
   - Set up Bun
   - Install dependencies in `/web/`
   - Run the respective check commands

3. Verify the workflow structure:
   - ESLint: `bun run lint`
   - TypeScript: `bun run type-check` (may need to add this script)
   - Vitest: `bun run test -- --run`

4. **COMMIT IMMEDIATELY** with the message above

## Implementation Notes

- Keep flat ESLint config (modern standard)
- Prettier config uses common defaults (can adjust based on team preferences)
- Vitest runs in watch mode by default (`bun run test`), use `--run` in
  pre-commit
- Pre-commit hooks scoped to `^web/` files only to avoid affecting API code
- Consider making Vitest pre-commit hook optional if tests become slow (can
  skip with `--no-verify`)

## Acceptance Criteria

✓ ESLint configured (already done with flat config)
✓ Prettier configured
✓ Vitest configured
✓ Initial formatting/linting offenses fixed
✓ ESLint pre-commit hook added
✓ Prettier pre-commit hook added
✓ Vitest pre-commit hook added
✓ `bun run lint` passes
✓ `bun run format:check` passes
✓ `bun run test` passes
✓ `pre-commit run` runs all three hooks on web/ files
