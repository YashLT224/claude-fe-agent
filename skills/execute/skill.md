---
name: execute
description: Shorthand SFE implementation. Invokes the senior-frontend-developer agent in shorthand mode — runs Phase 1 (gather requirements), Phase 2 (explore codebase), Phase 3 (decide approach), and Phase 6 (implement). Skips Phase 4 (formal plan), Phase 5 (TDD tests), and Phase 7 (review). Use for medium-sized changes that need real engineering judgment but not the full pipeline. Argument is a short task description, e.g. "delete button in todo".
---

# /execute — Shorthand SFE Implementation

A condensed senior-frontend-developer workflow. Skips formal planning, TDD tests, and the validation pass — keeps the parts that prevent the agent from flying blind (requirements, exploration, approach approval).

## Triggers

- User invokes `/execute <task description>`
- Examples:
  - `/execute delete button in todo`
  - `/execute add filter dropdown to dashboard`
  - `/execute sticky header on settings page`

## What runs (only these phases)

| Phase | Step |
|-------|------|
| **P1** | Gather Requirements — clarify intent, fetch Jira ticket if mentioned, capture acceptance criteria |
| **P2** | Explore Codebase — `/explore-codebase` finds similar patterns, files to touch, lt-components available |
| **P3** | Decide Approach — present approach with trade-offs ★ user approves ★ |
| **P6** | Execute Implementation — write code, invoke `/design-to-code` for any UI work, prefer lt-components |

## What is skipped

- **P4** — formal `plan.md` (the P3 approach summary takes its place)
- **P5** — TDD tests
- **P7** — `/review-changes`, `/security-audit`, a11y audit

## How to invoke the agent

Spawn the **senior-frontend-developer** sub-agent via the Task tool. Pass it:

```
Mode: --shorthand
Task: $ARGUMENTS

Run ONLY Phase 1, Phase 2, Phase 3, Phase 6.
Skip Phase 4 (plan), Phase 5 (tests), Phase 7 (validation).

In Phase 6:
- Always invoke /design-to-code for any UI work
- Prefer @lambdatestincprivate/lt-components over custom UI
```

## workflow-state behavior

Still create `workflow-state/` for traceability, but only these files:

- `state.json` — track phases (mark P4/P5/P7 as `skipped`)
- `exploration.json` — Phase 2 output
- `progress.md` — phase log

Do **not** create: `plan.md`, `testCases.md`, `issues.md`, `report.md`.

## Banner

The agent prints:

```
🟢 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   AGENT: senior-frontend-developer
   STATUS: Active
   MODE: --shorthand
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 [senior-fe] Phase 1: Gathering requirements...
🟢 [senior-fe] Phase 2: Exploring codebase...
🟢 [senior-fe] Phase 3: Deciding approach...
🟢 [senior-fe] Phase 4: Planning — SKIPPED (--shorthand)
🟢 [senior-fe] Phase 5: Tests — SKIPPED (--shorthand)
🟢 [senior-fe] Phase 6: Executing implementation...
🟢 [senior-fe] Phase 7: Validation — SKIPPED (--shorthand)
🟢 [senior-fe] Done!
```

## When to use vs. other modes

| Use this | When |
|----------|------|
| `/execute` (--shorthand) | Medium task, you want real exploration + approach gate, but not the heavy pipeline |
| `--quick` | Prototype/spike, you've already decided the approach, just want it built |
| `--direct` | Truly tiny edit (rename, typo, single-line fix) |
| `/implement` or full sfe | Real feature work, ticket-driven, needs tests + review |

## Final output

A short summary instead of `report.md`:

- What was built (1-2 sentences)
- Files changed (table: file / created-or-modified)
- Note: "Tests + review skipped — run `/review-changes` and add tests before merging if this is going to production."
