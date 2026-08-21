# Parallel Agents (dispatch index)

**Read this file, not the templates, when you are dispatching.** Every prompt in this directory is ALSO installed as a registered subagent type. On a runtime with an agent registry (Claude Code) the agent already carries its full prompt as its system prompt, so opening the template to paste it costs the prompt twice, once in your context and once in the agent's.

## The dispatch rule

| Runtime has an agent registry? | What you do |
|---|---|
| **Yes** (Claude Code) | Dispatch by **agent type** from the table below and pass ONLY the INPUTS values. **Do not open the template file.** |
| **No** (the six best-effort targets, see `runtime-adapters.md`) | Open the template, substitute `{{...}}`, paste the prompt. This is the only path there. |

Open a template on Claude Code for exactly two reasons: you are **authoring or auditing** it, or the phase has **no registered agent** (the last four rows below). Needing to know what a reviewer checks is not one of them; that is what this table and the Phase 5 lens list in `SKILL.md` are for.

## Registered agents (dispatch by type)

| Agent type | Role | INPUTS to pass | Template (fallback only) |
|---|---|---|---|
| `hackify:spec-reviewer-consistency` | 2.5 A, internal consistency + goal drift | `work_doc_path` | `phase-2.5-spec-review-a-consistency.md` |
| `hackify:spec-reviewer-rules` | 2.5 B, architectural / cross-cutting risk | `work_doc_path`, `project_root` | `phase-2.5-spec-review-b-rules.md` |
| `hackify:spec-reviewer-dependencies` | 2.5 C, dependency / ordering / parallelism | `work_doc_path` | `phase-2.5-spec-review-c-dependencies.md` |
| `hackify:wave-task-implementer` | 3, one implementer per task | `task_id`, `task_text`, `file_allowlist`, `test_mode`, `project_root`, `repo_brief` | `phase-3-implementation.md` |
| `hackify:code-reviewer-security` | 5 A, security & correctness | `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `repo_brief` | `phase-5-multi-review.md` |
| `hackify:code-reviewer-quality` | 5 B, quality, layering & engineering law | + `law_scout_report`, `folded_lenses` | `phase-5-multi-review-b-quality.md` |
| `hackify:code-reviewer-plan-consistency` | 5 C, plan consistency, scope & drift | + `task_file_index` | `phase-5-multi-review.md` |
| `hackify:code-reviewer-performance` | 5 D, performance | + `perf_scout_report` | `phase-5-multi-review-d-performance.md` |
| `hackify:design-conformance-reviewer` | 5 E, design conformance (UI-bearing only) | + `design_spec_path` | `phase-5-multi-review-e-design.md` |
| `hackify:code-reviewer-coherence` | 5 F, cross-module coherence | + `task_file_index` | `phase-5-multi-review-f-coherence.md` |
| `hackify:finding-refuter` | 5, adversarial refuter | `finding_verbatim`, `lens`, `project_root`, `head_sha` | `phase-5-refute.md` |

## Template-only prompts (no registered agent, paste these)

| Template | What it is | When to load |
|---|---|---|
| `phase-1-research.md` | one read-only research agent (`Explore` type) | Phase 1 fan-out on a real unknown |
| `phase-3b-debug-evidence.md` | one read-only debug-evidence agent | Phase 3b on multi-component bugs |
| `phase-4-cross-package-verification.md` | one faithful exit-code reporter per project root | Phase 4 with 2+ independent roots |
| `phase-5-escalation.md` | one specialist reviewer, lens pinned at dispatch | Phase 5 on a specialist surface beyond A/B/C/D/F, never design (that is E) |

## Contracts

- `template-contract.md`, the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), the fan-out decision matrix, the framework-citation allowlist, and the placeholder convention. Load when **authoring or auditing** a template, not when dispatching one.
- `phase-5-aggregation.md`, conflict resolution for combining N reports. Load after a wave returns.
- The four mirrored agents (D, E, F, refuter) assert byte-for-byte identity with their template's fenced block, and check `[75h]` in `scripts/validate-dod.sh` enforces it. **Edit both sides or the build fails.** `python3 scripts/sync_agent_mirrors.py` does it for you.
