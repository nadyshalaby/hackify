---
name: quick
description: Compressed-flow companion to the hackify workflow for genuinely small tasks where full ceremony (Plan+Gate, Spec review, Multi-reviewer, 4-options finish) would burn more wall-clock and tokens than the change is worth. Auto-discovery triggers — invoke this skill when the user says any of "quick fix", "small change", "just fix the", "one-line fix", "tiny edit", "small fix", "small bug", "quick patch", "minor tweak", "just rename", "fix typo", or the explicit slash form /hackify:quick. Workflow shape — Phase 1 (clarify ONLY if ambiguous; zero questions otherwise) → Phase 3 (implement; single foreground agent OR inline edit; file allowlist still applies) → Phase 4 (verify; full test + lint + typecheck triad still mandatory) → Phase 6 Step F (mandatory 2-column Area/Change summary table, printed to chat). Do NOT auto-fire on cross-file refactors, redesigns, debug investigations of unknown root causes, or anything touching auth/crypto/migration/secret/token/password — those route to full hackify via its own description. User-locked mode — once invoked, quick mode stays in quick mode for the entire task. It only promotes to full hackify when the user explicitly says so (e.g., "switch to full", "promote to full", "/hackify:hackify"). No work-doc is created, so progress cannot be paused or resumed across sessions — invoke full hackify if you need pause/resume.
---

# Hackify Quick — Compressed Flow For Small Tasks

Sibling to the main hackify skill. Same end-to-end discipline (clarify → implement → verify → summary), ceremony stripped. Fully self-contained — **never call other skills**; explicit user-initiated promotion re-enters full hackify by name. Target: ~one-third the tokens/wall-clock of full hackify.

## Workflow shape

```
Phase 1 (clarify if ambiguous) → Phase 3 (implement) → Phase 4 (verify) → Phase 6F (summary table)
```

No Plan+Gate. No Spec self-review. No Multi-reviewer. No four-options finish menu. The summary table is the only mandatory artifact; print to chat.

## Kept phases

| Phase | Action | Rationale |
|---|---|---|
| **1 — Clarify** | Run the wizard at `skills/hackify/references/clarify-questions.md` if the ask has any ambiguity. **If the ask names a file or symbol but not a fix, read it end-to-end before judging ambiguity.** Zero ambiguity ("fix typo on line 42 of README.md") → zero questions, go to Phase 3. | A misread ask costs more than a one-question wizard. |
| **3 — Implement** | Dispatch at most ONE foreground subagent with a file allowlist, or write inline for 1–3-line single-file edits. File-allowlist constraint applies — agent touches declared files only. | Scope discipline keeps quick mode quick. Spread is your call — promote to full hackify if the task outgrows the carve-out. |
| **4 — Verify** | Run the project's full triad (test + lint + typecheck) fresh. Paste output. Zero failures, zero errors. | Skipping verify is how typo fixes ship broken. |
| **6F — Summary table** | Generate the 2-column Area/Change table per `skills/hackify/references/finish.md` and print to chat. | The user opted into speed, not opacity. |

## Skipped phases — exactly these four, no others

| Phase | Rationale |
|---|---|
| **Phase 2 — Plan+Gate** | The ask itself is the plan. Tasks needing a written plan are too large for quick mode. |
| **Phase 2.5 — Spec self-review** | No spec was written in Phase 2 — nothing to scrutinize. |
| **Phase 5 — Multi-reviewer code review** | Single-file diffs do not justify three parallel review lenses. User can promote to full hackify explicitly to get multi-reviewer. |
| **Phase 6 — four-options finish menu** | Quick mode does in-place edits. The user lands via their normal git workflow. Step F is the only Phase 6 piece kept. |

## Note — Debug-when-stuck is not skipped

**Phase 3b is NOT skipped — if a debug investigation is needed, promote to full hackify (say "promote to full") and the 4-phase root-cause hunt runs there under its own discipline.** Quick mode itself does not run Phase 3b; the promotion path preserves the in-progress diff in the new work-doc's Daily Updates.

## Promotion to full hackify (user-initiated only)

Quick mode never auto-promotes. The user explicitly triggers promotion by saying any of these phrases (case-insensitive, scanned in the most recent user message only):

- `switch to full` / `switch to full mode`
- `go to full mode` / `go to full hackify`
- `promote to full` / `promote this to full`
- `/hackify:hackify` (slash command)
- `do full review` / `run Phase 5` / `run multi-reviewer` (explicit review request — promotes so Phase 5 can run)

No diff-size, file-count, attempt-counter, or path-pattern check ever auto-promotes. If the user is silent, quick mode stays in quick mode for the whole task — even if the diff grows large or touches sensitive paths. That is the user's stated preference.

## Promotion procedure

On user-initiated promotion: (1) STOP implementation; (2) write a work-doc from accumulated context at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` (template at `skills/hackify/references/work-doc-template.md`); (3) re-enter full hackify Phase 2 (Plan+Gate); (4) preserve intent + clarify-answers + any partial diff in the Daily Updates section. Set frontmatter `current_task: (promoted from quick mode — awaiting gate)`. Do not silently re-dispatch implementation agents.

## When NOT to use quick mode

Route these to full hackify (`/hackify:hackify`) from the start.

| Shape | Why |
|---|---|
| Cross-file refactors | Quick mode targets ≤3 files; larger spread wants Plan+Gate. |
| Redesigns | Plan+Gate is required for sign-off on the new shape. |
| Debug investigations of unknown root causes | Phase 3b's 4-phase root-cause hunt is needed from the jump. |
| Touches auth/crypto/migrations/secrets/tokens/passwords | Security-sensitive surface deserves Phase 5 multi-reviewer. |
| Cross-team review needs | Phase 5 multi-reviewer anchors the review conversation. |
| Cannot list touched files up-front | Task is too underspecified for a file allowlist. |

## Summary table — mandatory

End every task with a 2-column markdown table (`Area` | `Change`). Authoring rules per full hackify's Phase 6 Step F (see `skills/hackify/references/finish.md`):

- **Area** — 1–4 word concept/theme label. NOT a file path. NOT a DoD ID.
- **Change** — ≤25 words, present-tense action verb, backticks for code spans.
- 5–12 rows per task (quick mode typically 1–5).

Print to chat. If the user promoted to full hackify mid-task, append the table to the new work-doc's Retrospective under `## Summary of changes shipped`. For on-demand invocation, see `commands/summary.md` (`/hackify:summary`).

## Anti-rationalizations — STOP and apply the listed reality

| Thought | Reality |
|---|---|
| "I can skip Phase 4 verify, it is just a typo" | Phase 4 stays. Typo fixes still need lint + typecheck to pass. The verification triad is the cheapest insurance in the workflow. |
| "User said 'quick' so we skip Phase 1 clarify" | Only skip clarify if there is zero ambiguity in the ask. If even one detail is unclear, run the wizard — one batched question is cheaper than a wrong implementation. |
| "Summary table is overkill for a one-line fix" | The summary table is mandatory. One row is fine. The user always knows what landed. |
| "This task is getting bigger than I thought — let me silently switch to full mode for the user" | Quick mode never auto-promotes. The user explicitly opted into quick mode. Stay in quick mode until the user says "switch to full" or one of the documented promotion phrases. |

## One-line summary

Clarify-if-ambiguous → implement (one agent, file allowlist) → verify fresh → print the Area/Change summary table. Stays in quick mode until the user explicitly promotes to full hackify.
