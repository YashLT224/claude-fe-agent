---
name: visual-check
description: Verify frontend UI changes in a real browser at desktop and mobile sizes, checking layout, interactions, console errors, and basic accessibility behavior.
---

# Visual Check

Verify rendered UI rather than treating compilation as completion.

## Input

Identify the affected URL or route, changed states such as loading/empty/error
or open/disabled, and the local start command if the app is not already
running. Ask one concise question only if these cannot be discovered.

## Flow

1. Use an existing local server or start the detected development command.
2. Use `kane-cli` as this toolkit's browser engine. Run `kane-cli whoami`
   before the first check; if authentication is missing, request login before
   attempting verification.
3. Open a visible browser by default with:

   ```bash
   kane-cli run "<route, states, interactions, and assertions>" --agent --timeout 120
   ```

   Do not pass `--headless` unless the user explicitly requests background
   verification.
4. Verify at one desktop and one narrow mobile viewport.
5. Exercise changed interactions and states.
6. Inspect relevant console errors and failed resources/API calls.
7. Capture screenshots when documenting defects or significant UI completion.

## Checklist

- No overlapping, clipped, blank, or unintentionally overflowing content.
- Text fits its controls and containers.
- Desktop and mobile layouts remain usable.
- Changed loading, empty, error, disabled, focus, and open states render.
- Changed controls work with keyboard interaction.
- Icon actions have names and form fields have labels.
- The result is visually consistent with existing components and tokens.

## Output

Report routes/states verified, viewports checked, pass/fail result, and any
specific defect. During implementation work, send defects back for correction
and re-check; during review-only work, do not silently edit.
