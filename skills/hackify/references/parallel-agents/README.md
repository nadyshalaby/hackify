# Parallel Agents (File Map)

This directory replaces the former single-file `skills/hackify/references/parallel-agents.md` (1783 LOC, over the 500-LOC hard cap). Each file below is independently loadable; the canonical 7-section sub-agent contract lives once in `template-contract.md` and the per-phase template files reference it.

| File | What's inside | When to load |
|---|---|---|
| `template-contract.md` | Fan-out decision matrix (when to / when not to), dispatch pattern, the canonical 7-section sub-agent contract, the framework citation allowlist, the placeholder convention, the VERIFICATION shape picker. | Always, before authoring or auditing any per-phase dispatch. |
| `phase-1-research.md` | Sub-agent prompt for one Phase 1 parallel research agent (read-only `Explore` subagent type). | Phase 1 clarification when fanning out one or more research questions in a single message. |
| `phase-2.5-spec-review-a-consistency.md` | Sub-agent prompt for reviewer A (internal consistency lens). | Phase 2.5 spec-review wave (fire A+B+C in one message). |
| `phase-2.5-spec-review-b-rules.md` | Sub-agent prompt for reviewer B (architectural / cross-cutting risks lens). | Phase 2.5 spec-review wave. |
| `phase-2.5-spec-review-c-dependencies.md` | Sub-agent prompt for reviewer C (dependency / ordering / parallelism lens). | Phase 2.5 spec-review wave. |
| `phase-3-implementation.md` | Sub-agent prompt for one Phase 3 implementer per task, plus the post-wave aggregation steps (`After all wave agents return`). | Every Phase 3 wave (one agent per task, all in one message). |
| `phase-3b-debug-evidence.md` | Sub-agent prompt for one Phase 3b debug-evidence agent (read-only by default). | Phase 3b investigations on multi-component bugs. |
| `phase-4-cross-package-verification.md` | Sub-agent prompt for one Phase 4 verification agent (faithful test + lint + typecheck exit-code reporting per project root). | Phase 4 verification when one or more independent project roots must be checked in parallel. |
| `phase-5-multi-review.md` | Sub-agent prompts for the four Phase 5 reviewers inline (A = security & correctness; B = quality & layering; C = plan consistency & scope; D = performance) plus the 5th-reviewer note (cap 5). | Phase 5 multi-reviewer wave on non-trivial diffs. |
| `phase-5-multi-review-e-design.md` | Sub-agent prompt for reviewer E (design conformance), audits the diff against the project's committed `docs/design/DESIGN.md`, or against the `frontend-design.md` visual law when no spec exists. | Phase 5 multi-reviewer wave whenever the diff is UI-bearing; takes the 5th reviewer slot. |
| `phase-5-escalation.md` | Sub-agent prompt for one Phase 5 specialist escalation reviewer (lens pinned at dispatch, e.g. security, infrastructure, data, domain compliance). Design conformance is NOT this file's job, that is the standing reviewer E above. | Phase 5 escalation when the diff touches a specialist surface beyond the baseline A/B/C/D reviewers and is not design conformance. |
| `phase-5-aggregation.md` | Conflict-resolution guidance for combining N parallel-agent reports + the anti-patterns checklist. | After any parallel wave (Phase 2.5, Phase 3, Phase 3b, Phase 5) returns. |
