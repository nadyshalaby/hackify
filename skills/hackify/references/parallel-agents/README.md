# Parallel Agents (dispatch index)

**Read this file, not the templates, when you are dispatching.** Every prompt in this directory is ALSO installed as a registered subagent type. On a runtime with an agent registry (Claude Code) the agent already carries its full prompt as its system prompt, so opening the template to paste it costs the prompt twice, once in your context and once in the agent's.

## The dispatch rule

| Runtime has an agent registry? | What you do |
|---|---|
| **Yes** (Claude Code, OpenCode) | Dispatch by **agent type** from the table below and pass ONLY the INPUTS values. **Do not open the template file.** |
| **No** (Codex CLI, Codex App, Gemini CLI, Cursor and Copilot CLI, see `runtime-adapters.md`) | Open the template, substitute `{{...}}`, paste the prompt. This is the only path there. |

Open a template on Claude Code for exactly two reasons: you are **authoring or auditing** it, or the phase has **no registered agent** (the two rows in the second table). Needing to know what a reviewer checks is not one of them; that is what this table and the Phase 5 lens list in `SKILL.md` are for.

## Registered agents (dispatch by type)

| Agent type | Role | INPUTS to pass | Template (fallback only) |
|---|---|---|---|
| `hackify:codebase-investigator` | 1 and 3b, one read-only agent per question (`mode: research`) or per hypothesis (`mode: debug`) | `mode`, `inquiry`, `symptom`, `search_scope`, `project_name`, `seed_files`, `ruled_out`, `run_mode`, `word_cap` | `investigation.md` |
| `hackify:spec-reviewer` | 2.5, the only spec reviewer: internal consistency + goal drift, the wave plan Phase 3 dispatches off, every wave line marked a concurrency candidate or serial, delivered with a `## Serial resources` section beside it naming every shared file, generated sequence and exclusive resource the backlog touches, **and** architectural / cross-cutting risk | `work_doc_path`, `slug`, `wave_size_target`, `project_root`, `user_global_rules_path` | `phase-2.5-spec-reviewer.md` |
| `hackify:wave-implementer` | 3, exactly ONE implementer per execution WAVE, carrying every task in it, when the wave's tasks share a read surface. No cap on one wave's width and no split by module hunch. A concurrent wave is this same agent type dispatched again in the same round, so what changes is how many go out at once, and only the partition test in [`../contention-dispatch.md`](../contention-dispatch.md) may split a wave | `work_doc_path`, `task_ids` (every task in the wave, in plan order), `task_descriptions`, `file_allowlist` (the wave's union), `test_mode`, `test_command`, `lint_command`, `typecheck_command`, `project_rules_path`, `user_global_rules_path`, `stack_summary`, `repo_brief`, `exclusive_resources` (every exclusive resource this wave holds, one per line, or the literal `none`; never empty, since an absent value makes the agent refuse) | `phase-3-implementation.md` |
| `hackify:module-implementer` | 3, ONE agent per concurrent module track, dispatched only when a round holds two or more tracks. Builds one module to DONE inside a strict folder allowlist while siblings it cannot see build other modules in the same working tree, against its own database, against the interface its plan states rather than against code a sibling has not landed yet, and it reports every cross-module need instead of reaching for it | `module_id`, `module_plan_path`, `framing`, `folder_allowlist`, `owned_elsewhere`, `mandatory_reading`, `sharp_invariants`, `database_name`, `gate_commands`, `handoff_contract`, `rules_dir_path`, `project_rules_path`, `user_global_rules_path`, `repo_brief`, `stack_summary` | `phase-3-module-implementation.md` |
| `hackify:code-reviewer-security` | 5 A, security & correctness | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `review_scope` | `phase-5-multi-review-a-security.md` |
| `hackify:code-reviewer-quality-plan` | 5 B, quality, layering, engineering law **and** plan consistency, scope & goal drift, closing with a mandatory completeness section that asks what the review did not reach and files the answer as findings. Never sliced | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `project_rules_path`, `changelog_path`, `law_scout_report`, `task_file_index`, `metrics_table` | `phase-5-multi-review-b-quality-plan.md` |
| `hackify:code-reviewer-performance` | 5 D, performance | + `perf_scout_report`, `review_scope` | `phase-5-multi-review-d-performance.md` |
| `hackify:design-conformance-reviewer` | 5 E, design conformance (UI-bearing only) | + `design_spec_path`, `reference_images` | `phase-5-multi-review-e-design.md` |
| `hackify:code-reviewer-coherence` | 5 F, cross-module coherence | + `task_file_index` | `phase-5-multi-review-f-coherence.md` |
| `hackify:finding-refuter` | 5, exactly ONE adversarial refuter per review round, judging every finding at every severity and carrying both lenses itself. No per-Critical dispatch and no second-lens follow-up | `project_root`, `base_sha`, `head_sha`, `findings_batch` (the whole round, verbatim) | `phase-5-refute.md` |

### Which implementer a Phase 3 wave takes

Two implementer types, one rule, decided per wave and written into the wave plan:

| Wave | Agent type |
|---|---|
| The solo foundation wave (every contended write, no business logic) | `hackify:wave-implementer` |
| Two or more concurrent module tracks in one round | `hackify:module-implementer`, one per track, all dispatched in a single parent message |
| The solo assembly wave (mount every registrar, reconcile the seams, boot it for real) | `hackify:wave-implementer` |
| A round holding a single track | `hackify:wave-implementer` |

The reason the solo waves and the single-track round take the wave type is the same in all three cases: with nothing running beside it, the blind-sibling machinery `hackify:module-implementer` carries protects nothing and only costs context. Shape, scaling and the partition test behind the split: [`../contention-dispatch.md`](../contention-dispatch.md).

## Template-only prompts (no registered agent, paste these)

| Template | What it is | When to load |
|---|---|---|
| `phase-4-cross-package-verification.md` | one faithful exit-code reporter per project root | Phase 4 with 2+ independent roots |
| `phase-5-escalation.md` | one specialist reviewer, lens pinned at dispatch, takes no reviewer report | Phase 5 when the diff needs fresh findings on a specialist surface beyond A/B/D/F, never design (that is E) |
| `../review-and-verify.md` | one adjudication reviewer, written inline in that file rather than as a standalone template in this directory, rules CONCUR or REBUT on the reviewer reports a wave produced | Phase 5 when finished reviewer reports are in hand and a finding already filed needs a verdict |

## Contracts

- `template-contract.md`, the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), the fan-out decision matrix, the framework-citation allowlist, and the placeholder convention. Load when **authoring or auditing** a template, not when dispatching one.
- `phase-5-aggregation.md`, conflict resolution for combining N reports. Load after a wave returns.
- **Every** agent above is mirrored: each asserts byte-for-byte identity with its template's fenced block, and check `[75h]` in `scripts/validate-dod.sh` enforces it. **Edit both sides or the build fails.** `python3 scripts/sync_agent_mirrors.py` does it for you. There are no exceptions left as of v0.13.0. Phase 5 A and C were the last two, unmirrorable because they shared one canonical file holding three prompts and the script splits on the first fenced block; folding C into B and giving A its own file fixed both at once. Both had drifted in the meantime, in both directions, which is the argument for the check.
- **Retired in v0.13.0,** taking the plugin from 12 agent types to 9. `hackify:module-implementer` then landed, so the table above lists 10 and `agents/` holds 10 definitions. Every merge below is a union, not a summary: every METHOD step, VERIFICATION item and severity anchor from each retired lens is carried by whatever absorbed it.
  - `hackify:spec-reviewer-dependencies` (Spec-review C) and `hackify:spec-reviewer-rules` (Spec-review B) folded into the single `hackify:spec-reviewer`. Phase 2.5 is non-skippable, so no gate could ever have taken that saving instead. **The Phase 2.5 letters A, B and C are retired, not reassigned.**
  - `hackify:code-reviewer-plan-consistency` (Phase 5 Reviewer C) folded into `hackify:code-reviewer-quality-plan` (Reviewer B). Both ran unconditionally and neither ever folded, the same shape. **The Phase 5 letter C is retired, not reassigned.** Its lens gave up its own slice in the move, which is written down in `../review-scope.md`.
  - `hackify:codebase-researcher` and `hackify:debug-evidence-gatherer` merged into `hackify:codebase-investigator`, one prompt with a `mode`. This one is a maintenance merge and not a cost one: the two never ran in the same phase, so it removes an agent type to maintain rather than a duplicated read.
