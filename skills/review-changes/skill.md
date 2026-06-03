---
name: review-changes
description: Review modified files for best practices, duplication, and accessibility
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, Task
---

# Review Changes

Comprehensive review of all currently modified files covering best practices, code duplication detection, and accessibility compliance. Auto-detects the project's tech stack, conventions, and structure.

## Step 1: Identify Changed Files

Run these commands to gather all modified code:

```bash
# Get list of modified/new files (staged + unstaged + untracked)
git diff --name-only HEAD
git diff --cached --name-only
git status --short
```

Focus only on source files (`.js`, `.jsx`, `.ts`, `.tsx`, `.vue`, `.svelte`). Ignore config files, assets, lock files, and generated code.

## Step 2: Detect Project Context

Before reviewing, auto-detect:
- **Framework**: React, Vue, Svelte, Next.js, etc. (check `package.json`)
- **State management**: Redux, Zustand, Pinia, Context API, etc.
- **Styling approach**: CSS Modules, Tailwind, Styled Components, Emotion, SCSS
- **Component library**: Check for MUI, Ant Design, Primer, Radix, shadcn/ui, or custom libraries
- **Project structure**: Read `CLAUDE.md` or project docs if available for conventions
- **Linting/formatting**: ESLint config, Prettier config

## Step 3: Read All Changed Files

Read the full content of every modified source file identified in Step 1. You need the complete code to do a thorough review.

## Step 4: Code Quality & Best Practices Review

For each changed file, check against the project's coding standards:

### Structure & Patterns
- [ ] New code follows the project's established directory structure
- [ ] Business logic is separated from presentation (hooks, services, stores)
- [ ] Code splitting used for large pages/routes where applicable
- [ ] Feature flags used if the project has a feature flag system

### State Management Compliance
- [ ] Follows the project's state management patterns (Redux, Zustand, etc.)
- [ ] No direct state mutation
- [ ] Async operations follow the project's established patterns
- [ ] Selectors/computed values used for derived state

### Styling
- [ ] Follows the project's styling approach (no mixing paradigms)
- [ ] Theme/design tokens used instead of hardcoded colors
- [ ] Responsive design considered
- [ ] Dark mode / theming supported if the project uses it

### Code Readability
- [ ] No nested ternary operators
- [ ] No complex logic inside JSX/templates — extract to helper functions
- [ ] Meaningful variable and function names following project conventions
- [ ] Import order follows project standard

### React/Framework Best Practices
- [ ] `useEffect` has proper cleanup (event listeners, subscriptions, timers)
- [ ] `useEffect` dependency arrays are correct and complete
- [ ] `useCallback`/`useMemo` used where appropriate to prevent unnecessary re-renders
- [ ] No missing `key` props on list items
- [ ] Event handlers follow consistent naming conventions

### Error Handling
- [ ] Async operations wrapped in try-catch-finally
- [ ] Loading and error states managed properly
- [ ] API errors handled gracefully with user feedback

## Step 5: Duplicate Code Detection (CRITICAL)

This is the most important part. Search the ENTIRE codebase to find if similar code already exists:

### 5a. Component Duplication
For each new component in the changes:
- Search the project's shared/generic components directory
- Search feature-specific component directories for similar components
- Check if the project's component library already provides this component
- Check third-party UI libraries installed in `package.json`

### 5b. Hook/Composable Duplication
For each new hook or custom logic:
- Search the project's hooks/composables directory
- Check if similar logic exists in other hooks that could be extracted/shared

### 5c. Utility Duplication
For any utility functions or helpers:
- Search the project's utility/helper directories
- Check if lodash, date-fns, or other installed packages already provide this functionality

### 5d. State/Store Duplication
For any new state management code:
- Search for existing actions/slices/stores that do the same API call
- Search for existing state that already stores this data
- Check for duplicate action types or constants

### 5e. Style Duplication
For any new styled components or CSS:
- Search for existing styles with the same patterns
- Check if shared style utilities exist

**For each duplicate found, report:**
```
DUPLICATE FOUND:
  New code: [file:line] - [description]
  Existing: [file:line] - [description]
  Recommendation: Reuse existing [component/hook/utility] instead of creating new one
```

## Step 6: Accessibility Review

Launch the **a11y-checker** agent (Task tool with subagent_type "a11y-checker") to perform a full accessibility audit on the changed files. Pass it the list of modified files.

The a11y-checker will check for:
- Missing aria-labels on interactive elements
- Keyboard accessibility (tabIndex, onKeyDown handlers)
- Image alt text
- Form input labels
- Valid ARIA attributes
- Focus indicators
- Component library usage opportunities

## Step 7: Generate Report

Compile all findings into a structured report:

```markdown
# Review Changes Report

## Summary
- Files reviewed: N
- Best practice issues: N (Critical: X, Major: Y, Minor: Z)
- Duplications found: N
- Accessibility issues: N

---

## Best Practices Issues

### Critical
[issues that must be fixed before merge]

### Major
[issues that should be fixed]

### Minor
[nice-to-have improvements]

---

## Duplicate Code Found

[list each duplicate with existing location and recommendation]

---

## Accessibility Issues

[summary from a11y-checker agent]

---

## Recommendations

### Must Fix (before merge)
1. [actionable item]

### Should Fix (soon)
1. [actionable item]

### Nice to Have
1. [suggestion]
```

## Important Notes

- Do NOT auto-fix anything. Present findings and ask the user what to fix.
- Be specific with file paths and line numbers for every issue.
- For duplicates, always show both the new code AND the existing code location.
- Prioritize actionable feedback over nitpicks.
- Acknowledge good patterns and well-written code too.
- Adapt all checks to the detected project tech stack — do not assume any specific framework or library.
