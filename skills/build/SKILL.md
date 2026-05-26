---
name: build
description: Run the full production frontend feature workflow for Jira/Figma work, new user flows, broad refactors, or high-risk changes, with requirements, plan approval, tests, implementation, and validation.
disable-model-invocation: true
---

# Build Production Feature

Use `/build $ARGUMENTS` as the human-friendly full feature command from a
main `sfe` session.

## Contract

This is the preferred alias for the existing full `/implement` workflow.
Load and follow `${CLAUDE_SKILL_DIR}/../implement/SKILL.md` completely.

The required sequence is:

```text
Requirements -> Exploration -> Approach approval -> Plan approval
-> Tests -> Production implementation -> Review and validation
```

Use it for Jira features, Figma-driven features, new pages/flows, important
refactors, major approved bug fixes, and sensitive changes. Keep all workflow
artifacts under `.claude/workflow-state/`.

## Completion Gate

Do not mark delivery ready until relevant tests/checks pass or are explicitly
reported as blocked, `/review-changes` has covered meaningful multi-file work,
and visible UI has been verified through `ui-validator` or `/visual-check`.
