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
| `hackify:spec-reviewer` | 2.5, the only spec reviewer: internal consistency + goal drift, the wave plan Phase 3 dispatches off, every wave line marked a concurrency candidate or serial, delivered with a `## Serial resources` section beside it naming every shared file, generated sequence and exclusive resource the backlog touches, **and** architectural / cross-cutting risk | `work_doc_path`, `slug`, `wave_size_target`, `concurrent_wave_target`, `project_root`, `user_global_rules_path` | `phase-2.5-spec-reviewer.md` |
| `hackify:implementer` | 3, the ONE type every Phase 3 dispatch takes, exactly one per execution WAVE, carrying every task in it, when the wave's tasks share a read surface. One wave packs up to the per-agent task budget, and there is still no split by module hunch. A concurrent wave is this same agent type dispatched again in the same round, so what changes is how many go out at once, up to the concurrent-wave budget, and only the partition test in [`../contention-dispatch.md`](../contention-dispatch.md) may split a wave. `sibling_tracks` is the mode switch: `none` and it works alone, named tracks and it also reads [`../sibling-track-rules.md`](../sibling-track-rules.md) and applies every rule in it on top | `work_doc_path`, `track_id`, `task_ids` (every task in the wave, in plan order), `task_descriptions`, `file_allowlist` (the wave's union), `sibling_tracks`, `owned_elsewhere`, `mandatory_reading`, `sharp_invariants`, `database_name`, `exclusive_resources`, `test_mode`, `test_command`, `lint_command`, `typecheck_command`, `handoff_contract`, `rules_dir_path`, `project_rules_path`, `user_global_rules_path`, `repo_brief`, `stack_summary`. All 21 are required; nine take the literal `none` (`work_doc_path`, `track_id`, `sibling_tracks`, `owned_elsewhere`, `mandatory_reading`, `sharp_invariants`, `database_name`, `exclusive_resources`, `handoff_contract`) and `none` is a decision, while an EMPTY value makes the agent refuse. `work_doc_path` is `none` in quick mode alone, which writes no work-doc, so `task_descriptions` carries the whole spec instead | `phase-3-implementation.md` |
| `hackify:code-reviewer-security` | 5 A, security & correctness | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `review_scope` | `phase-5-multi-review-a-security.md` |
| `hackify:code-reviewer-quality-plan` | 5 B, quality, layering, engineering law **and** plan consistency, scope & goal drift, closing with a mandatory completeness section that asks what the review did not reach and files the answer as findings. Never sliced | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief`, `project_rules_path`, `changelog_path`, `law_scout_report`, `task_file_index`, `metrics_table` | `phase-5-multi-review-b-quality-plan.md` |
| `hackify:code-reviewer-performance` | 5 D, performance | + `perf_scout_report`, `review_scope` | `phase-5-multi-review-d-performance.md` |
| `hackify:design-conformance-reviewer` | 5 E, design conformance (UI-bearing only) | + `design_spec_path`, `reference_images` | `phase-5-multi-review-e-design.md` |
| `hackify:code-reviewer-coherence` | 5 F, cross-module coherence | + `task_file_index` | `phase-5-multi-review-f-coherence.md` |
| `hackify:finding-refuter` | 5, exactly ONE adversarial refuter per review round, judging every finding at every severity and carrying both lenses itself. No per-Critical dispatch and no second-lens follow-up | `project_root`, `base_sha`, `head_sha`, `findings_batch` (the whole round, verbatim, and the literal `none` on a round that found nothing, never a blank, which the agent refuses) | `phase-5-refute.md` |

### What a Phase 3 wave passes as `sibling_tracks`

One implementer type takes every wave, whatever its shape. The mode switch is `sibling_tracks`, decided per wave and written into the wave plan:

| Wave | Agent type | `sibling_tracks` |
|---|---|---|
| The solo foundation wave (every contended write, no business logic) | `hackify:implementer` | `none` |
| Two or more concurrent module tracks in one round | `hackify:implementer`, one per track, all dispatched in a single parent message | the OTHER tracks' IDs |
| The solo assembly wave (mount every registrar, reconcile the seams, boot it for real) | `hackify:implementer` | `none` |
| A round holding a single track | `hackify:implementer` | `none` |

`none` there is a decision, never a blank, and the reason all three solo shapes pass it is the same: with nothing running beside it, the blind-sibling machinery in [`../sibling-track-rules.md`](../sibling-track-rules.md) protects nothing and only costs context, so a solo dispatch never opens that file. Shape, scaling and the partition test behind the split: [`../contention-dispatch.md`](../contention-dispatch.md).

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
- **Retired in v0.13.0,** taking the plugin from 12 agent types to 9. The `module-implementer` type then landed, making 10, and 0.17.1 merged it with `wave-implementer` into the single `hackify:implementer`, so the table above lists 9 and `agents/` holds 9 definitions. **Those two retired names carry no `hackify:` prefix here on purpose:** check [40] bans the prefixed forms from every live file, and a note recording what was retired reads exactly the same without them, so this line drops the prefix rather than buying the whole file an exclusion that would waive all 13 of that check's literals to license the 2 really here. `scripts/test_ban_tokens.d/15-wi-absent-cases.sh` writes its own retired type the same way, for the same reason. Every merge below is a union, not a summary: every METHOD step, VERIFICATION item and severity anchor from each retired lens is carried by whatever absorbed it.
  - `hackify:spec-reviewer-dependencies` (Spec-review C) and `hackify:spec-reviewer-rules` (Spec-review B) folded into the single `hackify:spec-reviewer`. Phase 2.5 is non-skippable, so no gate could ever have taken that saving instead. **The Phase 2.5 letters A, B and C are retired, not reassigned.**
  - `hackify:code-reviewer-plan-consistency` (Phase 5 Reviewer C) folded into `hackify:code-reviewer-quality-plan` (Reviewer B). Both ran unconditionally and neither ever folded, the same shape. **The Phase 5 letter C is retired, not reassigned.** Its lens gave up its own slice in the move, which is written down in `../review-scope.md`.
  - `hackify:codebase-researcher` and `hackify:debug-evidence-gatherer` merged into `hackify:codebase-investigator`, one prompt with a `mode`. This one is a maintenance merge and not a cost one: the two never ran in the same phase, so it removes an agent type to maintain rather than a duplicated read.
