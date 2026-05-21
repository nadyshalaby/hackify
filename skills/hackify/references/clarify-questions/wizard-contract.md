# Wizard Contract

Phase 1 builds **one batched questionnaire** drawn from the bank for the matched task type. **Drop questions whose answer is already evident** from the user's prompt or from context you've already read (codebase exploration tools, file system). Add task-specific questions if a question bank misses something obvious.

## Delivery format — wizard only (mandatory)

**Every clarify question is delivered through the `AskUserQuestion` tool.** Plain numbered markdown lists in chat are forbidden for Phase 1 — the wizard renders structured options the user can click, which is faster, less error-prone, and easier to answer on the move.

Tool constraints to design around:

- **1–4 questions per call.** If your batch is larger, send **multiple back-to-back `AskUserQuestion` calls in the same turn** — fire the following call as soon as the previous batch is answered, with no chat narration in between unless something needs clarifying. Aim for ≤16 total questions across all batches; if you need more, your scope is too broad — narrow first.
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

Hackify also ships an anti-patterns reference at [anti-patterns.md](../anti-patterns.md) with worked wrong/right examples. Phase 1 doesn't load it (you're not writing code yet); Phase 3 implementers do. Keep it on your radar when drafting Q&A that touches a known anti-pattern (e.g., over-abstraction, scope creep, lint-suppression rationalization).

---

## Purpose

Every wizard bank (the universal preamble plus the six `Type:` task-type banks) MUST conform to the 4-section structure defined here. This is the canonical specification — banks that drift from it are dispatch bugs. RFC 2119 keywords (MUST / SHOULD / MAY) apply throughout.

## The 4 mandatory sections

Each bank MUST contain these four sections, in this order, with these exact names:

1. **SCENARIO** — one paragraph describing when this bank applies. MUST name the trigger condition concretely (e.g. "user is adding new behavior the system doesn't have"). Generic framing ("when the user has a question") is forbidden.

   *Mini-example:* "Use when the user is reporting broken behavior — an observable defect, a stack trace, or a flow that no longer produces the expected outcome."

2. **COMPOSITION** — decision rules for picking N questions from the bank based on context already gathered (prompt text, `CLAUDE.md`, codebase exploration output). MUST be explicit "if X then Y" rules — NOT free choice. Generic "use judgment" language is forbidden.

   *Mini-example:* "If user prompt already names the target file, skip Q1 (Scope). Else ask Q1. If `CLAUDE.md` pins the package manager, skip Q5 (Tooling). Else ask Q5."

3. **QUESTIONS** — the candidate question pool (4–8 per bank). Each question MUST conform to the Question structure (following subsection). Questions whose answer is already evident from context MUST be dropped at composition time, not asked.

   *Mini-example:* "Q1 — Scope. text: `Single file or cross-module?` header: `Scope`. options: A `Single file (Recommended)` / B `Cross-module` / C `Cross-project`. why-this-matters: determines whether the worktree is created and whether Phase 4 cross-package verification runs."

4. **EXIT CRITERIA** — the binary condition under which the wizard is "done enough" to proceed to Phase 2. MUST be checkable, not aspirational. The dispatching agent uses this to decide whether to loop back for another batch or move on.

   *Mini-example:* "All composed questions answered AND no answer left ambiguous (free-text answers reduced to one of A/B/C/D semantics or explicitly confirmed as a new option) AND scope sentence written into the work-doc preamble."

## Question structure

Every question in a bank's QUESTIONS section MUST specify:

- **text** — the question prompt shown to the user. One short sentence. No filler.
- **header** — the chip text rendered in the wizard. ≤12 characters. Concrete (`Scope`, `Roles`, `Invite flow`) — NOT `Question 1` or `Q3`.
- **options** — 2–4 mutually-exclusive options labeled A / B / C / D. Option A MUST be suffixed with ` (Recommended)`. NEVER include an `Other` option — the `AskUserQuestion` tool auto-injects free-text input.
- **why-this-matters** — one line stating what the answer changes downstream (which task-type branch is taken, which Phase 2 plan section is generated, which Phase 3 sub-agent fans out, which verification step runs). If the answer changes nothing downstream, the question MUST be cut.

## Composition rules

COMPOSITION is decision rules, NOT free choice. Each bank's COMPOSITION subsection MUST enumerate explicit conditionals that map context signals to question inclusion or exclusion.

*Mini-example (for a `fix` bank):* "If the user prompt already names the target file, skip Q1 (Scope). Else ask Q1. If the user prompt includes a stack trace, skip Q2 (Reproduction steps). Else ask Q2. Always ask Q5 (Regression test) — it's the only gate that prevents silent re-breakage."

Generic "use judgment" or "ask what feels relevant" language is forbidden. The dispatching agent (and a Haiku-class weak model executing this skill) MUST be able to mechanically apply the COMPOSITION rules without inferring intent.
