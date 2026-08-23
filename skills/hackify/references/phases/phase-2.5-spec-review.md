# Phase 2.5, Spec self-review (parallel, mandatory)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Catch inconsistent or conflicting logic in the work-doc *before* code is written. Cheap on paper; expensive after 200 LOC against a flawed spec.

**First line of this turn, print the completion sentinel.** Sign-off just landed, so this is the first turn where a finish line can be stated and the first where the native tool is not blocked by plan mode. Emit one fenced `/goal <condition>` line (≤500 chars) naming the archived work-doc plus the green triad and the ship-gate rows, so an evaluator outside this conversation can rule on "done" instead of you. **You print it; only the user can set it**, so never claim a goal is active, never propose one from a subagent, never wait on the answer, and never soften the condition later to make it pass. Shape, the per-mode wording, and who wins when the sentinel and the iteration driver disagree: [references/orchestration.md](../orchestration.md).

**Ledger, at phase open.** Right after the sentinel, set `Phase 2.5. Spec review (1 reviewer, patch the doc)` to in-progress and re-print the whole ledger block. Never open it while `Phase 2. Plan + Gate` is still open. Contract: [../phase-ledger.md](../phase-ledger.md).

1. **Dispatch 2 foreground reviewers in parallel in ONE message.** Each gets a self-contained prompt + absolute work-doc path:
   - **Reviewer A. Internal consistency + goal drift, AND the execution plan.** Two lenses over one read of the doc, because the planning lens used to be a third agent (Reviewer C) whose read set was a strict subset of this one's.
     - *Consistency.* Read work-doc end-to-end. Find Q&A↔DoD↔Approach↔Sprint Backlog contradictions. Flag tasks not covered by any DoD bullet, DoD bullets not covered by any task, Q&A answers contradicting the Approach. **Drift-check:** trace every Sprint Backlog task + DoD bullet to the Primary Goal & Guardrails anchor, a task serving no In-Scope bullet → **drift (Important)**; one violating a Guardrail or Non-Goal → **Critical** (canonical wording: [references/goal-anchor.md](../goal-anchor.md)).
     - *Execution plan.* Build a dependency graph from the per-task file lists it extracted on that same read. Emit the topological wave plan and the per-wave dispatch batches. Flag tasks sharing a file (parallel conflict), missing prerequisites, ordering bugs (consuming a helper before its task), tasks too coarse to be 5-30 min.
     - **Its report leads with the wave plan and the dispatch batches**, so a truncated report still carries what Phase 3 consumes.
   - **Reviewer B. Architectural / cross-cutting risks.** Match plan against project code-quality rules, if a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md`. Flag anything that would force a lint suppression, `!`, inline type, bare `Error` throw, or layering violation. Also flag plan-time performance risk: a plan item that would bake in a `rules/performance.md` Critical before code exists, an N+1-shaped task, unbounded fan-out, a list endpoint with no pagination.

**The letter C is retired, not reassigned.** A future third spec lens takes the next free letter, so a work-doc or transcript naming "Reviewer C" always means the merged planning lens and never something new.
2. **Aggregate findings.** Critical (plan bug forcing rework) / Important (fixable gap) / Minor (nit).
3. **Patch the work-doc.** Apply Critical + Important in place; record Minor in Retrospective.
4. **Re-gate ONLY if user's signed-off invariants changed** (Critical finding widened scope). Else straight to Phase 3.

Template: `references/parallel-agents/phase-2.5-spec-reviewer.md` (subdir index: `references/parallel-agents/README.md`). **Hard rule:** Phase 2.5 is non-skippable, even for small docs, a "small" plan can hide a contradictory Q&A pair. Cap the report at ≤900 words, the sum of the three lenses it carries; its wave plan and dispatch batches are enumerations and sit outside that budget.

**Ledger, at phase exit.** The reviewer report is aggregated and every Critical + Important finding is patched into the doc first, then one line of reflection (what changed, did it pass, what is next), then tick `Phase 2.5. Spec review` and open `Phase 3. Implement (all waves committed)`. A finding class that genuinely does not apply is recorded with a one-line reason, never dropped in silence.
