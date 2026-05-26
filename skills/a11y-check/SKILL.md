---
name: a11y-check
description: Run a focused accessibility review of changed frontend UI or a specified route/component, reporting WCAG-relevant findings without editing production code.
disable-model-invocation: true
---

# Accessibility Check

Use `/a11y-check $ARGUMENTS` after work on forms, modals, menus, navigation,
interactive components, media, or keyboard/focus behavior.

## Workflow

1. Identify changed UI files or the specified component/route and expected
   interactions.
2. Invoke the `a11y-checker` agent with that scope and relevant diff.
3. When the rendered behavior matters, coordinate with `/visual-check` for
   keyboard and focus-state observation.
4. Return findings only; ask `sfe` to implement approved fixes.

## Minimum Checks

- Semantic controls and accessible names for actions.
- Labels, errors, instructions, and associations for form fields.
- Keyboard operation, tab order, visible focus, and dialog/menu focus behavior.
- Images/media alternatives and meaningful status announcements.
- ARIA validity and use of existing accessible project components.

## Output

List findings first by severity with file/line references when available,
WCAG rationale, a concrete recommended correction, and checks that passed.
Do not edit production code in review-only mode.
