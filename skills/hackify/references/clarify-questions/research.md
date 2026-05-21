# Type: `research`

Phase 1 loads this bank when the user wants to explore or evaluate an idea before committing to build it — feasibility studies, architecture trade-offs, library comparisons. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user wants to discuss or explore an idea before committing to build it — feasibility studies, architecture trade-off comparisons, library evaluations, "is X possible?" Triggers on patterns like "research", "explore", "evaluate", "compare X vs Y", "should we...". The Phase 2 gate is reframed from "approve the plan to build" to "approve the conclusions and whether to build."

**COMPOSITION**

- Always ask Q1 (Question shape) — research with no testable question produces no testable answer.
- Always ask Q2 (Decision it informs) — if no decision rides on the answer, the research is theatre.
- Always ask Q3 (Depth) — sets the time-box and deliverable shape.
- Always ask Q4 (Output) — determines where conclusions land.
- Always ask Q5 (Continuation) — sets Phase 6's exit (auto-roll into build vs. pause for user decision).

**QUESTIONS**

Q1 — Question shape
- Text: How is the research question already specified?
- Header: Question
- Options:
  - A. Single testable question — I'll compress the prompt to one sentence (Recommended)
  - B. You'll dictate the question now in chat
  - C. Several open threads — propose a question hierarchy
- Why-this-matters: Sets the Phase 2 plan's "Question under investigation" line and gates whether sub-questions fan out into parallel research agents.

Q2 — Decision it informs
- Text: What decision will we make differently based on the answer?
- Header: Decision
- Options:
  - A. Build vs. don't build a specific feature (Recommended)
  - B. Pick one of several already-named approaches
  - C. Sizing / scoping a future work-doc
- Why-this-matters: Frames Phase 2's Approach section and what the Phase 6 conclusions report must contain.

Q3 — Depth
- Text: How deep should the research go?
- Header: Depth
- Options:
  - A. Quick sketch — 1-2 hours, no code (Recommended)
  - B. Spike — minimal prototype on a throwaway branch
  - C. Full investigation — multiple options compared with evidence
- Why-this-matters: Sets the Phase 1 time-box, whether a sandbox worktree is created, and how many parallel research sub-agents fan out.

Q4 — Output
- Text: Where should the conclusions land?
- Header: Output
- Options:
  - A. Markdown summary in the work-doc only (Recommended)
  - B. Markdown summary plus a spike branch
  - C. Markdown summary plus a follow-up build work-doc draft
- Why-this-matters: Determines whether Phase 6 commits a spike branch and whether a follow-up work-doc is scaffolded.

Q5 — Continuation
- Text: After the conclusions land, what happens next?
- Header: Continuation
- Options:
  - A. Pause and let you decide whether to build (Recommended)
  - B. If the answer is "yes, build", auto-roll into a `feature` doc
  - C. Hand off to another person / team
- Why-this-matters: Sets Phase 6's exit (pause vs. auto-dispatch a new `feature` work-doc) and the handoff format if applicable.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5 all answered; question sentence captured verbatim in the work-doc preamble; decision-it-informs captured in the Approach section; depth time-box recorded so Phase 1 has a hard checkpoint; Phase 2 gate framed as "approve the conclusions and whether to build" (not "approve the plan to build").
