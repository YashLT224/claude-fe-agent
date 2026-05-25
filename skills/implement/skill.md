---
name: implement
description: Run the full production frontend implementation workflow for a ticket, major feature, or high-risk change, including requirements, approvals, implementation, and validation.
disable-model-invocation: true
---

# Implement Feature

Use `/implement $ARGUMENTS` for production features, significant refactors,
and major bug implementations after an approved RCA. For smaller work, use
`/execute` or run the senior frontend agent in direct mode.

## Contract

- Run all seven phases.
- Require approval after approach and plan.
- Follow the target project's components, tokens, state, API, and test
  conventions.
- Verify visible UI changes with `/visual-check`.
- Store artifacts only under `.claude/workflow-state/` in the target repo.

Do not introduce alternative artifact names such as `current-workflow.json`,
`plan.json`, or `test-baseline.json`.

## State Files

```text
.claude/workflow-state/
├── state.json
├── requirements.json
├── exploration.json
├── plan.md
├── todo.md
├── testCases.md
├── issues.md
├── progress.md
└── report.md
```

## Phases

### 1. Requirements

Gather task summary, acceptance criteria, constraints, out of scope, designs,
and API/permission/analytics/feature-flag dependencies from Jira, GitHub, or
the user. Write `requirements.json`.

### 2. Exploration

Load current project memory where available, then inspect relevant existing
features, components, design tokens, state/API flow, and tests. Write
`exploration.json`.

### 3. Approach

Present a recommended approach, real alternatives where useful, and key risks.
Wait for approval.

### 4. Plan

Write `plan.md` describing files, component/data flow, UI states,
responsiveness, accessibility, tests, and validation. Wait for approval.

### 5. Tests

When tests exist, add or extend focused behavioral coverage. Prefer a
regression test for a bug. Document any explicit test waiver.

### 6. Implementation

Write production code according to the approved plan, reusing current project
patterns.

### 7. Validation

Run relevant tests and configured lint/type/build checks. Use `/visual-check`
for UI changes, accessibility review for interactive UI, `/security-audit` for
sensitive surfaces, and `/review-changes` for meaningful multi-file work.
Fix findings, rerun affected checks, and write `report.md`.

## Completion

Return what changed, files touched, checks completed, UI verification when
relevant, and remaining risk.
