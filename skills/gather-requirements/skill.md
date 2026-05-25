---
name: gather-requirements
description: Gather and structure frontend task requirements from Jira, GitHub issues, or manual input before implementation. Use when starting ticket-based work or when acceptance criteria are unclear.
allowed-tools: Read, Grep, Glob, Bash, WebFetch, Agent
---

# Gather Requirements Skill (Phase 1)

## Description
Gathers and structures requirements from JIRA tickets, GitHub Issues, or manual input. Works with any frontend project by auto-detecting project context.

## Triggers
- User invokes `/gather-requirements <ticket-id>`
- User invokes `/gather-requirements` (manual mode)
- Called by `/implement` orchestrator skill

---

## Workflow

### Step 1: Detect Project Context

**Auto-detect the current project's setup:**

1. **Read package.json** (if exists)
   - Extract project name
   - Identify framework (React, Vue, Next.js, etc.)
   - Identify state management (Redux, Zustand, Vuex, etc.)
   - Identify component libraries
   - Identify test framework

2. **Read CLAUDE.md** (if exists)
   - Extract project-specific conventions
   - Note any custom workflows
   - Identify key directories

3. **Scan directory structure**
   - Find component directories
   - Find state management directories
   - Find utility directories
   - Note project structure pattern

4. **Store detected context:**
   ```json
   {
     "project_name": "<from package.json>",
     "framework": "<react|vue|nextjs|angular|svelte>",
     "state_management": "<redux|zustand|mobx|vuex|pinia|none>",
     "component_libraries": ["<detected libraries>"],
     "test_framework": "<jest|vitest|mocha|cypress>",
     "directories": {
       "components": "<detected path>",
       "pages": "<detected path>",
       "hooks": "<detected path>",
       "state": "<detected path>",
       "utils": "<detected path>"
     }
   }
   ```

### Step 2: Determine Input Source

**If ticket ID provided:**

Detect ticket source from format:
- `TTN-XXXXX`, `FORCE-XXXX`, `ASE-XX` → JIRA
- `#123` or `owner/repo#123` → GitHub Issues
- `LIN-XXX` → Linear (future)

**Launch appropriate fetch agent:**

#### For JIRA Tickets:
```
Agent tool parameters:
  description: "Fetch Jira ticket"
  subagent_type: "general-purpose"
  run_in_background: false
  prompt: |
    Fetch Jira ticket [ticket_id] using MCP tools.

    Use mcp__atlassian__getJiraIssue with:
    - cloudId: [from ~/.claude/workflow-config.json or ask user]
    - issueIdOrKey: [ticket_id]

    Extract and return:
    - Summary
    - Description
    - Issue type (Bug, Task, Story, etc.)
    - Priority
    - Labels
    - Linked issues (fetch summaries for each, max 10)
    - Key comments
    - Any design links (Figma URLs in description/comments)

    Return as structured JSON.
```

#### For GitHub Issues:
```
Agent tool parameters:
  description: "Fetch GitHub issue"
  subagent_type: "general-purpose"
  run_in_background: false
  prompt: |
    Fetch GitHub issue [issue_number] using gh CLI or MCP.

    Extract:
    - Title
    - Body/Description
    - Labels
    - Milestone
    - Linked PRs
    - Key comments

    Return as structured JSON.
```

**If no ticket ID provided:**
- Skip fetch agent
- Proceed to manual input collection

### Step 3: Manual Input Collection (if needed)

Use `AskUserQuestion` tool to collect requirements:

**Question 1: Type**
```
question: "What type of work is this?"
header: "Type"
options:
  - label: "Bug fix"
    description: "Fixing existing broken functionality"
  - label: "New feature"
    description: "Adding new functionality"
  - label: "Enhancement"
    description: "Improving existing functionality"
  - label: "Refactor"
    description: "Code restructuring without behavior change"
```

**Question 2: Summary**
Ask for brief title/summary as free text.

**Question 3: Description**
```
"Please describe the requirement in detail:
- What should happen?
- What is the current behavior (if applicable)?
- Any specific constraints?"
```

**Question 4: Acceptance Criteria**
```
question: "What are the acceptance criteria?"
header: "Criteria"
options:
  - label: "I'll list them"
    description: "I have specific criteria to provide"
  - label: "Help me define"
    description: "Help me think through what 'done' looks like"
  - label: "Skip for now"
    description: "Will define during planning"
```

### Step 4: Extract Design Links

Search for Figma/design links in:
- Ticket description
- Ticket comments
- Linked issues

If Figma links found:
```
question: "Found design links. Should I fetch design details?"
header: "Design"
options:
  - label: "Yes, fetch Figma"
    description: "Extract design specs using Figma MCP"
  - label: "Skip for now"
    description: "I'll handle design manually"
```

### Step 5: Correlate with Codebase

Based on requirements keywords, identify:
- Likely affected directories
- Similar existing features
- Related components/files

```json
{
  "likely_directories": ["<based on keywords>"],
  "similar_features": ["<based on description>"],
  "potential_dependencies": ["<detected>"]
}
```

### Step 6: Validate Requirements

**Must have:**
- Summary (block if missing)

**For Bug type, should have:**
- Current behavior
- Expected behavior
- Steps to reproduce (if available)

**Should have (ask if missing):**
- At least 1 acceptance criterion
- Description > 50 characters

**Validation prompt (if incomplete):**
```
question: "Requirements seem incomplete. What would you like to do?"
header: "Validate"
options:
  - label: "Add more details"
    description: "I'll provide additional information"
  - label: "Proceed anyway"
    description: "Continue with what we have"
  - label: "Start over"
    description: "Re-enter requirements"
```

### Step 7: Write Requirements Output

Create workflow state directory if not exists:
```bash
mkdir -p .claude/workflow-state
```

Save to `.claude/workflow-state/requirements.json`:

```json
{
  "metadata": {
    "workflow_id": "<generated-uuid>",
    "created_at": "<timestamp>",
    "source": "jira|github|manual",
    "ticket_id": "<if applicable>",
    "ticket_url": "<if applicable>"
  },
  "project_context": {
    "name": "<project name>",
    "framework": "<detected>",
    "state_management": "<detected>",
    "component_libraries": [],
    "test_framework": "<detected>",
    "key_directories": {}
  },
  "requirements": {
    "summary": "...",
    "type": "bug_fix|new_feature|enhancement|refactor",
    "description": "...",
    "acceptance_criteria": ["..."],
    "out_of_scope": ["..."],
    "labels": ["..."],
    "design_links": ["..."],
    "linked_issues": []
  },
  "initial_analysis": {
    "likely_directories": ["..."],
    "similar_features": ["..."],
    "potential_dependencies": ["..."],
    "complexity_estimate": "low|medium|high"
  },
  "phase_status": {
    "phase": 1,
    "status": "pending_approval",
    "next_phase": "explore_codebase"
  }
}
```

### Step 8: Present Summary and Request Approval

```
## Requirements Gathered

**Summary:** [title]
**Type:** [type]
**Source:** [JIRA/GitHub/Manual]

### Project Context (Auto-Detected)
- **Framework:** [React/Vue/etc.]
- **State Management:** [Redux/Zustand/etc.]
- **Test Framework:** [Jest/Vitest/etc.]

### Description
[description]

### Acceptance Criteria
1. [criterion 1]
2. [criterion 2]

### Design Links
- [links if any]

### Initial Analysis
- **Likely impact areas:** [directories]
- **Complexity estimate:** [low/medium/high]
```

**Approval prompt:**
```
question: "Do these requirements look correct?"
header: "Approve"
options:
  - label: "Approve & Continue"
    description: "Proceed to Phase 2 (Explore Codebase)"
  - label: "Edit Requirements"
    description: "Modify something"
  - label: "Save & Pause"
    description: "Save and continue later"
  - label: "Cancel"
    description: "Discard and start over"
```

### Step 9: Handle Response

**If "Approve & Continue":**
- Update status to "approved"
- Output: "Requirements approved. Run `/explore-codebase` or `/implement` to continue."

**If "Edit Requirements":**
- Ask what to edit
- Loop back to relevant step
- Re-validate and re-present

**If "Save & Pause":**
- Update status to "paused"
- Output: "Requirements saved. Run `/gather-requirements --resume` to continue."

**If "Cancel":**
- Delete workflow state
- Output: "Workflow cancelled."

---

## Resume Capability

If invoked with `--resume`:
1. Check for `.claude/workflow-state/requirements.json`
2. If exists and paused, load and continue
3. If no saved state, start fresh

---

## Error Handling

| Error | Handling |
|-------|----------|
| JIRA MCP not configured | Ask for cloudId or fall back to manual |
| Ticket not found | Verify ID or use manual input |
| package.json missing | Use generic defaults |
| CLAUDE.md missing | Continue with auto-detection only |

---

## Output

**Primary output:** `.claude/workflow-state/requirements.json`

**Next phase:** Phase 2 (Explore Codebase) via `/explore-codebase`
