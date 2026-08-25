---
name: hackify
description: One unified end-to-end dev workflow for ANY substantive task, feature, bug fix, refactor, redesign, design, debug, migration, or research-then-build. Driven by one markdown work-doc at <project>/docs/work/, with every clarifying question asked up front in one batched questionnaire, a hard gate before code is written, dependency-ordered implementation waves and parallel review waves, mandatory evidence before claims, an always-on ship bar that proves the app builds and boots and serves the touched flow, and file-driven pause/resume across sessions. The default route for any substantive prompt, auto-fires on broad-spectrum verbs (add, build, implement, refactor, redesign, restyle, migrate, debug, polish, audit) AND on architecture/scope/security surface (auth, crypto, migration, secret, token, password, schema, data model, API surface, refactor everywhere, across all). Invoke even when the user does not say "use the workflow", carve-outs are trivial factual Q&A, single-line typo fixes, and pure read-only inspection. When in doubt, invoke this skill, escalation to full ceremony is free, demotion is not.
---

# Hackify (One Workflow For Every Dev Task)

Hackify replaces plan/spec/brainstorm/execute/verify/review/finish ceremony with **one workflow + one markdown work-doc per task**. The work-doc is spec, plan, progress tracker, review log, and post-mortem in one file. Resume across sessions via "continue work on `<slug>`".

Self-contained. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined here or in `references/`. **Three tiers govern what may be invoked, and only the third is banned.** (a) **Runtime-native skills** (`loop`) are allowed, but only where `references/runtime-adapters.md` maps them to a primitive with a written degrade cell, and the phase must still complete when the skill is absent. (b) **Skills that ship inside this plugin** (`/codewalk` at Phase 6 Step D.5, `/hackify:summary`) are allowed, they install together. Running a **bundled script** by path (the lawkeeper scanner behind the law-scout, `references/law-scout.md`) is not a skill call at all. (c) **Third-party plugin skills are never invoked**, they may not be installed. When in doubt, inline the behavior.

## The ship bar (always-on, no opt-in)

Every mode ends with work that is **proven to run**, not merely proven to compile. Four always-on mechanisms enforce it, and none of them asks the user first:

- **Two deterministic scouts at every wave-end and at review start.** The perf-scout (`references/perf-scout.md`) finds `perf.*` waste; the law-scout (`references/law-scout.md`) runs the bundled lawkeeper scanner over the touched files and finds `ban.*` / `cap.*` / `sec.*` / `clean.*` rule breaks. Every candidate gets one disposition, no silent drops.
- **The ship gate in Phase 4** (`references/ship-gate.md`). Build, boot, smoke the touched flow. A leg is blocking whenever the diff touched something that leg's target consumes, a written skip otherwise, never silently absent.
- **The coherence lens is never silently absent** (Reviewer F). A wave's implementer is blind to the waves that ran before it and to every line of pre-existing code, which is exactly where a producer and its consumers drift apart; F is the only lens that checks producer against consumer. It runs whenever the diff crosses a module boundary, which is most waves, and when it folds its residual checklist is handed to Reviewer B, so the check happens either way.
- **Refute before you fix, and exit on a settled diff.** Findings are judged by an adversarial refuter before a fix is spent on them, and the review loop may only exit when a clean round scanned the diff that is actually on disk.
- **Maximum orchestration tier, a self-driving task loop, and an independent completion sentinel** ([references/orchestration.md](references/orchestration.md)). The first two are **tool calls you make**, not a posture you describe. A pipelined fan-out (a reviewer panel that feeds per-finding refutation) is dispatched through the **Workflow tool**, whose opt-in these very instructions satisfy; a flat same-shaped batch stays a single parallel subagent message. And any turn that ends with a phase-ledger item still open **invokes the `loop` skill** self-paced on `continue work on <slug>`. A turn that leaves work open without that call has dropped the task. And every task hands the user a paste-ready `/goal <condition>` line so a **separate evaluator**, not you, rules on whether the task is finished; you can print that line but you can never set it yourself, and the driver's stop conditions outrank the evaluator. Announce the tier once in the Phase 2 plan and honor `light mode` / `no ultracode` / `cheap mode` / `single agent` at any point.

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
| 2.5 Spec review | 1 reviewer scrutinizes work-doc for conflicting / inconsistent logic, three lenses over one read |
| 3 Implement | Order tasks by dependency, dispatch each wave to ONE foreground agent |
| 3b Debug | Only if stuck after 2+ failed attempts |
| 4 Verify | Evidence Ledger (real proof per item) + three-layer re-verify + ship gate (build/boot/smoke) |
| 5 Review | PARALLEL multi-reviewer (security + quality + consistency + performance + coherence lenses, design on UI), always |
| 6 Finish | Present 4 options, execute, archive work-doc, cleanup |

The only mandatory user gate is between **Plan** and **Spec review**. After Phase 2.5, implementation begins automatically. Phases 3-6 run continuously with progress reports at each transition. The user can interrupt anytime, the work-doc holds state.

**Parallelism is the default.** Whenever 2+ pieces of work are independent (clarify research, code review concerns, cross-package verification) dispatch foreground subagents in one message. Phase 3 is the one place that gives it up on purpose: a wave's tasks are file-disjoint but they read the same code, so ONE agent takes the whole wave. Waves still run in dependency order and same-file tasks still split across waves. Spec review is dispatched to a subagent too, it is just a single reviewer rather than a fan-out.

## The work-doc (single source of truth)

- **Location.** `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` in flight; move to `<project>/docs/work/done/<YYYY-MM-DD>-<slug>.md` once shipped.
- **Skeleton** (`references/work-doc-template.md`). Frontmatter: `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`, `sprint_goal`. Body: **Phase ledger (section 0)** → Original Ask → Clarifying Q&A → Acceptance Criteria → Approach → Sprint Backlog → Daily Updates → Sprint Review → Retrospective.
- **State is the file.** No companion sidecar, no in-conversation memory. Resume = open file, read frontmatter, read the `## 0. Phase ledger` block back to find the open phase (an older doc without that block falls back to rebuilding the ledger, see the ledger section below), then jump to the first unchecked Sprint Backlog checkbox.
- **Project root.** Each sub-project is its own git repo. Work-doc lives inside the project repo. Multi-project tasks: one doc per project, linked via `related` frontmatter field.

---

## The phase ledger, trackable, ordered (always-on)

Every task runs against a **phase ledger**: one item per phase, ticked in order. It is the order-enforcer. Deep contract: [references/phase-ledger.md](references/phase-ledger.md).

The ledger opens at task start in every mode as a printed block, and in full hackify it is **written into the work-doc as section 0 at Phase 2 step 1**.

- **Substrate, primary then fallback.** The ledger is surfaced through the runtime's **todo tracker** primitive when the session actually exposes one, and through a printed markdown checklist in chat, re-printed at **every** phase boundary, when it does not. In full hackify it lives in the work-doc's `## 0. Phase ledger` section on either surface, once that file exists. **On Claude Code the fallback is the NORMAL path**, not an exotic edge case, because the todo tracker is frequently absent from the session tool surface. Check for the primitive at task start and degrade without comment when it is missing. A missing tool makes the ledger visible-but-not-interactive, never absent. On the fallback the marks live in text: `- [ ]` open, `- [>]` the single in-progress item, `- [x]` done. **On BOTH substrates, in full hackify, a tick is an edit to the work-doc file plus a chat re-print**, never a print on its own: rewrite the `## 0. Phase ledger` block and advance frontmatter `status` (plus `current_task` where the phase moves it) in that same edit, save, then print. A todo-tracker tick does not touch the file either. Skipping the edit is an abandoned-state bug, chat scrolls away and the archived doc records the phase you last wrote down.
- **The law is also injected.** `rules/phase-discipline.md` carries the ledger law, the in-order law and the wizard mandate into every prompt through the `UserPromptSubmit` hook, so they stay in front of you long after this file has scrolled away. Only Claude Code has that hook; the other six runtimes take the same laws from this prose alone (`references/runtime-adapters.md`).
- **One item `in_progress` at a time, no jumping ahead.** A later phase cannot start until the current phase's exit artifact exists and its item is `completed`. No phase is skipped: a carve-out is marked `completed` with a one-line reason, never deleted. Parallelism lives *inside* a phase (the Phase 5 reviewer panel, Phase 1 research agents), never across phases.
- **Phase 6 is split into sub-items** so archiving is its own line (`6c Archive → done/`), and it comes **before** the summary (`6d Summary + report`). The summary is unreachable while the archive item is open, so the work-doc always lands in `docs/work/done/` before any recap prints.
- **Reflect after each item:** one line, what changed, did it pass, what is next (the communication voice), then flip the item and start the next.
- **Resume READS the ledger back**, it does not rebuild it. In full hackify the ledger is section 0 of the work-doc: re-print that block, restore it into the todo tracker if the runtime has one, and set the first open phase to `in_progress`. That read only works because every earlier tick was written when it happened: resume finds the phase your last file edit recorded, not the phase your last chat print showed. Rebuilding from `status` + the Sprint Backlog checkboxes is the fallback for an older work-doc with no section 0 block, and for quick/yolo, which have no work-doc at all and whose ledgers are session-local.

The ledger is a **separate layer** from the work-doc Sprint Backlog: the Backlog tracks code tasks (task-level); the ledger tracks phases (phase-level). In full hackify both are durable, they are two sections of the same file; in quick and yolo the ledger is session-local because those modes keep nothing on disk. See [references/phase-ledger.md](references/phase-ledger.md) for the per-mode item lists and the exit-artifact table.

---

## Phase 1 (Clarify)

**Goal.** Groom the ask into a locked **Primary Goal & Guardrails** anchor, five parts, North-Star Goal / In-Scope / Out-of-Scope and Non-Goals / Guardrails and Invariants / Success Signals. Maximum understanding before any code. Enforced downstream by the drift-check, so no question survives into Phase 3 and no later phase wanders off the goal.

**Load the always-on trio first:** `references/communication-voice.md` (voice), `references/expert-mindset.md` (mindset), `references/phase-ledger.md` (ledger contract). They govern every phase from here on.

**Open the phase ledger here, not later.** The moment the ask is real and before any code, create the ten full-mode items in the todo tracker when the runtime has one, otherwise print them as a chat block, and set Phase 1 to `in_progress`. Phase 2 step 1 writes that same block into the work-doc as section 0. Waiting for the work-doc leaves the whole of Phase 1 with no visible tracker.

**Hard rule.** No code, no file edits, no test runs in Phase 1. Every question you put to the user, in EVERY phase, goes through the wizard tool; a plain numbered list in chat is forbidden. Every question also obeys the Clarity law in the canonical Wizard Contract (`references/clarify-questions/wizard-contract.md`), written so the user can answer without knowing how this workflow works.

**Exit artifact.** A locked answer set **and** a complete anchor recorded in the work-doc (an in-chat block for quick/yolo).

Full protocol, task-type classification, questionnaire assembly, and the anchor shape: [references/phases/phase-1-clarify.md](references/phases/phase-1-clarify.md).

---

## Phase 2 (Plan + Gate)

**Goal.** A work-doc the user can scan in 60 seconds and say "go."

**First, the phase ledger.** It is already open from Phase 1 (todo tracker where the runtime has one, otherwise the printed block, Phase 6 split into sub-items). Tick Phase 1 `completed`, set Phase 2 `in_progress`, and re-print the block. Step 1 below gives it its durable home, and from that first save on, every tick is an edit to that block with frontmatter `status: planning` in the same edit, and the re-print comes after. Contract: [references/phase-ledger.md](references/phase-ledger.md). Then:

1. **Create the work-doc** at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Slug `kebab-case`, ≤6 words. Date is today. **Write the phase ledger into it as `## 0. Phase ledger`**, between the title line and `## 1. Original ask`, before you draft anything else, so the durable copy exists from the file's first save.
2. **Fill from template** (`references/work-doc-template.md`). Required now: Original Ask (verbatim), Clarifying Q&A (verbatim), Acceptance Criteria (3-7 verifiable bullets), Approach (≤200 words; chosen path + 1-2 sentence rationale), Sprint Backlog (flat checklist, each task 5-30 min).
3. **Task granularity.** Each task independently testable. Break "Add invitation expiry" into "Add `expires_at` column + migration", "Reject expired tokens in invitations service", "Show 'expired' state in UI", "Backend test", "Frontend test". One commit closes the whole wave, never one per task.
4. **No placeholders.** No "TBD", no "implement error handling later", no "similar to T2". Decompose vague tasks now.
5. **Build the Repo Brief.** Fill the `### Repo Brief` block under Approach: stack, verbatim test/lint/typecheck commands, layout, the one layering rule, rules source, test convention, landmines. ≤350 words, facts only, and **every line carries the command or `file:line` that proved it**, a line with no such evidence is a guess and does not go in. You already know all of it from Phase 1. This block is passed verbatim as `{{repo_brief}}` to every implementer in Phase 3 and every reviewer in Phase 5, so none of them re-derives the repo one agent at a time. Skipping it means a dispatched agent receives an unfilled placeholder, refuses, and costs a whole round. See [references/repo-brief.md](references/repo-brief.md).
6. **Show the doc.** Paste rendered doc in chat or summarize and link. Ask: *"Sign off on this plan or call out anything to change?"*
7. **GATE.** Wait for explicit "go" / "approved" / "yes" before Phase 3. The turn ends here; Phase 2.5 opens the next one.

**On pushback,** edit doc, show diff, re-ask. Iterate until signed off. See `references/work-doc-template.md`.

---

## Phase 2.5, Spec Self-Review (1 reviewer, mandatory)

**First line of this turn, print the completion sentinel.** Sign-off just landed, so this is the first turn where a finish line can be stated and the first where the native tool is not blocked by plan mode. Emit one fenced `/goal <condition>` line (≤500 chars) naming the archived work-doc plus the green triad and the ship-gate rows, so an evaluator outside this conversation rules on "done" instead of you. The line is **paste-ready**: you print it, only the user can set it. Never claim a goal is active, never propose one **from a subagent**, never wait on the answer, and never soften the condition later to make it pass. Shape, per-mode wording, and who wins when the sentinel and the iteration driver disagree: [references/orchestration.md](references/orchestration.md).

**Then dispatch the spec reviewer by agent type** (`hackify:spec-reviewer`), passing only its INPUTS. Do not open the template to paste it (`references/parallel-agents/README.md`). It carries three lenses over one read: internal consistency and goal drift; the dependency, ordering and wave plan that Phase 3 dispatches off; and architectural and cross-cutting risk against the project's rules. **Its report leads with the wave plan**, so read that out before Phase 3 rather than rebuilding it.

**Hard rule:** Phase 2.5 is non-skippable, even for small docs, a "small" plan can hide a contradictory Q&A pair. Cap the report at ≤900 words, the sum of the three lenses it carries; its wave plan is an enumeration and sits outside that budget.

Full protocol, the three lenses' scope, the drift-check wording, and the conflict-resolution pass: [references/phases/phase-2.5-spec-review.md](references/phases/phase-2.5-spec-review.md).

---

## Phase 3, Implement (one agent per wave, mandatory)

**Goal.** Land the Sprint Backlog as a minimal, test-anchored diff, one dispatched implementer per execution wave.

Order tasks by dependency into waves, same-file tasks split across waves. Dispatch each wave by agent type (`hackify:wave-implementer`), exactly ONE subagent for the whole wave however wide it is: no cap, no module split, no grouping decision at dispatch time. Each task still sits under its own strict file allowlist and the wave is bounded by their union, which never widens what one task may touch. Read the wave plan out of the Phase 2.5 report rather than rebuilding it. **Pass every agent the `{{repo_brief}}` you built at the end of Phase 2** (the `### Repo Brief` block in the work-doc, [references/repo-brief.md](references/repo-brief.md)), so each wave's agent stops rediscovering the same stack, test command and layering rules the wave before it already derived. If the block is empty, fill it now before dispatching, an agent that receives an unfilled placeholder refuses.

**At every wave-end, before ticking any task,** run both deterministic scouts over the wave's touched files: the perf-scout (`references/perf-scout.md`) and the law-scout (`references/law-scout.md`, the bundled lawkeeper scanner scoped to those paths). Every candidate gets one written disposition, no silent drops.

**No scope creep.** No cleanup, no refactoring adjacent code, no abstractions for hypothetical futures. The plan is the contract.

Full protocol, wave planning, the allowlist contract, and the wave log: [references/phases/phase-3-implement.md](references/phases/phase-3-implement.md). TDD walkthrough and per-stack test commands: `references/implement-and-test.md`.

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

**Goal.** Prove every task and requirement landed AND that the app actually runs. Evidence before claims, fresh real output per item, never a summary and never a memory.

Three parts: the **Evidence Ledger** (one row per acceptance item, each carrying real output), the **three-layer re-verify**, and the **ship gate**.

**Ship gate (prove it runs).** A green triad says the code is well-formed, not that it starts. Run three legs and record one ledger row each: `ship.build` (builds clean from a cold cache, artifact on disk), `ship.boot` (starts, reaches a real ready signal, tears down clean), `ship.smoke` (the critical path this sprint touched works against the running app). **A leg is blocking whenever the diff touched something that leg's target consumes (source the build compiles, config read at startup, the touched flow); a written `⏭ skipped` row with the reason otherwise; never silently absent.** The trigger is the diff, not whether a run command exists. Detection table per ecosystem, readiness-probe rules, and the secrets/state guards: [references/ship-gate.md](references/ship-gate.md).

Full protocol: [references/phases/phase-4-verify.md](references/phases/phase-4-verify.md). DoD and the self-review checklist: `references/review-and-verify.md`.

---

## Phase 5, Review (parallel multi-reviewer, mandatory)

**Goal.** Every non-trivial diff faces a parallel reviewer panel before it can finish, and every finding gets a written disposition.

**Dispatch the wave in ONE message, by registered agent type**, passing only each reviewer's INPUTS. **Do not open the template files to paste prompts**, the agent already carries its prompt and reading it charges you the same text twice (type-to-INPUTS table: `references/parallel-agents/README.md`).

**B is the standing member of every wave**, carrying two lenses over one read: quality, layering & engineering law, and plan consistency, scope & goal drift (v0.13.0 merged Reviewer C into B, both ran on every wave and neither ever folded, so no evidence gate could have taken that saving). A (security & correctness), D (performance) and F (cross-module coherence) are gated on evidence that their lens has something to look at, the scouts already know what surface the diff touched. E (design conformance) joins on UI-bearing diffs. **A folded lens is written down with the evidence that let it fold, never silently absent, and when the evidence is ambiguous the reviewer runs.** F runs whenever the diff crosses a module boundary, which is most of the time, because a wave's implementer is blind to the waves that ran before it and to every line of pre-existing code, which is exactly where a producer and its consumers drift apart, and F is the only lens that checks producer against consumer. It folds only when the diff stays inside one module and there is no second side to compare against (`references/parallel-agents/phase-5-multi-review-f-coherence.md`).

**Slice the diff before you dispatch.** Each reviewer takes `{{review_scope}}`, the pathspec list its lens can actually act on, and diffs only that; a lens whose list comes out empty is not dispatched and the reason goes on the gate line. Anything you cannot confidently classify goes to B, so an unclassifiable file is never an uncovered file. **B is never sliced**, its semantic tier applies to every touched file, and it takes `{{metrics_table}}` instead so it judges precomputed size numbers rather than counting them by reading (`references/review-scope.md`).

**Refute before you fix.** A reviewer's finding is a claim, not a fact. ONE adversarial refuter judges every finding in the round before an edit is spent on any of them, carrying both lenses itself, reproduction and then authority, and receiving each finding verbatim plus the hunk it names rather than the whole range. A Critical dies only when BOTH lenses refute it, and not even then on the refuter's word: both lenses refuting earns an adjudication escalation, and the row reads `push-back` only after that reviewer rules and the user signs off. Until then it stays `accept` and out of the fix dispatch. An Important or Minor dies on one. **The default is to KEEP the finding**, uncertainty is never a refutation (`references/parallel-agents/phase-5-refute.md`).

**Exit only on a settled diff.** The loop may only end on a FULL round, the full gated panel over the full range, that finds nothing AND leaves every byte of the reviewed diff covered by a live verdict, one recorded against the blob hash the file still carries. **The reviewed diff is `git diff <base>..HEAD -- . ':(exclude)docs/work/*'`**, because the work-doc is the ruler the diff is measured against and cannot also be the measured; without the exclusion, writing a round's result into the work-doc kills the work-doc's own verdict and mandates another round, and the loop cannot close. That round is FULL only when every dispatched lens that takes a scope echoed a `settle `-prefixed scope, F echoed `settle all`, and B echoed `Round: settle`. Middle rounds are scoped to the fix diff and can never close the loop, no matter how clean.

Full protocol, the reviewer gate table, the per-round scope table, the dispatcher inputs, and the address-all loop: [references/phases/phase-5-review.md](references/phases/phase-5-review.md).

---

## Phase 6 (Finish)

**Goal.** Close the task: present the finish options, execute the chosen one, archive the work-doc, clean the touched scope, and hand the user a plain-language account of what changed.

Present **4 options** (1 merge to the base branch locally, 2 push and create a PR, 3 keep the branch as-is, 4 discard this work), execute the choice, then work the steps in order:

- **Step C.5, touched-scope cleanup.** The goal is the best version of the files this sprint changed, zero outstanding lint, type, test or dead-code issues in them. Whole-repo pre-existing issues stay out of scope (that is `/hackify:lawkeeper`'s job). Cleanup edits are dispatched per file-disjoint group, never parent-authored; the parent audits and aggregates.
- **Step D, archive.** Move the work-doc to `docs/work/done/` with `status: done`, and tick ledger item `6c`.
- **Step D.5, codewalk follow-up** *(options 1 or 2 only)*. If the task touched an entry-point file, ask whether to update an existing `.codewalk/<slug>/` trace, create a new one, or skip. Silent skip when no entry point was touched.
- **Step F, update log + HTML report.** **Precondition: Step D archive is done.** Print a plain-language update log, one block per change the user would recognize, five fields in this order, **Problem** / **Root cause** / **Solution** / **Verification evidence** / **Deployment status**, separated by a line containing exactly `----`. The HTML report beside it is rendered from a JSON payload by `skills/hackify/scripts/render-report.py`, never typed out by hand. Everyday words, no jargon they did not use, and never a phase number, task ID, reviewer letter or scout name. Append the same log to the archived work-doc under a new `## Update log` subheading, then emit the styled self-contained report beside it at `<slug>.report.html` ([references/html-report.md](references/html-report.md)). Standalone entry point: `/hackify:summary`.

Full protocol, the 4-options table, the cleanup classes, the codewalk detection list, and a worked update-log example: [references/phases/phase-6-finish.md](references/phases/phase-6-finish.md) and `references/finish.md`.

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

## Parallel agents (mandatory on code, never a judgment call)

**The parent never authors a diff.** Every change to code, in every phase and every mode, is written by a dispatched implementer agent under a file allowlist. The parent plans, dispatches, aggregates, verifies and reviews; it does not type the change itself. This binds for a one-line typo exactly as it binds for a new module. It is not conditional on task size, wave width, diff size, or how obvious the fix looks, and it is never something to ask the user to turn on.

Whenever 2+ pieces of work are independent, **dispatch foreground subagents in parallel in a single message**. Never sequential when independent. Phase 3 is the exception: a planned wave goes to ONE agent whatever its width, and the wave log records which task IDs it carried.

**Runtime caveat (honest about degradation).** Parallel dispatch needs a subagent primitive. On the **native tier** (Claude Code, OpenCode) these phases fan out concurrently. On the **best-effort tier** (Codex CLI/App, Gemini CLI, Cursor, no subagent primitive, see `references/runtime-adapters.md`) the *same mandatory phases still run*, but **inline and sequentially**, you keep the rigor, you lose the wall-clock win. The workflow degrades concurrency, never coverage; it does not silently skip a phase on a runtime that can't parallelize. **This is the only carve-out to the no-parent-authored-diff law, and it degrades the machinery, not the discipline:** with no subagent primitive the parent executes the implementer prompt itself, against the same file allowlist and the same Template Contract, and records `dispatch degraded, no subagent primitive` in the wave log. Never a free-hand edit. Runtimes with structured-output subagents may return reviewer/scout findings as machine-readable data instead of prose tables, see `references/runtime-adapters.md`.

**Every sub-agent prompt conforms to the canonical Template Contract** in `references/parallel-agents/template-contract.md`, the 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT) with `{{snake_case}}` placeholders. Binding because Haiku-class models read these prompts; the structure prevents soft-language / missing-verification / unanchored-severity failure modes from the v0.1.0 post-mortem. New templates MUST conform.

**Dispatch sub-agents for:**

| Phase | Use | Status |
|---|---|---|
| 1 | Research, different code areas, refs, questions | optional |
| 2.5 | Spec self-review, 1 reviewer scrutinizes the work-doc (one dispatch, not a fan-out) | MANDATORY |
| 3 | Implementation waves, one subagent per wave carrying every task in it (parent runs both scouts at wave-end) | MANDATORY |
| 3b | Debug evidence gathering, different component boundaries | optional (read-only) |
| 3b | The fix that closes the winning hypothesis | MANDATORY (it is a code change) |
| 4 | Cross-module verification, tests in different packages | optional (read-only) |
| 5 | Multi-reviewer code review, security/quality-and-law/plan/performance/coherence lenses, plus design conformance on UI-bearing diffs | MANDATORY (non-trivial diffs) |
| 5 | One adversarial refuter over the decision table, before any fix is applied | MANDATORY (non-trivial diffs) |
| 5 | Applying every surviving finding in the address-all loop | MANDATORY (it is a code change) |
| 6 C.5 | Cleanup edits inside the touched files | MANDATORY (it is a code change) |

**Do NOT use parallel agents for:** tightly-coupled investigations where each finding informs the next. **Separately, and whatever the dispatch shape:** two tasks that share a file never sit in the same wave, the wave planner splits them across waves. That is a wave-planning invariant, not a reason to avoid parallelism. Neither constraint is licence to write the code yourself. Templates in `references/parallel-agents/README.md`.

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

Hackify enforces the project's code-quality rules. If a `CLAUDE.md` is at workspace or project root, honor it; otherwise apply `rules/code-quality.md` (canonical doctrine; the legacy `references/code-rules.md` path is a forwarding stub). Hard caps non-negotiable, headline: ≤40 LOC per function, ≤3 params, ≤500 LOC per file, 0 lint suppressions; full list: `rules/hard-caps.md` (canonical, injected every prompt). The `UserPromptSubmit` hook injects FIVE rules files into every prompt, `rules/hard-caps.md` (caps), `rules/expert-mindset.md` (mindset), `rules/perf-guardrails.md` (performance), `rules/phase-discipline.md` (phase order, the always-open ledger, the wizard mandate), `rules/claim-integrity.md` (code is the only source of truth, prove every claim), so all five laws are always loaded; the deeper doctrine in `rules/code-quality.md` loads on demand from the Phase 2.5 spec reviewer and Phase 5 Reviewer B.

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
| `references/phases/` | the per-phase protocol, one file per phase (1, 2.5, 3, 4, 5, 6). **Load the file for the phase you are opening, not the set.** SKILL.md above states each phase's goal, hard gates and exit artifact; these hold the how |
| `references/review-scope.md` | how the sprint diff is sliced per reviewer and when a verdict carries into the settle round; the `{{review_scope}}` grammar, the classification table and the scope ledger (load: Phase 5) |
| `references/repo-brief.md` | the sprint's shared repo-context brief, built once in Phase 2 and passed to every implementer and reviewer so they stop rediscovering the repo one agent at a time |
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
| `rules/phase-discipline.md` (plugin root) | always-on phase stub, the always-open ledger + phases-in-order + wizard mandate, injected every prompt by the `UserPromptSubmit` hook |
| `references/perf-scout.md` | deterministic perf-scout protocol (run: every Phase 3 wave-end + Phase 5 start) |
| `references/law-scout.md` | deterministic engineering-law scan, the bundled lawkeeper scanner scoped to touched files (same two run points) |
| `references/ship-gate.md` | runtime proof protocol, build + boot + smoke (run: Phase 4, every mode) |
| `references/orchestration.md` | orchestration tier (`ultracode`) + iteration driver (`/loop`) + completion sentinel (`/goal`), all on by default; the standing authorization, its opt-out, and who wins when the sentinel and the driver disagree |
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
| "There is no to-do tool in this session, so there is no ledger" | There is one. Print it as a chat block and re-print it at every phase boundary, and in full mode keep it as work-doc section 0. On Claude Code that fallback is the normal path. The ledger degrades to visible-but-not-interactive, never to absent. |
| "Tests after will be fine, I know what I'm building" | Tests-after pass immediately and prove nothing. |
| "One more fix attempt before debug mode" | The 2-attempt limit is the circuit breaker. Honor it. |
| "I can self-review a 600-LOC diff" | No, you can't. Escalate. |
| "It's a one-line fix, dispatching an agent is overkill" | The no-parent-authored-diff law has no size threshold. Dispatch it. |
| "This wave only has one task, so there's nothing to parallelize" | There never is: a wave is ONE agent whatever its width. A one-task wave is the same dispatch with one task in it, and it still goes to an agent. |
| "I'll write this one myself and have an agent review it" | Backwards. The agent writes, you review. The parent never authors a diff. |
| "The user said 'just do X', skip the questionnaire" | If X has any ambiguity, batched questionnaire still applies. Trim it, don't skip it. |
| "Lint suppression is fine just this once" | Zero tolerance. Fix the root cause. |
| "Tests are green, so the app works" | Tests import modules. They do not start a server, read env, or run migrations. Run the ship gate. |
| "Nothing to run here, skip the ship gate" | Then write the `⏭ skipped` row with the reason and the manifest you read. A missing row is a failed gate. |
| "The re-scan was clean, we're done" | Only if the diff has not changed since. Fixes applied after a scan were never reviewed. |
| "The reviewer said Critical, just fix it" | Refute first. A wrong Critical fix breaks working code. One lens refuting and it stands; both refuting earns an adjudication escalation, not a drop, and closes only on the user's sign-off. |
| "Each agent's piece passed, so the feature works" | A wave's implementer is blind to every wave that ran before it and to every line of pre-existing code. Reviewer F is the only check that the pieces agree. |
| "I'll `/loop` this phase until it's clean" | Wrong layer. The iteration driver carries the TASK across phases; the review and debug loops stay inline inside their phase. |
| "The gate is open, I'll loop and check back" | A gate is a question only the user can answer. Looping at one burns tokens waiting for a human. Stop and surface. |
| "I set the session goal, so completion is now checked" | You cannot set it. Print the `/goal` line and let the user press the key. Claiming an evaluator is watching when none is is worse than having no sentinel at all. |
| "The goal condition passed, so we're done" | Only if the ledger agrees. A condition that passes with phases still open was written too loose. Finish them and say the condition under-specified the work. |

---

## Runtime primitives (where the tool names go)

This SKILL.md uses **runtime-primitive names** (wizard tool / subagent dispatcher / file-read op / file-write op / file-edit op / search / shell / todo tracker / orchestration tier / iteration driver / completion sentinel / always-on injection) rather than Claude-Code-specific tool names. Each target runtime maps these primitives to its own native tool via `references/runtime-adapters.md`. The mapping is the responsibility of the runtime, not the workflow, hackify's design law is identical across all 7 supported runtimes.

## One-line summary

Clarify up-front → gate before code → walk small tasks with self-review → verify with fresh evidence → finish with explicit options → archive. One file holds it all.
