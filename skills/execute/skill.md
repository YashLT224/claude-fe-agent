---
name: execute
description: Implement a medium-sized frontend change through focused requirements, code exploration, an approved short approach, implementation, and targeted verification.
disable-model-invocation: true
---

# Execute Daily Frontend Change

Use `/execute $ARGUMENTS` for normal frontend work such as a filter, loading
state, responsive fix, form validation change, or reusable component addition.

## Flow

1. Capture the objective, expected behavior, and key edge cases.
2. Read affected files and comparable existing patterns.
3. Present a concise implementation approach and wait for approval.
4. Implement using current components, tokens, state/API style, and tests.
5. Run targeted checks and `/visual-check` for rendered UI changes.

If the change becomes broad, architecture-sensitive, security-sensitive, or a
large new user flow, recommend switching to `/implement`.

## State

Create only:

```text
.claude/workflow-state/state.json
.claude/workflow-state/requirements.json
.claude/workflow-state/exploration.json
.claude/workflow-state/progress.md
```

Do not create a plan, test tracker, issue tracker, or report unless the user
upgrades the task to the full workflow.

## Completion

Return what changed, files touched, checks performed, visual verification when
applicable, and any unverified risk.
