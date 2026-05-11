---
name: hackify
description: One unified end-to-end dev workflow for ANY task — feature, bug fix, refactor, redesign, design, debug, or research-then-build — driven by a single per-task markdown work-doc at <project>/docs/work/. Replaces multi-skill ceremony (no separate spec/plan files). Asks every clarifying question up-front in one batched questionnaire, holds a hard gate before any code is written, file-driven pause/resume across sessions, mandatory evidence-before-claims, baked-in self-review checklist, mandatory multi-reviewer code review on non-trivial diffs, explicit definition-of-done verified end-to-end. Use this skill for ANY non-trivial prompt — building, fixing, refactoring, redesigning, debugging, polishing, or even just discussing an idea before building. Use it even when the user does not explicitly say "use the workflow" — the only carve-outs are trivial Q&A, single-line typo fixes, and pure read-only inspection. When in doubt, invoke this skill.
---

# Hackify — One Workflow For Every Dev Task

Hackify replaces the multi-skill ceremony of plan/spec/brainstorm/execute/verify/review/finish with **one workflow + one markdown work-doc per task**. The work-doc is the spec, the plan, the progress tracker, the review log, and the post-mortem — in one file. The user can pause and resume across sessions by saying "continue work on `<slug>`".

This skill is fully self-contained. **Never call other skills** — third-party plugins may not be installed. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined here or in `references/`.

## When to invoke

- **Default for every prompt** that asks for any of: building / adding / fixing / refactoring / redesigning / restyling / debugging / polishing / migrating / testing / discussing-then-building.
- **Slash command** (when the user types it explicitly): `/hackify:hackify <ask>` to start, `/hackify:hackify resume <slug>` to continue.
- **Carve-outs (skill optional):** trivial factual Q&A, one-line typo fixes, pure read-only inspection that won't lead to writing/editing/committing.
- **Compressed-flow alternative:** for small bug fixes, single-file edits, and quick direct-effort requests, use `/hackify:quick` instead. That skill skips Plan+Gate, Spec review, Multi-reviewer, and the 4-options finish; runs Clarify-if-needed → Implement → Verify → Summary; falls back to full hackify on signal (≥2 failed attempts, >3 files touched, security-sensitive path, user requests Phase 5).

When in doubt, invoke. A redundant skill load is cheap; a missed one ships broken work.

## The phases (lean, expert-led)

```
Phase 1: Clarify         ─── wizard questions in one batch, get user answers
Phase 2: Plan            ─── draft the work-doc, present, ── HARD GATE: user signs off ──
Phase 2.5: Spec review   ─── parallel agents scrutinize the work-doc for conflicting / inconsistent logic
Phase 3: Implement       ─── order tasks by dependency, dispatch each wave to PARALLEL foreground agents
        │
        └── Phase 3b: Debug (only if stuck after 2+ failed attempts)
Phase 4: Verify          ─── run DoD checklist, paste fresh evidence
Phase 5: Review          ─── PARALLEL multi-reviewer (security + quality + consistency) — always
Phase 6: Finish          ─── present 4 options, execute, archive work-doc, cleanup
```

The only mandatory user gate is between **Plan** and **Spec review**. After Phase 2.5 surfaces issues (or doesn't), implementation begins automatically. Phases 3–6 run continuously with progress reports at each transition. The user can interrupt anytime — the work-doc holds state, so resuming is always possible.

**Parallelism is the default**, not the exception. Whenever 2+ pieces of work are independent — clarify research, spec review, implementation tasks in the same wave, code review concerns, cross-package verification — dispatch them to foreground subagents in one message. Wave-based dependency ordering is what makes parallel implementation safe — same-file tasks are split across waves so two agents never write to the same file in the same wave.

## The work-doc — single source of truth

**Location.** `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` while in flight. Move to `<project>/docs/work/done/<YYYY-MM-DD>-<slug>.md` once shipped (after Phase 6).

**Skeleton.** See `references/work-doc-template.md`. Frontmatter holds `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`. Body sections: Original Ask → Clarifying Q&A → Definition of Done → Approach → Tasks → Implementation Log → Verification → Post-mortem.

**State is the file.** No companion JSON, no in-conversation memory. Resume = open the file, read frontmatter, jump to the next unchecked checkbox.

**Find the right project root.** Each sub-project (e.g., your backend and frontend repos) is its own git repo. The work-doc lives inside the project repo, not at workspace root. If the task spans multiple projects, create one doc in each — link them via the `related` frontmatter field.

---

## Phase 1 — Clarify

**Goal.** Understand the ask precisely enough that no question survives into Phase 3.

**Steps.**

1. **Classify the task type:** `feature` | `fix` | `refactor` | `revamp` | `redesign` | `debug` | `research`. The classification drives which questionnaire to use (see `references/clarify-questions.md`).
2. **Read just enough context.** Use `Grep` / `Read` / your codebase exploration tool of choice. For broad architecture, scan key entry points and follow imports; for blast radius, grep usages of the symbol; for onboarding to a single module, read it top-to-bottom. For trivial single-file edits, skip exploration.
3. **Build ONE batched questionnaire.** Pull the relevant question bank from `references/clarify-questions.md`. Each bank conforms to the canonical 4-section Wizard Contract (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA) documented at the top of that file. Strip questions whose answer is already evident from the ask or from context you just read. Add task-specific questions if the bank misses something obvious. The recommended option is always the **first** option in each question, suffixed with `(Recommended)`.
4. **Send the questionnaire as a wizard, NEVER as plain markdown.** Use the `AskUserQuestion` tool — every clarify question goes through it. Plain numbered lists in chat are forbidden for clarify questions. Lead the message that contains the first wizard call with a one-paragraph "What I heard you ask for" recap so misreadings surface before the user wastes time clicking. `AskUserQuestion` takes 1–4 questions per call and 2–4 options per question, so split a longer questionnaire across **multiple back-to-back `AskUserQuestion` calls** in the same turn (one call after the other; user answers the first batch, then you immediately fire the next). Use `multiSelect: true` only when options are non-exclusive; never use it for "pick one approach" questions. The "Other" free-text option is auto-provided — never add one yourself.
5. **Wait.** Do not start Phase 2 until the user has answered every wizard question. If a single answer is ambiguous, ask **one** targeted follow-up via another `AskUserQuestion` call — do not spiral into iterative interrogation.

**Hard rule.** Do not write code, do not edit files, do not run tests in Phase 1. The output of Phase 1 is a list of clear, locked answers — nothing else.

See `references/clarify-questions.md` for the per-task-type question banks.

---

## Phase 2 — Plan + Gate

**Goal.** A work-doc the user can scan in 60 seconds and say "go."

**Steps.**

1. **Create the work-doc** at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Slug is `kebab-case`, ≤6 words. Date is today.
2. **Fill it from the template** (`references/work-doc-template.md`). Required sections at this point: Original Ask (verbatim), Clarifying Q&A (verbatim), Definition of Done (3–7 verifiable bullets), Approach (≤200 words; chosen path + 1–2 sentence rationale), Tasks (flat checklist, each task 5–30 min of work).
3. **Task granularity.** Tasks must be bite-sized — each one independently testable and committable. Break "Add invitation expiry" into "Add `expires_at` column + migration", "Reject expired tokens in invitations service", "Show 'expired' state in UI", "Backend test", "Frontend test". One commit per task is the default.
4. **No placeholders.** No "TBD", no "implement error handling later", no "similar to T2". If a task is vague, decompose it now.
5. **Show the user the doc.** Either paste the rendered doc in chat or summarize and link to the file. Ask: *"Sign off on this plan or call out anything to change?"*
6. **GATE.** Wait for explicit "go" / "approved" / "yes" before Phase 3. Do not start writing code until you see it.

**If the user pushes back,** edit the doc, show the diff (or the new version), re-ask. Iterate until signed off.

See `references/work-doc-template.md` for the exact template.

---

## Phase 2.5 — Spec Self-Review (parallel — mandatory)

**Goal.** Catch inconsistent or conflicting logic in the work-doc *before* a single line of code is written. Cheap to fix on paper, expensive to fix after parallel agents have already written 200 LOC against a flawed spec.

**Steps.**

1. **Dispatch 3 foreground reviewers in parallel in ONE message.** Each gets a self-contained prompt + the absolute path to the work-doc:
   - **Reviewer A — Internal consistency.** Read the work-doc end-to-end. Find Q&A↔DoD↔Approach↔Tasks contradictions. Flag tasks not covered by any DoD bullet, DoD bullets not covered by any task, and Q&A answers that contradict the Approach.
   - **Reviewer B — Architectural / cross-cutting risks.** Match the plan against the project's code-quality rules — if a `CLAUDE.md` is present at workspace or project root, honor its rules; otherwise apply the patterns documented in `references/code-rules.md`. Flag anything that would force a lint suppression, an `!`, an inline type, a bare `Error` throw, or a layering violation.
   - **Reviewer C — Dependency / ordering / parallelism risks.** Build a quick dependency graph from the Tasks list. Flag tasks that share a file (would conflict if dispatched in parallel), missing prerequisite tasks, ordering bugs (e.g., consuming a helper before its task), and tasks that are too coarse to be 5–30 min.
2. **Aggregate findings.** Critical / Important / Minor severity. Critical = a bug in the plan that would force rework. Important = a fixable gap. Minor = nit.
3. **Patch the work-doc.** Apply Critical and Important fixes immediately, in place; mention Minor fixes in the Post-mortem at the end.
4. **Re-gate ONLY if the user's signed-off invariants changed** (e.g., a Critical finding required widening scope). Otherwise proceed straight to Phase 3 with the patched plan — the user already signed off.

The reviewer prompt template lives in `references/parallel-agents.md` under "Spec self-review (Phase 2.5)".

**Hard rule.** Phase 2.5 is non-skippable, even for small docs. Even a "small" plan can have a contradictory Q&A pair — that's exactly what spec review catches. Cap each reviewer at ≤300 words to keep the round-trip fast.

---

## Phase 3 — Implement (parallel waves — mandatory)

**Goal.** Ship the Tasks list as fast as wall-clock allows by dispatching each wave to foreground parallel subagents in one message.

**Pre-flight: build the wave plan.**

```
1. List every task. For each: which files it CREATES or MODIFIES; which earlier
   tasks must complete first.
2. Sort tasks by priority (DoD load-bearing first) and topological dependency.
3. Group into WAVES — a wave is a set of tasks with NO file overlap and NO inter-task
   dep within the wave. Tasks in wave N may depend on tasks in waves 1..N-1.
4. Write the wave plan into the work-doc Approach section as "Execution waves".
   Show the user before dispatching wave 1.
```

**Per-wave loop:**

```
1. Set frontmatter: status: implementing, current_task: W<n>:T<a>+T<b>+…
2. Dispatch ONE foreground Agent per task in the wave, in a SINGLE assistant
   message (multiple Agent tool calls in parallel). Each agent gets a self-contained
   prompt with: work-doc path, exact task ID, exact files to touch, test mode,
   project rules summary, "do NOT touch any other files".
3. Wait for all agents to return.
4. Aggregate: read each agent's report. Verify each touched only its declared files.
5. Run the full project verification (test + lint + typecheck) ONCE for the wave.
6. If anything red: classify — agent failure (re-dispatch with sharper prompt) vs.
   plan failure (drop to Phase 3b debug). Never paper over.
7. Tick all wave checkboxes in work-doc Tasks; append one Implementation Log
   entry per task summarizing the agent's work and self-review.
8. Commit ONCE for the wave (single commit, conventional-commit subject covers
   the wave; body lists task IDs).
9. Advance to wave N+1.
```

**Per-task safety constraints inside an agent's prompt:**

- "You may only modify these files: <list>. If you discover you need to touch any other file, STOP and report back — do not edit it."
- "Run only these commands: <list of test/lint commands scoped to your files>. Do not run repo-wide commands; the parent will do that."
- "Apply TDD when test mode is test-first. Watch the test fail before writing impl. Refuse to ship without a watched RED."
- "Self-review against the checklist before reporting done. Report: pass/fail per checklist item, plus any deviations from the work-doc Approach."
- Cap reports at ≤200 words per agent.

The dispatch prompt template lives in `references/parallel-agents.md` under "Implementation wave (Phase 3)".

**Single-task waves are fine.** When a wave has only one task (e.g., a serializing migration), dispatch a single agent. The discipline (self-contained prompt, declared files, scoped commands) still applies.

**Test mode per task:**

- **Test-first (mandatory):** business logic, services, validators, auth/permission code, bug fixes, anything with branching behavior. RED → GREEN → REFACTOR. Watch the test fail before writing implementation. *"If you didn't watch it fail, you don't know if it tests the right thing."*
- **Test-after (acceptable):** integration/E2E layers where setup is heavy, framework wiring, glue code. Test still required, but order is flexible.
- **Manual smoke (acceptable when user opted in):** UI cosmetics, copy edits, color/spacing tweaks, doc edits, config-only changes. Log the steps you tested in the Implementation Log entry. Always offer to also write an automated test if the user wants — never *replace* automated tests when the behavior is testable.
- **No tests:** only when the task is purely additive scaffolding (e.g., "create empty file") or pure documentation. Note "no test (rationale: …)" in the log.

**If stuck** (tests still failing after 2 honest attempts to fix, or behavior surprising), **switch to Phase 3b: Debug**. Don't try a third blind fix.

**No scope creep.** Don't add cleanup, don't refactor adjacent code, don't introduce abstractions for hypothetical futures. The plan is the contract.

See `references/implement-and-test.md` for the TDD walkthrough and the per-stack test commands.

---

## Phase 3b — Debug (only when stuck)

**Trigger.** ≥2 failed fix attempts on the same task, OR a test failure whose message doesn't match the expected error, OR a regression appearing while implementing something else.

**4-phase root-cause hunt** (do not skip phases):

```
1. ROOT CAUSE — read errors carefully, reproduce reliably, gather evidence at every
   component boundary, trace the bad value back to its source.
2. PATTERN ANALYSIS — find a working analogue in the codebase, list every difference.
3. HYPOTHESIS — write down: "I think X is the cause because Y."
   Make ONE smallest change. Run. Did it fix it?
4. IMPLEMENT — write a failing test that reproduces the bug, fix the SOURCE
   (not the symptom), watch the test go green, watch all other tests stay green.
```

**Circuit breaker.** After 3 failed hypotheses, **stop**. Architectural problem, not failed hypothesis. Document the dead-ends in the work-doc and surface to the user.

**Hard rules.** No "quick fix for now." No multiple fixes at once. No skipping the failing-test step.

See `references/debug-when-stuck.md`.

---

## Phase 4 — Verify

**Goal.** Prove the original ask is met. Evidence before claims.

**Definition of Done (top-level — every task type):**

- [ ] All tests pass — paste fresh test-command output (exit code 0, 0 failures, 0 errors)
- [ ] Linter clean — paste fresh lint output (0 errors)
- [ ] Typecheck clean — paste fresh typecheck output (0 errors)
- [ ] All `Tasks` checkboxes ticked
- [ ] Every Definition-of-Done bullet from Phase 2 verified — for each, paste the evidence (output, screenshot reference, or a short verifying script)
- [ ] No placeholders, no `TODO` comments without owners, no `console.log`/`println!` debug statements, no commented-out code
- [ ] No new lint suppressions (`biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`) — zero tolerance
- [ ] No new `!` non-null assertions in production code
- [ ] Manual smoke check (if user opted in) — list steps and outcomes

**Run the commands fresh.** Don't trust earlier output. Re-run before claiming.

**Per-stack quick reference:** see `references/review-and-verify.md`.

**If anything is red, do NOT advance to Phase 5.** Loop back to Phase 3 (or 3b if stuck).

---

## Phase 5 — Review (parallel multi-reviewer — mandatory)

**Default: dispatch THREE foreground reviewers in parallel in ONE message.** Self-review is the floor, not the ceiling — for any diff that wasn't a one-line typo, multi-reviewer is on. The user has explicitly opted into this behavior to catch issues a single lens always misses.

The three reviewers (each is a foreground general-purpose subagent, dispatched in the same message):

- **Reviewer A — Security & correctness.** Auth, permissions, injection, CORS, cookies, secrets, PII, migrations, crypto, race conditions. Reads the diff with adversarial intent.
- **Reviewer B — Quality & layering.** DRY, named types, layering (routes pure / services own DB), file/function caps, lint suppressions, `!` non-null, empty catches, bare `Error` throws, dead code.
- **Reviewer C — Plan consistency & scope.** Diff vs. the work-doc DoD + Tasks list. Anything missing, anything beyond scope, anything that contradicts a Q&A answer or the Approach.

For multi-concern diffs (e.g., touches both UI and a backend migration), add a 4th reviewer focused on the second concern. Cap at 4 — diminishing returns past that.

**Self-review still happens** — by you, against `references/review-and-verify.md`'s 14-item checklist. The three reviewers are *additive* defense, not replacement.

**Carve-out (skill optional).** A diff that is *purely* a one-line typo / comment / config-only change can skip multi-reviewer; self-review is enough. When in doubt, dispatch.

**Acting on feedback.**

- **Critical** → fix immediately, before merging.
- **Important** → fix before claiming Phase 6 done.
- **Minor** → either fix now if cheap, or add a "follow-up" entry to the work-doc Post-mortem.

Push back only with **technical evidence** — never performative agreement. If the reviewer is wrong for this codebase (YAGNI, missing context, bad pattern fit), say so with reasoning. See the response pattern in `references/review-and-verify.md`.

---

## Phase 6 — Finish

**Goal.** Land the work cleanly and archive the doc.

**Step A — re-run verification one more time.** Even if it passed in Phase 4. Pre-merge state can drift.

**Step B — present exactly 4 options, no open-ended choice:**

1. **Merge to base branch locally** (default for small in-place changes).
2. **Push and create a PR** (default for cross-team or larger changes).
3. **Keep the branch as-is** (work pauses; no cleanup).
4. **Discard this work** (requires user typing "discard" verbatim — no shortcut).

**Step C — execute the choice.**

- **For 1 or 2:** Commit message follows the project convention; ends with the Claude Code Co-Authored-By trailer. PRs include a Summary section, Test plan, and link to the work-doc.
- **For 3:** Stop. Leave everything in place.
- **For 4:** Confirm, then `git checkout` the base branch and remove the worktree (if any). Never `git reset --hard` without explicit user instruction.

**Step D — archive the work-doc** (options 1 and 2 only): move from `<project>/docs/work/<slug>.md` to `<project>/docs/work/done/<slug>.md`. Update frontmatter `status: done`. The Post-mortem section is mandatory at this point — 3–8 bullets capturing what surprised, what to remember next time.

**Step E — worktree cleanup** (1, 2, or 4): `git worktree remove <path>` and delete the local branch if merged. NOT for option 3.

**Step F — Summary table** (1 or 2 only): Generate a concise 2-column Area/Change markdown table covering every change shipped. Print it to the chat. Append the same table to the archived work-doc inside the Post-mortem section under a new `## Summary of changes shipped` subheading. Area labels are 1–4 word concept/theme tokens; Change cells are ≤25 words with `backticks` for technical terms. See `references/finish.md` "Summary table — authoring guidance" for rules and a worked example.

**Invoking the summary on demand.** The same Area/Change table is available any time during a task via the `/hackify:summary` slash command, or by phrase trigger ("show summary", "summarize", "summary table", "show me what changed"). Mid-flight invocation prints to chat only; the Phase 6 Step F invocation also appends to the work-doc.

See `references/finish.md`.

---

## Pause / Resume

**Pause** — the user can stop at any time. The work-doc is the state. Don't summarize the conversation in chat unless asked; the next session will read the doc.

**Resume** — when the user says "continue work on `<slug>`" or "resume hackify":

1. Locate the work-doc — search `<project>/docs/work/*.md` for the slug. If multiple projects might host it, ask which one. As a fallback, recursively search known project roots.
2. Read frontmatter. Honor `status` and `current_task`.
3. Read the latest Implementation Log entry to see exactly where you stopped.
4. Confirm with user: *"Resuming `<title>` at `<status>`, next task: `<T<n>>`. Continue?"*
5. Continue from the appropriate phase — do NOT re-run earlier phases unless the user asks.

**Stale doc detection.** If `created` is more than 14 days old, before resuming, check whether the codebase moved underneath the plan (`git log --since="<created>" -- <touched files>`). If so, surface the drift before continuing.

---

## Parallel agents — the default, not the exception

The user wants speed. Whenever there are 2+ independent pieces of work — **dispatch foreground subagents in parallel in a single message**. Do not run them sequentially when they're independent.

**Every sub-agent prompt you write conforms to the canonical Template Contract** in `references/parallel-agents.md` — the 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT) with `{{snake_case}}` placeholders for runtime values. The contract is binding because Haiku-class models read these prompts; the structure prevents the soft-language / missing-verification / unanchored-severity failure modes documented in the v0.1.0 post-mortem. Every existing template in `references/parallel-agents.md` already conforms; new templates MUST conform.

Use parallel agents for:

- **Research** (Phase 1) — different parts of the codebase, different reference docs, different questions.
- **Spec self-review** (Phase 2.5, MANDATORY) — three reviewers in parallel scrutinize the work-doc for inconsistent / conflicting logic.
- **Implementation waves** (Phase 3, MANDATORY) — order tasks by dependency, group into waves, dispatch each wave's tasks to one agent each in parallel.
- **Cross-module verification** (Phase 4) — running tests in different packages.
- **Multi-reviewer code review** (Phase 5, MANDATORY for non-trivial diffs) — security/correctness, quality/layering, plan-consistency lenses dispatched in one message.
- **Debug evidence gathering** (Phase 3b) — different component boundaries.

Do NOT use parallel agents for:

- **Tasks that share a file in the same wave** — the wave planner must split same-file tasks across waves.
- Tightly-coupled investigations where each finding informs the next.
- One-line typo fixes (overhead exceeds value).

See `references/parallel-agents.md` for dispatch templates (including the file-allowlist constraint that makes parallel implementation safe).

---

## Frontend design work — special handling

When the task touches **UI / styling / theming / layout / components / typography / colors / spacing / icons / forms / motion / brand / RTL**, before drafting the Plan **load `references/frontend-design.md`** and treat its rules as binding. If your project has a committed brand/design spec, design WITHIN it, not over it — let the spec lead and adapt new components to its tokens, scale, and voice.

---

## Code quality (always-on)

Hackify enforces the project's code-quality rules. If a `CLAUDE.md` is present at workspace or project root, honor its rules; otherwise apply the patterns documented in `references/code-rules.md`. Hard caps non-negotiable: ≤40 LOC per function, ≤3 params, ≤3 nesting levels, ≤500 LOC per file, 0 lint suppressions, 0 non-null `!`, 0 empty catches, 0 inline `interface`/`type` blocks ≥2 props in route/service/middleware modules, 0 bare `Error` throws in domain code.

Patterns: DRY, named types for any 2+ prop shape, explicit over clever, single responsibility, every code path tested, edge cases handled.

For depth, see `references/code-rules.md`.

---

## File map

```
SKILL.md                                ← this file (the workflow)
references/
  work-doc-template.md                  ← markdown skeleton for every task
  clarify-questions.md                  ← per-task-type question banks for Phase 1
  implement-and-test.md                 ← TDD walkthrough, per-stack test commands
  debug-when-stuck.md                   ← 4-phase root-cause hunt for Phase 3b
  review-and-verify.md                  ← DoD + self-review checklist + escalation rules
  finish.md                             ← Phase 6 — 4-options, archive, worktree cleanup
  frontend-design.md                    ← visual law (load on FE/UI/design tasks)
  code-rules.md                         ← SOLID/DRY/types/layering deep dive
  parallel-agents.md                    ← parallel subagent dispatch templates
evals/
  evals.json                            ← optional eval harness (use with skill-creator plugin if installed)
```

Load reference files **only when the relevant phase needs them** — keeps context lean.

---

## Anti-rationalizations

These thoughts mean STOP and reset:

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

## One-line summary

Clarify everything up-front → gate before code → walk small tasks with self-review → verify with fresh evidence → finish with explicit options → archive the doc. One file holds it all.
