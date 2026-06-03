---
name: revise-memory
description: Track feature development progress across sessions. Creates and updates feature memory files organized by product with backend and frontend context sections.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
user-invocable: true
arguments: feature-name
---

# Revise Memory Skill

## Purpose
Maintains persistent feature-level memory for long-running feature development. Organized by product (auto-detected from current working directory) with separate backend and frontend sections per feature.

## Usage
```
/revise-memory <feature-name>
```

**Examples:**
```
/revise-memory wcag-scanner
/revise-memory dashboard-redesign
/revise-memory audit-reports
```

---

## Memory Location

```
~/Desktop/Lambdatest Clients/memory/
└── <product>/                          # e.g., accessibility, automation
    └── <feature-name>.md               # e.g., wcag-scanner.md
```

---

## Execution Steps

### Step 1: Parse Arguments

Extract `<feature-name>` from the command arguments. The feature name is REQUIRED.

If no feature name is provided, ask the user:
> "What feature are you working on? Give me a short name (e.g., wcag-scanner, dashboard-redesign)"

### Step 2: Detect Product

Determine the product from the current working directory path.

Look for the product folder name under `~/Desktop/Lambdatest Clients/`:
```
Current dir: ~/Desktop/Lambdatest Clients/accessibility/lambda-accessibility-service
Product: accessibility

Current dir: ~/Desktop/Lambdatest Clients/automation/some-repo
Product: automation
```

**Logic:**
```
1. Get current working directory
2. Find the path segment immediately after "Lambdatest Clients/"
3. That segment is the product name
4. If cannot determine, ask the user: "Which product is this feature for?"
```

### Step 3: Check Memory Structure

```
MEMORY_BASE = ~/Desktop/Lambdatest Clients/memory
PRODUCT_DIR = $MEMORY_BASE/<product>
FEATURE_FILE = $PRODUCT_DIR/<feature-name>.md
```

1. Check if `$MEMORY_BASE` exists → if not, create it
2. Check if `$PRODUCT_DIR` exists → if not, create it
3. Check if `$FEATURE_FILE` exists → determines UPDATE vs CREATE flow

### Step 4A: CREATE Flow (Feature file does not exist)

Ask the user a series of questions to populate the feature memory:

**Question 1:** "Give me a brief description of this feature — what does it do?"

**Question 2:** "What's the current status? What has been done so far?"

**Question 3:** "What repos/services are involved? (I detected you're in `<current-repo>`)"

**Question 4:** "Any key decisions, API contracts, or important context I should remember?"

Then create the feature file with this template:

```markdown
# Feature: <feature-name>
**Product:** <product>
**Created:** <date>
**Last Updated:** <date>
**Status:** In Progress

## Overview
<user's description>

## Repos Involved
- **Backend:** <detected or user-provided>
- **Frontend:** <detected or user-provided>

---

## Backend Context

### What's Done
<from user input>

### Key Files
<list important files/paths discovered>

### API Contracts
<any API endpoints, request/response formats>

### Decisions & Notes
<architectural decisions, trade-offs>

---

## Frontend Context

### What's Done
<from user input>

### Key Files
<list important files/paths discovered>

### Component Structure
<key components involved>

### Decisions & Notes
<UI decisions, state management approach>

---

## Current State
<what's the current state of development>

## Next Steps
<what needs to be done next>

## Open Questions
<any unresolved questions or blockers>
```

### Step 4B: UPDATE Flow (Feature file already exists)

1. Read the existing feature file
2. Display a summary to the user:
   > "Here's what I have for **<feature-name>**:"
   > (show key sections summary)

3. Ask the user:
   > "What should I update? You can tell me about:
   > - New progress (backend/frontend)
   > - New decisions or changes
   > - Updated next steps
   > - Any new context"

4. Based on user input:
   - Update the relevant sections in the feature file
   - Update the `Last Updated` date
   - Update the `Status` if needed
   - Preserve all existing content that wasn't explicitly changed
   - Append new information to existing sections rather than overwriting

5. Also scan the current repo for recent changes to enrich the update:
   - Run `git log --oneline -10` to see recent commits
   - Run `git diff --stat HEAD~5` to see recently changed files
   - Cross-reference with the feature memory to add any new key files

### Step 5: Confirm

After creating/updating, display the result:

```
=========================================
FEATURE MEMORY: <feature-name>
Product: <product>
Status: <status>
Last Updated: <date>
=========================================

Saved to: ~/Desktop/Lambdatest Clients/memory/<product>/<feature-name>.md

Sections updated:
- <list of sections that changed>
```

---

## Auto-Context Loading

When starting ANY session in a product directory, check if feature memories exist:

```
1. Detect product from current directory
2. Check ~/Desktop/Lambdatest Clients/memory/<product>/
3. If feature files exist, list them:
   "Found feature memories for <product>: <feature-1>, <feature-2>"
   "Run /revise-memory <name> to load or update"
```

---

## Tips for Users

- Run `/revise-memory <feature>` at the **end of a session** to save progress
- Run `/revise-memory <feature>` at the **start of a session** to load context
- Keep feature names short and kebab-case: `wcag-scanner`, `audit-reports`
- One feature file per feature — don't create duplicates
