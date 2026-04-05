---
name: review-pr
description: Review a frontend PR by URL. Checks functionality, hardcoded colors, lt-components usage, security, and code quality. Takes a GitHub PR URL as input.
allowed-tools: Bash, Read, Grep, Glob, Task, WebFetch
---

# Review PR

Review a frontend pull request from its GitHub URL. Runs parallel checks for code quality, hardcoded colors, component library compliance, and security.

## Input

The user provides a GitHub PR URL:
```
/review-pr https://github.com/org/repo/pull/123
```

## Step 1: Fetch PR Details

Extract the PR number and repo from the URL, then fetch all context:

```bash
# Parse owner/repo and PR number from the URL
# URL format: https://github.com/{owner}/{repo}/pull/{number}

# Fetch PR metadata
gh pr view {number} --repo {owner}/{repo} --json title,body,baseRefName,headRefName,files,additions,deletions,changedFiles

# Get the list of changed files with diffs
gh pr diff {number} --repo {owner}/{repo}

# Get the list of changed file paths only
gh pr diff {number} --repo {owner}/{repo} --name-only
```

If `gh` is not authenticated or the command fails, inform the user and stop.

## Step 2: Get Full File Context

You need full file contents (not just diffs) to properly review. Use `gh` to fetch file contents **without cloning or checking out** — don't mess with the user's local repo.

```bash
# Get the PR's head branch and SHA
gh pr view {number} --repo {owner}/{repo} --json headRefOid,headRefName,headRepository

# For each changed file, fetch the full content from the PR's head branch
gh api repos/{owner}/{repo}/contents/{file_path}?ref={head_branch} --jq '.content' | base64 -d
```

If the repo is already the current directory AND on a different branch, you can alternatively:
```bash
# Fetch without checkout — just get the content
git fetch origin pull/{number}/head:pr-{number} --no-checkout
git show pr-{number}:{file_path}
```

**Never switch the user's current branch.** Always use `gh api` or `git show` to read files from the PR branch.

## Step 3: Detect Project Context

Before reviewing, auto-detect:
- **Framework**: React, Vue, Next.js, etc. (from `package.json`)
- **Component library**: Check if `@lambdatestincprivate/lt-components` or similar is in `package.json` dependencies
- **Styling approach**: Tailwind, CSS Modules, Styled Components, SCSS, CSS vars
- **Theme system**: Look for Tailwind config, theme.js, CSS variables file, SCSS variables, design tokens
- **State management**: Redux, Zustand, Context API, etc.

Build a **theme token inventory** for the hardcoded color check:
```bash
# Check for Tailwind config
cat tailwind.config.js 2>/dev/null || cat tailwind.config.ts 2>/dev/null

# Check for CSS variables / theme files
grep -r "var(--" src/ --include="*.css" --include="*.scss" -l
grep -r "colors" src/theme* src/styles/theme* 2>/dev/null

# Check for SCSS variables
grep -r "^\$" src/ --include="*.scss" -l
```

## Step 4: Read All Changed Files (Full Content)

Read the **complete content** of every changed source file (`.js`, `.jsx`, `.ts`, `.tsx`, `.vue`, `.css`, `.scss`). You need full file context, not just the diff.

Skip: lock files, `.map` files, build output, binary files, config-only changes.

## Step 5: Run Parallel Reviews

Launch these in parallel using the Task tool:

### 5a. Code Quality Review — `code-reviewer` agent

Spawn the **code-reviewer** agent (subagent_type: `code-reviewer`) with:
- The list of changed files
- The detected project context (framework, state management, styling)
- The full diff

The code-reviewer will check: functionality correctness, React best practices, state management patterns, error handling, performance, and code structure.

### 5b. Security Audit — `/security-audit` skill

Invoke the **security-audit** skill to scan all changed files for:
- XSS, injection, hardcoded secrets
- Insecure storage, CORS, auth issues
- Frontend-specific: open redirects, postMessage, clickjacking

### 5c. Hardcoded Colors Check (you do this yourself)

Scan every changed file for hardcoded color values. **This is a LambdaTest-specific rule: all colors MUST come from the theme system, never hardcoded.**

Search patterns in changed files:
```
# Hex colors
/#[0-9a-fA-F]{3,8}\b/

# RGB/RGBA
/rgb\(|rgba\(/

# HSL/HSLA
/hsl\(|hsla\(/

# Named CSS colors used as values (not in comments/strings)
/color:\s*(red|blue|green|white|black|gray|grey|orange|yellow|purple|pink)/

# Inline style color objects (React)
/color:\s*['"][#a-zA-Z]/
/backgroundColor:\s*['"][#a-zA-Z]/
/borderColor:\s*['"][#a-zA-Z]/
```

**Exceptions (NOT violations):**
- Colors inside theme/token definition files (these ARE the source of truth)
- Colors in comments
- Colors in test files
- `transparent`, `inherit`, `currentColor`, `none`
- Colors in SVG files that are part of icons/assets (not components)

For each hardcoded color found, report:
```
HARDCODED COLOR:
  File: src/components/Button.tsx:45
  Code: `backgroundColor: '#FF5722'`
  Should be: `backgroundColor: theme.colors.primary` or `bg-primary` (Tailwind)
  Closest theme token: [suggest the closest match from theme inventory]
```

### 5d. lt-components Compliance Check (you do this yourself)

**Rule: If a component exists in `@lambdatestincprivate/lt-components`, it MUST be imported from there. No custom re-implementations.**

Step 1 — Build lt-components inventory (no `node_modules` available in PR review):

```bash
# METHOD 1: Scan the entire repo for existing lt-components imports
# This tells you exactly which components the project already uses from lt-components
grep -r "from '@lambdatestincprivate/lt-components" src/ --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" -h | \
  grep -oP "import\s*\{([^}]+)\}" | \
  sed 's/import\s*{//;s/}//;s/,/\n/g' | \
  tr -d ' ' | sort -u

# METHOD 2: Check which version the project uses
grep -A2 '"@lambdatestincprivate/lt-components"' package.json
```

**METHOD 3 (most complete): Fetch the Storybook sidebar to get ALL available components.**
The lt-components Storybook is at: `https://ui-components-playground.lambdatestinternal.com/`

Fetch the Storybook stories index to discover every component:
```bash
# Storybook v7+ exposes a stories.json or index.json
curl -s "https://ui-components-playground.lambdatestinternal.com/stories.json" 2>/dev/null || \
curl -s "https://ui-components-playground.lambdatestinternal.com/index.json" 2>/dev/null
```

If the JSON fetch fails, use WebFetch to load the Storybook page and extract component names from the sidebar navigation.

**Priority order:**
1. Storybook (complete list of all available components)
2. Repo grep (confirmed imports the project already uses)
3. Fallback baseline list (below)

**Fallback baseline** (use only if Storybook and grep both fail):
`Button`, `Modal`, `Dialog`, `Input`, `Select`, `Dropdown`, `Tooltip`, `Table`, `Badge`, `Avatar`, `Checkbox`, `Radio`, `Switch`, `Tabs`, `Toast`, `Alert`, `Card`, `Spinner`, `Loader`, `Popover`, `Tag`, `IconButton`, `TextArea`, `Header`, `Sidebar`, `Pagination`, `Breadcrumb`, `Menu`, `Drawer`

**Important:** The grep of existing imports is the source of truth. The list above is a fallback. If a component name appears in the project's existing lt-components imports, it's confirmed available.

Step 2 — For each changed file, check:
- Are there any custom components being created that already exist in lt-components?
- Are there imports from other sources for components available in lt-components?
- Look for common component names: `Button`, `Modal`, `Dialog`, `Input`, `Select`, `Dropdown`, `Tooltip`, `Table`, `Badge`, `Avatar`, `Checkbox`, `Radio`, `Switch`, `Tabs`, `Toast`, `Alert`, `Card`, `Spinner`, `Loader`, etc.

For each violation found:
```
LT-COMPONENTS VIOLATION:
  File: src/components/CustomModal.tsx:1
  Issue: Custom Modal component created, but Modal exists in lt-components
  Current: `import Modal from './Modal'` (custom)
  Should be: `import { Modal } from '@lambdatestincprivate/lt-components'`
```

Also check for components imported from **other third-party libraries** when lt-components has the same component:
```
LT-COMPONENTS VIOLATION:
  File: src/pages/Settings.tsx:3
  Issue: Button imported from @mui/material, but Button exists in lt-components
  Current: `import { Button } from '@mui/material'`
  Should be: `import { Button } from '@lambdatestincprivate/lt-components'`
```

## Step 6: Compile Report

After all parallel checks complete, compile a unified report:

```markdown
# PR Review: #{number} — {title}

**Repo:** {owner}/{repo}
**Branch:** {head} → {base}
**Changed Files:** {count} | **+{additions}** / **-{deletions}**
**Reviewed by:** senior-frontend-developer agent

---

## Verdict: APPROVE / REQUEST CHANGES / COMMENT

**Criteria:**
- Any Critical issue → REQUEST CHANGES
- Any hardcoded color → REQUEST CHANGES
- Any lt-components violation → REQUEST CHANGES
- Only Medium/Low issues → COMMENT (approve with suggestions)
- Clean → APPROVE

---

## Hardcoded Colors
{count} violations found

| File | Line | Hardcoded Value | Suggested Theme Token |
|------|------|-----------------|-----------------------|
| ... | ... | ... | ... |

---

## lt-components Compliance
{count} violations found

| File | Custom Component | lt-components Equivalent | Action |
|------|------------------|--------------------------|--------|
| ... | ... | ... | Import from lt-components |

---

## Code Quality Issues
(from code-reviewer agent)

### Critical
...

### Major
...

### Minor
...

---

## Security Issues
(from /security-audit)

### Critical / High
...

### Medium / Low
...

---

## What's Good
- [acknowledge good patterns, clean code, proper testing]

---

## Action Items (Prioritized)

### Must Fix (blocking)
1. [ ] ...

### Should Fix (before merge)
1. [ ] ...

### Nice to Have
1. [ ] ...
```

## Step 7: Cleanup

After review is complete:
```bash
# Only needed if you used git fetch method
git branch -D pr-{number} 2>/dev/null
```

No cleanup needed if you used the `gh api` method (recommended) — it doesn't create any local state.

## Rules

- **Never auto-fix or push changes.** This is a review skill, not a fix skill.
- **Always provide file paths and line numbers** for every finding.
- **Be constructive** — acknowledge good patterns alongside issues.
- **Hardcoded colors and lt-components violations are always REQUEST CHANGES** — these are non-negotiable LambdaTest standards.
- **For the code-reviewer and security-audit sub-agents**, pass only the changed file paths and relevant context — not your entire conversation.
- If the PR is too large (>50 files), warn the user and offer to review in batches or focus on specific directories.
- If `gh` CLI is not available, instruct the user to install and authenticate: `brew install gh && gh auth login`.
