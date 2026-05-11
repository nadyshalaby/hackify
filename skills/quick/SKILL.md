---
name: quick
description: Compressed-flow companion to the hackify workflow. Use for small bug fixes, direct quick-effort requests, single-file edits, polish/typo work, and tiny tweaks where full hackify ceremony (Plan+Gate, Spec review, Multi-reviewer, 4-options finish) would burn more wall-clock and tokens than the change is worth. Auto-discovery triggers — invoke this skill when the user says any of "quick fix", "small change", "just fix the", "one-line fix", "tiny edit", "small fix", "small bug", "quick patch", "minor tweak", or the explicit slash form /hackify:quick. Workflow shape Phase 1 (clarify only if ambiguous; zero questions otherwise) -> Phase 3 (implement, single agent or inline; file allowlist still applies) -> Phase 4 (verify; test + lint + typecheck still mandatory) -> Phase 6 Step F (mandatory 2-column Area/Change summary table, printed to chat). Do NOT use for cross-file refactors, redesigns, debug investigations of unknown root causes, or anything with security/auth/crypto/migration surface — those go to full hackify from the start. Falls back to full hackify automatically on any of 4 testable signals — implementation-attempt counter reaches 2, git diff --name-only HEAD | wc -l > 3, any touched path matches *auth*/*crypto*/*migration*/*secret*/*token*/*password*, or the user explicitly requests Phase 5 / multi-reviewer / full review during the task. On fallback, quick mode writes a work-doc from accumulated context and re-enters full hackify Phase 2.
---

# Hackify Quick — Compressed Flow For Small Tasks

Quick mode is a sibling to the main hackify skill, not a sub-skill. It runs the same end-to-end discipline (clarify → implement → verify → summary) with the heavy ceremony stripped out, for tasks that fit the small-and-direct carve-out. When the task grows past the carve-out, the fallback rules below escalate to full hackify cleanly — no half-done state, no lost context.

This skill is fully self-contained. **Never call other skills** — third-party plugins may not be installed. The fallback procedure re-enters full hackify by name; it does not depend on any other plugin.

---

## Workflow shape

Quick mode runs exactly four phases of the full hackify flow, in order:

```
Phase 1 (clarify if ambiguous) → Phase 3 (implement) → Phase 4 (verify) → Phase 6F (summary table)
```

No Plan+Gate. No Spec self-review. No Multi-reviewer. No four-options finish menu. The summary table at the end is the only mandatory artifact, and it goes to chat (not a work-doc — quick mode does not create one by default).

Target: roughly one-third the tokens and wall-clock of the full hackify flow for tasks that fit the carve-out.

---

## Kept phases

- **Phase 1 — Clarify (only if ambiguous).** Run the full clarify wizard from `skills/hackify/references/clarify-questions.md` if any part of the ask is unclear. If the ask is concrete and zero-ambiguity ("fix the typo on line 42 of README.md"), ask zero questions and go straight to Phase 3. Rationale: a misread ask wastes more time than a one-question wizard.
- **Phase 3 — Implement (single agent or inline).** Dispatch at most ONE foreground implementation subagent with a file allowlist, or write the change inline if it is genuinely a one- to three-line edit in a single file. The file-allowlist constraint from full hackify still applies — the agent may only touch declared files. Rationale: scope discipline is what keeps quick mode quick; the moment the work spreads, the fallback fires.
- **Phase 4 — Verify (test + lint + typecheck).** Run the project's full verification triad fresh. Paste the output. Zero failures, zero errors. Rationale: skipping verify is how typo fixes ship broken — Phase 4 stays.
- **Phase 6 Step F — Summary table (mandatory).** Generate the 2-column Area/Change markdown table per the authoring rules in `skills/hackify/references/finish.md` and print it to chat. Rationale: the user opted into quick mode for speed, not for opacity — the summary keeps them aligned on what shipped.

---

## Skipped phases

Quick mode skips EXACTLY these four phases. No others.

- **Phase 2 — Plan+Gate.** Skipped. Rationale: a small task does not need a 60-second-readable work-doc and an explicit sign-off — the ask itself is the plan. If the task is large enough to need a written plan, it is too large for quick mode.
- **Phase 2.5 — Spec self-review.** Skipped. Rationale: no spec was written in Phase 2, so there is nothing for three parallel reviewers to scrutinize.
- **Phase 5 — Multi-reviewer code review.** Skipped. Rationale: small single-file diffs do not benefit enough from three parallel review lenses to justify the round-trip cost. If the user wants Phase 5 anyway, the fallback rule below fires automatically on that phrase.
- **Phase 6 — four-options finish menu.** Skipped. Rationale: quick mode is for in-place edits — the merge/PR/keep/discard ceremony is overkill. The user decides how to land the change with their normal git workflow. Step F (the summary table) is the only Phase 6 piece kept.

---

## Note — Debug-when-stuck is not skipped

**Phase 3b Debug-when-stuck is NOT skipped — the fallback rule below escalates to full hackify, which handles Phase 3b normally.** Quick mode does not enter the debug branch directly; instead, the attempt-counter trigger (≥2 failed implementation passes) flips the task into full hackify, and full hackify then runs Phase 3b under its own discipline. This preserves the 4-phase root-cause hunt without bloating the quick-mode flow with a debug branch.

---

## Fallback to full hackify

Quick mode escalates to full hackify on any of the following 4 concrete, testable triggers. Each is a predicate an agent can evaluate without judgment calls — every step below produces a binary signal a Haiku-class model can act on. Vague signals like "feels big" are forbidden — if the predicate does not fire, quick mode keeps going.

- **(a) Attempt counter reaches 2.** Maintain the counter by writing `attempt: N` as the first line of every Implementation Log entry inside an in-flight scratch file at `<project>/docs/work/.quick-<slug>.md` (created lazily on attempt 1 if absent; can be gitignored). Increment N by 1 in the implementation agent's report after each pass (whether the pass passed or failed verification). When the counter reaches **2**, fall back. Storing the counter on disk (not "in-session state") survives subagent restarts and makes the value testable by the parent.
- **(b) File count exceeds 3 (including untracked).** After each implementation pass, run `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | wc -l`. If the result is `> 3`, fall back. Untracked files MUST count — new files are exactly the cross-file scope creep this trigger catches; `git diff HEAD` alone would silently miss them.
- **(c) Security-sensitive path touched.** After each implementation pass, run `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | grep -iE 'auth|crypto|migration|secret|token|password'`. Match the FULL path case-insensitively (so `src/auth/foo.ts`, `AuthHelper.ts`, and `db/migrations/0042.sql` all fire). If grep exits 0 (any match), fall back. Security-sensitive surfaces need Phase 5 multi-reviewer, period.
- **(d) User invokes full review.** Scan ONLY the most recent user message during the quick-mode task (NOT the full transcript — earlier prompts must NOT retro-trigger) for the case-insensitive substrings `Phase 5`, `multi-reviewer`, or `do full review`. If any match, fall back. The user is explicitly asking for the heavier flow.

---

## Fallback procedure

On fallback trigger: (1) STOP the in-progress implementation; (2) write a work-doc from accumulated context at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`; (3) re-enter full hackify Phase 2 (Plan+Gate); (4) preserve quick-mode's intent + clarify-answers + any partial diff in the work-doc Implementation Log so full hackify resumes with full context.

The work-doc skeleton is the same one full hackify uses (`skills/hackify/references/work-doc-template.md`). Frontmatter `current_task` should read `(fallback from quick mode — awaiting gate)` so the user sees the handoff explicitly when the Phase 2 plan is presented. Do not silently re-dispatch implementation agents — the gate exists exactly because the task grew past the quick-mode carve-out, and the user deserves a chance to sign off on the revised scope.

---

## When NOT to use quick mode

Route these task shapes to full hackify (`/hackify:hackify`) from the start. Do not start them in quick mode.

- **Cross-file refactors.** Even a "small" refactor that touches more than one file is past the carve-out — the >3-file trigger would fire shortly, and starting in quick mode just wastes the first pass.
- **Redesigns.** Visual or architectural redesigns need the Plan+Gate so the user can sign off on the new shape before code lands.
- **Debug investigations of unknown root causes.** If the task starts with "something is broken and I don't know why", you need Phase 3b's 4-phase root-cause hunt from the jump.
- **Anything touching auth, crypto, migrations, secrets, tokens, or passwords.** The security-sensitive trigger would fire immediately; start with full hackify and Phase 5.
- **Anything with cross-team review needs.** PR-track work that needs reviewer sign-off from another team needs the Phase 5 multi-reviewer output to anchor the review conversation.
- **Tasks where you cannot list the touched files up-front.** If you cannot name the file allowlist for the implementation agent before dispatch, the task is too underspecified for quick mode.

---

## Summary table — mandatory

At the end of every quick-mode task, generate a 2-column markdown table with columns `Area` and `Change`. Authoring rules are identical to full hackify's Phase 6 Step F — see `skills/hackify/references/finish.md` for the canonical guidance:

- **Area** — 1–4 word concept/theme label. NOT a file path. NOT a DoD ID. The user-facing concept.
- **Change** — ≤25 words, present-tense action verb, backticks for code spans.
- 5–12 rows total per task (quick mode usually lands in the 1–5 range).

Print the table to chat. Quick mode has no work-doc to append to by default, so chat is the sole destination — unless the fallback fired, in which case the table is appended to the new work-doc's Post-mortem under `## Summary of changes shipped` per full hackify's Phase 6 Step F rules.

For on-demand invocation outside any in-flight task, cross-reference `commands/summary.md` (the `/hackify:summary` slash command), which uses the same authoring rules.

---

## Anti-rationalizations

These thoughts mean STOP and apply the listed reality.

| Thought | Reality |
|---|---|
| "It's only one file, no need to check the diff scope" | Run quick. After the implementation pass, `git diff --name-only HEAD | wc -l` runs anyway. If it touches >3, fall back — that is the trigger doing its job. |
| "I can skip Phase 4 verify, it is just a typo" | Phase 4 stays. Typo fixes still need lint + typecheck to pass. The verification triad is the cheapest insurance in the workflow. |
| "User said 'quick' so we skip Phase 1 clarify" | Only skip clarify if there is zero ambiguity in the ask. If even one detail is unclear, run the wizard — one batched question is cheaper than a wrong implementation. |
| "The diff touches an `auth_helper.ts` file but it is just a comment edit" | The path glob trigger fires on `*auth*` regardless of edit size. Fall back to full hackify and let Phase 5 confirm the comment edit is safe. |
| "Attempt 2 failed but I have a great idea for attempt 3" | The attempt counter hitting 2 is the circuit breaker. No attempt 3 in quick mode — fall back, write the work-doc, let full hackify run Phase 3b properly. |
| "Summary table is overkill for a one-line fix" | The summary table is mandatory. One row is fine. The point is that the user always knows what landed. |

---

## One-line summary

Clarify-if-ambiguous → implement (one agent, file allowlist) → verify fresh → print the Area/Change summary table. Fall back to full hackify the moment the task grows past the carve-out.
