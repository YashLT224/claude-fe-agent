---
name: fix
description: Handle a frontend bug end to end through evidence-based investigation, approved root cause and fix plan, implementation by SFE, regression tests, and validation.
disable-model-invocation: true
---

# Fix Frontend Bug

Use `/fix $ARGUMENTS` from the main `sfe` session for reported bugs,
regressions, production issues, or unclear broken behavior.

## Workflow

1. Capture symptom, repro, expected/actual result, severity, and ticket/logs.
2. Invoke `bug-hunter` for focused exploration and evidence-based RCA.
3. Present the RCA and wait for user approval.
4. Present a fix plan including risks and regression tests; wait for approval.
5. After approval, `sfe` implements the fix. Specialist agents do not edit
   production code.
6. Add or update a focused regression test where the project supports it.
7. Run relevant checks, `/review-changes` for meaningful diffs, and
   `ui-validator` or `/visual-check` when UI behavior changed.

## Routing

- If the defect is an obvious tiny typo or style correction with no uncertain
  root cause, announce downgrade to direct mode.
- If the approved fix is broad, security-sensitive, or architectural, upgrade
  implementation to the `/build` contract.

## Output

Report the approved root cause, implemented fix, regression coverage,
validation performed, and any remaining risk or blocked verification.
