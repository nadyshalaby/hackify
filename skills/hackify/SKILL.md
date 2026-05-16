---
name: hackify
description: One unified end-to-end dev workflow for ANY substantive task — feature, bug fix, refactor, redesign, design, debug, migration, or research-then-build — driven by a single per-task markdown work-doc at <project>/docs/work/. Replaces multi-skill ceremony (no separate spec/plan files). Asks every clarifying question up-front in one batched questionnaire, holds a hard gate before code is written, file-driven pause/resume across sessions, mandatory evidence-before-claims, baked-in self-review checklist, parallel multi-reviewer code review on non-trivial diffs, explicit definition-of-done verified end-to-end. The default route for any substantive prompt — auto-fires on broad-spectrum verbs (add, build, implement, refactor, redesign, restyle, migrate, debug, polish, audit) AND on architecture/scope/security surface (auth, crypto, migration, secret, token, password, schema, data model, API surface, refactor everywhere, across all). Invoke even when the user does not say "use the workflow" — carve-outs are trivial factual Q&A, single-line typo fixes, and pure read-only inspection. When in doubt, invoke this skill — escalation to full ceremony is free, demotion is not.
---

# Hackify — One Workflow For Every Dev Task

Hackify replaces plan/spec/brainstorm/execute/verify/review/finish ceremony with **one workflow + one markdown work-doc per task**. The work-doc is spec, plan, progress tracker, review log, and post-mortem in one file. Resume across sessions via "continue work on `<slug>`".

Self-contained. **Never call other skills** — third-party plugins may not be installed. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined here or in `references/`.

## When to invoke

- **Default for every prompt** that asks for any of: building / adding / fixing / refactoring / redesigning / restyling / debugging / polishing / migrating / testing / discussing-then-building.
- **Slash command:** `/hackify:hackify <ask>` to start, `/hackify:hackify resume <slug>` to continue.
- **Carve-outs (skill optional):** trivial factual Q&A, one-line typo fixes, pure read-only inspection that won't lead to writing/editing/committing.
- **Compressed-flow alternative:** for small bug fixes, single-file edits, and quick direct-effort requests, use `/hackify:quick`. Skips Plan+Gate, Spec review, Multi-reviewer, and 4-options finish; runs Clarify-if-needed → Implement → Verify → Summary; stays in quick mode until you explicitly switch to full hackify.
- **Full-autopilot alternative:** for substantive tasks where you trust the pipeline and don't want gates, use `/hackify:yolo`. Same phases as full hackify (clarify, exploration, plan, spec-review, implement, verify, multi-reviewer, finish) but Phase 2 sign-off and Phase 6 4-options menu auto-pass. No work-doc on disk → no pause/resume across sessions. Phase 5 multi-reviewer findings are auto-fixed in-place at every severity; inspect with `git diff HEAD~1` after the commit lands.

When in doubt, invoke. Redundant skill load is cheap; a missed one ships broken work.

## The phases (lean, expert-led)

| Phase | What |
|---|---|
| 1 Clarify | Wizard questions in one batch, get user answers |
| 2 Plan | Draft work-doc, present, **HARD GATE: user signs off** |
| 2.5 Spec review | Parallel agents scrutinize work-doc for conflicting / inconsistent logic |
| 3 Implement | Order tasks by dependency, dispatch each wave to PARALLEL foreground agents |
| 3b Debug | Only if stuck after 2+ failed attempts |
| 4 Verify | Run DoD checklist, paste fresh evidence |
| 5 Review | PARALLEL multi-reviewer (security + quality + consistency) — always |
| 6 Finish | Present 4 options, execute, archive work-doc, cleanup |

The only mandatory user gate is between **Plan** and **Spec review**. After Phase 2.5, implementation begins automatically. Phases 3–6 run continuously with progress reports at each transition. The user can interrupt anytime — the work-doc holds state.

**Parallelism is the default.** Whenever 2+ pieces of work are independent (clarify research, spec review, same-wave tasks, code review concerns, cross-package verification) dispatch foreground subagents in one message. Wave-based dependency ordering makes parallel implementation safe — same-file tasks split across waves.

## The work-doc — single source of truth

- **Location.** `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` in flight; move to `<project>/docs/work/done/<YYYY-MM-DD>-<slug>.md` once shipped.
- **Skeleton** (`references/work-doc-template.md`). Frontmatter: `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`, `sprint_goal`. Body: Original Ask → Clarifying Q&A → Acceptance Criteria → Approach → Sprint Backlog → Daily Updates → Sprint Review → Retrospective.
- **State is the file.** No companion JSON, no in-conversation memory. Resume = open file, read frontmatter, jump to next unchecked checkbox.
- **Project root.** Each sub-project is its own git repo. Work-doc lives inside the project repo. Multi-project tasks: one doc per project, linked via `related` frontmatter field.

---

## Phase 1 — Clarify

**Goal.** Understand the ask precisely enough that no question survives into Phase 3.

1. **Classify task type:** `feature` | `fix` | `refactor` | `revamp` | `redesign` | `debug` | `research`. Drives questionnaire choice (`references/clarify-questions.md`).
2. **Read just enough context.** Broad architecture → scan entry points + follow imports; blast radius → grep symbol usages; single-module onboarding → read top-to-bottom; trivial single-file edits → skip exploration.
3. **Build ONE batched questionnaire.** Pull the relevant question bank from `references/clarify-questions.md`. Each bank conforms to the canonical 4-section Wizard Contract (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA) documented at the top of that file. Strip questions whose answer is evident from ask or context. Add task-specific questions if the bank misses something. Recommended option is the **first** in each question, suffixed `(Recommended)`.
4. **Send the questionnaire as a wizard, NEVER as plain markdown.** Every clarify question goes through the wizard tool — plain numbered lists in chat are forbidden. Lead the first wizard message with a one-paragraph "What I heard you ask for" recap so misreadings surface early. Wizard takes 1–4 questions per call, 2–4 options per question — split longer questionnaires across **multiple back-to-back wizard-tool calls in the same turn** (fire the next batch as soon as prior answers land). Use `multiSelect: true` only for non-exclusive options; never for "pick one approach". "Other" free-text is auto-provided — never add one yourself.
5. **Wait.** Do not start Phase 2 until every wizard question is answered. One ambiguous answer → one targeted follow-up wizard call. No iterative interrogation.

**Hard rule.** No code, no file edits, no test runs in Phase 1. Output is a list of clear, locked answers. See `references/clarify-questions.md`.

---

## Phase 2 — Plan + Gate

**Goal.** A work-doc the user can scan in 60 seconds and say "go."

1. **Create the work-doc** at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Slug `kebab-case`, ≤6 words. Date is today.
2. **Fill from template** (`references/work-doc-template.md`). Required now: Original Ask (verbatim), Clarifying Q&A (verbatim), Acceptance Criteria (3–7 verifiable bullets), Approach (≤200 words; chosen path + 1–2 sentence rationale), Sprint Backlog (flat checklist, each task 5–30 min).
3. **Task granularity.** Each task independently testable and committable. Break "Add invitation expiry" into "Add `expires_at` column + migration", "Reject expired tokens in invitations service", "Show 'expired' state in UI", "Backend test", "Frontend test". Default: one commit per task.
4. **No placeholders.** No "TBD", no "implement error handling later", no "similar to T2". Decompose vague tasks now.
5. **Show the doc.** Paste rendered doc in chat or summarize and link. Ask: *"Sign off on this plan or call out anything to change?"*
6. **GATE.** Wait for explicit "go" / "approved" / "yes" before Phase 3.

**On pushback,** edit doc, show diff, re-ask. Iterate until signed off. See `references/work-doc-template.md`.

---

## Phase 2.5 — Spec Self-Review (parallel — mandatory)

**Goal.** Catch inconsistent or conflicting logic in the work-doc *before* code is written. Cheap on paper; expensive after 200 LOC against a flawed spec.

1. **Dispatch 3 foreground reviewers in parallel in ONE message.** Each gets a self-contained prompt + absolute work-doc path:
   - **Reviewer A — Internal consistency.** Read work-doc end-to-end. Find Q&A↔DoD↔Approach↔Sprint Backlog contradictions. Flag tasks not covered by any DoD bullet, DoD bullets not covered by any task, Q&A answers contradicting the Approach.
   - **Reviewer B — Architectural / cross-cutting risks.** Match plan against project code-quality rules — if a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md`. Flag anything that would force a lint suppression, `!`, inline type, bare `Error` throw, or layering violation.
   - **Reviewer C — Dependency / ordering / parallelism risks.** Build a quick dependency graph from Sprint Backlog. Flag tasks sharing a file (parallel conflict), missing prerequisites, ordering bugs (consuming a helper before its task), tasks too coarse to be 5–30 min.
2. **Aggregate findings.** Critical (plan bug forcing rework) / Important (fixable gap) / Minor (nit).
3. **Patch the work-doc.** Apply Critical + Important in place; record Minor in Retrospective.
4. **Re-gate ONLY if user's signed-off invariants changed** (Critical finding widened scope). Else straight to Phase 3.

Template: `references/parallel-agents.md` "Spec self-review (Phase 2.5)". **Hard rule:** Phase 2.5 is non-skippable, even for small docs — a "small" plan can hide a contradictory Q&A pair. Cap each reviewer at ≤300 words.

---

## Phase 3 — Implement (parallel waves — mandatory)

**Goal.** Ship the Sprint Backlog as fast as wall-clock allows by dispatching each wave to foreground parallel subagents in one message.

**Pre-flight — build the wave plan.**

```
1. List every task. For each: files CREATED/MODIFIED; earlier tasks required.
2. Sort by priority (DoD load-bearing first) and topological dependency.
3. Group into WAVES — NO file overlap, NO inter-task dep within a wave; wave N may depend on 1..N-1.
4. Write wave plan into work-doc Approach as "Execution waves". Show user before wave 1.
```

**Per-wave loop:**

```
1. Set frontmatter: status: implementing, current_task: W<n>:T<a>+T<b>+…
2. Dispatch ONE subagent per task in a SINGLE assistant message. Each agent prompt
   self-contained: work-doc path, task ID, exact files, test mode, rules summary,
   "do NOT touch any other files".
3. Wait for all agents. Aggregate reports. Verify each touched only its declared files.
4. Run full project verification (test + lint + typecheck) ONCE for the wave.
5. On red: classify — agent failure (re-dispatch sharper prompt) vs. plan failure
   (drop to Phase 3b). Never paper over.
6. Tick wave checkboxes; append one Daily Updates entry per task.
7. Commit ONCE for the wave (conventional subject; body lists task IDs).
8. Advance to wave N+1.
```

**Per-task safety constraints (in each agent's prompt):**

| Constraint | Wording |
|---|---|
| File allowlist | "Modify only these files: `<list>`. If another file is needed, STOP and report — do not edit." |
| Command allowlist | "Run only these commands: `<list scoped to your files>`. The parent runs repo-wide checks." |
| TDD | "If test mode is test-first, watch the test fail before writing impl. Refuse to ship without a watched RED." |
| Self-review | "Self-review against the checklist before reporting done. Report pass/fail per item + any Approach deviations." |
| Word cap | ≤200 words per agent report. |

Template: `references/parallel-agents.md` "Implementation wave (Phase 3)". **Single-task waves are fine** — dispatch a single agent; discipline (self-contained prompt, declared files, scoped commands) still applies.

**Test mode per task:**

| Mode | When | Discipline |
|---|---|---|
| **Test-first (mandatory)** | Business logic, services, validators, auth/permission, bug fixes, branching behavior | RED → GREEN → REFACTOR. Watch the test fail. *"If you didn't watch it fail, you don't know it tests the right thing."* |
| **Test-after (acceptable)** | Integration/E2E with heavy setup, framework wiring, glue code | Test required; order is flexible. |
| **Manual smoke (user opt-in)** | UI cosmetics, copy edits, color/spacing, doc edits, config-only | Log steps in Daily Updates. Offer an automated test; never *replace* automated tests when behavior is testable. |
| **No tests** | Purely additive scaffolding ("create empty file") or pure documentation | Note `no test (rationale: …)` in the log. |

**If stuck** (tests still red after 2 honest fix attempts, or behavior surprising), **switch to Phase 3b: Debug**. No third blind fix.

**No scope creep.** No cleanup, no refactoring adjacent code, no abstractions for hypothetical futures. The plan is the contract. See `references/implement-and-test.md`.

### Wave-end persistence (mandatory)

**Wave-end persistence (mandatory).** Before dispatching wave N+1, the parent MUST update the work-doc: tick the completed checkboxes in the Sprint Backlog, append a Daily Updates entry summarizing what each agent produced, run `bash scripts/validate-dod.sh` (or the project's verification triad), and advance frontmatter `current_task` to the next wave's task IDs. Skipping this step is an abandoned-state bug — interrupting between waves loses no progress; interrupting mid-wave-update loses the wave.

---

## Phase 3b — Debug (only when stuck)

**Trigger.** ≥2 failed fix attempts on the same task, OR a test failure whose message doesn't match the expected error, OR a regression surfaced by unrelated work.

**4-phase root-cause hunt** (do not skip phases):

```
1. ROOT CAUSE — reproduce reliably, gather evidence at every component boundary,
   trace the bad value to its source.
2. PATTERN ANALYSIS — find a working analogue, list every difference.
3. HYPOTHESIS — write: "I think X is the cause because Y." Make ONE smallest change. Run.
4. IMPLEMENT — write a failing test reproducing the bug, fix the SOURCE (not symptom),
   watch the test go green, watch all other tests stay green.
```

**Circuit breaker.** After 3 failed hypotheses, **stop** — architectural problem. Document dead-ends in the work-doc and surface to the user.

**Hard rules.** No "quick fix for now." No multiple fixes at once. No skipping the failing-test step. See `references/debug-when-stuck.md`.

---

## Phase 4 — Verify

**Goal.** Prove the original ask is met. Evidence before claims.

**Acceptance Criteria (top-level — every task type):**

- [ ] All tests pass — paste fresh test output (exit 0, 0 failures, 0 errors)
- [ ] Linter clean — paste fresh lint output (0 errors)
- [ ] Typecheck clean — paste fresh typecheck output (0 errors)
- [ ] All `Sprint Backlog` checkboxes ticked
- [ ] Every Phase 2 DoD bullet verified — paste evidence per bullet (output, screenshot ref, or verifying script)
- [ ] No placeholders, no `TODO` without owners, no `console.log`/`println!`, no commented-out code
- [ ] No new lint suppressions (`biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`) — zero tolerance
- [ ] No new `!` non-null assertions in production code
- [ ] Manual smoke check (if user opted in) — list steps and outcomes

**Run commands fresh.** Re-run before claiming. Per-stack quick reference: `references/review-and-verify.md`.

**On any red, do NOT advance to Phase 5.** Loop back to Phase 3 (or 3b if stuck).

---

## Phase 5 — Review (parallel multi-reviewer — mandatory)

**Default: dispatch THREE foreground reviewers in parallel in ONE message.** Self-review is the floor, not the ceiling — for any diff beyond a one-line typo, multi-reviewer is on.

- **Reviewer A — Security & correctness.** Auth, permissions, injection, CORS, cookies, secrets, PII, migrations, crypto, race conditions. Adversarial intent.
- **Reviewer B — Quality & layering.** DRY, named types, layering (routes pure / services own DB), file/function caps, lint suppressions, `!` non-null, empty catches, bare `Error` throws, dead code.
- **Reviewer C — Plan consistency & scope.** Diff vs. work-doc DoD + Sprint Backlog. Missing items, scope creep, anything contradicting a Q&A answer or the Approach.

Multi-concern diffs (UI + backend migration): add a 4th reviewer on the second concern. Cap at 4. **Self-review still happens** by you, against `references/review-and-verify.md`'s 14-item checklist — reviewers are *additive* defense, not replacement.

**Carve-out (skill optional).** A diff that is *purely* a one-line typo / comment / config-only change can skip multi-reviewer. When in doubt, dispatch.

**Acting on feedback.**

| Severity | Action |
|---|---|
| Critical | Fix immediately, before merging. |
| Important | Fix before claiming Phase 6 done. |
| Minor | Fix now if cheap, else add a "follow-up" entry to Retrospective. |

Push back only with **technical evidence** — never performative agreement. If the reviewer is wrong for this codebase (YAGNI, missing context, bad pattern fit), say so with reasoning. Response pattern: `references/review-and-verify.md`.

---

## Phase 6 — Finish

**Goal.** Land the work cleanly and archive the doc.

**Step A — re-run verification.** Even if Phase 4 passed. Pre-merge state drifts.

**Step B — present exactly 4 options, no open-ended choice:**

| # | Option | Default for |
|---|---|---|
| 1 | Merge to base branch locally | Small in-place changes |
| 2 | Push and create a PR | Cross-team or larger changes |
| 3 | Keep the branch as-is | Work pauses; no cleanup |
| 4 | Discard this work | Requires user typing "discard" verbatim — no shortcut |

**Step C — execute the choice.** **1 or 2:** Commit follows project convention; ends with Claude Code Co-Authored-By trailer. PRs include Summary, Test plan, and link to work-doc. **3:** Stop. Leave everything in place. **4:** Confirm, then `git checkout` base branch and remove worktree if any. Never `git reset --hard` without explicit user instruction.

**Step D — archive the work-doc** (1 or 2): move `<project>/docs/work/<slug>.md` → `<project>/docs/work/done/<slug>.md`. Update `status: done`. Retrospective is mandatory — 3–8 bullets on what surprised, what to remember.

**Step E — worktree cleanup** (1, 2, or 4): `git worktree remove <path>`; delete the local branch if merged. NOT for option 3.

**Step F — Summary table** (1 or 2 only): Generate a concise 2-column Area/Change markdown table covering every change shipped. Print to chat. Append the same table to the archived work-doc inside Retrospective under a new `## Summary of changes shipped` subheading. Area labels are 1–4 word concept/theme tokens; Change cells ≤25 words with `backticks` for technical terms. See `references/finish.md` "Summary table — authoring guidance".

**Invoking the summary on demand.** The Area/Change table runs any time via `/hackify:summary` or phrase trigger ("show summary", "summarize", "summary table", "show me what changed"). Mid-flight invocation prints to chat; Step F also appends to the work-doc.

---

## Pause / Resume

**Pause** — user can stop at any time. The work-doc holds state; do not summarize in chat unless asked.

**Resume** — on "continue work on `<slug>`" or "resume hackify":

1. Locate the work-doc — search `<project>/docs/work/*.md` for the slug. Multiple project candidates → ask which. Fallback: recursively search known project roots.
2. Read frontmatter. Honor `status` and `current_task`.
3. Read the latest Daily Updates entry to see where you stopped.
4. Confirm: *"Resuming `<title>` at `<status>`, next task: `<T<n>>`. Continue?"*
5. Resume from the appropriate phase — do NOT re-run earlier phases unless asked.

**Stale doc detection.** If `created` is >14 days old, check whether the codebase moved underneath the plan (`git log --since="<created>" -- <touched files>`). On drift, surface it before continuing.

**Back-compat: section-name labels.** When resuming a work-doc, accept EITHER the new sprint labels (`Acceptance Criteria`, `Sprint Backlog`, `Daily Updates`, `Sprint Review`, `Retrospective`) OR the legacy labels (`Definition of Done`, `Tasks`, `Implementation Log`, `Verification`, `Post-mortem`). Pre-v0.2.0 archived work-docs in `docs/work/done/` use the legacy labels; new work-docs use the sprint labels. No migration of archived docs is required.

### Pause checkpoint (mid-wave exit)

**Pause checkpoint (mid-wave exit).** When the user's prompt contains any of the **pause-keyword list** — `pause`, `stop`, `exit`, `later`, `tomorrow`, `come back`, `pick this up later` — during an active wave, the parent does five things in order: (1) wait for any in-flight subagents to return; (2) finish the work-doc update for completed agents (tick their checkboxes, append their Daily Updates entry); (3) write a `## Pause checkpoint` entry to the Daily Updates with timestamp, completed-task list, and partial-state notes; (4) update frontmatter `current_task` to reflect the partial-state (e.g., `W3b — T3.2 done, T3.3 in progress (deferred to next session)`); (5) tell the user: `Your progress is saved. Resume with "continue work on <slug>".`

---

## Parallel agents — the default, not the exception

Whenever 2+ pieces of work are independent — **dispatch foreground subagents in parallel in a single message**. Never sequential when independent.

**Every sub-agent prompt conforms to the canonical Template Contract** in `references/parallel-agents.md` — the 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT) with `{{snake_case}}` placeholders. Binding because Haiku-class models read these prompts; the structure prevents soft-language / missing-verification / unanchored-severity failure modes from the v0.1.0 post-mortem. New templates MUST conform.

**Use parallel agents for:**

| Phase | Use | Status |
|---|---|---|
| 1 | Research — different code areas, refs, questions | optional |
| 2.5 | Spec self-review — 3 reviewers scrutinize work-doc | MANDATORY |
| 3 | Implementation waves — one agent per task | MANDATORY |
| 3b | Debug evidence gathering — different component boundaries | optional |
| 4 | Cross-module verification — tests in different packages | optional |
| 5 | Multi-reviewer code review — security/quality/plan lenses | MANDATORY (non-trivial diffs) |

**Do NOT use parallel agents for:** tasks sharing a file in the same wave (wave planner splits them); tightly-coupled investigations where each finding informs the next; one-line typo fixes (overhead exceeds value). Templates in `references/parallel-agents.md`.

---

## Frontend design work — special handling

For tasks touching **UI / styling / theming / layout / components / typography / colors / spacing / icons / forms / motion / brand / RTL**, before drafting the Plan **load `references/frontend-design.md`** and treat its rules as binding. If your project has a committed brand/design spec, design WITHIN it — let the spec lead and adapt new components to its tokens, scale, and voice.

---

## Code quality (always-on)

Hackify enforces the project's code-quality rules. If a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md` (canonical doctrine; the legacy `references/code-rules.md` path is a forwarding stub). Hard caps non-negotiable: ≤40 LOC per function, ≤3 params, ≤3 nesting levels, ≤500 LOC per file, 0 lint suppressions, 0 non-null `!`, 0 empty catches, 0 inline `interface`/`type` blocks ≥2 props in route/service/middleware modules, 0 bare `Error` throws in domain code. The plugin-root `rules/hard-caps.md` is injected into every prompt by the `UserPromptSubmit` hook so the hard caps are always loaded; the deeper doctrine in `rules/code-quality.md` loads on demand from Phase 2.5 Reviewer B and Phase 5 Reviewer B.

Patterns: DRY, named types for any 2+ prop shape, explicit over clever, single responsibility, every code path tested, edge cases handled. Depth: `rules/code-quality.md`.

---

## File map

| Path | Purpose |
|---|---|
| `SKILL.md` | this file (the workflow) |
| `references/work-doc-template.md` | markdown skeleton for every task |
| `references/clarify-questions.md` | per-task-type question banks for Phase 1 |
| `references/implement-and-test.md` | TDD walkthrough, per-stack test commands |
| `references/debug-when-stuck.md` | 4-phase root-cause hunt for Phase 3b |
| `references/review-and-verify.md` | DoD + self-review checklist + escalation rules |
| `references/finish.md` | Phase 6 — 4-options, archive, worktree cleanup |
| `references/frontend-design.md` | visual law (load on FE/UI/design tasks) |
| `rules/code-quality.md` (plugin root) | SOLID/DRY/types/layering deep dive — canonical location (legacy `references/code-rules.md` is a forwarding stub) |
| `references/parallel-agents.md` | parallel subagent dispatch templates |
| `evals/evals.json` | optional eval harness |

Load reference files **only when the phase needs them** — keeps context lean.

---

## Anti-rationalizations — STOP and reset

| Thought | Reality |
|---|---|
| "This task is too small for the workflow" | Use it. Small tasks ship broken without DoD. |
| "I'll skip the gate, the user will be happy I'm fast" | The gate is the only thing protecting against misread asks. |
| "Tests after will be fine, I know what I'm building" | Tests-after pass immediately and prove nothing. |
| "One more fix attempt before debug mode" | The 2-attempt limit is the circuit breaker. Honor it. |
| "I can self-review a 600-LOC diff" | No, you can't. Escalate. |
| "The user said 'just do X', skip the questionnaire" | If X has any ambiguity, batched questionnaire still applies. Trim it, don't skip it. |
| "Lint suppression is fine just this once" | Zero tolerance. Fix the root cause. |

---

## Runtime primitives — where the tool names go

This SKILL.md uses **runtime-primitive names** (wizard tool / subagent dispatcher / file-read op / file-write op / file-edit op / search / shell) rather than Claude-Code-specific tool names. Each target runtime maps these primitives to its own native tool via `references/runtime-adapters.md`. The mapping is the responsibility of the runtime, not the workflow — hackify's design law is identical across all 7 supported runtimes.

## One-line summary

Clarify up-front → gate before code → walk small tasks with self-review → verify with fresh evidence → finish with explicit options → archive. One file holds it all.
