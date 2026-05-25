---
name: remember
description: Scan and cache the current project's stable frontend context for faster future Claude Code sessions. Use when onboarding a project or refreshing memory after architecture or dependency changes.
disable-model-invocation: true
---

# Remember Project

Run the established project-memory workflow described in the sibling
`remember-project` skill. Read
`${CLAUDE_SKILL_DIR}/../remember-project/SKILL.md` and follow it for
`$ARGUMENTS`.

Supported invocations:

```text
/remember
/remember --refresh
/remember --view
/remember --list
```

Keep cached content limited to stable project knowledge: stack, directories,
design system, data/state/API patterns, tests, and architecture. Do not store
temporary task progress as permanent project memory.
