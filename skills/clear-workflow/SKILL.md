---
name: clear-workflow
description: Clean completed Claude frontend workflow Markdown artifacts from .claude/workflow-state/ only. Use after a task has been reviewed, validated, accepted, or committed and the user wants to remove progress, plan, test, issue, todo, or report Markdown files without touching project documentation.
disable-model-invocation: true
---

# Clear Workflow Markdown State

Clean completed task notes safely. This command must never delete Markdown
outside `.claude/workflow-state/`.

## Command Forms

```text
/clear-workflow
/clear-workflow --confirm
```

## Flow

1. Resolve the current target project root and check whether
   `.claude/workflow-state/` exists.
2. List only Markdown files directly inside that directory:

   ```bash
   find .claude/workflow-state -maxdepth 1 -type f -name '*.md' -print
   ```

3. Without `--confirm`, report the listed files and ask the user to invoke
   `/clear-workflow --confirm` after confirming the task is complete.
4. With `--confirm`, delete only the listed Markdown files:

   ```bash
   find .claude/workflow-state -maxdepth 1 -type f -name '*.md' -delete
   ```

5. List the directory afterward and report exactly what was removed.

## Safety Rules

- Never search above or outside `.claude/workflow-state/`.
- Never delete `README.md`, application documentation, source files, or
  Markdown in any other directory.
- Preserve `state.json`, `requirements.json`, and `exploration.json`; they can
  be inspected or cleaned separately only on an explicit user request.
- Do not run deletion unless the user used `--confirm` or explicitly approved
  the previewed deletion in the current conversation.
- If tests, review, visual validation, or commit are still pending, warn before
  deleting completion context.

## Output

Return the files found, whether deletion occurred, files remaining in
`.claude/workflow-state/`, and a reminder that JSON state was intentionally
preserved.
