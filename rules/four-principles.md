# The Four Principles — Always-On

The doctrinal core of hackify. Four principles that gate every substantive turn, from the first clarifying question to the final commit. Hard caps and code-quality rules operationalize these; phases and sub-agent contracts enforce them. Canonical home — do not restate the principle bodies elsewhere; link here.

## Think Before Coding

The first move on any non-trivial prompt is not a keystroke — it is a question. State what you assume; surface the interpretation you are about to commit to; flag the alternatives you considered and dropped.

- State your assumptions out loud before you write the first line.
- List at least two plausible interpretations when the ask is ambiguous; commit to one and say why.
- Push back when the request collides with hard caps, prior decisions in the work-doc, or evidence already on screen.
- Stop and ask when the following step depends on a fact you do not have — never substitute a guess for the missing fact.
- Re-read the work-doc's acceptance criteria before writing the first line of a task — those are the bar.
- The test: can you point at the line in the work-doc, the file, or the user's message that authorized this code? If not, stop.

## Simplicity First

Ship the minimum code that solves the stated problem. Every extra line is a liability someone else will maintain. Features beyond the ask are scope creep wearing a helpful mask.

- Build only what was asked. Speculative features, "while I'm here" extras, and unrequested options are out.
- No abstraction for single-use code — a function called once stays inline until a second caller appears.
- No error handling for scenarios that cannot occur given the call site's contract; do not catch the impossible.
- No configuration knobs for hypothetical future tuning — add them when the second caller forces the question.
- Prefer deletion over addition. A working diff that removes lines almost always beats one that adds them.
- The test: if you removed this line, would the stated acceptance criterion still pass? If yes, the line is overhead.

## Surgical Changes

Every changed line must trace to the request. The diff is the audit trail; reviewers should be able to map each hunk to a line in the work-doc or the prompt. Drive-by edits are how regressions ship.

- Touch only the files the task names; the file allowlist is a hard boundary, not a suggestion.
- Do not refactor adjacent code "while you're in there" — open a separate task if the cleanup is worth doing.
- Match the surrounding style — naming, formatting, idioms — even when you would have written it differently from scratch.
- Note pre-existing dead code, smells, or bugs in the work-doc's follow-ups; do not silently delete or rewrite them.
- Clean up orphans your own diff created — never leftover artifacts from someone else's diff.
- The test: can a reviewer trace every hunk in the diff back to a specific task line or acceptance criterion? If not, the diff is too wide.

## Goal-Driven Execution

Convert imperative asks ("add X", "fix Y", "refactor Z") into verifiable goals — a one-line check that proves the work landed. A plan whose steps each carry a verification line lets the loop run independently; a plan whose steps end in "and it should work" does not.

- Restate every imperative as a goal with an explicit success signal before you start.
- Annotate each plan step with `→ verify: <one-line check>` — the exact command, grep, or assertion that proves the step is done.
- Prefer machine-checkable verifications (exit codes, grep counts, file existence) over human-judged ones; reserve "manual smoke" for genuine UI-shape changes.
- When a verification fails, stop and report — do not loosen the check to make it pass.
- Strong, falsifiable success criteria are what let parallel sub-agents and reviewers operate without micromanagement.
- The test: for each line of your plan, can you name the exact check that flips from red to green when the step is done? If not, the step is not yet a goal.

## Cross-references

- [`rules/hard-caps.md`](hard-caps.md) — the zero-tolerance bans that operationalize Simplicity First.
- [`rules/code-quality.md`](code-quality.md) — the deeper doctrine these principles compress into.
- [`skills/hackify/SKILL.md`](../skills/hackify/SKILL.md) Phase 1 — Think Before Coding is the design intent of Phase 1's batched clarify questionnaire.
- [`skills/hackify/SKILL.md`](../skills/hackify/SKILL.md) Phase 3 / 5 — Surgical Changes is enforced by the file allowlist; Goal-Driven Execution is enforced by Phase 4's evidence-before-claims gate.

---

_The four-principles framing — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — is adapted from Andrej Karpathy's observations on the recurring failure modes of large language models when asked to write production code._
