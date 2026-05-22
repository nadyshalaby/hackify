# Type: `refactor`

Phase 1 loads this bank when behavior should NOT change but structure should — moving, renaming, extracting, deduplicating, restoring layer boundaries. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when behavior should NOT change but structure should — moving code, renaming, extracting, deduplicating, restoring layer boundaries, prepping for an upcoming feature. Triggers on patterns like "clean up X", "extract Y", "consolidate Z", "this is getting messy", "prep for...". Not for user-visible changes (that's `feature` or `revamp`).

**COMPOSITION**

- Always ask Q1 (Driver) — drives the Phase 2 plan narrative.
- Always ask Q2 (Behavior contract) — the central refactor invariant. If the user names exceptions in the prompt, present them as confirmation.
- If the prompt names the scope (one file, one module, cross-project), skip Q3 (Scope).
- Always ask Q4 (Test coverage) — gates whether a "write tests first" sub-phase is inserted.
- Always ask Q5 (Migration shape) — determines whether Phase 2 plans a single PR or a staged rollout.
- If the user's prompt cites an exemplar module to mimic, skip Q6 (Pattern reference) and link it in the preamble.

**QUESTIONS**

Q1 — Driver
- Text: What problem is this refactor solving?
- Header: Driver
- Options:
  - A. Reduce tech debt / improve readability (Recommended)
  - B. Prep the code for an upcoming feature
  - C. Performance or scalability win
  - D. Restore a violated layer / architectural boundary
- Why-this-matters: Frames the Phase 2 plan narrative and selects the Phase 5 reviewer focus (quality vs. performance vs. layering).

Q2 — Behavior contract
- Text: Is any user-visible behavior allowed to change?
- Header: Behavior
- Options:
  - A. No — pure refactor, zero observable change (Recommended)
  - B. Yes — list allowed changes now in chat
- Why-this-matters: Determines whether Phase 5 includes a behavior-equivalence reviewer and whether Phase 3 runs a before/after snapshot test.

Q3 — Scope
- Text: How wide is the refactor's blast radius?
- Header: Scope
- Options:
  - A. Single module (Recommended)
  - B. Multiple modules in one project
  - C. Cross-project (backend + frontend)
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and whether more than one Wave 2 agent fans out.

Q4 — Test coverage
- Text: Is there enough existing test coverage to refactor safely?
- Header: Coverage
- Options:
  - A. Yes — coverage is sufficient, proceed (Recommended)
  - B. No — add characterization tests first as a sub-phase
  - C. Unknown — run a coverage check before deciding
- Why-this-matters: Inserts a "write tests first" sub-phase in Phase 2 when B/C are selected; gates Phase 3 entry.

Q5 — Migration shape
- Text: How should the refactor land?
- Header: Migration
- Options:
  - A. Big-bang single PR (Recommended)
  - B. Staged with shim + deprecation
  - C. Feature-flagged rollout
- Why-this-matters: Determines Phase 6 release shape and whether deprecation comments are emitted in Phase 3.

Q6 — Pattern reference
- Text: Is there an existing module that already shows the target shape?
- Header: Exemplar
- Options:
  - A. Yes — I'll link it now in chat (Recommended)
  - B. No — propose 2-3 candidate shapes in Phase 2
- Why-this-matters: Phase 2 mimics the linked exemplar verbatim; without one, Phase 2 spends time deriving the shape.

**EXIT CRITERIA**

Q1, Q2, Q4, Q5 answered (always required); Q3, Q6 answered if their COMPOSITION trigger fired; behavior-contract decision and migration shape captured in the work-doc; if Q4 = B, the work-doc Tasks list opens with a "write characterization tests" task before any structural change.
