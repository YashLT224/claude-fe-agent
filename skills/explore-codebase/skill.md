---
name: explore-codebase
description: Explore a frontend repository for task-relevant architecture, reusable patterns, component and state conventions, and similar implementation examples. Use during feature planning or before implementing a non-trivial change.
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Explore Codebase Skill (Phase 2)

## Description
Deep codebase exploration using parallel agents. Auto-detects project structure and patterns to build comprehensive understanding before implementation.

**Memory-Aware:** If project memory exists (from `/remember`), loads cached context first and only scans for feature-specific details.

## Triggers
- User invokes `/explore-codebase`
- Called by `/implement` orchestrator after Phase 1
- User says "explore the codebase" or "understand the code"

## Prerequisites
- Phase 1 complete: `requirements.json` exists with status "approved"

---

## MEMORY-FIRST APPROACH

### Before Full Scan, Check for Cached Memory

```
Step 0: Check Project Memory
─────────────────────────────
1. Get project name from current directory
2. Check ~/.claude/memory/projects/<project-name>/context.json
3. If exists and fresh:
   - Load cached tech_stack, directories, patterns, architecture
   - Skip Agents 2 & 3 (already know structure & patterns)
   - Only run Agent 1 (find similar features for THIS specific task)
   - Time: ~30 seconds vs 3-5 minutes

4. If not exists or stale:
   - Run full exploration (all 3 agents)
   - Optionally save to memory after completion
```

### With Memory (Fast Path)
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Load Memory    │ ──▶ │  Agent 1 Only   │ ──▶ │  Combine with   │
│  (cached)       │     │  Similar        │     │  cached context │
│  ~0.5 sec       │     │  Features       │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Without Memory (Full Scan)
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  No cache       │ ──▶ │  All 3 Agents   │ ──▶ │  Full synthesis │
│                 │     │  in parallel    │     │  + save memory  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## PARALLEL AGENT ARCHITECTURE

```
═══════════════════════════════════════════════════════════════════════════════
Phase 2 launches 3 PARALLEL exploration agents
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXPLORE-CODEBASE SKILL                               │
│                    (Orchestrates agents, synthesizes results)                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  AGENT 1        │     │  AGENT 2        │     │  AGENT 3        │
│  Similar        │     │  Architecture   │     │  Patterns &     │
│  Features       │     │  & Flow         │     │  Conventions    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                          │                          │
         └──────────────────────────┼──────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │  COMBINE & SYNTHESIZE     │
                    │  Read key files           │
                    │  Write exploration.json   │
                    └───────────────────────────┘
```

---

## Workflow

### Step 1: Load Prerequisites

1. **Load requirements**
   - Read `.claude/workflow-state/requirements.json`
   - Extract: summary, type, acceptance criteria, project_context

2. **Load project context from requirements**
   ```json
   {
     "framework": "<from requirements>",
     "state_management": "<from requirements>",
     "key_directories": "<from requirements>",
     "keywords": ["<extracted from description>"]
   }
   ```

3. **Read CLAUDE.md if exists**
   - Extract any additional project conventions
   - Note documented patterns

### Step 2: Launch Parallel Exploration Agents

**CRITICAL: Launch ALL agents in a SINGLE message**

#### Agent 1: Similar Features Explorer

```
Agent tool parameters:
  description: "Find similar features"
  subagent_type: "Explore"
  run_in_background: true
  prompt: |
    GOAL: Find features similar to "[feature_summary]" in this codebase.

    CONTEXT:
    - Feature: [feature_summary]
    - Type: [feature_type]
    - Framework: [framework]
    - Keywords: [keywords]

    INSTRUCTIONS:
    1. Search for components/features with similar functionality
    2. For EACH similar feature found:
       - Trace the complete implementation flow
       - Note file structure and organization
       - Identify patterns (state management, API calls, UI patterns)
       - Document error handling approach
    3. Look in these directories first: [key_directories]

    OUTPUT FORMAT (JSON):
    {
      "similar_features": [
        {
          "name": "<feature name>",
          "location": "<main file/directory>",
          "description": "<what it does>",
          "implementation_pattern": "<how it's implemented>",
          "key_files": ["<5-10 most important files>"],
          "patterns_used": ["<patterns identified>"],
          "relevance": "<why relevant to our feature>"
        }
      ],
      "common_patterns": ["<patterns shared across features>"],
      "recommended_approach": "<based on findings>"
    }
```

#### Agent 2: Architecture & Flow Explorer

```
Agent tool parameters:
  description: "Map architecture"
  subagent_type: "Explore"
  run_in_background: true
  prompt: |
    GOAL: Map the architecture and data flow relevant to "[feature_summary]".

    CONTEXT:
    - Feature: [feature_summary]
    - Framework: [framework]
    - State Management: [state_management]

    INSTRUCTIONS:
    1. Identify architectural layers:
       - UI/Component layer
       - State management layer
       - API/Service layer
       - Utility layer
    2. Trace data flow from user action to backend and back
    3. Map key abstractions (components, hooks, stores, services)
    4. Identify where new code would integrate

    OUTPUT FORMAT (JSON):
    {
      "architecture": {
        "layers": [
          {
            "name": "<layer name>",
            "purpose": "<what this layer does>",
            "key_files": ["<files>"],
            "patterns": ["<patterns used>"]
          }
        ],
        "data_flow": "<description>",
        "integration_points": ["<where new code connects>"]
      },
      "key_abstractions": [
        {
          "name": "<name>",
          "type": "<component|hook|store|service|utility>",
          "file": "<path>",
          "purpose": "<what it does>"
        }
      ],
      "key_files": ["<5-10 most important files>"]
    }
```

#### Agent 3: Patterns & Conventions Explorer

```
Agent tool parameters:
  description: "Analyze patterns"
  subagent_type: "Explore"
  run_in_background: true
  prompt: |
    GOAL: Identify coding patterns, conventions, and reusable code for "[feature_summary]".

    CONTEXT:
    - Feature: [feature_summary]
    - Framework: [framework]
    - Component Libraries: [component_libraries]

    INSTRUCTIONS:
    1. Analyze coding conventions:
       - File naming patterns
       - Component structure patterns
       - Import organization
       - Error handling patterns
    2. Identify UI patterns:
       - Component composition
       - Styling approach (CSS modules, styled-components, Tailwind, etc.)
       - Form handling
       - Loading/error states
    3. Find testing patterns:
       - Test file organization
       - Testing utilities
       - Mocking approaches
    4. Identify reusable utilities, hooks, components

    OUTPUT FORMAT (JSON):
    {
      "coding_conventions": {
        "file_naming": "<pattern>",
        "component_structure": "<pattern>",
        "imports": "<pattern>",
        "error_handling": "<pattern>"
      },
      "ui_patterns": [
        {
          "pattern": "<name>",
          "example_file": "<path>",
          "description": "<how it works>"
        }
      ],
      "styling_approach": "<css modules|styled-components|tailwind|scss|etc>",
      "testing_patterns": {
        "organization": "<how tests organized>",
        "utilities": ["<available>"],
        "example_files": ["<good examples>"]
      },
      "reusable_code": [
        {
          "name": "<name>",
          "file": "<path>",
          "type": "<hook|utility|component>",
          "purpose": "<what it does>",
          "how_to_use": "<usage pattern>"
        }
      ],
      "key_files": ["<5-10 pattern examples>"]
    }
```

### Step 3: Wait for All Agents

```
For each agent task_id:
  TaskOutput:
    task_id: "<agent task id>"
    block: true
    timeout: 120000
```

**Handle failures:**
- If agent times out, log and continue with others
- If all fail, fall back to manual exploration

### Step 4: Combine Key Files

1. Collect all key_files from all agents
2. Deduplicate
3. Prioritize (files mentioned by multiple agents first)
4. Limit to ~20 files max

### Step 5: Read Key Files

For each key file:
1. Read file contents
2. Note:
   - Exports and interfaces
   - Key functions/components
   - Patterns used
   - Relevance to feature

### Step 6: Synthesize Findings

Combine all results into comprehensive summary:

```
## Exploration Summary

### Project Overview
- Framework: [detected]
- State Management: [detected]
- Styling: [detected]
- Testing: [detected]

### Similar Features Found
[From Agent 1]

### Architecture Understanding
[From Agent 2]
- Layers: [list]
- Data flow: [description]
- Integration points: [list]

### Patterns & Conventions
[From Agent 3]
- Coding conventions: [summary]
- UI patterns: [list]
- Reusable code: [list]

### Key Files (Read)
[List with brief purpose]

### Recommendations
- Suggested approach
- Patterns to follow
- Potential challenges
```

### Step 7: Present and Get Approval

```
═══════════════════════════════════════════════════════════════════════════════
PHASE 2: CODEBASE EXPLORATION COMPLETE
═══════════════════════════════════════════════════════════════════════════════

[Display summary]

### Key Insights
1. [Most important]
2. [Second]
3. [Third]
```

**Approval prompt:**
```
question: "Does this understanding look correct?"
header: "Explore"
options:
  - label: "Approve & Continue"
    description: "Proceed to decide approach"
  - label: "Explore more"
    description: "Explore additional areas"
  - label: "Read specific files"
    description: "Read files I'll specify"
  - label: "Clarify findings"
    description: "Some findings need discussion"
```

### Step 8: Write Output

Save to `.claude/workflow-state/exploration.json`:

```json
{
  "metadata": {
    "workflow_id": "<from requirements>",
    "phase": 2,
    "created_at": "<timestamp>",
    "agents_used": 3
  },
  "project_context": {
    "framework": "<detected>",
    "state_management": "<detected>",
    "styling_approach": "<detected>",
    "test_framework": "<detected>",
    "component_libraries": []
  },
  "agent_results": {
    "similar_features": {},
    "architecture": {},
    "patterns": {}
  },
  "key_files_read": [
    {
      "path": "<path>",
      "purpose": "<why important>",
      "key_exports": [],
      "patterns_used": []
    }
  ],
  "synthesis": {
    "understanding_summary": "<high-level>",
    "patterns_to_follow": [],
    "reusable_code": [],
    "integration_points": [],
    "potential_challenges": [],
    "recommendations": []
  },
  "phase_status": {
    "status": "approved",
    "next_phase": "decide_approach"
  }
}
```

---

## Output

**Primary output:** `.claude/workflow-state/exploration.json`

**Next phase:** Phase 3 (Decide Approach) via `/decide-approach`
