---
name: design-to-code
description: Converts Figma designs into code components. Auto-detects project's framework and component libraries. Use when implementing designs from Figma or translating mockups to code.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Design-to-Code Translator (Generic)

## Auto-Detection Strategy

This skill adapts to ANY frontend project by:
1. Detecting the framework (React, Vue, Svelte, etc.)
2. Finding existing component libraries in package.json
3. Matching project's styling approach
4. Following existing patterns in the codebase

---

## Step 1: Detect Project Setup

### Read package.json
Extract:
```json
{
  "framework": "react|vue|svelte|angular",
  "component_libraries": ["<from dependencies>"],
  "styling": "tailwind|styled-components|css-modules|scss|emotion"
}
```

### Component Library Priority (Auto-Detected)

**ALWAYS use this order:**

1. **Project's existing component library** (Highest Priority)
   - Check package.json for UI libraries
   - Common ones: MUI, Chakra, Ant Design, Primer, Radix, shadcn/ui
   - Use whatever the project already has

2. **Project's custom components** (Second Priority)
   - Search for existing components in the codebase
   - Check common paths: `src/components/`, `components/`, `src/ui/`

3. **Create new component** (Last Resort)
   - Only if nothing suitable exists
   - Follow project's existing component patterns

### Detect Styling Approach

Check for:
- `tailwind.config.js` → Tailwind CSS
- `styled-components` in deps → Styled Components
- `.module.css` files → CSS Modules
- `.scss` files → SCSS
- `@emotion` in deps → Emotion
- `theme.js` or `theme.ts` → Theme system

### Detect Theme System (CRITICAL)

**NEVER use raw hex codes directly in components.** Always map Figma colors to the project's theme tokens.

Search for the project's theme/color system:

1. **Tailwind theme** → check `tailwind.config.js` or `tailwind.config.ts`
   - Look in `theme.extend.colors` for custom color tokens
   - Use classes like `bg-primary`, `text-secondary`, NOT `bg-[#1a2b3c]`

2. **CSS Variables** → search for `:root` or `[data-theme]` in CSS files
   - Look for `--color-primary`, `--bg-surface`, etc.
   - Use `var(--color-primary)`, NOT `#1a2b3c`

3. **Theme object** → search for `theme.js`, `theme.ts`, `tokens.js`, `tokens.ts`, `colors.js`, `colors.ts`
   - Check `src/theme/`, `src/styles/`, `src/tokens/`, `styles/`
   - Use `theme.colors.primary`, NOT `#1a2b3c`

4. **Design tokens file** → search for `*.tokens.json`, `design-tokens.*`
   - May be generated from Figma or design system

5. **Component library theme** → check library-specific theme files
   - MUI: `createTheme()` in `theme.ts`
   - Chakra: `extendTheme()` in `theme.ts`
   - Ant Design: `ConfigProvider` theme config
   - Primer: `ThemeProvider` tokens
   - shadcn/ui: CSS variables in `globals.css`

6. **SCSS variables** → search for `$color-*`, `$brand-*` in `_variables.scss` or similar

**Build a color mapping table before writing any code:**

```
Figma Color (hex)  →  Theme Token
─────────────────────────────────────
#1E88E5            →  primary / blue-500 / var(--color-primary)
#FFFFFF            →  background / white / var(--bg-surface)
#333333            →  text-primary / gray-800 / var(--text-primary)
#F5F5F5            →  background-secondary / gray-100 / var(--bg-muted)
#E0E0E0            →  border / gray-300 / var(--border-default)
```

**If a Figma color has NO matching theme token:**
- Check if it's close to an existing token (within a few shades) → use the closest token
- If truly new → flag it to the user: "Color #XX has no theme token. Should I add it to the theme or use the closest existing token?"
- NEVER silently hardcode a hex value

---

## Step 2: Extract Design Specifications

### From Figma Design, Extract:

**Design Tokens:**
- Colors: Map each HEX to project theme tokens (see theme detection above)
- Spacing: Padding, margin (usually 4px/8px grid)
- Typography: Font family, size, weight, line-height — use theme typography tokens if available
- Borders: Width, radius, color — use theme border tokens
- Shadows: Box-shadow values — use theme shadow tokens if available

**Component Structure:**
- Layout type (flex, grid)
- Component hierarchy
- Responsive breakpoints
- Interactive states (hover, active, disabled)

---

## Step 3: Map to Project's Stack

### Framework-Specific Mapping

**React:**
```jsx
// Figma Frame → div or semantic HTML
// Auto Layout → CSS Flexbox/Grid
// Variants → Component props
// Instances → Reusable component
```

**Vue:**
```vue
<template>
  <!-- Figma structure → Vue template -->
</template>
<script setup>
// Props from variants
</script>
<style scoped>
/* Styles from Figma */
</style>
```

**Svelte:**
```svelte
<!-- Figma structure → Svelte markup -->
<script>
  // Props from variants
</script>
<style>
  /* Styles from Figma */
</style>
```

### Styling Approach Mapping

**RULE: Always use theme tokens for colors. Never hardcode hex values.**

**If Tailwind:**
```jsx
// GOOD — uses theme color tokens
<div className="flex gap-4 p-6 bg-primary text-on-primary rounded-lg">
<div className="flex gap-4 p-6 bg-blue-500 text-white rounded-lg">

// BAD — hardcoded hex
<div className="flex gap-4 p-6 bg-[#1E88E5] text-[#FFFFFF] rounded-lg">
```

**If CSS Modules:**
```jsx
import styles from './Component.module.css';
<div className={styles.container}>
```
```css
/* GOOD — uses CSS variables from theme */
.container { background: var(--color-primary); color: var(--text-primary); }

/* BAD — hardcoded hex */
.container { background: #1E88E5; color: #333333; }
```

**If Styled Components:**
```jsx
// GOOD — uses theme
const Container = styled.div`
  display: flex;
  gap: 1rem;
  background: ${({ theme }) => theme.colors.primary};
  color: ${({ theme }) => theme.colors.textPrimary};
`;

// BAD — hardcoded hex
const Container = styled.div`
  background: #1E88E5;
  color: #333333;
`;
```

**If SCSS:**
```scss
// GOOD — uses SCSS variables
.component-container {
  background: $color-primary;
  color: $text-primary;
}

// BAD — hardcoded hex
.component-container {
  background: #1E88E5;
  color: #333333;
}
```

---

## Step 4: Component Library Usage

### Auto-Detect Available Components

Search package.json for these libraries and use their components:

**Material UI (@mui/material):**
```jsx
import { Button, TextField, Card } from '@mui/material';
```

**Chakra UI (@chakra-ui/react):**
```jsx
import { Button, Input, Box } from '@chakra-ui/react';
```

**Ant Design (antd):**
```jsx
import { Button, Input, Card } from 'antd';
```

**Primer React (@primer/react):**
```jsx
import { Button, TextInput, Box } from '@primer/react';
```

**Radix UI (@radix-ui/*):**
```jsx
import * as Dialog from '@radix-ui/react-dialog';
```

**shadcn/ui:**
```jsx
import { Button } from '@/components/ui/button';
```

### Finding Existing Custom Components

```bash
# Search for components in common locations
grep -r "export.*function\|export.*const" src/components/
grep -r "export default" src/Components/
```

---

## Step 5: Implementation Workflow

### 5.1 Analyze Design Structure
- Identify top-level container
- List all child components
- Note spacing relationships
- Identify variants/states

### 5.2 Check for Existing Components
```
Search for similar components:
1. In project's component library
2. In src/components/ or equivalent
3. In project's UI kit
```

### 5.3 Extract CSS Properties from Figma

From Figma's "Inspect" panel:
- Layout (display, flex-direction, gap)
- Sizing (width, height, min/max)
- Spacing (padding, margin) → map to theme spacing tokens
- Colors (background, text, borders) → **MUST map to theme tokens, never use raw hex**
- Typography (font, size, weight) → map to theme typography tokens

### 5.4 Implement Component

**Template (React + detected styling):**

```jsx
import React from 'react';
// Import from detected component library
// Import styles based on detected approach

const ComponentName = ({ prop1, prop2 }) => {
  return (
    <div className={/* based on styling approach */}>
      {/* Implementation matching project patterns */}
    </div>
  );
};

export default ComponentName;
```

### 5.5 Visual Verification
- Compare with design pixel-by-pixel
- Test all interactive states
- Verify responsive behavior

---

## Common Patterns

### Layout Grid (8px base - universal)
```
4px  = 0.25rem  (Tailwind: p-1)
8px  = 0.5rem   (Tailwind: p-2)
12px = 0.75rem  (Tailwind: p-3)
16px = 1rem    (Tailwind: p-4)
24px = 1.5rem  (Tailwind: p-6)
32px = 2rem    (Tailwind: p-8)
```

### Figma → CSS Mapping

**Auto Layout → Flexbox:**
```
Figma: Auto Layout (Horizontal, 16px gap)
CSS:   display: flex; gap: 1rem;
Tailwind: flex gap-4
```

**Constraints → CSS:**
```
Figma: Left + Right → width: 100%
Figma: Center → margin: 0 auto
```

**Effects → CSS:**
```
Figma: Drop Shadow (0, 4, 8, rgba(0,0,0,0.1))
CSS:   box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1)
Tailwind: shadow-md
```

---

## Responsive Implementation

**Mobile-first approach:**
```css
/* Mobile: 320px - 767px */
.component { width: 100%; }

/* Tablet: 768px - 1023px */
@media (min-width: 768px) { }

/* Desktop: 1024px+ */
@media (min-width: 1024px) { }
```

**Tailwind responsive:**
```jsx
<div className="w-full md:w-1/2 lg:w-1/3">
```

---

## Color Rules (MANDATORY)

1. **NEVER hardcode hex values** (`#1E88E5`, `#333`, `rgba(0,0,0,0.5)`) directly in components or styles
2. **ALWAYS map Figma colors to theme tokens** before writing any code
3. **If no matching token exists** → ask the user whether to:
   - Add a new token to the theme
   - Use the closest existing token
4. **Acceptable patterns:**
   - Tailwind: `bg-primary`, `text-gray-800`, `border-secondary`
   - CSS vars: `var(--color-primary)`, `var(--text-muted)`
   - Theme object: `theme.colors.primary`, `theme.colors.text.secondary`
   - SCSS vars: `$color-primary`, `$text-secondary`
5. **Unacceptable patterns:**
   - `color: #1E88E5`
   - `bg-[#1E88E5]` (Tailwind arbitrary hex)
   - `background: rgba(30, 136, 229, 0.8)` (raw rgba)
   - `style={{ color: '#333' }}` (inline hex)

## Tips

- Always check package.json first for available libraries
- Search codebase for similar components before creating new
- Match the project's existing code style
- **ALWAYS use theme tokens for colors — never hardcode hex values**
- Build a Figma-to-theme color mapping table before writing code
- If a color has no theme token, flag it — don't silently hardcode it
- Test responsive behavior at common breakpoints
- Document any deviations from design with reasoning
