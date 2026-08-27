# Goal anchor (Primary Goal & Guardrails)

The **Primary Goal & Guardrails** anchor is the north-star that drives every plan and implementation decision for a task. It is captured once in Phase 1, persisted in the work-doc, and enforced by a drift-check in Phase 2.5 and Phase 5. Its job is to convert a fuzzy ask into a fixed target so no later phase silently wanders off it.

Load this file from Phase 1 (to capture the anchor), the Phase 2.5 spec reviewer, and Phase 5 Reviewer B (to enforce it).

## The anchor shape

Five sub-parts. Keep each tight, this is a decision record, not an essay.

- **North-Star Goal**, one sentence naming the single outcome the task commits to. If you cannot state it in one sentence, Phase 1 is not done.
- **In-Scope**, the bullets of work this task WILL do. The boundary of the change.
- **Out-of-Scope / Non-Goals**, the bullets this task will explicitly NOT do. The tempting-but-excluded work. A change that does one of these is drift.
- **Guardrails / Invariants**, the properties the solution must never violate (a passing test suite, a security boundary, a public API contract, a size cap). Breaking one is a Critical defect.
- **Success Signals**, how we will know the goal is met: the concrete, observable proofs Phase 4 will paste.

## Phase 1 capture (grooming)

Phase 1 is a grooming session, not a formality. Its exit condition is a complete anchor, and the batched wizard keeps asking until every sub-part is pinned.

**Coverage checklist, do not leave Phase 1 until all five are settled:**

- [ ] North-Star Goal stated in one sentence and confirmed by the user.
- [ ] In-Scope boundary enumerated.
- [ ] Out-of-Scope / Non-Goals named (ask "what should I explicitly NOT touch?").
- [ ] Guardrails / Invariants listed (existing behavior that must survive, caps, contracts).
- [ ] Success Signals agreed (what proof closes the task).

**Question budget.** The ~16-question soft target is a target, not a ceiling. Raise it whenever understanding is still incomplete, maximum task understanding before any code beats a fast, wrong start. Strip only questions already answered by the ask, the exploration, or `CLAUDE.md`. Every question must fork a real decision (branches lead to different plans, code, or acceptance), never ask a vanity question to pad the count.

## Persistence

- **Full hackify + any run with a work-doc**, write the anchor into the work-doc `## Primary Goal & Guardrails` section (see [work-doc-template.md](work-doc-template.md)). It sits directly under `## 1. Original ask`.
- **quick (no persisted work-doc)**, keep the anchor as an in-chat block and restate its North-Star Goal + top Non-Goal at the top of each phase so drift is visible even without a file.

## Enforcement (the drift-check)

The anchor has teeth. Work is traced back to it at three points.

- **The Phase 2.5 spec reviewer (consistency lens)**, trace every Sprint Backlog task and every Acceptance-Criteria bullet to the anchor.
- **Phase 4 Layer 2 (goal-drift re-check)**, trace every Evidence Ledger proof to the North-Star Goal and the Success Signals; a Success Signal with no proving row means the goal is not met yet ([review-and-verify.md](review-and-verify.md)).
- **Phase 5 Reviewer B (plan-consistency lens)**, trace every changed hunk in the diff to the anchor.

**Verdicts (identical wording in both reviewers):**

- A task / hunk that serves no In-Scope bullet and is not required by one → **drift finding (Important)**: justify it against the anchor or revert it.
- A task / hunk that violates a Guardrail or does something a Non-Goal excludes → **Critical**.

A clean pass means every unit of work traces to an In-Scope bullet and no unit violates a Guardrail or Non-Goal.

### The fourth point: an evaluator that is not you

The three points above are all self-checks, the workflow grading its own work. The **completion sentinel** ([orchestration.md](orchestration.md)) adds a fourth that is not: the anchor's Success Signals are distilled into one ≤500-character condition, printed as a paste-ready `/goal <condition>` line, and re-checked after every turn by an evaluator outside this conversation.

Distilling is the skill. The anchor lists every signal; the sentinel names only the **exit artifact** that cannot be true unless the signals are. Prefer files, exit codes and artifacts over adjectives: `docs/work/done/<date>-<slug>.md exists with status: done` is rulable, "the refactor is complete" is not. Print the line; only the user can set it, and only the user clears it (`/goal clear`). Never propose one from a subagent, and never soften a condition later to make it pass.

## See also

- [work-doc-template.md](work-doc-template.md), the `## Primary Goal & Guardrails` section skeleton.
- [parallel-agents/phase-2.5-spec-reviewer.md](parallel-agents/phase-2.5-spec-reviewer.md). Phase 2.5 drift-check.
- [parallel-agents/phase-5-multi-review-b-quality-plan.md](parallel-agents/phase-5-multi-review-b-quality-plan.md). Reviewer B drift-check.
- [clarify-questions/universal-preamble.md](clarify-questions/universal-preamble.md), the Phase 1 goal-anchor question.
- [orchestration.md](orchestration.md), the completion sentinel this anchor's Success Signals distil into, plus who wins when it and the iteration driver disagree.
