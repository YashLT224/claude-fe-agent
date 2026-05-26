---
name: do
description: Route a frontend development request to direct work, execute, build, fix, review, or validation based on scope and risk, then run the selected workflow from the main SFE session.
disable-model-invocation: true
---

# Do: Smart Frontend Router

Use `/do $ARGUMENTS` when the user knows the task but does not want to choose
the workflow command manually. Run this from the main `sfe` session.

## Route

| Signal | Route |
| --- | --- |
| One obvious copy, token, import, prop, or tiny CSS change | Direct mode |
| Limited normal enhancement or clear small fix | `/execute` contract |
| New flow, Jira/Figma feature, multi-area work, risky refactor, sensitive behavior | `/build` contract |
| Reported bug with unknown root cause or regression | `/fix` contract |
| Existing unreviewed local diff only | `/review-changes` |
| Verification-only request for rendered UI | `ui-validator` / `/visual-check` |

## Process

1. Restate the task and classify scope/risk in one short paragraph.
2. Announce the selected route and why.
3. If classification is ambiguous between two workflows, choose the safer
   fuller workflow or ask one focused clarification when scope changes cost.
4. Continue by following the selected workflow in the same main session.

Never make production edits before the approval gate required by `/execute`,
`/build`, or `/fix`.
