---
name: create-rfc
description: Create RFC (Request for Comments) documents from JIRA tickets and code changes. Generates standardized RFC following LambdaTest SDLC process for automatic JIRA ticket creation.
allowed-tools: Read, Write, Bash, AskUserQuestion, Agent, Glob, Grep, WebFetch, mcp__plugin_atlassian_atlassian__getJiraIssue
---

# Create RFC Skill
`
## Purpose

Generate standardized RFC (Request for Comments) documents from JIRA tickets and code changes. The RFC follows LambdaTest's SDLC process and enables automatic JIRA ticket creation when merged.

**Powered by:** LambdaTest SDLC RFC Automation ([Confluence Doc](https://lambdatest.atlassian.net/wiki/spaces/PROD/pages/4941053961))

**Repository:** [github.com/LambdatestIncPrivate/internal-docs](https://github.com/LambdatestIncPrivate/internal-docs)

## Triggers

- `/create-rfc <JIRA-ID>` - Create RFC from JIRA ticket
- `/create-rfc` - Create RFC manually (will ask for details)
- `/create-rfc --from-pr <PR-URL>` - Create RFC from existing PR
- `/create-rfc --validate <path>` - Validate existing RFC file

### Examples

```bash
# Create RFC from JIRA ticket
/create-rfc TE-1812

# Create RFC manually
/create-rfc

# Create from PR (extracts changes and JIRA info)
/create-rfc --from-pr https://github.com/LambdatestIncPrivate/lt-web-platform/pull/264

# Validate RFC before PR
/create-rfc --validate docs/Features-RFC/my-feature.md
```

---

## Prerequisites

- Access to LambdaTest Atlassian (JIRA) via MCP
- Clone of `internal-docs` repository (or will guide to clone)
- JIRA ticket must exist before creating RFC

---

## RFC Template Location

**Template:** `docs/Features-RFC/TEMPLATE.md`

**To create new RFC:**
```bash
cp docs/Features-RFC/TEMPLATE.md docs/Features-RFC/<ticket-id>-<feature-name>.md
```

---

## Required Fields (For RFC Automation)

The following fields are **mandatory** for the automation to work:

| Field | Section | Format |
|-------|---------|--------|
| **JIRA Ticket** | Section 1 - Basic Information | `[TE-XXX](https://lambdatest.atlassian.net/browse/TE-XXX)` |
| **Microservices Affected** | Section 5 | Table with Service, Changes Required, DB Changes |
| **Total Dev Efforts** | Section 6 | `**Total: XX hours**` |

**Optional but Recommended:**
- Service-wise effort breakdown (auto-distributed if not provided)
- DevOps & Infrastructure requirements (triggers Platform Engineering ticket)

---

## Workflow

### Step 1: Determine Input Source

**If JIRA ID provided:**
```
/create-rfc TE-1812
```

1. Fetch JIRA ticket using MCP:
   ```
   mcp__plugin_atlassian_atlassian__getJiraIssue
   cloudId: 3def4f78-101d-4614-9b65-735c17a98a93
   issueIdOrKey: TE-1812
   ```

2. Extract from ticket:
   - Summary
   - Description
   - Issue type (Bug/Task/Story)
   - Priority
   - Labels
   - Components
   - Attachments (design links, screenshots)

**If --from-pr provided:**
1. Extract JIRA ID from PR title/body
2. Get changed files using `gh pr diff`
3. Analyze code changes for context

**If manual mode:**
1. Ask for JIRA ticket ID (required)
2. Ask for feature/bug description
3. Ask for affected services

### Step 2: Analyze Code Changes (If PR or Recent Changes)

If working from a PR or recent git changes:

1. **Get changed files:**
   ```bash
   git diff --name-only HEAD~1
   # OR
   gh pr diff <pr-number> --name-only
   ```

2. **Identify affected services:**
   - Parse file paths to determine services
   - Frontend apps: `apps/hyperexecute`, `apps/mobile-web-client`, etc.
   - Backend services: service names from paths

3. **Analyze change complexity:**
   - Count files changed
   - Count lines added/removed
   - Identify patterns (bug fix, new feature, refactor)

### Step 3: Determine RFC Type

Ask user to confirm type:

```
question: "What type of change is this?"
header: "Type"
options:
  - label: "Bug Fix"
    description: "Fixing existing broken functionality"
  - label: "New Feature"
    description: "Adding new functionality"
  - label: "Enhancement"
    description: "Improving existing functionality (refactor, tech debt, UX)"
```

### Step 4: Collect Required Information

**For Bug Fixes (RCA required):**
```
question: "What was the root cause?"
header: "Root Cause"
options:
  - label: "I'll describe it"
    description: "Provide root cause analysis"
```

Then ask:
- Root cause description (use 5 Whys if possible)
- Customer impact description

**For Features/Enhancements:**
```
question: "What problem are we solving?"
header: "Problem"
options:
  - label: "I'll describe it"
    description: "Provide problem statement"
```

Then ask:
- Problem statement
- Success metrics (optional)

### Step 5: Determine Services and Effort

**Auto-detect from code changes if available:**
- Parse file paths
- Map to service names
- Estimate based on change size

**Or ask user:**
```
question: "What services are affected?"
header: "Services"
options:
  - label: "Frontend only"
    description: "hyperexecute-frontend, mobile-web-client, etc."
  - label: "Backend only"
    description: "API services"
  - label: "Full stack"
    description: "Both frontend and backend"
```

**Effort estimation:**
```
question: "What is the estimated dev effort?"
header: "Effort"
options:
  - label: "2 hours"
    description: "Quick fix"
  - label: "4 hours"
    description: "Small change"
  - label: "8 hours"
    description: "Medium change"
  - label: "Other"
    description: "I'll specify"
```

> **Note:** Valid estimates per service: 2h, 4h, 6h, 8h. Services >8h are auto-split into chunks.

### Step 6: Check Infrastructure Requirements

```
question: "Does this require DevOps/Infrastructure changes?"
header: "DevOps"
options:
  - label: "No"
    description: "No infrastructure changes needed"
  - label: "Yes"
    description: "New CI/CD, env vars, infrastructure, monitoring"
```

If yes, collect details for Section 8.

### Step 7: Generate RFC Document

1. **Create RFC file:**
   ```bash
   cp docs/Features-RFC/TEMPLATE.md docs/Features-RFC/<ticket-id>-<feature-name>.md
   ```

2. **Fill in all sections:**
   - Section 1: Basic Information (author, date, JIRA link)
   - Section 2: Classification (Bug/Feature/Enhancement)
   - Section 3: Context (RCA for bugs, Problem for features)
   - Section 4: Solution Design (architecture, technical details)
   - Section 5: Microservices Affected (table)
   - Section 6: Dev Effort Estimates (total + breakdown)
   - Section 7: Impact Analysis (layers, on-prem)
   - Section 8: DevOps & Infrastructure
   - Section 9: QA Strategy
   - Section 10: Rollout Strategy
   - Section 11: Sign-Offs (TBD placeholders)
   - Section 12: Additional Notes (PR link, files changed)

3. **Add code context:**
   - Include before/after code snippets for bug fixes
   - Include architecture diagrams (mermaid) for features
   - Link to PR if available

### Step 8: Validate RFC

Run validation to ensure required fields are present:

```bash
./scripts/rfc-automation/validate-rfc.sh docs/Features-RFC/<file>.md
```

Check for:
- [ ] JIRA ticket link present and valid format
- [ ] Microservices table has at least one service
- [ ] Total dev effort is specified
- [ ] No TODO placeholders in required fields

### Step 9: Present Summary

```
═══════════════════════════════════════════════════════════════════════════════
RFC CREATED
═══════════════════════════════════════════════════════════════════════════════

**File:** docs/Features-RFC/<ticket-id>-<feature-name>.md
**JIRA:** <JIRA-ID>
**Type:** Bug Fix / New Feature / Enhancement

## Summary
<brief description>

## Services Affected
- <service-1> (Xh)
- <service-2> (Xh)

## Total Effort: XX hours

## What Happens Next

1. Review the RFC file
2. Create PR to `internal-docs` repository
3. PR validation will run automatically
4. On merge → JIRA tickets created automatically:
   - Story Chunks for each service
   - QA Chunks (Dev/Stage/Prod)
   - Platform Engineering chunk (if DevOps work)

## Commands

# Open RFC file
code docs/Features-RFC/<file>.md

# Create PR
cd /path/to/internal-docs
git checkout -b rfc/<ticket-id>
git add docs/Features-RFC/<file>.md
git commit -m "RFC: <ticket-id> - <title>"
git push origin rfc/<ticket-id>
gh pr create --base master
```

### Step 10: Offer Next Steps

```
question: "What would you like to do next?"
header: "Done"
options:
  - label: "Open RFC file"
    description: "View/edit the generated RFC"
  - label: "Create PR"
    description: "Create PR to internal-docs"
  - label: "Validate RFC"
    description: "Run validation script"
  - label: "Done"
    description: "Handle manually"
```

---

## RFC Document Structure

The generated RFC follows this structure:

| Section | Purpose | Required? |
|---------|---------|-----------|
| 1. Basic Information | Author, date, JIRA link, PRD | **Yes** |
| 2. Classification | Bug/Feature/Enhancement type | Yes |
| 3. Context & Problem | RCA or Problem Statement | Yes |
| 4. Solution Design | Architecture, technical details | Yes |
| 5. Microservices Affected | Services table | **Yes** |
| 6. Dev Effort Estimates | Total hours + breakdown | **Yes** |
| 7. Impact Analysis | Layer impact, on-prem | Yes |
| 8. DevOps & Infrastructure | CI/CD, env vars, infra | Optional |
| 9. QA Strategy | Test coverage, test data | Yes |
| 10. Rollout Strategy | Feature flags, phases | Yes |
| 11. Sign-Offs | Approvals | Placeholder |
| 12. Additional Notes | PR links, references | Optional |

---

## JIRA Ticket Creation (On Merge)

When RFC PR is merged to `master`, automation creates:

### Story Chunks (per service)
- Type: `Story Chunk`
- Title: `[service-name] Brief description`
- Estimate: From RFC (max 8h per chunk, auto-split if larger)
- Linked to: Parent JIRA ticket

### QA Chunks (3 per RFC)
- `[PARENT-KEY] Feature - QA Dev Env` (functional testing)
- `[PARENT-KEY] Feature - QA Stage Env` (regression testing)
- `[PARENT-KEY] Feature - QA Prod Env` (smoke testing)

### Platform Engineering Chunk (conditional)
- Created only if DevOps section has actual work items
- Type: `Story Chunk`
- Team: Platform Engineering

---

## Validation Rules

The RFC validation checks:

1. **JIRA Ticket** - Must be valid link format: `[TE-XXX](https://lambdatest.atlassian.net/browse/TE-XXX)`
2. **Microservices Table** - At least one service listed
3. **Total Dev Effort** - Must be specified as `**Total: XX hours**`
4. **No TODO Placeholders** - Required fields cannot have `TODO` markers
5. **Valid Estimates** - Service estimates must be 2, 4, 6, or 8 hours

---

## Formatting Rules (MDX Compatibility)

> **CRITICAL:** RFC files are processed by MDX (Markdown + JSX). Follow these rules to avoid parsing errors.

### DO NOT Use Inside Table Cells:
- `<br>` or `<br/>` tags - MDX cannot parse these in tables
- Any self-closing HTML tags (`<hr/>`, `<img/>`, etc.)
- Multi-line content with line breaks

### Instead, Use These Patterns:

**For multi-item lists in table cells:**
```markdown
<!-- BAD - Will cause MDX error -->
| Impact | Item 1<br>Item 2<br>Item 3 |

<!-- GOOD - Short summary in table, details outside -->
| Impact | Multiple issues affecting performance and UX |

**Impact Details:**
- Item 1
- Item 2
- Item 3
```

**For long content:**
```markdown
<!-- BAD - Long content with line breaks in cell -->
| Root Cause | This is a very long explanation<br>with multiple lines<br>that breaks MDX |

<!-- GOOD - Brief summary, expand below table -->
| Root Cause | Polling mechanism lacks in-flight request tracking |

**Root Cause Details:**
The polling hooks use `setInterval` which fires regardless of whether
the previous API request has completed...
```

### Safe Markdown in Tables:
- **Bold**: `**text**` ✅
- **Inline code**: `` `code` `` ✅
- **Links**: `[text](url)` ✅
- **Simple text**: Plain text ✅

### Unsafe in Tables:
- `<br>`, `<br/>` ❌
- `<hr>`, `<hr/>` ❌
- Multi-line content ❌
- Block-level elements ❌
- Nested lists ❌

---

## Error Handling

### JIRA Not Found
```
JIRA ticket TE-XXXX not found. Please verify the ticket ID.
Options:
1. Enter correct ticket ID
2. Continue with manual input
```

### RFC Already Exists
```
RFC file already exists: docs/Features-RFC/TE-1812-*.md
Options:
1. Overwrite existing
2. Create new with suffix
3. Cancel
```

### Validation Failed
```
RFC validation failed:
- [ ] Missing: Microservices Affected table
- [ ] Missing: Total Dev Effort

Fix these issues and re-validate.
```

### Internal-docs Not Cloned
```
internal-docs repository not found.

Clone it first:
  git clone git@github.com:LambdatestIncPrivate/internal-docs.git

Or specify path:
  /create-rfc TE-1812 --repo-path /path/to/internal-docs
```

---

## Configuration

### Default Paths

| Config | Default | Override |
|--------|---------|----------|
| internal-docs repo | `~/Desktop/Lambdatest Clients/internal-docs` | `--repo-path` |
| RFC template | `docs/Features-RFC/TEMPLATE.md` | - |
| Output directory | `docs/Features-RFC/` | - |
| Atlassian Cloud ID | `3def4f78-101d-4614-9b65-735c17a98a93` | - |

### Service Name Mapping

```json
{
  "apps/hyperexecute": "hyperexecute-frontend",
  "apps/mobile-web-client": "mobile-web-client",
  "apps/magic-leap-dashboard": "magic-leap-frontend",
  "packages/TestPageApp": "test-page-app",
  "services/": "<extract-service-name>"
}
```

---

## Examples

### Bug Fix RFC
```bash
/create-rfc TE-1812
```

Generates RFC with:
- Section 3.1 filled with RCA (5 Whys)
- Before/after code snippets in Section 4
- PR link in Section 12

### New Feature RFC
```bash
/create-rfc TTN-50000
```

Generates RFC with:
- Section 3.2 filled with Problem Statement
- Architecture diagram in Section 4
- Feature flag details in Section 10

### From Existing PR
```bash
/create-rfc --from-pr https://github.com/LambdatestIncPrivate/lt-web-platform/pull/264
```

Auto-extracts:
- JIRA ID from PR title/body
- Changed files and services
- Code diff for technical details

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `/create-rfc <JIRA-ID>` | Create RFC from JIRA ticket |
| `/create-rfc` | Create RFC manually |
| `/create-rfc --from-pr <url>` | Create RFC from PR |
| `/create-rfc --validate <path>` | Validate RFC file |

---

## Notes

1. **JIRA Ticket Required** - RFC must reference an existing JIRA ticket
2. **One RFC per Ticket** - Each JIRA ticket should have one RFC
3. **Don't Modify Template** - `TEMPLATE.md` is the base, don't edit it directly
4. **Valid Estimates Only** - Use 2, 4, 6, or 8 hours per service
5. **Merge to Master** - PRs to `master` branch trigger automation
