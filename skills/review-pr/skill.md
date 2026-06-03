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
- **Is this the lt-components repo itself?** (Check `package.json` `name` field) — if yes, enable lt-components-authoring checks in Step 5f.

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

### 5e. Common Frontend Anti-Patterns Check (you do this yourself)

Scan all changed files for these frequently missed patterns. These are real bugs and code quality issues found in production PRs.

#### Rendering & Performance

1. **Pure functions defined inside components/hooks that don't use closures**
   - Functions that only use their own parameters should be at module level or in a util file
   - They get recreated on every render/recompute unnecessarily
   ```
   // BAD: inside component
   const addToMap = (map, key) => { map[key] = true; };
   
   // GOOD: module level or util file
   const addToMap = (map, key) => { map[key] = true; };
   const MyComponent = () => { ... };
   ```

2. **Functions defined inside useEffect that don't need closure variables**
   - Pure helper functions inside useEffect should be moved outside
   - Only keep functions inside useEffect if they read state/refs from the closure

3. **Missing or stale useEffect dependency arrays**
   - Effect reads variables (state, props, derived values) but doesn't list them in deps
   - Causes stale closures when values change without re-running the effect
   ```
   // BAD: reads testId but not in deps
   useEffect(() => {
     if (sseTestId === testId) { ... }
   }, [sseEventData]);
   
   // GOOD
   useEffect(() => {
     if (sseTestId === testId) { ... }
   }, [sseEventData, testId]);
   ```

4. **Unmemoized derived values returning new references every render**
   - Computed objects/arrays/styles returned from helpers that get spread into child props
   - New reference → downstream memoized children re-render unnecessarily
   ```
   // BAD: new object every render, breaks sx reference equality
   const tokenStyles = getTokenStyles(tokenColor, fillColor);
   return <Child sx={{ ...tokenStyles }} />;
   
   // GOOD
   const tokenStyles = useMemo(
     () => getTokenStyles(tokenColor, fillColor),
     [tokenColor, fillColor]
   );
   ```

#### Data Integrity

5. **Stale data not cleared on state transitions**
   - When toggling between states (hide/restore, enable/disable), related fields must be reset
   - e.g., clearing a `reason` field when restoring an issue that was hidden with a reason
   ```
   // BAD: reason persists from previous hide
   return { ...issue, hidden: false };
   
   // GOOD: explicitly clear stale fields
   return { ...issue, hidden: false, reason: null };
   ```

6. **Scope escalation bugs in hierarchical data**
   - When UI allows changing scope (e.g., single item -> group -> all), associated data (IDs, counts) must be recomputed
   - Common bug: modal opens with 1 item's data, user selects broader scope, but action still uses original 1 item
   ```
   // BAD: always uses original IDs regardless of scope change
   return originalIssueIds;
   
   // GOOD: recompute IDs based on selected scope
   if (selectedLevel === 'group') {
     return group.items.map(i => i.id);
   }
   return originalIssueIds;
   ```

7. **Inconsistent counts between views and exports (PDF/CSV/JSON)**
   - Dashboard may recompute counts from filtered Redux state
   - Exports may use a different data source or miss filters
   - Always verify that export functions apply the same filters as the UI

8. **`undefined` keys in object accumulation**
   - When building maps/objects from nullable properties, guard against undefined keys
   - `obj[undefined] = true` silently adds an `"undefined"` key, inflating counts
   ```
   // BAD: creates obj["undefined"] when tagName is null
   let tagName = issue?.htmlTagName?.toLowerCase();
   uniqueTags[tagName] = true;
   
   // GOOD
   let tagName = issue?.htmlTagName?.toLowerCase();
   if (tagName) { uniqueTags[tagName] = true; }
   ```

#### Code Hygiene

9. **Hardcoded string literals repeated across files**
   - Repeated strings like `'url'`, `'rule'`, `'element'` used for comparisons should be enums/constants
   - Especially when the same strings appear in 3+ files
   ```
   // BAD: scattered across files
   if (level === 'elementGroup') { ... }
   
   // GOOD: centralized enum
   export const Level = { ELEMENT_GROUP: 'elementGroup' };
   if (level === Level.ELEMENT_GROUP) { ... }
   ```

10. **`includes()` used for prefix matching instead of `startsWith()`**
    - `includes()` matches anywhere in the string, causing false positives
    - When checking if a string begins with a prefix, always use `startsWith()`
    ```
    // BAD: "MANUAL_AUT_123".includes("AUT") === true (false positive)
    if (testId.includes(PREFIX.AUTOMATION)) { ... }
    
    // GOOD
    if (testId.startsWith(PREFIX.AUTOMATION)) { ... }
    ```

11. **Duplicate DOM `id` attributes inside `.map()` loops**
    - `id` must be unique in the document; duplicates break `getElementById`, a11y tools, and CSS `#` selectors
    - Use `className` for styling/querying multiple elements, or make IDs unique per iteration

12. **Missing braces on single-line if/else**
    - Can cause bugs when someone adds a second line expecting it to be inside the condition
    - Project convention: always use `{}` braces

13. **Inconsistent optional chaining**
    - If one branch uses `obj?.method()`, all branches accessing the same object should
    - Mixed usage suggests a missed null-safety check
    ```
    // BAD: inconsistent
    if (testId?.startsWith(A) || testId.startsWith(B)) { ... }
    
    // GOOD
    if (testId?.startsWith(A) || testId?.startsWith(B)) { ... }
    ```

14. **Missing default parameter values on utility functions**
    - Functions that access properties on parameters should have defaults to prevent crashes
    ```
    // BAD: crashes if called with undefined
    const compare = (a, b) => a.level === b.level;
    
    // GOOD
    const compare = (a = {}, b = {}) => a?.level === b?.level;
    ```

15. **Reusable component/hook extraction opportunities**
    - Two or more components with identical state logic -> extract a custom hook
    - Two or more components with identical UI patterns -> extract a shared component
    - Only flag when the duplication is substantial (not just 2-3 similar lines)

For each anti-pattern found, report:
```
ANTI-PATTERN: {pattern name}
  File: src/components/MyComponent.tsx:45
  Issue: {description}
  Fix: {suggested fix}
  Severity: Critical | Major | Minor
```

**Severity guide:**
- **Critical**: Data integrity bugs (items 5-8) — wrong data shown/sent to backend
- **Major**: Performance/correctness issues (items 1-4), missing enums used in 3+ files (item 9)
- **Minor**: Code hygiene (items 10-15) — style and maintainability

### 5f. LT-Components Authoring Patterns (you do this yourself)

**When to run:** Only when the PR is authoring/modifying code INSIDE `lt-components` itself (i.e., the repo being reviewed is the lt-components library, not a consumer). Detected in Step 3.

These are patterns learned from real PR review comments on lt-components. Each is a concrete bug or quality issue that reviewers consistently flag.

#### CSS Correctness

1. **Malformed CSS declarations (missing colons, mistyped properties)**
   - Styled-components / template literal CSS: a declaration like `padding 2px 4px;` (missing colon) is **silently ignored** by the browser, not a syntax error.
   - Scan for `^\s*(padding|margin|border|display|color|background|font|flex|grid|width|height|top|left|right|bottom|position|z-index|opacity|cursor|overflow)\s+[^:]` in styled-component template literals.
   ```
   // BAD: silently ignored
   padding 2px 4px;
   
   // GOOD
   padding: 2px 4px;
   ```

2. **Border shorthand without color (relies on `currentColor` fallback)**
   - `border: "1px solid"` or `borderBottom: "1px solid"` without a color uses the element's `color` property as the border color (CSS `currentColor` default).
   - Almost always a bug when combined with `color: "#333"` etc. — gives you a dark text-colored border regardless of variant/theme.
   - Flag any `border*: "Npx (solid|dashed|dotted)"` declaration that doesn't include a color. Check if `borderColor` / `border*Color` is set separately; if not, this is a bug.
   ```
   // BAD: bottom border picks up text color (#24292F)
   color: "#24292F",
   borderBottom: "1px solid",
   
   // GOOD
   color: "#24292F",
   borderBottom: "1px solid",
   borderBottomColor: getBorderColor(variant),
   ```

3. **`<img>` without explicit width/height (CLS)**
   - Icon `<img>` tags rendered from URL strings must have explicit `width` and `height` to prevent Cumulative Layout Shift.
   - Flag `<img ... />` where neither `width`, `height`, nor both `style.width`/`style.height` are set.

#### Dead Code

4. **Computed values never referenced**
   - `const effectiveType = cond ? X : Y;` that's never read downstream is dead code.
   - Use a grep check: for every `const <name> =` inside a component body, grep the rest of the function for `<name>`. If the only match is the declaration itself, flag it.
   - Especially dangerous when the logic "looks" important (normalization, mapping) — suggests a half-implemented feature.

#### Enum Discipline

5. **String literals where enum values should be used**
   - If a file defines `enum Foo { BAR = "bar" }`, then `if (size === "bar")` or `case "bar":` is a violation — should use `Foo.BAR`.
   - Breaks refactoring safety (renaming the enum member doesn't catch string literals) and makes intent unclear.
   ```
   // BAD: string literal
   if (size === "small") { ... }
   switch (variant) { case "success": ... }
   
   // GOOD: enum reference
   if (size === LTInlineMessageSize.SMALL) { ... }
   switch (variant) { case LTInlineMessageVariant.SUCCESS: ... }
   ```

6. **Plain `const` objects used where TypeScript `enum` is the convention**
   - Project convention: size/variant/direction constants are declared as `enum`, not `const { ... }`.
   - Grep neighbor components to confirm the convention before flagging.

7. **Asymmetric / missing enum members**
   - Direction enums, size enums, and similar discrete-value enums should be symmetric.
   - Example: `TOP`, `TOP_RIGHT`, `BOTTOM`, `BOTTOM_RIGHT`, `BOTTOM_LEFT` — missing `TOP_LEFT` is a gap.
   - When flagging, check if the corresponding positioning/rendering logic also handles the missing value.

#### JSX Structure

8. **Ternaries in JSX (simple and nested)**
   - Even a single ternary inside JSX is frowned upon in this codebase.
   - Nested ternaries (`cond1 ? A : cond2 ? B : C`) are always flagged.
   - Fix: extract to a `renderX()` helper above the `return`, using early-return `if` statements.
   ```
   // BAD: nested ternary in JSX
   {loading ? <Spinner /> : iconComponent ? iconComponent : <DefaultIcon />}
   
   // GOOD: helper with if-returns
   const renderIndicator = () => {
     if (loading) return <Spinner />;
     if (iconComponent) return iconComponent;
     return <DefaultIcon />;
   };
   // ...
   {renderIndicator()}
   ```

9. **Large inline `sx` / `style` arrow functions in JSX**
   - Anything >5 lines of style logic inline in `sx={(theme) => ({...})}` should be extracted to a helper above the `return`.
   - Same for `style={...}` objects with branching logic.
   ```
   // BAD: 15 lines of sx inside JSX
   <Textarea sx={(theme) => ({
     backgroundColor: disabled || readOnly ? "bg.disabled" : "bg.default",
     borderColor: disabled ? "..." : `border.${validationStatus}`,
     boxShadow: disabled || readOnly ? "none" : undefined,
     cursor: disabled ? "not-allowed" : readOnly ? "default" : undefined,
     // ... more
   })} />
   
   // GOOD: extracted helper OR const Styles object
   const Styles = { ... };  // non-theme-dependent parts
   // JSX
   sx={(theme) => ({
     ...Styles,
     "textarea::placeholder": { color: `${theme.colors.text.disabled} !important` },
   })}
   ```

10. **Per-key conditional styles (`cond ? X : undefined` repeated)**
    - When you see 3+ keys in a style object each doing `cond ? something : undefined` with the same `cond`, refactor to a single spread.
    ```
    // BAD: 4 per-key conditionals, all on `fullBorder`
    {
      borderRadius: fullBorder ? "6px" : "0px",
      border: fullBorder ? undefined : "none",
      borderBottom: fullBorder ? undefined : "1px solid",
      borderBottomColor: fullBorder ? undefined : getBorderColor(variant),
    }
    
    // GOOD: single conditional spread, each branch lists exactly what applies
    {
      ...(fullBorder
        ? { borderRadius: "6px" }
        : {
            borderRadius: "0px",
            border: "none",
            borderBottom: "1px solid",
            borderBottomColor: getBorderColor(variant),
          }),
    }
    ```

11. **Repetitive JSX children that could be `.map()`ed**
    - 4+ near-identical JSX siblings (same tag, same props, differing only by content) should be generated from an array map.
    ```
    // BAD
    <Label>Item 1</Label>
    <Label>Item 2</Label>
    <Label>Item 3</Label>
    <Label>Item 4</Label>
    
    // GOOD
    {items.map((label) => <Label key={label}>{label}</Label>)}
    ```

12. **Duplicate expressions across JSX branches (extract to variable)**
    - When the same non-trivial expression appears in 2+ places (often inside both arms of a ternary), hoist it to a local `const`.
    ```
    // BAD: computed twice
    <Case1 data-testid={dataTestId ? `${dataTestId}-clear-btn` : "lt-input-box-clear-btn"} />
    <Case2 data-testid={dataTestId ? `${dataTestId}-clear-btn` : "lt-input-box-clear-btn"} />
    
    // GOOD
    const clearBtnTestId = dataTestId ? `${dataTestId}-clear-btn` : "lt-input-box-clear-btn";
    <Case1 data-testid={clearBtnTestId} />
    <Case2 data-testid={clearBtnTestId} />
    ```

13. **Magic values in JSX instead of lookup tables**
    - Pixel values / sizes / heights that depend on a size enum should live in a lookup Record, not in nested ternaries.
    ```
    // BAD
    height:
      size === Size.XLARGE ? "31px"
      : size === Size.LARGE ? "23px"
      : size === Size.SMALL ? "15px"
      : "19px"
    
    // GOOD (module-level or above component)
    const TOKEN_HEIGHTS: Record<string, string> = {
      [Size.XLARGE]: "31px",
      [Size.LARGE]: "23px",
      [Size.MEDIUM]: "19px",
      [Size.SMALL]: "15px",
    };
    height: TOKEN_HEIGHTS[size] ?? TOKEN_HEIGHTS.medium,
    ```

#### Accessibility (a11y) for LT Components

14. **`aria-disabled` not aligned with the actual `disabled` state**
    - When a component has BOTH a `loading` state and a `disabled` prop AND the native `disabled` attribute is set to `disabled || loading`, then `aria-disabled` must also be `disabled || loading` (not just `disabled`).
    - Misalignment = screen reader says "enabled" while the control is functionally disabled.
    ```
    // BAD
    aria-disabled={disabled}
    disabled={disabled || loading}
    
    // GOOD
    aria-disabled={disabled || loading}
    disabled={disabled || loading}
    ```

15. **Visually-disabled `<a>` / `<div role="button">` without `tabIndex={-1}` + `aria-disabled`**
    - `<a>` has no native `disabled` attribute. CSS alone (`pointer-events: none`, dim color) blocks mouse clicks but:
      - Still focusable via Tab
      - Enter key still navigates via `href`
      - Screen readers announce as enabled link
    - Fix: conditionally set `aria-disabled` AND `tabIndex={-1}` when disabled.
    ```
    // BAD: only CSS-level disable
    <StyledLink disabled={disabled} href={href}>
    
    // GOOD
    <StyledLink
      disabled={disabled}
      aria-disabled={disabled || undefined}
      tabIndex={disabled ? -1 : 0}
      href={href}
    >
    ```

16. **`role="img"` combined with `aria-hidden="true"` on the same element**
    - Contradictory: `aria-hidden="true"` hides from AT; `role="img"` declares it as image for AT.
    - Pick one based on intent:
      - Decorative icon: `aria-hidden="true"` alone
      - Meaningful image: `role="img"` + `aria-label="..."`

17. **`<img>` without `alt=""` or explicit dimensions**
    - Every `<img>` needs either `alt="meaningful text"` (content) or `alt=""` + `aria-hidden="true"` (decorative).
    - Also flag missing width/height (CLS — already listed above at item 3).

#### Public API Surface

18. **Missing `className` prop support on new components**
    - Every new LT component should accept `className` (and `id`) and forward it to the outermost rendered element.
    - Enables CSS/querying hooks and consumer-driven targeting.
    ```
    // BAD: no className prop
    export const LTSwitch = ({ label, ... }) => (
      <LTBox>...</LTBox>
    );
    
    // GOOD
    export const LTSwitch = ({ label, className = "", ... }) => (
      <LTBox className={`lt-switch ${className}`.trim()}>...</LTBox>
    );
    ```

19. **Using Primer primitives (`Box`, `Text`, etc.) instead of LT equivalents when they exist**
    - lt-components wraps Primer behind `LT*` prefixes. Internal code should go through the wrapper so theming/overrides have a single choke point.
    - Check: if the file imports `Box` from `@primer/react` AND `LTBox` exists internally, it should use `LTBox`.
    - Same for any `LT*` wrapper that already exists.

#### Type Safety

20. **`any`-typed event handlers**
    - `onClick={(e: any) => {...}}` loses type inference for `e.target`, `e.currentTarget`, and downstream functions receiving `e`.
    - Replace with React's generic event types:
      - `React.MouseEvent<HTMLElement>` (or `HTMLButtonElement`/`HTMLDivElement` when specific)
      - `React.KeyboardEvent<HTMLElement>`
      - `React.ChangeEvent<HTMLInputElement>`
    - Prefer `HTMLElement` when the element type could change (e.g., Primer's `Box` + `as` prop).

#### JSX Guard Conventions

21. **Redundant `!!` on already-boolean props**
    - If a prop is typed `boolean` and has a default of `false`, `{!!prop && <X />}` is noise — just use `{prop && <X />}`.
    - Flag only when the type is strictly `boolean`. For `string`, `number`, `ReactNode`, or `any`-typed values, `!!` is protective (against `0`, `""`, etc. rendering as text).

22. **Missing `!!` on non-boolean values**
    - `{caption && <X />}` where `caption: string` with default `""` — at runtime, `""` short-circuits but React still reconciles an empty-string child.
    - More importantly, `{count && <X />}` where `count: number` renders `0` as text (classic footgun).
    - For `string`/`number`/`ReactNode` values used as JSX guards, prefer `!!` or an explicit comparison.

For each pattern found in this section, report:
```
LT-AUTHORING PATTERN: {pattern name from list above}
  File: src/components/LTFoo/index.tsx:45
  Issue: {one-sentence description tied to the pattern}
  Current: {the problematic code}
  Fix: {the corrected code}
  Severity: Critical | Major | Minor
```

**Severity guide for 5f:**
- **Critical**: Items 2 (CSS bug producing wrong color), 14, 15 (a11y bugs users can actually hit), 16 (contradictory ARIA)
- **Major**: Items 1 (silently ignored CSS), 4 (dead code suggesting incomplete feature), 7 (missing enum members block API use cases), 8/9/10 (JSX readability), 18 (public API gap)
- **Minor**: Items 3 (CLS), 5/6 (enum discipline), 11/12/13 (refactoring opportunities), 17 (a11y polish), 19 (internal convention), 20 (type safety), 21/22 (guard conventions)

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

## Frontend Anti-Patterns
{count} issues found

### Critical (Data Integrity)
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | Stale data on transition | ... |

### Major (Performance/Correctness)
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | Stale useEffect deps | ... |

### Minor (Code Hygiene)
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | Missing braces | ... |

---

## LT-Components Authoring Patterns
(Only populated when PR is inside lt-components itself)

### Critical
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | aria-disabled misalignment | ... |

### Major
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | Nested ternary in JSX | ... |

### Minor
| File | Line | Pattern | Issue |
|------|------|---------|-------|
| ... | ... | Enum literal vs value | ... |

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
- **Anti-pattern Critical/Major issues should be REQUEST CHANGES** — these are real bugs.
- **LT-Authoring Critical issues are also REQUEST CHANGES** — they are a11y bugs or visual correctness bugs users will hit.
- **For the code-reviewer and security-audit sub-agents**, pass only the changed file paths and relevant context — not your entire conversation.
- If the PR is too large (>50 files), warn the user and offer to review in batches or focus on specific directories.
- If `gh` CLI is not available, instruct the user to install and authenticate: `brew install gh && gh auth login`.
