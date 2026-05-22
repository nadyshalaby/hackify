# Type: `revamp` or `redesign`

Phase 1 loads this bank for deeper rework where old behavior is being replaced — UI redesign, API redesign, subsystem replacement, framework migration. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use for deeper rework — UI redesign, API redesign, replacing a subsystem, migrating to a new framework. Triggers on patterns like "redesign", "revamp", "rewrite", "replace X with Y", "modernize". Distinguished from `feature` because old behavior is being replaced (not just augmented), and from `refactor` because user-visible behavior IS allowed to change.

**COMPOSITION**

- This bank is standalone — do NOT chain to the `feature` bank. Authoritative questions duplicated here on purpose.
- Always ask Q1 (Goal shape), Q2 (What stays), Q3 (What goes), Q7 (Migration plan), Q8 (Backward compatibility).
- Ask Q4 (Visual reference) if the user prompt contains any of `UI`, `frontend`, `component`, `page`, `layout`, `design`, `visual`, `theme`, `styling`, `redesign`; otherwise skip.
- If the redesign touches a public API, ask Q5 (API impact); else skip.
- Always ask Q6 (Acceptance criteria) — gates Phase 2's DoD section.
- If the project has a brand spec under `docs/`, confirm in the preamble and skip the brand portion of Q4.

**QUESTIONS**

Q1 — Goal shape
- Text: How is the redesign's user-visible goal already specified?
- Header: Goal
- Options:
  - A. Use the prompt verbatim — I'll compress to one sentence (Recommended)
  - B. I'll write a one-sentence goal now in chat
  - C. Goal is ambiguous — propose 2-3 framings and pick one
- Why-this-matters: Determines whether Phase 2's DoD section is auto-derived or waits for user input before drafting.

Q2 — What stays
- Text: What about the current implementation must NOT change?
- Header: Invariants
- Options:
  - A. Nothing flagged — defer to my judgment, confirm at gate (Recommended)
  - B. I'll list invariants now in chat
  - C. Everything is on the table — full rewrite
- Why-this-matters: Captures invariants into the Phase 2 plan and seeds Phase 5's behavior-equivalence reviewer.

Q3 — What goes
- Text: What is explicitly removed or replaced?
- Header: Removed
- Options:
  - A. I'll list removed surfaces now in chat (Recommended)
  - B. Everything not in Q2 is in scope for removal
  - C. Removal list emerges during Phase 2 — flag at gate
- Why-this-matters: Frames the Phase 2 "what we're deleting" section and the Phase 6 communication plan for affected consumers.

Q4 — Visual reference (UI redesigns only)
- Text: What visual reference should the redesign honor?
- Header: Visual ref
- Options:
  - A. Existing brand spec under `docs/` (Recommended)
  - B. Reference mockups / mood — I'll attach now
  - C. No reference — propose 2-3 directions in Phase 2
- Why-this-matters: Loads `references/frontend-design.md` (binding) and determines whether Phase 3 fans out a design exploration sub-agent.

Q5 — API impact
- Text: What is the public-API impact of the redesign?
- Header: API impact
- Options:
  - A. No public API touched (Recommended)
  - B. Backward-compatible additive changes only
  - C. Breaking changes — transition window required
- Why-this-matters: Determines whether Phase 2 emits a deprecation timeline and whether Phase 5 includes a backward-compatibility reviewer.

Q6 — Acceptance criteria
- Text: How should the testable DoD be phrased?
- Header: DoD
- Options:
  - A. I'll draft a one-sentence testable DoD; you confirm at the gate (Recommended)
  - B. You'll dictate the DoD sentence now
  - C. DoD = the new acceptance test plus parity with the old one
- Why-this-matters: Determines whether Phase 2 emits a Definition-of-Done checklist or copies an existing one.

Q7 — Migration plan
- Text: How do existing users / data move from old to new?
- Header: Migration
- Options:
  - A. Big-bang cutover (Recommended)
  - B. Dual-run / shadow the new surface, then cut over
  - C. Phased rollout (feature flag, canary)
  - D. No migration needed — greenfield surface
- Why-this-matters: Drives Phase 2's migration section, Phase 3 data-migration sub-agent dispatch, and Phase 6 rollout plan.

Q8 — Backward compatibility
- Text: Are existing consumers still in flight that the redesign must keep working?
- Header: Back-compat
- Options:
  - A. Yes — transition period required (Recommended)
  - B. No — clean break acceptable
  - C. Unknown — survey consumers in Phase 1
- Why-this-matters: Determines whether Phase 3 emits compatibility shims and whether Phase 5 includes a back-compat reviewer.

**EXIT CRITERIA**

Q1, Q2, Q3, Q6, Q7, Q8 answered (always required); Q4 answered if the redesign is UI-bearing; Q5 answered if a public API is touched; invariants list and migration plan captured in the work-doc. If revamp Q4 indicates a UI-bearing change, the dispatching agent MUST load `references/frontend-design.md` and follow its rules BEFORE drafting the work-doc Approach section. This is binding, not advisory.
