# Parallel Agents (dispatch index)

**Read this file, not the templates, when you are dispatching.** Every prompt in this directory is ALSO installed as a registered subagent type. On a runtime with an agent registry (Claude Code) the agent already carries its full prompt as its system prompt, so opening the template to paste it costs the prompt twice, once in your context and once in the agent's.

## The dispatch rule

| Runtime has an agent registry? | What you do |
|---|---|
| **Yes** (Claude Code) | Dispatch by **agent type** from the table below and pass ONLY the INPUTS values. **Do not open the template file.** |
| **No** (the six best-effort targets, see `runtime-adapters.md`) | Open the template, substitute `{{...}}`, paste the prompt. This is the only path there. |

Open a template on Claude Code for exactly two reasons: you are **authoring or auditing** it, or the phase has **no registered agent** (the two rows in the second table). Needing to know what a reviewer checks is not one of them; that is what this table and the Phase 5 lens list in `SKILL.md` are for.

## Registered agents (dispatch by type)

| Agent type | Role | INPUTS to pass | Template (fallback only) |
|---|---|---|---|
| `hackify:codebase-investigator` | 1 and 3b, one read-only agent per question (`mode: research`) or per hypothesis (`mode: debug`) | `mode`, `inquiry`, `symptom`, `search_scope`, `project_name`, `seed_files`, `ruled_out`, `run_mode`, `word_cap` | `investigation.md` |
| `hackify:spec-reviewer` | 2.5, the only spec reviewer: internal consistency + goal drift, the wave plan + dispatch batches, **and** architectural / cross-cutting risk | `work_doc_path`, `slug`, `wave_size_target`, `project_root`, `user_global_rules_path` | `phase-2.5-spec-reviewer.md` |
| `hackify:wave-task-implementer` | 3, one implementer per task BATCH | `task_ids`, `task_descriptions`, `file_allowlist` (union), `test_mode`, `project_root`, `repo_brief` | `phase-3-implementation.md` |
| `hackify:code-reviewer-security` | 5 A, security & correctness | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `review_scope` | `phase-5-multi-review-a-security.md` |
| `hackify:code-reviewer-quality-plan` | 5 B, quality, layering, engineering law **and** plan consistency, scope & goal drift. Never sliced | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `project_rules_path`, `changelog_path`, `law_scout_report`, `task_file_index`, `folded_lenses`, `metrics_table` | `phase-5-multi-review-b-quality-plan.md` |
| `hackify:code-reviewer-performance` | 5 D, performance | + `perf_scout_report`, `review_scope` | `phase-5-multi-review-d-performance.md` |
| `hackify:design-conformance-reviewer` | 5 E, design conformance (UI-bearing only) | + `design_spec_path` | `phase-5-multi-review-e-design.md` |
| `hackify:code-reviewer-coherence` | 5 F, cross-module coherence | + `task_file_index` | `phase-5-multi-review-f-coherence.md` |
| `hackify:finding-refuter` | 5, adversarial refuter | `finding_verbatim`, `lens`, `project_root`, `head_sha` | `phase-5-refute.md` |

## Template-only prompts (no registered agent, paste these)

| Template | What it is | When to load |
|---|---|---|
| `phase-4-cross-package-verification.md` | one faithful exit-code reporter per project root | Phase 4 with 2+ independent roots |
| `phase-5-escalation.md` | one specialist reviewer, lens pinned at dispatch | Phase 5 on a specialist surface beyond A/B/C/D/F, never design (that is E) |

## Contracts

- `template-contract.md`, the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), the fan-out decision matrix, the framework-citation allowlist, and the placeholder convention. Load when **authoring or auditing** a template, not when dispatching one.
- `phase-5-aggregation.md`, conflict resolution for combining N reports. Load after a wave returns.
- **Every** agent above is mirrored: each asserts byte-for-byte identity with its template's fenced block, and check `[75h]` in `scripts/validate-dod.sh` enforces it. **Edit both sides or the build fails.** `python3 scripts/sync_agent_mirrors.py` does it for you. There are no exceptions left as of v0.13.0. Phase 5 A and C were the last two, unmirrorable because they shared one canonical file holding three prompts and the script splits on the first fenced block; folding C into B and giving A its own file fixed both at once. Both had drifted in the meantime, in both directions, which is the argument for the check.
- **Retired in v0.13.0,** taking the plugin from 12 agent types to 9. Every one is a union, not a summary: every METHOD step, VERIFICATION item and severity anchor from each retired lens is carried by whatever absorbed it.
  - `hackify:spec-reviewer-dependencies` (Spec-review C) and `hackify:spec-reviewer-rules` (Spec-review B) folded into the single `hackify:spec-reviewer`. Phase 2.5 is non-skippable, so no evidence gate could ever have taken that saving instead. **The Phase 2.5 letters A, B and C are retired, not reassigned.**
  - `hackify:code-reviewer-plan-consistency` (Phase 5 Reviewer C) folded into `hackify:code-reviewer-quality-plan` (Reviewer B). Both ran unconditionally and neither ever folded, the same shape. **The Phase 5 letter C is retired, not reassigned.** Its lens gave up settle-round slicing in the move, which is written down in `../review-scope.md`.
  - `hackify:codebase-researcher` and `hackify:debug-evidence-gatherer` merged into `hackify:codebase-investigator`, one prompt with a `mode`. This one is a maintenance merge and not a cost one: the two never ran in the same phase, so it removes an agent type to maintain rather than a duplicated read.
