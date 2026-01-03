# Issue #7: React + TypeScript Skeleton

## Overview

Set up Vite + React + TypeScript in `web/` directory with basic App
component displaying "Rewards App" heading.

## Deliverables

- `web/` directory with Vite + React + TypeScript
- No .jsx files (only .tsx)
- Basic App.tsx with "Rewards App" heading
- `bun run dev` starts dev server
- `bun run build` succeeds
- TypeScript compiles with no errors

## Implementation Steps

### 1. Add Bun to mise tooling

Update `.mise.toml` to include Bun version for consistent dev environment.

### 2. Scaffold Vite + React + TypeScript

Run: `bun create vite web --template react-ts`

Creates:

- `web/package.json` with dependencies
- `web/tsconfig.json` and Vite config
- `web/src/` with App.tsx, main.tsx
- `web/public/` with assets

### 3. Clean up scaffold

Remove unused demo files:

- Delete `src/App.css`
- Delete `public/vite.svg`
- Update `src/main.tsx` to remove CSS import

### 4. Implement basic App component

Replace demo App.tsx with:

```tsx
export default function App() {
  return <h1>Rewards App</h1>;
}
```

### 5. Verify build and dev server

- Run `bun install` in web/
- Run `bun run dev` - should start on localhost:5173
- Run `bun run build` - should create dist/ without errors
- Verify TypeScript compiles cleanly

## Commits Plan

**IMPORTANT: Create commits immediately after completing each step below.
Do NOT wait until all work is done.**

**WHY INCREMENTAL COMMITS:** If multiple steps modify the same files, waiting
until the end makes changes indistinguishable and defeats the purpose of
logical commit separation.

1. **Add Bun to mise tooling**
   - **Files:** `.mise.toml`
   - **What:** Add Bun version specification
   - **Test:** `mise install && bun --version`
   - **Commit:** `feat(#7): Add Bun to mise tooling`

2. **Scaffold Vite + React + TypeScript project**
   - **Files:** Entire `web/` directory
   - **What:** Run `bun create vite web --template react-ts`
   - **Test:** `cd web && bun install` succeeds
   - **Commit:** `feat(#7): Scaffold Vite + React + TypeScript project`

3. **Clean up scaffold and implement App component**
   - **Files:** Delete: `web/src/App.css`, `web/public/vite.svg`; Modify:
     `web/src/main.tsx`, `web/src/App.tsx`
   - **What:** Remove unused demo files and create basic App component with
     "Rewards App" heading
   - **Test:** `bun run dev` shows heading, `bun run build` succeeds
   - **Commit:** `feat(#7): Clean up scaffold and implement App component`

## Critical Files

- `.mise.toml` - Add Bun
- `web/package.json` - Created by Vite scaffold
- `web/bun.lockb` - Bun lockfile
- `web/src/App.tsx` - Main component
- `web/src/main.tsx` - Entry point
- `web/vite.config.ts` - Vite configuration

## Out of Scope

- ESLint + Prettier + Vitest hooks (issue #8)
- Docker setup for web
- API integration
