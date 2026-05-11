# Clarify — Per-Task-Type Question Banks

Phase 1 builds **one batched questionnaire** drawn from the bank for the matched task type. **Drop questions whose answer is already evident** from the user's prompt or from context you've already read (codebase exploration tools, file system). Add task-specific questions if a question bank misses something obvious.

## Delivery format — wizard only (mandatory)

**Every clarify question is delivered through the `AskUserQuestion` tool.** Plain numbered markdown lists in chat are forbidden for Phase 1 — the wizard renders structured options the user can click, which is faster, less error-prone, and easier to answer on the move.

Tool constraints to design around:

- **1–4 questions per call.** If your batch is larger, send **multiple back-to-back `AskUserQuestion` calls in the same turn** — fire the next call as soon as the previous batch is answered, with no chat narration in between unless something needs clarifying. Aim for ≤16 total questions across all batches; if you need more, your scope is too broad — narrow first.
- **2–4 options per question.** Mutually exclusive by default. Use `multiSelect: true` ONLY when options are genuinely combinable (e.g., "which edge cases to handle"). Never use multiSelect for "pick one approach" questions.
- **First option is the recommendation.** Suffix its `label` with ` (Recommended)`. Even if you'd personally rank a different option higher, leading with your strongest opinion saves the user time.
- **No "Other" option** — the tool auto-injects free-text input.
- **`header`** ≤12 chars. Concrete chip text like `Hierarchy`, `Roles`, `Invite flow`. Not `Question 1`.
- **`description`** explains the trade-off in one short sentence — what happens if you pick this.
- **Use `preview`** for single-select questions when the choice is between concrete artifacts (UI mockups, code snippets, schema sketches). Skip preview for preference questions where labels + descriptions are enough.

## Composing the questionnaire

- Lead the message containing the **first** `AskUserQuestion` call with a 1-paragraph "What I heard you ask for" preamble so misreads surface before the user clicks anything. Do NOT repeat that preamble before subsequent batches in the same turn.
- Order: scope-shaping questions first (anything whose answer changes which other questions matter), then data model, then UX, then logistics (worktree, tests, output).
- Combine related sub-questions into one wizard question with letter options — don't burn a separate question on every micro-decision.
- Short, concrete, no filler. Drop any question whose answer is in `CLAUDE.md`, your codebase-exploration tool output, or the codebase itself — confirm in the preamble instead.

---

## All task types — universal preamble

Always ask up-front (unless already obvious):

- **Scope check.** "Is this a one-off task, or part of a larger initiative I should align with?"
- **Worktree.** "Work in a git worktree (isolated branch) or in-place on the current branch?" — *Default A: worktree, unless the task is <30 min and the user is on the right branch.*
- **Tests preference.** "Test mode: A) test-first per task / B) test-after acceptable / C) manual smoke acceptable for visual-only tasks." *Default A.*
- **Output expectation.** "Done = merged to main? PR opened? Branch left as-is for review?" *Default depends on diff size.*

Drop any of these you can infer.

---

## Type: `feature`

Use when the user is **adding new behavior** the system doesn't have.

- **Issue #1 — Goal.** What single user-visible behavior should exist after this ships? (One sentence; if you can't compress to one sentence, the feature is two features.)
- **Issue #2 — Scope boundary.** What is explicitly OUT of scope this round?
- **Issue #3 — Where it lives.**
  - A. New module / file
  - B. Extend existing module — which one?
  - C. Cross-module change
- **Issue #4 — Data model impact.**
  - A. No DB / schema changes
  - B. New columns on existing table — migration acceptable?
  - C. New table / new tenant schema
  - D. Cross-schema change (control + tenant)
- **Issue #5 — Public API impact.**
  - A. No new endpoint
  - B. New endpoint — auth required? Permission?
  - C. Modifies existing endpoint — backward compatible?
- **Issue #6 — UI surface (skip if backend-only).** Page / component / dialog / inline / non-UI?
- **Issue #7 — Acceptance criteria (the DoD).** "What single sentence describes 'this is working'?" — phrase as something testable.
- **Issue #8 — Edge cases the user wants explicitly handled.** Empty state? Concurrent writes? Permission denied? Unauthenticated? Network failure? Locale?

---

## Type: `fix`

Use when the user is reporting **broken behavior**.

- **Issue #1 — Reproduction.** "Walk me through the exact steps that reproduce this. What did you expect? What actually happens?"
- **Issue #2 — Frequency.** Always / sometimes / once?
- **Issue #3 — Recent changes.** When did it start failing? Any recent deploy / dep upgrade / config change?
- **Issue #4 — Scope of the regression.** Just this flow? Or others affected too?
- **Issue #5 — Severity.** Production blocker / important / nice-to-have? Affects how much we polish vs. ship a minimum fix.
- **Issue #6 — Acceptable solution shape.**
  - A. Small targeted patch + regression test
  - B. Broader refactor of the broken area (more risk, more value)
  - C. Workaround for now + open a follow-up
- **Issue #7 — Test artifact.** "Should I add a regression test that fails before the fix and passes after?" — *Default A: yes. Always say yes unless the user has a reason.*

---

## Type: `refactor`

Use when **behavior should not change** but structure should.

- **Issue #1 — Driver.** What problem are we solving? (Tech debt, prepping for a feature, performance, readability, layering violation?)
- **Issue #2 — Behavior contract.** "Confirm: no user-visible behavior changes? If any are acceptable, list them."
- **Issue #3 — Scope.**
  - A. Single module
  - B. Multiple modules in one project
  - C. Cross-project (backend + frontend)
- **Issue #4 — Test coverage prerequisite.** Are there enough tests to refactor safely? If not, write tests first as a sub-phase.
- **Issue #5 — Migration shape.**
  - A. Big-bang single-PR
  - B. Staged with shim / deprecation
  - C. Feature-flagged rollout
- **Issue #6 — Pattern reference.** Is there an existing module in the codebase that already shows the target shape? (If yes, link it — refactor mimics it.)

---

## Type: `revamp` or `redesign`

Use for **deeper rework** — UI redesign, API redesign, replacing a subsystem.

Run the **`feature` questionnaire** as the base, then add:

- **Issue #N — What stays.** What about the current implementation must NOT change?
- **Issue #N+1 — What goes.** What is explicitly removed / replaced?
- **Issue #N+2 — Visual reference (UI redesigns only).** Mood, references, brand spec to honor? If the project has a committed brand spec under `docs/`, link it and confirm it still applies.
- **Issue #N+3 — Backward compatibility.** Are old API consumers still in flight? Need a transition period?
- **Issue #N+4 — Migration plan.** How do existing users / data move from old to new?

For UI redesigns, **also load `references/frontend-design.md` before drafting the plan** — it's binding.

---

## Type: `debug`

Use when the user has a **mystery to solve** rather than a clear ask.

This usually starts with the user describing weird behavior. Default into Phase 3b's 4-phase debugging method *during clarify* — gather evidence inline.

- **Issue #1 — Reproduction.** Same as `fix` Issue #1.
- **Issue #2 — Evidence already collected.** What logs / errors / stack traces / screenshots have you already seen?
- **Issue #3 — Hypotheses already tried.** What did you already try, and what was the outcome?
- **Issue #4 — Boundary.** Is the user OK with you adding instrumentation (logs, telemetry) as part of the investigation?
- **Issue #5 — Outcome you want.**
  - A. Root cause identified + fix shipped
  - B. Root cause identified + handed off to user
  - C. Mitigation now, deeper investigation later

After clarify, the work-doc Approach section is replaced by an **Investigation Plan** — list the components to instrument, the evidence to gather, the hypotheses to test in order.

---

## Type: `research`

Use when the user wants to **discuss / explore an idea** before committing to build it.

- **Issue #1 — Question.** What single question should this research answer?
- **Issue #2 — Decision it informs.** What will we do differently based on the answer?
- **Issue #3 — Depth.**
  - A. Quick sketch (1–2 hours, no code)
  - B. Spike — minimal prototype to validate
  - C. Full investigation with multiple options compared
- **Issue #4 — Output.** Markdown summary in the work-doc? A spike branch? Both?
- **Issue #5 — Time-box.** How long are you OK with this taking before we cut it short?
- **Issue #6 — Continuation.** "If the answer is X, do you want me to immediately roll into a `feature` doc for the build? Or pause and let you decide?"

For research tasks, the gate at end of Phase 2 is reframed: not "approve the plan to build", but "approve the conclusions and whether to build."

---

## Picking & combining questions

- **Single source of ambiguity** → 1 question is enough. Don't pad to look thorough.
- **Multiple ambiguities of the same shape** → group into one numbered Issue with options.
- **Question whose answer is in CLAUDE.md** → don't ask it. (E.g. if the project's CLAUDE.md pins the package manager, don't ask.)
- **Question whose answer is in your codebase-exploration tool output or recent commits** → don't ask it. Confirm in the preamble ("I see the existing `invitations` table has no `expires_at` column…") and skip the question.

The point of the batch is to make Phase 1 **one round-trip**, not zero. If you have 10 things to ask, ask them — that's still one round-trip. If you have 3, ask 3.
