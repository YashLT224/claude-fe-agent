---
name: grill-me
description: Interview the user relentlessly about a plan, design, or RFC until reaching shared understanding. Walks the decision tree branch-by-branch, asks one question at a time, provides recommended answers. Use after generating a plan, when stress-testing a design, or when the user says "grill me".
---

# /grill-me

Interview the user relentlessly about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, **provide your recommended answer**.

## Rules

1. **One question at a time.** Never bulk-ask. Wait for the user's answer before moving on.
2. **Explore before asking.** If a question can be answered by reading `workflow-state/plan.md`, `workflow-state/exploration.json`, `package.json`, theme files, or `@lambdatestincprivate/lt-components` — explore first. Don't ask what you can find on disk.
3. **Always recommend an answer.** End every question with `**Recommendation:** ...` so the user can say "yes" and move on.
4. **Update plan.md as you go.** When the user gives an answer that affects the plan, write it into `workflow-state/plan.md` immediately — don't batch updates to the end.
5. **Stop on alignment, not silence.** If the user keeps deferring ("you decide", "whatever"), take the recommendation and move on.
6. **Don't re-grill what's already settled.** If `plan.md` already specifies a decision clearly, skip it.

## Categories to walk (in order; skip if N/A)

1. **Scope & boundaries** — what's in, what's out, hidden assumptions
2. **User flows & states** — empty / loading / error / success / offline / partial-data
3. **State management** — local vs global, persistence, derived state, source of truth
4. **Data shape** — types, validation, defaults, optionality, server vs client shape
5. **Component composition** — which lt-components map to which UI primitive; what's genuinely custom
6. **API contract** — endpoints, request/response shapes, error codes, retries, optimistic updates
7. **Accessibility** — keyboard nav, focus management, ARIA, screen-reader announcements
8. **Theming & tokens** — which theme tokens, dark mode, responsive breakpoints
9. **Testing strategy** — unit vs integration vs e2e, what's mocked, coverage targets
10. **Out of scope** — explicit non-goals (anti-scope-creep)

## Question format

```
**Q:** [the question]
**Why it matters:** [1 line — what breaks if we get this wrong]
**Recommendation:** [your suggested answer + reasoning, grounded in exploration.json / CLAUDE.md / lt-components]

Your call?
```

## Stop conditions

Stop grilling when ALL of these are true:

- Every open branch in `workflow-state/plan.md` has an explicit answer
- Recommendations align with `CLAUDE.md` and patterns from `workflow-state/exploration.json`
- The user confirms with "approve" / "looks good" / "ship it" / equivalent

Then summarize what changed in `plan.md` and hand control back to the orchestrator (sfe Phase 4) for the formal approval step.

## Anti-patterns

- **Don't ask for permission to start.** Just begin with Q1.
- **Don't list 10 questions at once.** That's a survey, not an interview.
- **Don't ask without a recommendation.** Forces the user to do your thinking.
- **Don't ask philosophical questions** ("how should error states feel?"). Be concrete: "On 500, do we show a toast or inline error?"
- **Don't grill on style/lint** — those are caught in Phase 7.
