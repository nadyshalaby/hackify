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

## Wizard Contract

### Purpose

Every wizard bank below (the universal preamble plus the six `Type:` task-type banks) MUST conform to the 4-section structure defined here. This is the canonical specification — banks that drift from it are dispatch bugs. RFC 2119 keywords (MUST / SHOULD / MAY) apply throughout.

### The 4 mandatory sections

Each bank MUST contain these four sections, in this order, with these exact names:

1. **SCENARIO** — one paragraph describing when this bank applies. MUST name the trigger condition concretely (e.g. "user is adding new behavior the system doesn't have"). Generic framing ("when the user has a question") is forbidden.

   *Mini-example:* "Use when the user is reporting broken behavior — an observable defect, a stack trace, or a flow that no longer produces the expected outcome."

2. **COMPOSITION** — decision rules for picking N questions from the bank based on context already gathered (prompt text, `CLAUDE.md`, codebase exploration output). MUST be explicit "if X then Y" rules — NOT free choice. Generic "use judgment" language is forbidden.

   *Mini-example:* "If user prompt already names the target file, skip Q1 (Scope). Else ask Q1. If `CLAUDE.md` pins the package manager, skip Q5 (Tooling). Else ask Q5."

3. **QUESTIONS** — the candidate question pool (4–8 per bank). Each question MUST conform to the Question structure (next subsection). Questions whose answer is already evident from context MUST be dropped at composition time, not asked.

   *Mini-example:* "Q1 — Scope. text: `Single file or cross-module?` header: `Scope`. options: A `Single file (Recommended)` / B `Cross-module` / C `Cross-project`. why-this-matters: determines whether the worktree is created and whether Phase 4 cross-package verification runs."

4. **EXIT CRITERIA** — the binary condition under which the wizard is "done enough" to proceed to Phase 2. MUST be checkable, not aspirational. The dispatching agent uses this to decide whether to loop back for another batch or move on.

   *Mini-example:* "All composed questions answered AND no answer left ambiguous (free-text answers reduced to one of A/B/C/D semantics or explicitly confirmed as a new option) AND scope sentence written into the work-doc preamble."

### Question structure

Every question in a bank's QUESTIONS section MUST specify:

- **text** — the question prompt shown to the user. One short sentence. No filler.
- **header** — the chip text rendered in the wizard. ≤12 characters. Concrete (`Scope`, `Roles`, `Invite flow`) — NOT `Question 1` or `Q3`.
- **options** — 2–4 mutually-exclusive options labeled A / B / C / D. Option A MUST be suffixed with ` (Recommended)`. NEVER include an `Other` option — the `AskUserQuestion` tool auto-injects free-text input.
- **why-this-matters** — one line stating what the answer changes downstream (which task-type branch is taken, which Phase 2 plan section is generated, which Phase 3 sub-agent fans out, which verification step runs). If the answer changes nothing downstream, the question MUST be cut.

### Composition rules

COMPOSITION is decision rules, NOT free choice. Each bank's COMPOSITION subsection MUST enumerate explicit conditionals that map context signals to question inclusion or exclusion.

*Mini-example (for a `fix` bank):* "If the user prompt already names the target file, skip Q1 (Scope). Else ask Q1. If the user prompt includes a stack trace, skip Q2 (Reproduction steps). Else ask Q2. Always ask Q5 (Regression test) — it's the only gate that prevents silent re-breakage."

Generic "use judgment" or "ask what feels relevant" language is forbidden. The dispatching agent (and a Haiku-class weak model executing this skill) MUST be able to mechanically apply the COMPOSITION rules without inferring intent.

---

## Universal preamble

**SCENARIO**

Runs before any task-type bank, on every Phase 1. Sets the four cross-cutting logistics answers that every downstream bank assumes are already settled: scope shape, isolation strategy, test discipline, and done-state. Skip questions whose answers are already implied by the user's prompt or pinned in `CLAUDE.md`.

**COMPOSITION**

- If the user's prompt explicitly names a scope ("just this one file", "all over the codebase"), skip Q1 (Scope check).
- If the user is already on a branch named for the task, skip Q2 (Worktree) and confirm in the preamble. Also skip if the user prompt contains the literal substring `this branch`, `in place`, or `just push`.
- If `CLAUDE.md` or the task-type bank pins a test discipline (e.g. TDD mandatory), skip Q3 (Tests).
- Always ask Q4 (Done state) unless the user has explicitly stated PR vs merge intent in the prompt.

**QUESTIONS**

Q1 — Scope check
- Text: Is this a one-off task or part of a larger initiative I should align with?
- Header: Scope
- Options:
  - A. One-off task (Recommended)
  - B. Part of a larger initiative — align with it
  - C. Start of a larger initiative — set up scaffolding
- Why-this-matters: Determines whether the work-doc is standalone or links to a parent plan, and whether Phase 2 surveys neighboring work before drafting.

Q2 — Worktree
- Text: Work in an isolated git worktree or in-place on the current branch?
- Header: Worktree
- Options:
  - A. Isolated worktree on a new branch (Recommended)
  - B. In-place on the current branch (task <30 min, already on right branch)
- Why-this-matters: Triggers (or skips) the worktree-creation step in Phase 2 and changes how Phase 6 finishes (merge vs. push-and-PR).

Q3 — Tests
- Text: Which test discipline applies for this task?
- Header: Tests
- Options:
  - A. Test-first per task (Recommended)
  - B. Test-after acceptable
  - C. Manual smoke acceptable (visual-only)
- Why-this-matters: Decides whether Phase 3 fans out a RED→GREEN sub-agent or a build-then-verify sub-agent.

Q4 — Done state
- Text: What does "done" mean for this task?
- Header: Done state
- Options:
  - A. Branch left for your review (Recommended)
  - B. PR opened, awaiting your merge
  - C. Merged to main directly
- Why-this-matters: Sets Phase 6's exit action (push only / open PR / merge) and whether release artifacts (CHANGELOG, tag) are generated. Recommended option A (Branch left for your review) applies when diff is ≤3 files OR ≤200 added lines; recommend B (PR opened) for larger diffs or cross-team changes; recommend C (Merged to main directly) only when the user prompt contains the literal substring `ship it`, `merge it`, `commit and push`, or `merge directly`.

**EXIT CRITERIA**

Q1–Q4 each answered or explicitly skipped per COMPOSITION rules; scope sentence, worktree decision, test mode, and done-state recorded in the work-doc preamble; no answer left as free-text without being reduced to one of A/B/C/D semantics.

---

## Type: `feature`

**SCENARIO**

Use when the user is adding new behavior the system doesn't currently have — a new endpoint, a new screen, a new role, a new flow, a new entity. Triggers on prompt patterns like "add", "build", "introduce", "ship", "let users do X." Not for changing how existing behavior works (that's `revamp`) or fixing it (that's `fix`).

**COMPOSITION**

- Always ask Q1 (Goal shape) — it determines whether the plan needs a DoD sentence written by us or already supplied.
- If the user's prompt already lists out-of-scope items, skip Q2 (Scope boundary).
- Skip Q3 (Where it lives) and confirm in the preamble if the user prompt names a file path matching `^[A-Za-z0-9_./-]+\.(ts|tsx|js|jsx|py|go|rs|md|json|yaml|yml|sql)$`.
- Always ask Q4 (Data model) and Q5 (Public API) unless the prompt rules them out (e.g. "no DB changes, no new endpoint").
- Skip Q6 (UI surface) if the task is explicitly backend-only or CLI-only.
- Always ask Q7 (Acceptance criteria) — it gates Phase 2's DoD section.
- Always ask Q8 (Edge cases, multi-select) — under-asking here is the most common Phase 5 review failure.

**QUESTIONS**

Q1 — Goal shape
- Text: How is the user-visible goal already specified?
- Header: Goal
- Options:
  - A. Use the prompt verbatim — I'll compress to one sentence (Recommended)
  - B. I'll write a one-sentence DoD now in chat
  - C. Goal is ambiguous — propose 2-3 framings and pick one
- Why-this-matters: Determines whether Phase 2's DoD section is auto-derived or waits for user input before drafting.

Q2 — Scope boundary
- Text: What is explicitly OUT of scope this round?
- Header: Out of scope
- Options:
  - A. Nothing flagged — defer to my judgment, confirm at gate (Recommended)
  - B. I'll list out-of-scope items now in chat
  - C. Build the minimum that satisfies Q1; everything else is out
- Why-this-matters: Sets the Phase 2 plan's "Out of scope" section and prevents scope creep in Phase 3.

Q3 — Where it lives
- Text: Where should the new behavior live in the codebase?
- Header: Location
- Options:
  - A. New module / file (Recommended)
  - B. Extend an existing module
  - C. Cross-module change
- Why-this-matters: Drives the file-creation list in Phase 2 and whether Phase 4 cross-package verification runs.

Q4 — Data model impact
- Text: What is the data-model impact of this feature?
- Header: Data model
- Options:
  - A. No DB / schema changes (Recommended)
  - B. New columns on an existing table (migration acceptable)
  - C. New table / new tenant schema
  - D. Cross-schema change (control + tenant)
- Why-this-matters: Determines whether a migration sub-agent fans out in Wave 2 and whether the expand-then-contract pattern applies.

Q5 — Public API impact
- Text: What is the public-API impact?
- Header: API
- Options:
  - A. No new endpoint (Recommended)
  - B. New endpoint (auth-required by default)
  - C. Modifies an existing endpoint (must stay backward-compatible)
- Why-this-matters: Decides whether OpenAPI/route registration is touched and whether Phase 5 includes a security reviewer pass.

Q6 — UI surface
- Text: What UI surface does this feature need?
- Header: UI surface
- Options:
  - A. No UI — backend/CLI only (Recommended)
  - B. New page or route
  - C. New component embedded in an existing page
  - D. Dialog / modal / inline action
- Why-this-matters: Triggers (or skips) loading `references/frontend-design.md` and the frontend-design sub-agent in Phase 3.

Q7 — Acceptance criteria
- Text: How should the testable DoD be phrased?
- Header: DoD
- Options:
  - A. I'll draft a one-sentence testable DoD; you confirm at the gate (Recommended)
  - B. You'll dictate the DoD sentence now
  - C. DoD = the existing acceptance test passes (point me at it)
- Why-this-matters: Determines whether Phase 2 emits a Definition-of-Done checklist or copies an existing one.

Q8 — Edge cases (multi-select)
- Text: Which edge cases must be explicitly handled? (Pick all that apply.)
- Header: Edge cases
- Options (multiSelect):
  - A. Empty state (Recommended)
  - B. Concurrent writes / race conditions
  - C. Permission denied / unauthenticated
  - D. Network failure / retry semantics
- Why-this-matters: Each selected case becomes a required Phase 3 test case and a Phase 5 review-checklist item.

**EXIT CRITERIA**

Q1, Q4, Q5, Q7, Q8 answered (always required); Q2, Q3, Q6 answered if their COMPOSITION trigger fired; every answer reduced to A/B/C/D semantics (no free-text left ambiguous); DoD sentence captured verbatim in the work-doc preamble.

---

## Type: `fix`

**SCENARIO**

Use when the user is reporting broken behavior — an observable defect, a stack trace, a flow that no longer produces the expected outcome. Triggers on patterns like "X is broken", "Y doesn't work", "throws an error", "regressed since...". Not for mysteries with no clear reproduction (that's `debug`).

**COMPOSITION**

- Skip Q1 (Reproduction shape) and confirm if the user prompt contains BOTH the substring `expected` AND `actual`.
- Skip Q2 (Frequency) if the user prompt contains any of the literal substrings `always`, `every time`, `intermittently`, `once`, or `sometimes`.
- Skip Q3 (Recent changes) if the user prompt contains any of `started failing`, `regressed`, `after the`, `since we merged`.
- Always ask Q4 (Regression scope) — silently affected flows are the top source of incomplete fixes.
- Always ask Q5 (Severity) — it determines polish-vs-ship tradeoff.
- Always ask Q6 (Solution shape) — it gates whether Phase 3 dispatches a refactor sub-agent.
- Always ask Q7 (Regression test) — defaults to A; the only gate that prevents silent re-breakage. Q1 wording aligns with `debug` Q1 by design (keep in sync if either is edited).

**QUESTIONS**

Q1 — Reproduction shape
- Text: How is the reproduction already specified?
- Header: Repro
- Options:
  - A. Prompt has full steps + expected + actual — confirm and proceed (Recommended)
  - B. I'll walk through the repro now in chat
  - C. No reliable repro yet — switch to `debug` flow
- Why-this-matters: Routes the task: stay in `fix` flow vs. escalate to `debug` (Phase 3b evidence-gathering).

Q2 — Frequency
- Text: How often does this defect occur?
- Header: Frequency
- Options:
  - A. Always reproducible (Recommended)
  - B. Intermittent / flaky
  - C. Happened once
- Why-this-matters: Intermittent/once-only routes require evidence gathering in Phase 3b before patching.

Q3 — Recent changes
- Text: Is the regression linked to a recent change?
- Header: Trigger
- Options:
  - A. Known trigger (deploy / dep upgrade / config change) (Recommended)
  - B. No known trigger — appeared on its own
  - C. Unknown — needs git-bisect or log review
- Why-this-matters: Determines whether Phase 1 ends with a bisect step or jumps directly to root-cause analysis.

Q4 — Regression scope
- Text: What is the blast radius of this defect?
- Header: Blast radius
- Options:
  - A. Just this one flow (Recommended)
  - B. This flow plus a small set of related flows
  - C. Cross-cutting — multiple unrelated areas affected
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and whether the fix needs a feature-flag rollback path.

Q5 — Severity
- Text: How urgent is this fix?
- Header: Severity
- Options:
  - A. Production blocker — minimum viable fix now (Recommended)
  - B. Important but not blocking — polish acceptable
  - C. Nice-to-have — can be batched with other work
- Why-this-matters: Trades off Phase 3 minimum-diff vs. broader refactor and whether Phase 6 fast-paths to a hotfix tag.

Q6 — Solution shape
- Text: What shape should the fix take?
- Header: Fix shape
- Options:
  - A. Small targeted patch + regression test (Recommended)
  - B. Broader refactor of the broken area (more risk, more value)
  - C. Workaround now + follow-up work-doc filed
- Why-this-matters: Determines whether Phase 3 dispatches a single implementation agent or also a refactor agent.

Q7 — Regression test
- Text: Should a regression test be added that fails before the fix and passes after?
- Header: Regression
- Options:
  - A. Yes — write the failing test first (Recommended)
  - B. No — fix only, no new test
- Why-this-matters: Determines whether Phase 3 starts with a RED test step (TDD) or skips straight to the patch. A regression test that fails before the fix and passes after is the only way to prove the bug is actually fixed. Recommend A (yes) unconditionally unless the user prompt contains `no test`, `quick fix only`, or `can't test`.

**EXIT CRITERIA**

Q4, Q5, Q6, Q7 answered (always required); for Q1, Q2, Q3: either the question was answered OR its COMPOSITION skip condition fired and was logged; if Q1 = C, the task is re-routed to the `debug` bank and this bank's exit is bypassed; regression-test decision captured in the work-doc.

---

## Type: `refactor`

**SCENARIO**

Use when behavior should NOT change but structure should — moving code, renaming, extracting, deduplicating, restoring layer boundaries, prepping for an upcoming feature. Triggers on patterns like "clean up X", "extract Y", "consolidate Z", "this is getting messy", "prep for...". Not for user-visible changes (that's `feature` or `revamp`).

**COMPOSITION**

- Always ask Q1 (Driver) — drives the Phase 2 plan narrative.
- Always ask Q2 (Behavior contract) — the central refactor invariant. If the user names exceptions in the prompt, present them as confirmation.
- If the prompt names the scope (one file, one module, cross-project), skip Q3 (Scope).
- Always ask Q4 (Test coverage) — gates whether a "write tests first" sub-phase is inserted.
- Always ask Q5 (Migration shape) — determines whether Phase 2 plans a single PR or a staged rollout.
- If the user's prompt cites an exemplar module to mimic, skip Q6 (Pattern reference) and link it in the preamble.

**QUESTIONS**

Q1 — Driver
- Text: What problem is this refactor solving?
- Header: Driver
- Options:
  - A. Reduce tech debt / improve readability (Recommended)
  - B. Prep the code for an upcoming feature
  - C. Performance or scalability win
  - D. Restore a violated layer / architectural boundary
- Why-this-matters: Frames the Phase 2 plan narrative and selects the Phase 5 reviewer focus (quality vs. performance vs. layering).

Q2 — Behavior contract
- Text: Is any user-visible behavior allowed to change?
- Header: Behavior
- Options:
  - A. No — pure refactor, zero observable change (Recommended)
  - B. Yes — list allowed changes now in chat
- Why-this-matters: Determines whether Phase 5 includes a behavior-equivalence reviewer and whether Phase 3 runs a before/after snapshot test.

Q3 — Scope
- Text: How wide is the refactor's blast radius?
- Header: Scope
- Options:
  - A. Single module (Recommended)
  - B. Multiple modules in one project
  - C. Cross-project (backend + frontend)
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and whether more than one Wave 2 agent fans out.

Q4 — Test coverage
- Text: Is there enough existing test coverage to refactor safely?
- Header: Coverage
- Options:
  - A. Yes — coverage is sufficient, proceed (Recommended)
  - B. No — add characterization tests first as a sub-phase
  - C. Unknown — run a coverage check before deciding
- Why-this-matters: Inserts a "write tests first" sub-phase in Phase 2 when B/C are selected; gates Phase 3 entry.

Q5 — Migration shape
- Text: How should the refactor land?
- Header: Migration
- Options:
  - A. Big-bang single PR (Recommended)
  - B. Staged with shim + deprecation
  - C. Feature-flagged rollout
- Why-this-matters: Determines Phase 6 release shape and whether deprecation comments are emitted in Phase 3.

Q6 — Pattern reference
- Text: Is there an existing module that already shows the target shape?
- Header: Exemplar
- Options:
  - A. Yes — I'll link it now in chat (Recommended)
  - B. No — propose 2-3 candidate shapes in Phase 2
- Why-this-matters: Phase 2 mimics the linked exemplar verbatim; without one, Phase 2 spends time deriving the shape.

**EXIT CRITERIA**

Q1, Q2, Q4, Q5 answered (always required); Q3, Q6 answered if their COMPOSITION trigger fired; behavior-contract decision and migration shape captured in the work-doc; if Q4 = B, the work-doc Tasks list opens with a "write characterization tests" task before any structural change.

---

## Type: `revamp` or `redesign`

**SCENARIO**

Use for deeper rework — UI redesign, API redesign, replacing a subsystem, migrating to a new framework. Triggers on patterns like "redesign", "revamp", "rewrite", "replace X with Y", "modernize". Distinguished from `feature` because old behavior is being replaced (not just augmented), and from `refactor` because user-visible behavior IS allowed to change.

**COMPOSITION**

- This bank is standalone — do NOT chain to the `feature` bank. Authoritative questions duplicated here on purpose.
- Always ask Q1 (Goal shape), Q2 (What stays), Q3 (What goes), Q7 (Migration plan), Q8 (Backward compatibility).
- Ask Q4 (Visual reference) if the user prompt contains any of `UI`, `frontend`, `component`, `page`, `layout`, `design`, `visual`, `theme`, `styling`, `redesign`; otherwise skip.
- If the redesign touches a public API, ask Q5 (API impact); else skip.
- Always ask Q6 (Acceptance criteria) — gates Phase 2's DoD section.
- If the project has a brand spec under `docs/`, confirm in the preamble and skip the brand portion of Q4.

**QUESTIONS**

Q1 — Goal shape
- Text: How is the redesign's user-visible goal already specified?
- Header: Goal
- Options:
  - A. Use the prompt verbatim — I'll compress to one sentence (Recommended)
  - B. I'll write a one-sentence goal now in chat
  - C. Goal is ambiguous — propose 2-3 framings and pick one
- Why-this-matters: Determines whether Phase 2's DoD section is auto-derived or waits for user input before drafting.

Q2 — What stays
- Text: What about the current implementation must NOT change?
- Header: Invariants
- Options:
  - A. Nothing flagged — defer to my judgment, confirm at gate (Recommended)
  - B. I'll list invariants now in chat
  - C. Everything is on the table — full rewrite
- Why-this-matters: Captures invariants into the Phase 2 plan and seeds Phase 5's behavior-equivalence reviewer.

Q3 — What goes
- Text: What is explicitly removed or replaced?
- Header: Removed
- Options:
  - A. I'll list removed surfaces now in chat (Recommended)
  - B. Everything not in Q2 is in scope for removal
  - C. Removal list emerges during Phase 2 — flag at gate
- Why-this-matters: Frames the Phase 2 "what we're deleting" section and the Phase 6 communication plan for affected consumers.

Q4 — Visual reference (UI redesigns only)
- Text: What visual reference should the redesign honor?
- Header: Visual ref
- Options:
  - A. Existing brand spec under `docs/` (Recommended)
  - B. Reference mockups / mood — I'll attach now
  - C. No reference — propose 2-3 directions in Phase 2
- Why-this-matters: Loads `references/frontend-design.md` (binding) and determines whether Phase 3 fans out a design exploration sub-agent.

Q5 — API impact
- Text: What is the public-API impact of the redesign?
- Header: API impact
- Options:
  - A. No public API touched (Recommended)
  - B. Backward-compatible additive changes only
  - C. Breaking changes — transition window required
- Why-this-matters: Determines whether Phase 2 emits a deprecation timeline and whether Phase 5 includes a backward-compatibility reviewer.

Q6 — Acceptance criteria
- Text: How should the testable DoD be phrased?
- Header: DoD
- Options:
  - A. I'll draft a one-sentence testable DoD; you confirm at the gate (Recommended)
  - B. You'll dictate the DoD sentence now
  - C. DoD = the new acceptance test plus parity with the old one
- Why-this-matters: Determines whether Phase 2 emits a Definition-of-Done checklist or copies an existing one.

Q7 — Migration plan
- Text: How do existing users / data move from old to new?
- Header: Migration
- Options:
  - A. Big-bang cutover (Recommended)
  - B. Dual-run / shadow the new surface, then cut over
  - C. Phased rollout (feature flag, canary)
  - D. No migration needed — greenfield surface
- Why-this-matters: Drives Phase 2's migration section, Phase 3 data-migration sub-agent dispatch, and Phase 6 rollout plan.

Q8 — Backward compatibility
- Text: Are existing consumers still in flight that the redesign must keep working?
- Header: Back-compat
- Options:
  - A. Yes — transition period required (Recommended)
  - B. No — clean break acceptable
  - C. Unknown — survey consumers in Phase 1
- Why-this-matters: Determines whether Phase 3 emits compatibility shims and whether Phase 5 includes a back-compat reviewer.

**EXIT CRITERIA**

Q1, Q2, Q3, Q6, Q7, Q8 answered (always required); Q4 answered if the redesign is UI-bearing; Q5 answered if a public API is touched; invariants list and migration plan captured in the work-doc. If revamp Q4 indicates a UI-bearing change, the dispatching agent MUST load `references/frontend-design.md` and follow its rules BEFORE drafting the work-doc Approach section. This is binding, not advisory.

---

## Type: `debug`

**SCENARIO**

Use when the user has a mystery to solve rather than a clear ask — weird behavior with no reliable reproduction, intermittent failures, "sometimes X happens and I don't know why." Triggers on patterns like "I'm seeing weird X", "sometimes Y fails", "I can't figure out why", "no error but Z is wrong". Phase 3b's 4-phase debugging method runs during clarify; evidence gathering is part of Phase 1.

**COMPOSITION**

- Q1 wording mirrors `fix` Q1 by design — keep in sync if either is edited.
- Skip Q1 (Reproduction shape) if the user prompt contains BOTH `expected` AND `actual` (same rule as `fix` Q1); else ask Q1 as discovery.
- Always ask Q2 (Evidence collected) and Q3 (Hypotheses tried) — they prevent us from re-running work the user already did.
- Always ask Q4 (Instrumentation boundary) — gates whether Phase 3b can add logs/telemetry.
- Always ask Q5 (Outcome) — determines Phase 6's exit shape.
- Always ask Q6 (Time-box) — debug tasks have the highest risk of unbounded exploration.

**QUESTIONS**

Q1 — Reproduction shape
- Text: How reliable is the current reproduction?
- Header: Repro
- Options:
  - A. Reliable — I can reproduce on demand (Recommended)
  - B. Intermittent — happens but not predictably
  - C. Once-only — no current reproduction
- Why-this-matters: Reliable repro skips Phase 3b's evidence-gathering loop; intermittent/once-only triggers instrumentation-first investigation.

Q2 — Evidence collected
- Text: What logs / stack traces / screenshots have you already gathered?
- Header: Evidence
- Options:
  - A. I'll paste them now in chat (Recommended)
  - B. None yet — I need help collecting
  - C. Some collected — I'll describe what's missing
- Why-this-matters: Determines whether Phase 3b starts from a known-evidence baseline or from zero.

Q3 — Hypotheses tried
- Text: What have you already tried, and what was the outcome?
- Header: Tried
- Options:
  - A. I'll list attempts and outcomes now in chat (Recommended)
  - B. Nothing tried yet — fresh investigation
  - C. Tried many things, lost track — start over
- Why-this-matters: Prevents Phase 3b from re-running failed approaches and seeds the hypothesis list.

Q4 — Instrumentation boundary
- Text: May I add instrumentation (logs, telemetry, breakpoints) as part of the investigation?
- Header: Instrument
- Options:
  - A. Yes — add freely, I'll remove after (Recommended)
  - B. Yes, but only with a temporary feature-flag / DEBUG guard
  - C. No — read-only investigation
- Why-this-matters: Sets Phase 3b's evidence-gathering toolkit and whether Phase 6 includes a "remove instrumentation" cleanup task.

Q5 — Outcome
- Text: What outcome do you want from this investigation?
- Header: Outcome
- Options:
  - A. Root cause identified + fix shipped (Recommended)
  - B. Root cause identified + handed back to you
  - C. Mitigation now, deeper investigation later
- Why-this-matters: Determines Phase 6's exit shape (fix lands vs. report-only vs. mitigation + follow-up doc).

Q6 — Time-box
- Text: How long are you OK with this investigation running before we stop and reassess?
- Header: Time-box
- Options:
  - A. 2-4 hours, then checkpoint (Recommended)
  - B. Half a day, then checkpoint
  - C. As long as it takes — no time-box
- Why-this-matters: Phase 3b inserts a hard checkpoint at the named duration; without it, debug tasks run unbounded.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5, Q6 all answered; evidence pasted (or "none yet" explicitly confirmed); hypotheses-tried list captured; instrumentation boundary recorded so Phase 3b knows its toolkit; the work-doc Approach section is replaced by an Investigation Plan with components-to-instrument, evidence-to-gather, and hypotheses-to-test in order.

---

## Type: `research`

**SCENARIO**

Use when the user wants to discuss or explore an idea before committing to build it — feasibility studies, architecture trade-off comparisons, library evaluations, "is X possible?" Triggers on patterns like "research", "explore", "evaluate", "compare X vs Y", "should we...". The Phase 2 gate is reframed from "approve the plan to build" to "approve the conclusions and whether to build."

**COMPOSITION**

- Always ask Q1 (Question shape) — research with no testable question produces no testable answer.
- Always ask Q2 (Decision it informs) — if no decision rides on the answer, the research is theatre.
- Always ask Q3 (Depth) — sets the time-box and deliverable shape.
- Always ask Q4 (Output) — determines where conclusions land.
- Always ask Q5 (Continuation) — sets Phase 6's exit (auto-roll into build vs. pause for user decision).

**QUESTIONS**

Q1 — Question shape
- Text: How is the research question already specified?
- Header: Question
- Options:
  - A. Single testable question — I'll compress the prompt to one sentence (Recommended)
  - B. You'll dictate the question now in chat
  - C. Several open threads — propose a question hierarchy
- Why-this-matters: Sets the Phase 2 plan's "Question under investigation" line and gates whether sub-questions fan out into parallel research agents.

Q2 — Decision it informs
- Text: What decision will we make differently based on the answer?
- Header: Decision
- Options:
  - A. Build vs. don't build a specific feature (Recommended)
  - B. Pick one of several already-named approaches
  - C. Sizing / scoping a future work-doc
- Why-this-matters: Frames Phase 2's Approach section and what the Phase 6 conclusions report must contain.

Q3 — Depth
- Text: How deep should the research go?
- Header: Depth
- Options:
  - A. Quick sketch — 1-2 hours, no code (Recommended)
  - B. Spike — minimal prototype on a throwaway branch
  - C. Full investigation — multiple options compared with evidence
- Why-this-matters: Sets the Phase 1 time-box, whether a sandbox worktree is created, and how many parallel research sub-agents fan out.

Q4 — Output
- Text: Where should the conclusions land?
- Header: Output
- Options:
  - A. Markdown summary in the work-doc only (Recommended)
  - B. Markdown summary plus a spike branch
  - C. Markdown summary plus a follow-up build work-doc draft
- Why-this-matters: Determines whether Phase 6 commits a spike branch and whether a follow-up work-doc is scaffolded.

Q5 — Continuation
- Text: After the conclusions land, what happens next?
- Header: Continuation
- Options:
  - A. Pause and let you decide whether to build (Recommended)
  - B. If the answer is "yes, build", auto-roll into a `feature` doc
  - C. Hand off to another person / team
- Why-this-matters: Sets Phase 6's exit (pause vs. auto-dispatch a new `feature` work-doc) and the handoff format if applicable.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5 all answered; question sentence captured verbatim in the work-doc preamble; decision-it-informs captured in the Approach section; depth time-box recorded so Phase 1 has a hard checkpoint; Phase 2 gate framed as "approve the conclusions and whether to build" (not "approve the plan to build").

---

## Picking & combining questions

- **Single source of ambiguity** → 1 question is enough. Don't pad to look thorough.
- **Multiple ambiguities of the same shape** → group into one numbered Issue with options.
- **Question whose answer is in CLAUDE.md** → don't ask it. (E.g. if the project's CLAUDE.md pins the package manager, don't ask.)
- **Question whose answer is in your codebase-exploration tool output or recent commits** → don't ask it. Confirm in the preamble ("I see the existing `invitations` table has no `expires_at` column…") and skip the question.

The point of the batch is to make Phase 1 **one round-trip**, not zero. If you have 10 things to ask, ask them — that's still one round-trip. If you have 3, ask 3.
