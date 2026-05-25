---
name: doctor
description: Diagnose the Claude FE Agent installation by checking symlinks, core skills and agents, CLI dependencies, integrations, and permission hygiene.
disable-model-invocation: true
---

# Doctor

Run read-only diagnostics for this toolkit. Do not change authentication,
links, permissions, or files without explicit approval.

## Checks

Verify user-level symlinks:

```text
~/.claude/CLAUDE.md
~/.claude/settings.json
~/.claude/workflow-config.json
~/.claude/skills
~/.claude/agents
~/.claude/memory
```

Verify core files:

```text
agents/senior-frontend-developer.md
agents/sfe.md
agents/bug-hunter.md
skills/implement/SKILL.md
skills/execute/SKILL.md
skills/remember/SKILL.md
skills/visual-check/SKILL.md
```

Check the presence of `claude`, `node`, `npm`, `git`, and optionally `gh`.
Read config without exposing credentials and report configured MCP names,
enabled plugins, machine-specific paths, and broad or destructive permissions
worth reviewing.

## Output

Return a compact table with `Check`, `Status`, and `Action Needed` rows for
symlinks, core files, tools, MCP configuration, and permission hygiene. End
with an ordered fix list only if issues are found.
