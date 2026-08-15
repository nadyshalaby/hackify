---
name: hackify
description: One unified end-to-end dev workflow for ANY substantive task, feature, bug fix, refactor, redesign, design, debug, migration, or research-then-build, driven by a single per-task markdown work-doc at <project>/docs/work/. Replaces multi-skill ceremony (no separate spec/plan files). Asks every clarifying question up-front in one batched questionnaire, holds a hard gate before code is written, file-driven pause/resume across sessions, mandatory evidence-before-claims, baked-in self-review checklist, parallel multi-reviewer code review on non-trivial diffs, explicit definition-of-done verified end-to-end. Ships an always-on ship bar in every mode with no opt-in: a deterministic engineering-law scan and a performance scan at every wave-end and at review start, a runtime gate that proves the app builds, boots and serves the touched flow before the task can finish, a standing cross-module coherence reviewer that checks the parts agree with each other, and adversarial refutation of every finding before a fix is spent on it. The default route for any substantive prompt, auto-fires on broad-spectrum verbs (add, build, implement, refactor, redesign, restyle, migrate, debug, polish, audit) AND on architecture/scope/security surface (auth, crypto, migration, secret, token, password, schema, data model, API surface, refactor everywhere, across all). Invoke even when the user does not say "use the workflow", carve-outs are trivial factual Q&A, single-line typo fixes, and pure read-only inspection. When in doubt, invoke this skill, escalation to full ceremony is free, demotion is not.
---

# Hackify (One Workflow For Every Dev Task)

Hackify replaces plan/spec/brainstorm/execute/verify/review/finish ceremony with **one workflow + one markdown work-doc per task**. The work-doc is spec, plan, progress tracker, review log, and post-mortem in one file. Resume across sessions via "continue work on `<slug>`".

Self-contained. **Never call other skills**, third-party plugins may not be installed. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined here or in `references/`. Running a **script bundled inside this plugin** by path (the lawkeeper scanner behind the law-scout, `references/law-scout.md`) is not a skill call: no sibling skill is invoked, no sibling workflow is entered, and the file ships with hackify.

## The ship bar (always-on, no opt-in)

Every mode ends with work that is **proven to run**, not merely proven to compile. Four always-on mechanisms enforce it, and none of them asks the user first:

- **Two deterministic scouts at every wave-end and at review start.** The perf-scout (`references/perf-scout.md`) finds `perf.*` waste; the law-scout (`references/law-scout.md`) runs the bundled lawkeeper scanner over the touched files and finds `ban.*` / `cap.*` / `sec.*` / `clean.*` rule breaks. Every candidate gets one disposition, no silent drops.
- **The ship gate in Phase 4** (`references/ship-gate.md`). Build, boot, smoke the touched flow. A leg is blocking whenever the diff touched something that leg's target consumes, a written skip otherwise, never silently absent.
- **A coherence reviewer in every review wave** (Reviewer F). Parallel waves are what make hackify fast and also what let two halves of a feature disagree; F is the only lens that checks producer against consumer.
- **Refute before you fix, and exit on a settled diff.** Findings are judged by adversarial refuters before a fix is spent on them, and the review loop may only exit when a clean round scanned the diff that is actually on disk.
- **Maximum orchestration tier and a self-driving task loop** ([references/orchestration.md](references/orchestration.md)). Every mandatory fan-out runs at the heaviest orchestration the runtime offers (Claude Code: `ultracode` in scope plus the Workflow tool), and the workflow re-enters itself across turns until the phase ledger is fully ticked (Claude Code: `/loop` self-paced on `continue work on <slug>`). Announce the tier once in the Phase 2 plan and honor `light mode` / `no ultracode` / `cheap mode` / `single agent` at any point.

## When to invoke

- **Default for every prompt** that asks for any of: building / adding / fixing / refactoring / redesigning / restyling / debugging / polishing / migrating / testing / discussing-then-building.
- **Slash command:** `/hackify:hackify <ask>` to start, `/hackify:hackify resume <slug>` to continue.
- **Carve-outs (skill optional):** trivial factual Q&A, one-line typo fixes, pure read-only inspection that won't lead to writing/editing/committing.
- **Compressed-flow alternative:** for small bug fixes, single-file edits, and quick direct-effort requests, use `/hackify:quick`. Skips Plan+Gate, Spec review, Multi-reviewer, and 4-options finish; runs Clarify-if-ambiguous → Implement → Verify → 5-lite review → cleanup → summary; stays in quick mode until you explicitly switch to full hackify.
- **Full-autopilot alternative:** for substantive tasks where you trust the pipeline and don't want gates, use `/hackify:yolo`. Same phases as full hackify (clarify, exploration, plan, spec-review, implement, verify, multi-reviewer, finish) but Phase 2 sign-off and Phase 6 4-options menu auto-pass. No work-doc on disk → no pause/resume across sessions. Phase 5 multi-reviewer findings are auto-fixed in-place at every severity; inspect with `git diff HEAD~1` after the commit lands.

When in doubt, invoke. Redundant skill load is cheap; a missed one ships broken work.

## Working principles

Four principles frame every phase. Read [rules/four-principles.md](../../rules/four-principles.md) for the full doctrine.

- **Think Before Coding**, surface assumptions and ambiguity before code (operationalized by Phase 1).
- **Simplicity First**, minimum code that solves the ask (operationalized by Phase 3 file allowlists).
- **Surgical Changes**, every changed line traces to the request (operationalized by Phase 5 scope-consistency review).
- **Goal-Driven Execution**, convert asks into verifiable goals with `→ verify:` checks (operationalized by Phase 4 evidence-before-claims).

## The phases (lean, expert-led)

| Phase | What |
|---|---|
| 1 Clarify | Wizard questions in one batch, get user answers |
| 2 Plan | Draft work-doc, present, **HARD GATE: user signs off** |
| 2.5 Spec review | Parallel agents scrutinize work-doc for conflicting / inconsistent logic |
| 3 Implement | Order tasks by dependency, dispatch each wave to PARALLEL foreground agents |
| 3b Debug | Only if stuck after 2+ failed attempts |
| 4 Verify | Evidence Ledger (real proof per item) + three-layer re-verify + ship gate (build/boot/smoke) |
| 5 Review | PARALLEL multi-reviewer (security + quality + consistency + performance + coherence, design on UI), always |
| 6 Finish | Present 4 options, execute, archive work-doc, cleanup |

The only mandatory user gate is between **Plan** and **Spec review**. After Phase 2.5, implementation begins automatically. Phases 3-6 run continuously with progress reports at each transition. The user can interrupt anytime, the work-doc holds state.

**Parallelism is the default.** Whenever 2+ pieces of work are independent (clarify research, spec review, same-wave tasks, code review concerns, cross-package verification) dispatch foreground subagents in one message. Wave-based dependency ordering makes parallel implementation safe, same-file tasks split across waves.

## The work-doc (single source of truth)

- **Location.** `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` in flight; move to `<project>/docs/work/done/<YYYY-MM-DD>-<slug>.md` once shipped.
- **Skeleton** (`references/work-doc-template.md`). Frontmatter: `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`, `sprint_goal`. Body: Original Ask → Clarifying Q&A → Acceptance Criteria → Approach → Sprint Backlog → Daily Updates → Sprint Review → Retrospective.
- **State is the file.** No companion sidecar, no in-conversation memory. Resume = open file, read frontmatter, jump to the first unchecked checkbox.
- **Project root.** Each sub-project is its own git repo. Work-doc lives inside the project repo. Multi-project tasks: one doc per project, linked via `related` frontmatter field.

---

## The phase ledger, trackable, ordered (always-on)

Every task runs against a **phase ledger**: a trackable to-do list (the runtime's **todo tracker** primitive) with one item per phase, created at the **start of Phase 2**. It is the order-enforcer. Deep contract: [references/phase-ledger.md](references/phase-ledger.md).

- **One item `in_progress` at a time, no jumping ahead.** A later phase cannot start until the current phase's exit artifact exists and its item is `completed`. No phase is skipped: a carve-out is marked `completed` with a one-line reason, never deleted. Parallelism lives *inside* a phase (waves, reviewers), never across phases.
- **Phase 6 is split into sub-items** so archiving is its own line (`6c Archive → done/`), and it comes **before** the summary (`6d Summary + report`). The summary is unreachable while the archive item is open, so the work-doc always lands in `docs/work/done/` before any recap prints.
- **Reflect after each item:** one line, what changed, did it pass, what is next (the communication voice), then flip the item and start the next.
- **Resume rebuilds the ledger** from the work-doc's `status` + Sprint Backlog checkboxes; quick/yolo ledgers are session-local.

The ledger is a **separate layer** from the work-doc Sprint Backlog: the Backlog tracks code tasks (durable, task-level); the ledger tracks phases (session-local, phase-level). See [references/phase-ledger.md](references/phase-ledger.md) for the per-mode item lists and the exit-artifact table.

---

## Phase 1 (Clarify)

**Goal.** Groom the ask into a locked **Primary Goal & Guardrails** anchor, maximum understanding before any code. Phase 1 is a grooming session that drives every downstream plan and implementation decision and is enforced by the drift-check, so no question survives into Phase 3 and no later phase wanders off the goal. See [references/goal-anchor.md](references/goal-anchor.md).

1. **Load the always-on trio:** `references/communication-voice.md` (voice), `references/expert-mindset.md` (mindset), and `references/phase-ledger.md` (ledger contract), they govern every phase from here on. Create the phase ledger at its declared point: full hackify at the **start of Phase 2**, before drafting the work-doc; quick/yolo at task start, right after Phase 1 (see phase-ledger.md "When to create it").
2. **Classify task type:** `feature` | `fix` | `refactor` | `revamp` | `redesign` | `debug` | `research`. Drives questionnaire choice (`references/clarify-questions/README.md`).
3. **Read just enough context.** Broad architecture → scan entry points + follow imports; blast radius → grep symbol usages; single-module onboarding → read top-to-bottom; trivial single-file edits → skip exploration.
4. **Build ONE batched questionnaire.** Pull the relevant question bank from `references/clarify-questions/README.md` (per-task-type files: `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`; combine via `picking-and-combining.md`; always prepend `universal-preamble.md`). Each bank conforms to the canonical 4-section Wizard Contract (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA) at `references/clarify-questions/wizard-contract.md`. Strip questions whose answer is evident from ask or context. Add task-specific questions if the bank misses something. Recommended option is the **first** in each question, suffixed `(Recommended)`. The ~16-question target is a floor, not a ceiling, keep asking (across back-to-back wizard calls) until the anchor's five parts are all pinned: North-Star Goal, In-Scope, Out-of-Scope/Non-Goals, Guardrails/Invariants, Success Signals. Every question must fork a real decision; never pad with vanity questions.
5. **Send the questionnaire as a wizard, NEVER as plain markdown.** Every question you put to the user, in EVERY phase (clarify, a Phase 5 fix-approval batch, the Phase 6 finish menu), goes through the wizard tool; plain numbered lists in chat are forbidden. Questions must also obey the **Clarity law** in `references/clarify-questions/wizard-contract.md`: written so the user can answer without knowing how this workflow works. No task IDs, no phase numbers, no internal artifact names; name the real files and current behavior you found; and give every option a one-line "what happens if you pick this". Lead the first wizard message with a one-paragraph "What I heard you ask for" recap so misreadings surface early. Wizard takes 1-4 questions per call, 2-4 options per question, split longer questionnaires across **multiple back-to-back wizard-tool calls in the same turn** (fire the following batch as soon as prior answers land). Use `multiSelect: true` only for non-exclusive options; never for "pick one approach". "Other" free-text is auto-provided, never add one yourself.
6. **Wait.** Do not start Phase 2 until every wizard question is answered. One ambiguous answer → one targeted follow-up wizard call. No iterative interrogation.

**Hard rule.** No code, no file edits, no test runs in Phase 1. Output is a locked answer set **and** a complete Primary Goal & Guardrails anchor recorded in the work-doc (in-chat block for quick/yolo). See [references/goal-anchor.md](references/goal-anchor.md) and `references/clarify-questions/README.md`.

---

## Phase 2 (Plan + Gate)

**Goal.** A work-doc the user can scan in 60 seconds and say "go."

**First, open the phase ledger.** Create the trackable to-do list (todo tracker, one item per phase, Phase 6 split into sub-items) per the always-on ledger section above and [references/phase-ledger.md](references/phase-ledger.md). Set Phase 2 to `in_progress`. Then:

1. **Create the work-doc** at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Slug `kebab-case`, ≤6 words. Date is today.
2. **Fill from template** (`references/work-doc-template.md`). Required now: Original Ask (verbatim), Clarifying Q&A (verbatim), Acceptance Criteria (3-7 verifiable bullets), Approach (≤200 words; chosen path + 1-2 sentence rationale), Sprint Backlog (flat checklist, each task 5-30 min).
3. **Task granularity.** Each task independently testable and committable. Break "Add invitation expiry" into "Add `expires_at` column + migration", "Reject expired tokens in invitations service", "Show 'expired' state in UI", "Backend test", "Frontend test". Default: one commit per task.
4. **No placeholders.** No "TBD", no "implement error handling later", no "similar to T2". Decompose vague tasks now.
5. **Show the doc.** Paste rendered doc in chat or summarize and link. Ask: *"Sign off on this plan or call out anything to change?"*
6. **GATE.** Wait for explicit "go" / "approved" / "yes" before Phase 3.

**On pushback,** edit doc, show diff, re-ask. Iterate until signed off. See `references/work-doc-template.md`.

---

## Phase 2.5, Spec Self-Review (parallel, mandatory)

**Goal.** Catch inconsistent or conflicting logic in the work-doc *before* code is written. Cheap on paper; expensive after 200 LOC against a flawed spec.

1. **Dispatch 3 foreground reviewers in parallel in ONE message.** Each gets a self-contained prompt + absolute work-doc path:
   - **Reviewer A. Internal consistency + goal drift.** Read work-doc end-to-end. Find Q&A↔DoD↔Approach↔Sprint Backlog contradictions. Flag tasks not covered by any DoD bullet, DoD bullets not covered by any task, Q&A answers contradicting the Approach. **Drift-check:** trace every Sprint Backlog task + DoD bullet to the Primary Goal & Guardrails anchor, a task serving no In-Scope bullet → **drift (Important)**; one violating a Guardrail or Non-Goal → **Critical** (canonical wording: [references/goal-anchor.md](references/goal-anchor.md)).
   - **Reviewer B. Architectural / cross-cutting risks.** Match plan against project code-quality rules, if a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md`. Flag anything that would force a lint suppression, `!`, inline type, bare `Error` throw, or layering violation. Also flag plan-time performance risk: a plan item that would bake in a `rules/performance.md` Critical before code exists, an N+1-shaped task, unbounded fan-out, a list endpoint with no pagination.
   - **Reviewer C. Dependency / ordering / parallelism risks.** Build a quick dependency graph from Sprint Backlog. Flag tasks sharing a file (parallel conflict), missing prerequisites, ordering bugs (consuming a helper before its task), tasks too coarse to be 5-30 min.
2. **Aggregate findings.** Critical (plan bug forcing rework) / Important (fixable gap) / Minor (nit).
3. **Patch the work-doc.** Apply Critical + Important in place; record Minor in Retrospective.
4. **Re-gate ONLY if user's signed-off invariants changed** (Critical finding widened scope). Else straight to Phase 3.

Templates: `references/parallel-agents/phase-2.5-spec-review-a-consistency.md`, `references/parallel-agents/phase-2.5-spec-review-b-rules.md`, `references/parallel-agents/phase-2.5-spec-review-c-dependencies.md` (subdir index: `references/parallel-agents/README.md`). **Hard rule:** Phase 2.5 is non-skippable, even for small docs, a "small" plan can hide a contradictory Q&A pair. Cap each reviewer at ≤300 words.

---

## Phase 3, Implement (parallel waves, mandatory)

**Goal.** Ship the Sprint Backlog as fast as wall-clock allows by dispatching each wave to foreground parallel subagents in one message.

**Pre-flight, build the wave plan.**

```
1. List every task. For each: files CREATED/MODIFIED; earlier tasks required.
2. Sort by priority (DoD load-bearing first) and topological dependency.
3. Group into WAVES. NO file overlap, NO inter-task dep within a wave; wave N may depend on 1..N-1.
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
5. On red: classify, agent failure (re-dispatch sharper prompt) vs. plan failure
   (drop to Phase 3b). Never paper over.
6. Run BOTH deterministic scouts over the wave-touched files (union of the wave's
   allowlists), BEFORE ticking tasks: the perf-scout (references/perf-scout.md) and
   the law-scout (references/law-scout.md, the bundled lawkeeper scanner scoped with
   --paths-from). Trivial in-allowlist candidates are fixed in-wave; everything else
   is staged for Phase 5 in each scout's staging table, appended to the wave's Daily
   Updates entry. Every candidate carries exactly one disposition.
7. Tick wave checkboxes; append one Daily Updates entry per task.
8. Commit ONCE for the wave (conventional subject; body lists task IDs).
9. Advance to wave N+1.
```

**Per-task safety constraints (in each agent's prompt):**

| Constraint | Wording |
|---|---|
| File allowlist | "Modify only these files: `<list>`. If another file is needed, STOP and report, do not edit." |
| Command allowlist | "Run only these commands: `<list scoped to your files>`. The parent runs repo-wide checks." |
| TDD | "If test mode is test-first, watch the test fail before writing impl. Refuse to ship without a watched RED." |
| Self-review | "Self-review against the checklist before reporting done. Report pass/fail per item + any Approach deviations." |
| Word cap | ≤200 words per agent report. |

Template: `references/parallel-agents/phase-3-implementation.md`. **Single-task waves are fine**, dispatch a single agent; discipline (self-contained prompt, declared files, scoped commands) still applies.

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

**Wave-end persistence (mandatory).** Before dispatching wave N+1, the parent MUST update the work-doc: tick the completed checkboxes in the Sprint Backlog, append a Daily Updates entry summarizing what each agent produced, run `bash scripts/validate-dod.sh` (or the project's verification triad), and advance frontmatter `current_task` to the upcoming wave's task IDs. Skipping this step is an abandoned-state bug, interrupting between waves loses no progress; interrupting mid-wave-update loses the wave.

---

## Phase 3b, Debug (only when stuck)

**Trigger.** ≥2 failed fix attempts on the same task, OR a test failure whose message doesn't match the expected error, OR a regression surfaced by unrelated work.

**4-phase root-cause hunt** (do not skip phases):

```
1. ROOT CAUSE, reproduce reliably, gather evidence at every component boundary,
   trace the bad value to its source.
2. PATTERN ANALYSIS, find a working analogue, list every difference.
3. HYPOTHESIS, write: "I think X is the cause because Y." Make ONE smallest change. Run.
4. IMPLEMENT, write a failing test reproducing the bug, fix the SOURCE (not symptom),
   watch the test go green, watch all other tests stay green.
```

**Circuit breaker.** After 3 failed hypotheses, **stop**, architectural problem. Document dead-ends in the work-doc and surface to the user.

**Hard rules.** No "quick fix for now." No multiple fixes at once. No skipping the failing-test step. See `references/debug-when-stuck.md`.

---

## Phase 4 (Verify)

**Goal.** Prove every task and requirement landed AND that the app actually runs. Evidence before claims. Three parts, full spec in `references/review-and-verify.md`.

**Part 1. Evidence Ledger (per-item proof).** One row per Sprint Backlog task AND per Acceptance-Criteria bullet: `Item | Type | Claim | What I ran | Proof sample | Result`. The proof sample is a REAL, trimmed slice of output, never a summary, never invented. A missing or ❌ row blocks Phase 5. The ledger is saved in the work-doc Sprint Review and rendered again in the Phase 6 HTML report's evidence appendix (cumulative proof in one place).

**Part 2. Three-layer re-verify (prove it without drifting).** Run in order; re-run any layer on demand when the user says "prove it again".

| Layer | What | Runs in |
|---|---|---|
| 1 Fresh triad | test + lint + typecheck from a clean state (all packages, no warm cache) | all |
| 2 Goal-drift re-check | trace every proof to the North-Star Goal + Success Signals in the anchor; a signal with no proving row = not done | all |
| 3 Independent re-prove | re-earn the proof without trusting Layer 1, clean re-run or a fresh subagent | hackify + yolo |

**Part 3. Ship gate (prove it runs).** A green triad says the code is well-formed, not that it starts. Run three legs and record one ledger row each: `ship.build` (builds clean from a cold cache, artifact on disk), `ship.boot` (starts, reaches a real ready signal, tears down clean), `ship.smoke` (the critical path this sprint touched works against the running app). **A leg is blocking whenever the diff touched something that leg's target consumes (source the build compiles, config read at startup, the touched flow); a written `⏭ skipped` row with the reason otherwise; never silently absent.** The trigger is the diff, not whether a run command exists, so a docs-only change records skips rather than booting the app. Detection table per ecosystem, readiness-probe rules, and the secrets/state guards: [references/ship-gate.md](references/ship-gate.md). Runs in every mode, quick included.

**Top-level acceptance rows (each appears in the ledger):**

- [ ] All tests pass, fresh test output (exit 0, 0 failures, 0 errors)
- [ ] Linter clean, fresh lint output (0 errors)
- [ ] Typecheck clean, fresh typecheck output (0 errors)
- [ ] All `Sprint Backlog` checkboxes ticked
- [ ] Every Phase 2 acceptance bullet has a ledger row with a proof sample
- [ ] No placeholders, no `TODO` without owners, no `console.log`/`println!`, no commented-out code
- [ ] No new lint or type-checker suppressions (inline ignore directives, file-level disables, expect-error pragmas outside test files), zero tolerance
- [ ] No new `!` non-null assertions in production code
- [ ] Perf-scout AND law-scout run on the sprint diff, every candidate dispositioned (fixed / staged / false-positive with reason)
- [ ] No new Critical or Important violation of `rules/performance.md` (Reviewer D confirms in Phase 5)
- [ ] No new Critical or Important violation of the engineering law (Reviewer B confirms the law-scout rows in Phase 5)
- [ ] Ship gate: `ship.build`, `ship.boot`, `ship.smoke` rows all present, each ✅ or `⏭ skipped` with a written reason
- [ ] Manual smoke check (if user opted in), list steps and outcomes

**On any red, do NOT advance to Phase 5.** Loop back to Phase 3 (or 3b if stuck).

---

## Phase 5, Review (parallel multi-reviewer, mandatory)

**Default: dispatch FIVE foreground reviewers in parallel in ONE message** (A, B, C, D, F), plus E as a sixth on UI-bearing diffs. Self-review is the floor, not the ceiling, for any diff beyond a one-line typo, multi-reviewer is on.

**Build the three dispatcher inputs BEFORE the message goes out.** Each is the parent's job; a reviewer that receives an unfilled placeholder refuses and reports it, which costs a whole round.

| Input | Goes to | Built from |
|---|---|---|
| `{{law_scout_report}}` | Reviewer B | law-scout re-run on the whole sprint diff (`references/law-scout.md`) |
| `{{perf_scout_report}}` | Reviewer D | perf-scout re-run on the whole sprint diff (`references/perf-scout.md`) |
| `{{task_file_index}}` | Reviewers C **and** F | the work-doc's Execution waves block plus each task's file allowlist, keyed `W<n>/T<m>`. Build it once and pass the same map to both: F reads the `W<n>` prefix to find same-wave seams, C matches on `T<m>` |

Surviving candidates from both scouts enter the decision table beside reviewer findings.

- **Reviewer A. Security & correctness.** Auth, permissions, injection, CORS, cookies, secrets, PII, migrations, crypto, race conditions. Adversarial intent.
- **Reviewer B. Quality, layering & engineering law.** DRY, named types, layering (routes pure / services own DB), file/function caps, lint suppressions, `!` non-null, empty catches, bare `Error` throws, dead code. Consumes the law-scout table and re-judges every row, then applies the semantic tier no grep can reach: one-construct-per-file, folder/topology conformance, controller purity, single responsibility, reuse and magic literals, SOLID/YAGNI, and test coverage of what this diff added. Cites lawkeeper `rule_id`s (`references/law-scout.md`).
- **Reviewer C. Plan consistency, scope & goal drift.** Diff vs. work-doc DoD + Sprint Backlog. Missing items, scope creep, anything contradicting a Q&A answer or the Approach. **Drift-check:** trace every changed hunk to the Primary Goal & Guardrails anchor, a hunk serving no In-Scope bullet → **drift (Important)**; one violating a Guardrail or Non-Goal → **Critical** (canonical wording: [references/goal-anchor.md](references/goal-anchor.md)).
- **Reviewer D. Performance.** Semantic perf lens: consumes the scout report, judges every staged candidate, and hunts what greps cannot. N+1 shapes, algorithmic complexity, unbounded growth (caches, listeners, result sets), wasted parallelism, blocking I/O on request paths, render storms. Cites `perf.<domain>.<slug>` catalog IDs from `rules/performance.md` and sets final severity. Adversarial intent, a hot path is hot until proven cold.

- **Reviewer F. Cross-module coherence** *(standing, every wave)*. The only lens that asks whether the pieces agree with each other. For every boundary-crossing symbol it names the producer and every consumer, then checks shape agreement (fields, optionality, nullability, enum sets), semantic agreement (units, timezones, identifier space, ordering, range bounds), error-contract agreement (throw vs null vs result object), duplicate concepts that should have reused a shared definition, and wiring completeness (route registered, handler subscribed, component mounted, column actually read). Cites file:line for BOTH sides. It exists because Phase 3's parallel waves build each half blind to the other. Template: `references/parallel-agents/phase-5-multi-review-f-coherence.md`.

- **Reviewer E. Design conformance** *(joins as the sixth whenever the diff is UI-bearing)*. Audits the diff against the project's committed `docs/design/DESIGN.md`: hardcoded color/size/shadow literals where a token exists, off-ramp type sizes, components missing documented hover/focus/press/disabled states, violations of the spec's own Don'ts list, WCAG AA contrast and focus regressions, and physical properties where logical are required. Names the exact replacement token for every finding. When reference screenshots of the target design exist, it compares the rendered result against them side by side. With no spec present it falls back to the `references/frontend-design.md` visual law and reports the missing spec. Template: `references/parallel-agents/phase-5-multi-review-e-design.md`.

Cap at 6 reviewers. A, B, C, D and F always run; E takes the sixth slot on UI-bearing diffs, otherwise a second-concern specialist may (`references/parallel-agents/phase-5-escalation.md`). **Self-review still happens** by you, against `references/review-and-verify.md`'s checklist, reviewers are *additive* defense, not replacement.

**Carve-out (skill optional).** A diff that is *purely* a one-line typo / comment / config-only change can skip multi-reviewer. When in doubt, dispatch.

**Acting on feedback, address ALL findings (lawkeeper-style loop).** Build a decision table (Finding / Severity / Decision / Evidence) covering EVERY finding, **refute before you fix**, work the survivors in severity order, and **re-run review + verify to prove zero remaining**. No finding is left un-addressed.

**Refute before you fix.** A reviewer's finding is a claim, not a fact. Before spending an edit on it, dispatch the adversarial refuters in one message (`references/parallel-agents/phase-5-refute.md`): two independent refuters with distinct lenses (reproduction, authority) per Critical, one batched refuter for the whole Important+Minor set. **The default is to KEEP the finding**, uncertainty is never a refutation, and a Critical dies only when BOTH refuters refute it with a file:line counter-citation. Dropping a real defect costs more than fixing a phantom, so the bias runs the opposite way from a content-generation refuter panel. Their verdicts are what let a `push-back` carry the evidence this workflow already demands.

| Severity | Action |
|---|---|
| Critical | Fix immediately, before merging. |
| Important | Fix before claiming Phase 6 done. |
| Minor | Fix too, defer to Retrospective ONLY with explicit user sign-off, never by default. |

Non-trivial fixes go through a batched approval wizard (propose 2-3 options, ask before writing); trivial fixes applied directly. After each batch, re-run both scouts and re-dispatch the reviewers until the decision table is empty. **Exit only on a settled diff:** a round that changed any code mandates another round, because that round's clean result describes the pre-fix diff, not the one on disk. The loop ends when a full round finds nothing AND `git diff <base>..HEAD` is byte-identical to what that round scanned. Push back only with **technical evidence**, never performative agreement. Full loop + response pattern: [references/review-and-verify.md](references/review-and-verify.md).

---

## Phase 6 (Finish)

**Goal.** Land the work cleanly and archive the doc.

**Step A, re-run verification.** Even if Phase 4 passed. Pre-merge state drifts.

**Step B, present exactly 4 options, no open-ended choice:**

| # | Option | Default for |
|---|---|---|
| 1 | Merge to base branch locally | Small in-place changes |
| 2 | Push and create a PR | Cross-team or larger changes |
| 3 | Keep the branch as-is | Work pauses; no cleanup |
| 4 | Discard this work | Requires user typing "discard" verbatim, no shortcut |

**Step C, execute the choice.** **1 or 2:** Commit follows project convention; ends with Claude Code Co-Authored-By trailer. PRs include Summary, Test plan, and link to work-doc. **3:** Stop. Leave everything in place. **4:** Confirm, then `git checkout` base branch and remove worktree if any. Never `git reset --hard` without explicit user instruction.

**Step C.5. Cleanup sweep** (mandatory; runs before archive). Sweep for 8 classes of leftover/abandoned/stale state introduced or surfaced during the sprint. Each class needs a one-line evidence record in the work-doc Phase 6 archive (0 findings counts).

| # | Cleanup class | Audit |
|---|---|---|
| a | Stale cross-references | grep for references to files/sections that no longer exist after this sprint. |
| b | Broken internal anchor links | scan markdown anchor links inside touched files. |
| c | TODO/FIXME without owners | grep diff for new `TODO`/`FIXME` lacking an explicit owner or follow-up issue. |
| d | Empty directories left after file moves | `find` for empty dirs under primitives. |
| e | Dead branches | local + remote branches created during the sprint that won't be merged. |
| f | Unrelated changes that snuck in | final scope-creep audit: `git diff main..HEAD` cross-checked against work-doc Sprint Backlog file allowlists. |
| g | Pre-existing errors + dead code in touched files (lint/type/test failures, dead code) | detect against the sprint-start baseline; surface and **offer to fix** so touched files end with nothing a reviewer would flag (auto-fix in yolo). Defer only if too large, with explicit user sign-off. |
| h | Work-doc references to file paths that just changed | grep the work-doc itself + any sibling work-docs for paths that moved/deleted in this sprint. |

If any class finds defects, fix them inline before archiving; if a defect is too large for this sprint, file a follow-up Retrospective entry and link to it. The touched-scope goal is the **best version**, zero outstanding lint/type/test/dead-code issues in files this sprint changed; whole-repo pre-existing issues stay out of scope (that is `/hackify:lawkeeper`'s job). Detailed audit + baseline commands per class: `references/finish.md`.

**Step D, archive the work-doc** (1 or 2): move `<project>/docs/work/<slug>.md` → `<project>/docs/work/done/<slug>.md`. Update `status: done`. Retrospective is mandatory, 3-8 bullets on what surprised, what to remember. This is phase-ledger item **6c**; its exit artifact (the doc physically in `done/` with `status: done`) is the **hard precondition for Step F**. **Do not print the summary or emit the report until this move is complete**, the summary is the reward for archiving, not a substitute.

**Step D.5. Codewalk follow-up** *(since v0.3.2; 1 or 2 only)*: if the task touched an entry-point file (controller, CLI command, queue/Inngest function, UI action, route handler), ask the user via `AskUserQuestion` whether to *update an existing* `.codewalk/<slug>/` trace, *create a new codewalk* for the touched entry, or *skip*. On Update/Create, invoke `/codewalk <entry-point>` immediately, codewalk runs in update-by-default mode so a re-invoke preserves manual edits and produces an amber diff callout. Skip silently when no entry-point files were touched. Details + the file-pattern detection list + the exact AskUserQuestion shape: `references/finish.md` Step D.5.

**Step E, worktree cleanup** (1, 2, or 4): `git worktree remove <path>`; delete the local branch if merged. NOT for option 3.

**Step F. Update log + HTML report** (1 or 2 only). **Precondition: Step D archive is done**, the work-doc must already be in `docs/work/done/` with `status: done`, and ledger item `6c` `completed`, before this step runs. If it is not, go back and archive first. Print a plain-language **update log**: one block per change the user would recognize, each with five fields in this order, **Problem** / **Root cause** / **Solution** / **Verification evidence** / **Deployment status**, separated by a line containing exactly `----`. Write it the way you would explain the work out loud to someone who was not in the room: everyday words, no jargon they did not use, and never a phase number, task ID, reviewer letter or scout name. Append the same log to the archived work-doc inside Retrospective under a new `## Update log` subheading. **Then emit a styled, self-contained HTML report** (stats, inline-SVG charts, findings, action items, next steps) beside the archived work-doc at `<slug>.report.html`, see [references/html-report.md](references/html-report.md). Field-by-field guidance, voice rules, and a worked example: `references/finish.md` "Step F (Update log + HTML report)".

**Invoking the summary on demand.** The update log runs any time via `/hackify:summary` or phrase trigger ("show summary", "summarize", "summary table", "show me what changed"). Mid-flight invocation prints to chat; Step F also appends to the work-doc.

---

## Pause / Resume

**Pause**, user can stop at any time. The work-doc holds state; do not summarize in chat unless asked.

**Resume**, on "continue work on `<slug>`" or "resume hackify":

1. Locate the work-doc, search `<project>/docs/work/*.md` for the slug. Multiple project candidates → ask which. Fallback: recursively search known project roots.
2. Read frontmatter. Honor `status` and `current_task`.
3. Read the latest Daily Updates entry to see where you stopped.
4. Confirm: *"Resuming `<title>` at `<status>`, upcoming task: `<T<n>>`. Continue?"*
5. Resume from the appropriate phase, do NOT re-run earlier phases unless asked.

**Stale doc detection.** If `created` is >14 days old, check whether the codebase moved underneath the plan (`git log --since="<created>" -- <touched files>`). On drift, surface it before continuing.

**Back-compat: section-name labels.** When resuming a work-doc, accept EITHER the new sprint labels (`Acceptance Criteria`, `Sprint Backlog`, `Daily Updates`, `Sprint Review`, `Retrospective`) OR the legacy labels (`Definition of Done`, `Tasks`, `Implementation Log`, `Verification`, `Post-mortem`). Pre-v0.2.0 archived work-docs in `docs/work/done/` use the legacy labels; new work-docs use the sprint labels. No migration of archived docs is required.

### Pause checkpoint (mid-wave exit)

**Pause checkpoint (mid-wave exit).** When the user's prompt contains any of the **pause-keyword list**, `pause`, `stop`, `exit`, `later`, `tomorrow`, `come back`, `pick this up later`, during an active wave, the parent does five things in order: (1) wait for any in-flight subagents to return; (2) finish the work-doc update for completed agents (tick their checkboxes, append their Daily Updates entry); (3) write a `## Pause checkpoint` entry to the Daily Updates with timestamp, completed-task list, and partial-state notes; (4) update frontmatter `current_task` to reflect the partial-state (e.g., `W3b. T3.2 done, T3.3 in progress (deferred to a later session)`); (5) tell the user: `Your progress is saved. Resume with "continue work on <slug>".`

---

## Parallel agents (the default, not the exception)

Whenever 2+ pieces of work are independent, **dispatch foreground subagents in parallel in a single message**. Never sequential when independent.

**Runtime caveat (honest about degradation).** Parallel dispatch needs a subagent primitive. On the **native tier** (Claude Code, OpenCode) these phases fan out concurrently. On the **best-effort tier** (Codex CLI/App, Gemini CLI, Cursor, no subagent primitive, see `references/runtime-adapters.md`) the *same mandatory phases still run*, but **inline and sequentially**, you keep the rigor, you lose the wall-clock win. The workflow degrades concurrency, never coverage; it does not silently skip a phase on a runtime that can't parallelize. Runtimes with structured-output subagents may return reviewer/scout findings as machine-readable data instead of prose tables, see `references/runtime-adapters.md`.

**Every sub-agent prompt conforms to the canonical Template Contract** in `references/parallel-agents/template-contract.md`, the 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT) with `{{snake_case}}` placeholders. Binding because Haiku-class models read these prompts; the structure prevents soft-language / missing-verification / unanchored-severity failure modes from the v0.1.0 post-mortem. New templates MUST conform.

**Use parallel agents for:**

| Phase | Use | Status |
|---|---|---|
| 1 | Research, different code areas, refs, questions | optional |
| 2.5 | Spec self-review, 3 reviewers scrutinize work-doc | MANDATORY |
| 3 | Implementation waves, one agent per task (parent runs both scouts at wave-end) | MANDATORY |
| 3b | Debug evidence gathering, different component boundaries | optional |
| 4 | Cross-module verification, tests in different packages | optional |
| 5 | Multi-reviewer code review, security/quality-and-law/plan/performance/coherence lenses, plus design conformance on UI-bearing diffs | MANDATORY (non-trivial diffs) |
| 5 | Adversarial refuters over the decision table, before any fix is applied | MANDATORY (non-trivial diffs) |

**Do NOT use parallel agents for:** tasks sharing a file in the same wave (wave planner splits them); tightly-coupled investigations where each finding informs the next; one-line typo fixes (overhead exceeds value). Templates in `references/parallel-agents/README.md`.

---

## Frontend design work (special handling)

For tasks touching **UI / styling / theming / layout / components / typography / colors / spacing / icons / forms / motion / brand / RTL** on web **or** native, before drafting the Plan **load `references/frontend-design.md`** (the visual law) and treat its rules as binding. It loads the design-spec package in turn.

**Design work produces a spec before it produces components.** The artifact is a committed `DESIGN.md` in the *user's* project at `<project>/docs/design/DESIGN.md`, with its visual catalog at `docs/design/preview.html`, machine-readable tokens plus the prose that explains them, so intent survives the session and reviewers have something to check against.

| Situation | Phase 1 → 2 action |
|---|---|
| Spec exists at `docs/design/DESIGN.md` | Load it; its tokens are binding. A raw hex in a component is a defect. |
| Tokens exist, no spec | Run `references/design-spec/extract-protocol.md` Mode A; propose the recovered spec. |
| Neither, task is UI-bearing | Pick a direction from `references/design-spec/direction-library.md` in Phase 1; author the spec in Phase 2 **before** any component. |
| One-line copy/color/spacing fix | No spec needed; honor the existing one. |

Contract, schema, and the web↔native token mapping: `references/design-spec/spec-contract.md`. Twelve ready-to-drop specs: `references/design-spec/catalog/`. Standalone entry point: `/hackify:designify`. Conformance is enforced in Phase 5 by Reviewer E.

---

## Code quality (always-on)

Hackify enforces the project's code-quality rules. If a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md` (canonical doctrine; the legacy `references/code-rules.md` path is a forwarding stub). Hard caps non-negotiable, headline: ≤40 LOC per function, ≤3 params, ≤500 LOC per file, 0 lint suppressions; full list: `rules/hard-caps.md` (canonical, injected every prompt). The `UserPromptSubmit` hook injects THREE rules files into every prompt, `rules/hard-caps.md` (caps), `rules/expert-mindset.md` (mindset), `rules/perf-guardrails.md` (performance), so all three laws are always loaded; the deeper doctrine in `rules/code-quality.md` loads on demand from Phase 2.5 Reviewer B and Phase 5 Reviewer B.

**Performance law.** `rules/perf-guardrails.md` is the always-on tier; the canonical catalog is `rules/performance.md` (stable `perf.<domain>.<slug>` IDs + severity model), loaded by implementers, Reviewer D, and the scout; the deterministic scan protocol lives in `references/perf-scout.md`.

Patterns: reusable/generic/shareable by default (the prime directive), DRY, named types for any 2+ prop shape, one construct + one component per file, consistent folder structure, explicit over clever, single responsibility, every code path tested, edge cases handled. Depth: `rules/code-quality.md`.

---

## Expert mindset (always-on)

Approach every task as a **senior, multi-disciplinary engineer**, problem-solver, security engineer, performance engineer, solutions architect, tech advisor, verifier, and wear the hat the moment calls for. The work ships to real users: a skipped phase, an unproven claim, or a missed edge case is a production incident waiting to happen, not a style nit. Think before you type, prove instead of claim, reflect after each step, and when unsure stop and ask. A tight version is injected on every prompt (`rules/expert-mindset.md`); the fuller doctrine, the hat-by-hat table and the deliberate-work rules, is in `references/expert-mindset.md`, loaded from Phase 1 alongside the communication voice.

---

## Communication voice (always-on)

Hackify talks in **B2 (upper-intermediate) English** so non-native readers can follow, and every message is **self-explanatory**, it says WHAT you are doing and WHY. Before each phase or tool batch, lead with one short line of intent; at the end of a phase, state in plain words what changed, whether it passed, and what is next. Short sentences, common words, define jargon once, active voice, lists over walls of text. This governs chat prose ONLY, code, commands, file paths, identifiers, and commit messages stay exact. Load `references/communication-voice.md` from Phase 1; it applies to every phase.

---

## File map

| Path | Purpose |
|---|---|
| `SKILL.md` | this file (the workflow) |
| `references/communication-voice.md` | B2 + self-explanatory chat voice (load Phase 1; always-on) |
| `references/phase-ledger.md` | trackable ordered phase ledger, order-enforcer + archive gate (load Phase 1; always-on) |
| `references/expert-mindset.md` | senior multi-hat mindset + stakes framing (load Phase 1; always-on) |
| `references/work-doc-template.md` | markdown skeleton for every task |
| `references/clarify-questions/` | per-task-type question banks for Phase 1 (subdir index: `README.md`; canonical wizard contract: `wizard-contract.md`) |
| `references/implement-and-test.md` | TDD walkthrough, per-stack test commands |
| `references/debug-when-stuck.md` | 4-phase root-cause hunt for Phase 3b |
| `references/review-and-verify.md` | DoD + self-review checklist + escalation rules |
| `references/finish.md` | Phase 6, 4-options, archive, worktree cleanup |
| `references/frontend-design.md` | visual law (load on FE/UI/design tasks); loads the design-spec package |
| `references/design-spec/` | the design artifact: `spec-contract.md` (DESIGN.md schema + web↔native mapping), `direction-library.md` (the 12 directions, the plugin's only direction list), `extract-protocol.md` (derive a spec from code / reference / screenshots), `catalog/` (12 ready-to-drop specs) |
| `assets/design-preview-template.html` | self-contained visual catalog; fill with a spec's tokens → `docs/design/preview.html` |
| `rules/code-quality.md` (plugin root) | SOLID/DRY/types/layering deep dive, canonical location (legacy `references/code-rules.md` is a forwarding stub) |
| `rules/performance.md` (plugin root) | canonical perf catalog, stable `perf.<domain>.<slug>` IDs + severity model (load: implementers, Reviewer D, scout triage) |
| `rules/perf-guardrails.md` (plugin root) | always-on perf stub, injected every prompt by the `UserPromptSubmit` hook |
| `references/perf-scout.md` | deterministic perf-scout protocol (run: every Phase 3 wave-end + Phase 5 start) |
| `references/law-scout.md` | deterministic engineering-law scan, the bundled lawkeeper scanner scoped to touched files (same two run points) |
| `references/ship-gate.md` | runtime proof protocol, build + boot + smoke (run: Phase 4, every mode) |
| `references/orchestration.md` | orchestration tier (`ultracode`) + iteration driver (`/loop`), both on by default; the standing authorization and its opt-out |
| `references/parallel-agents/` | parallel subagent dispatch templates (subdir index: `README.md`; canonical template contract: `template-contract.md`) |
| `evals/evals.json` | optional eval harness |

Load reference files **only when the phase needs them**, keeps context lean.

---

## Anti-rationalizations (STOP and reset)

| Thought | Reality |
|---|---|
| "This task is too small for the workflow" | Use it. Small tasks ship broken without DoD. |
| "I'll skip the gate, the user will be happy I'm fast" | The gate is the only thing protecting against misread asks. |
| "I'll print the summary now and archive after" | The ledger blocks it. Archive (item `6c`) gates the summary (item `6d`). The doc moves to `done/` first. |
| "I can skip this phase and catch up later" | The ledger forbids it. One item `in_progress`; no later phase starts until the current one is `completed`. |
| "Tests after will be fine, I know what I'm building" | Tests-after pass immediately and prove nothing. |
| "One more fix attempt before debug mode" | The 2-attempt limit is the circuit breaker. Honor it. |
| "I can self-review a 600-LOC diff" | No, you can't. Escalate. |
| "The user said 'just do X', skip the questionnaire" | If X has any ambiguity, batched questionnaire still applies. Trim it, don't skip it. |
| "Lint suppression is fine just this once" | Zero tolerance. Fix the root cause. |
| "Tests are green, so the app works" | Tests import modules. They do not start a server, read env, or run migrations. Run the ship gate. |
| "Nothing to run here, skip the ship gate" | Then write the `⏭ skipped` row with the reason and the manifest you read. A missing row is a failed gate. |
| "The re-scan was clean, we're done" | Only if the diff has not changed since. Fixes applied after a scan were never reviewed. |
| "The reviewer said Critical, just fix it" | Refute first. A wrong Critical fix breaks working code. Two refuters, both must refute, or it stands. |
| "Each agent's piece passed, so the feature works" | Wave agents build blind to each other. Reviewer F is the only check that the pieces agree. |
| "I'll `/loop` this phase until it's clean" | Wrong layer. The iteration driver carries the TASK across phases; the review and debug loops stay inline inside their phase. |
| "The gate is open, I'll loop and check back" | A gate is a question only the user can answer. Looping at one burns tokens waiting for a human. Stop and surface. |

---

## Runtime primitives (where the tool names go)

This SKILL.md uses **runtime-primitive names** (wizard tool / subagent dispatcher / file-read op / file-write op / file-edit op / search / shell / todo tracker / orchestration tier / iteration driver) rather than Claude-Code-specific tool names. Each target runtime maps these primitives to its own native tool via `references/runtime-adapters.md`. The mapping is the responsibility of the runtime, not the workflow, hackify's design law is identical across all 7 supported runtimes.

## One-line summary

Clarify up-front → gate before code → walk small tasks with self-review → verify with fresh evidence → finish with explicit options → archive. One file holds it all.
