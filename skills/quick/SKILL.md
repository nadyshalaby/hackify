---
name: quick
description: Compressed-flow companion to the hackify workflow. Use for small bug fixes, direct quick-effort requests, single-file edits, polish/typo work, and tiny tweaks where full hackify ceremony (Plan+Gate, Spec review, Multi-reviewer, 4-options finish) would burn more wall-clock and tokens than the change is worth. Auto-discovery triggers — invoke this skill when the user says any of "quick fix", "small change", "just fix the", "one-line fix", "tiny edit", "small fix", "small bug", "quick patch", "minor tweak", or the explicit slash form /hackify:quick. Workflow shape Phase 1 (clarify only if ambiguous; zero questions otherwise) -> Phase 3 (implement, single agent or inline; file allowlist still applies) -> Phase 4 (verify; test + lint + typecheck still mandatory) -> Phase 6 Step F (mandatory 2-column Area/Change summary table, printed to chat). Do NOT use for cross-file refactors, redesigns, debug investigations of unknown root causes, or anything with security/auth/crypto/migration surface — those go to full hackify from the start. Falls back to full hackify automatically on any of 4 testable signals — implementation-attempt counter reaches 2, git diff --name-only HEAD | wc -l > 3, any touched path matches *auth*/*crypto*/*migration*/*secret*/*token*/*password*, or the user explicitly requests Phase 5 / multi-reviewer / full review during the task. On fallback, quick mode writes a work-doc from accumulated context and re-enters full hackify Phase 2.
---

## Pre-flight: smart router — pick the right flow

Before doing anything else when invoked, the router decides whether the user prompt actually belongs in quick mode. Three signal groups are evaluated against the user's most recent prompt (the one that triggered this skill load); exactly one must fire to stay in quick. If zero or two-or-more groups fire, default to full hackify — the most-ensured decision.

### Signal group (i) — Brainstorm triggers

If the user prompt contains any of the following (case-insensitive substring match), route to the `brainstorm` skill (NOT quick or full). Brainstorm itself decides when the conversation graduates to a build task and hands off to Phase 1 of full hackify.

- `/brainstorm`
- `let's discuss`
- `let's think`
- `what if`
- `brainstorm`
- `explore the idea`

### Signal group (ii) — Full-mode triggers

The inverse of quick mode's four testable fallback triggers, PLUS the explicit slash-command override. If any of these fire, route to full hackify (`/hackify:hackify`) from the start.

- **Auth/security keywords** (case-insensitive substring): `auth`, `crypto`, `migration`, `secret`, `token`, `password`.
- **Multi-file scope keywords** (case-insensitive substring): `across all`, `refactor everything`, `redesign`, `everywhere`.
- **Architecture keywords** (case-insensitive substring): `schema`, `data model`, `API surface`.
- **Prompt length > 80 characters** AND not already brainstorm-tagged (Group (i) did not fire).
- **Explicit `/hackify:hackify` slash** in the prompt.

### Signal group (iii) — Quick-eligible

None of Group (i) or Group (ii) fired AND the user prompt is concrete — either a file path is mentioned, or a single behavioral change is named. Stay in quick.

### Decision table

| Signal group fired | Route to | Rationale |
|---|---|---|
| Group (i) only — brainstorm triggers | `brainstorm` skill | The user is in idea-exploration mode; brainstorm graduates to full hackify Phase 1 when the conversation converges on a build task. |
| Group (ii) only — full-mode triggers | Full hackify (`/hackify:hackify`) | The task carries security/scope/architecture surface, or the user explicitly asked for the heavier flow — quick mode's carve-out does not cover it. |
| Group (iii) only — quick-eligible | Stay in quick | The prompt is small, concrete, and free of security/scope/architecture signals — quick mode is the right speed-to-discipline tradeoff. |
| Zero groups fired | Full hackify (default) | The prompt is ambiguous or off-pattern; default-to-full is the most-ensured decision — full hackify's Phase 1 clarify wizard will disambiguate before any code lands. |
| Two-or-more groups fired | Full hackify (default) | Conflicting signals mean the task spans multiple shapes; default-to-full lets Phase 2 Plan+Gate resolve the scope before implementation starts. |

**Fallback rule.** If the signal-group count is not exactly 1 (i.e., zero groups fire OR two-or-more groups fire), default to full hackify. Default-to-full is the documented most-ensured decision — quick mode is a carve-out, not a default.

The same router logic lives in `skills/hackify/SKILL.md` (added by T1.4a). Both skills route consistently; this block is the source of truth for the quick-skill side.

---

# Hackify Quick — Compressed Flow For Small Tasks

Sibling to the main hackify skill. Same end-to-end discipline (clarify → implement → verify → summary), ceremony stripped. Fully self-contained — **never call other skills**; fallback re-enters full hackify by name. Target: ~one-third the tokens/wall-clock of full hackify.

## Workflow shape

```
Phase 1 (clarify if ambiguous) → Phase 3 (implement) → Phase 4 (verify) → Phase 6F (summary table)
```

No Plan+Gate. No Spec self-review. No Multi-reviewer. No four-options finish menu. The summary table is the only mandatory artifact; print to chat.

## Kept phases

| Phase | Action | Rationale |
|---|---|---|
| **1 — Clarify** | Run the wizard at `skills/hackify/references/clarify-questions.md` if the ask has any ambiguity. Zero ambiguity ("fix typo on line 42 of README.md") → zero questions, go to Phase 3. | A misread ask costs more than a one-question wizard. |
| **3 — Implement** | Dispatch at most ONE foreground subagent with a file allowlist, or write inline for 1–3-line single-file edits. File-allowlist constraint applies — agent touches declared files only. | Scope discipline keeps quick mode quick. Spread = fallback fires. |
| **4 — Verify** | Run the project's full triad (test + lint + typecheck) fresh. Paste output. Zero failures, zero errors. | Skipping verify is how typo fixes ship broken. |
| **6F — Summary table** | Generate the 2-column Area/Change table per `skills/hackify/references/finish.md` and print to chat. | The user opted into speed, not opacity. |

## Skipped phases — exactly these four, no others

| Phase | Rationale |
|---|---|
| **Phase 2 — Plan+Gate** | The ask itself is the plan. Tasks needing a written plan are too large for quick mode. |
| **Phase 2.5 — Spec self-review** | No spec was written in Phase 2 — nothing to scrutinize. |
| **Phase 5 — Multi-reviewer code review** | Single-file diffs do not justify three parallel review lenses. User can force it via the fallback trigger. |
| **Phase 6 — four-options finish menu** | Quick mode does in-place edits. The user lands via their normal git workflow. Step F is the only Phase 6 piece kept. |

## Note — Debug-when-stuck is not skipped

**Phase 3b is NOT skipped — the fallback escalates to full hackify, which runs Phase 3b under its own discipline.** The attempt-counter trigger (≥2 failed passes) flips the task into full hackify, preserving the 4-phase root-cause hunt without bloating quick mode.

## Fallback to full hackify

Quick mode escalates on any of the 4 concrete, testable triggers below. Each predicate produces a binary signal a Haiku-class model can act on. Vague signals like "feels big" are forbidden.

- **(a) Attempt counter reaches 2.** Write `attempt: N` as the first line of every Daily Updates entry in a scratch file at `<project>/docs/work/.quick-<slug>.md` (lazy-created on attempt 1; gitignorable). Increment N after each pass (pass or fail). At N=2, fall back. On-disk storage survives subagent restarts.
- **(b) File count exceeds 3 (including untracked).** After each pass, run `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | wc -l`. If `> 3`, fall back. Untracked files MUST count — `git diff HEAD` alone misses new-file scope creep.
- **(c) Security-sensitive path touched.** After each pass, run `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | grep -iE 'auth|crypto|migration|secret|token|password'`. Full path match, case-insensitive (so `src/auth/foo.ts`, `AuthHelper.ts`, `db/migrations/0042.sql` all fire). If grep exits 0, fall back.
- **(d) User invokes full review.** Scan ONLY the most recent user message (NOT the full transcript) for case-insensitive `Phase 5`, `multi-reviewer`, or `do full review`. If any match, fall back.

## Fallback procedure

On trigger: (1) STOP implementation; (2) write a work-doc from accumulated context at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` (template at `skills/hackify/references/work-doc-template.md`); (3) re-enter full hackify Phase 2 (Plan+Gate); (4) preserve intent + clarify-answers + any partial diff in the Daily Updates section. Set frontmatter `current_task: (fallback from quick mode — awaiting gate)`. Do not silently re-dispatch implementation agents.

## When NOT to use quick mode

Route these to full hackify (`/hackify:hackify`) from the start.

| Shape | Why |
|---|---|
| Cross-file refactors | >3-file trigger fires; first pass is wasted. |
| Redesigns | Plan+Gate is required for sign-off on the new shape. |
| Debug investigations of unknown root causes | Phase 3b's 4-phase root-cause hunt is needed from the jump. |
| Touches auth/crypto/migrations/secrets/tokens/passwords | Security-sensitive trigger fires immediately. |
| Cross-team review needs | Phase 5 multi-reviewer anchors the review conversation. |
| Cannot list touched files up-front | Task is too underspecified for a file allowlist. |

## Summary table — mandatory

End every task with a 2-column markdown table (`Area` | `Change`). Authoring rules per full hackify's Phase 6 Step F (see `skills/hackify/references/finish.md`):

- **Area** — 1–4 word concept/theme label. NOT a file path. NOT a DoD ID.
- **Change** — ≤25 words, present-tense action verb, backticks for code spans.
- 5–12 rows per task (quick mode typically 1–5).

Print to chat. If fallback fired, append the table to the new work-doc's Retrospective under `## Summary of changes shipped`. For on-demand invocation, see `commands/summary.md` (`/hackify:summary`).

## Anti-rationalizations — STOP and apply the listed reality

| Thought | Reality |
|---|---|
| "It's only one file, no need to check the diff scope" | Run quick. After the implementation pass, `git diff --name-only HEAD | wc -l` runs anyway. If it touches >3, fall back — that is the trigger doing its job. |
| "I can skip Phase 4 verify, it is just a typo" | Phase 4 stays. Typo fixes still need lint + typecheck to pass. The verification triad is the cheapest insurance in the workflow. |
| "User said 'quick' so we skip Phase 1 clarify" | Only skip clarify if there is zero ambiguity in the ask. If even one detail is unclear, run the wizard — one batched question is cheaper than a wrong implementation. |
| "The diff touches an `auth_helper.ts` file but it is just a comment edit" | The path glob trigger fires on `*auth*` regardless of edit size. Fall back to full hackify and let Phase 5 confirm the comment edit is safe. |
| "Attempt 2 failed but I have a great idea for attempt 3" | The attempt counter hitting 2 is the circuit breaker. No attempt 3 in quick mode — fall back, write the work-doc, let full hackify run Phase 3b properly. |
| "Summary table is overkill for a one-line fix" | The summary table is mandatory. One row is fine. The user always knows what landed. |

## One-line summary

Clarify-if-ambiguous → implement (one agent, file allowlist) → verify fresh → print the Area/Change summary table. Fall back to full hackify the moment the task grows past the carve-out.
