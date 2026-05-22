# Type: `feature`

Phase 1 loads this bank when the user is adding new behavior the system doesn't currently have. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user is adding new behavior the system doesn't currently have — a new endpoint, a new screen, a new role, a new flow, a new entity. Triggers on prompt patterns like "add", "build", "introduce", "ship", "let users do X." Not for changing how existing behavior works (that's `revamp`) or fixing it (that's `fix`).

**COMPOSITION**

- Always ask Q1 (Goal shape) — it determines whether the plan needs a DoD sentence written by us or already supplied.
- If the user's prompt already lists out-of-scope items, skip Q2 (Scope boundary).
- Skip Q3 (Where it lives) and confirm in the preamble if the user prompt explicitly names a concrete file path.
- Always ask Q4 (Data model) and Q5 (Public API) unless the prompt rules them out (e.g. "no DB changes, no new endpoint").
- Skip Q6 (UI surface) if the task is explicitly backend-only or CLI-only.
- Always ask Q7 (Acceptance criteria) — it gates Phase 2's DoD section.
- Always ask Q8 (Edge cases, multi-select) — under-asking here is the most common Phase 5 review failure.

**QUESTIONS**

Q1 — Goal shape
- Text: How is the user-visible goal already specified?
- Header: Goal
- Options:
  - A. Use the prompt verbatim — I'll compress to one sentence (Recommended)
  - B. I'll write a one-sentence DoD now in chat
  - C. Goal is ambiguous — propose 2-3 framings and pick one
- Why-this-matters: Determines whether Phase 2's DoD section is auto-derived or waits for user input before drafting.

Q2 — Scope boundary
- Text: What is explicitly OUT of scope this round?
- Header: Out of scope
- Options:
  - A. Nothing flagged — defer to my judgment, confirm at gate (Recommended)
  - B. I'll list out-of-scope items now in chat
  - C. Build the minimum that satisfies Q1; everything else is out
- Why-this-matters: Sets the Phase 2 plan's "Out of scope" section and prevents scope creep in Phase 3.

Q3 — Where it lives
- Text: Where should the new behavior live in the codebase?
- Header: Location
- Options:
  - A. New module / file (Recommended)
  - B. Extend an existing module
  - C. Cross-module change
- Why-this-matters: Drives the file-creation list in Phase 2 and whether Phase 4 cross-package verification runs.

Q4 — Data model impact
- Text: What is the data-model impact of this feature?
- Header: Data model
- Options:
  - A. No DB / schema changes (Recommended)
  - B. New columns on an existing table (migration acceptable)
  - C. New table / new tenant schema
  - D. Cross-schema change (control + tenant)
- Why-this-matters: Determines whether a migration sub-agent fans out in Wave 2 and whether the expand-then-contract pattern applies.

Q5 — Public API impact
- Text: What is the public-API impact?
- Header: API
- Options:
  - A. No new endpoint (Recommended)
  - B. New endpoint (auth-required by default)
  - C. Modifies an existing endpoint (must stay backward-compatible)
- Why-this-matters: Decides whether OpenAPI/route registration is touched and whether Phase 5 includes a security reviewer pass.

Q6 — UI surface
- Text: What UI surface does this feature need?
- Header: UI surface
- Options:
  - A. No UI — backend/CLI only (Recommended)
  - B. New page or route
  - C. New component embedded in an existing page
  - D. Dialog / modal / inline action
- Why-this-matters: Triggers (or skips) loading `references/frontend-design.md` and the frontend-design sub-agent in Phase 3.

Q7 — Acceptance criteria
- Text: How should the testable DoD be phrased?
- Header: DoD
- Options:
  - A. I'll draft a one-sentence testable DoD; you confirm at the gate (Recommended)
  - B. You'll dictate the DoD sentence now
  - C. DoD = the existing acceptance test passes (point me at it)
- Why-this-matters: Determines whether Phase 2 emits a Definition-of-Done checklist or copies an existing one.

Q8 — Edge cases (multi-select)
- Text: Which edge cases must be explicitly handled? (Pick all that apply.)
- Header: Edge cases
- Options (multiSelect):
  - A. Empty state (Recommended)
  - B. Concurrent writes / race conditions
  - C. Permission denied / unauthenticated
  - D. Network failure / retry semantics
- Why-this-matters: Each selected case becomes a required Phase 3 test case and a Phase 5 review-checklist item.

**EXIT CRITERIA**

Q1, Q4, Q5, Q7, Q8 answered (always required); Q2, Q3, Q6 answered if their COMPOSITION trigger fired; every answer reduced to A/B/C/D semantics (no free-text left ambiguous); DoD sentence captured verbatim in the work-doc preamble.
