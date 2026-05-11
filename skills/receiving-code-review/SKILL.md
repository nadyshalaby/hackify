---
name: receiving-code-review
description: Structured response engine for reviewer findings — converts a batch of comments into a per-finding decision table with columns Finding / Severity / Decision / Evidence. Two trigger surfaces. First, Phase 5 internal — the full hackify multi-reviewer dispatch returns parallel security/quality/plan-consistency findings and this skill produces the response table before the parent acts on them. Second, external paste — the user pastes review feedback from GitHub PR comments, Slack quotes, or email, and asks the model to respond. Each row picks exactly one of `accept` / `push-back` / `defer`. Push-back REQUIRES technical evidence with file:line, prior commit, or established pattern. Critical findings cannot be pushed back without explicit Phase 5 escalation. Use this skill when the user types `/receiving-code-review`, says "respond to the review", "respond to PR feedback", "respond to reviewer comments", or "address review findings", or when Phase 5 multi-reviewer has just returned and the parent must decide what to fix.
---

# Receiving-Code-Review — structured response to reviewer findings

This skill converts a batch of reviewer comments into a per-finding response table. Every comment becomes one row. Every row carries a Decision (`accept` / `push-back` / `defer`) and Evidence anchored in code, not opinion.

The skill is fully self-contained. It does not call other skills.

## When to invoke

Two trigger paths, both end in the same output table.

**Path A — Phase 5 internal.** Triggered automatically inside the full hackify workflow once the Phase 5 parallel-reviewer dispatch returns. The parent has just received the three reviewer reports (security & correctness, quality & layering, plan consistency & scope). Before the parent decides what to fix, what to push back on, and what to defer to the Retrospective, this skill produces the structured per-finding response. The Critical / Important / Minor severity tags from the reviewers are mirrored into the table's Severity column verbatim.

**Path B — External paste.** Triggered when the user pastes external review feedback into chat and asks for a response. Detection rule — the most recent user message contains a review-shaped paste, where a paste is review-shaped if it has multiple bullet or numbered items AND each item has either a `file:line` anchor OR a normative verb (`should`, `must`, `consider`, `recommend`, `prefer`, `avoid`). Common sources — GitHub PR comments, Slack quotes, email review, reviewer DM.

**Auto-discovery triggers.** Invoke this skill when the user types `/receiving-code-review`, says "respond to the review", "respond to PR feedback", "respond to reviewer comments", "address review findings", or pastes review-shaped feedback and asks for a response.

**Carve-out (skill optional).** A single-comment review with one obvious fix is fine to handle inline without the table. The table is mandatory when there are 2+ findings.

## The output table

The deliverable is a single 4-column markdown table. One row per finding — never collapse two findings into one row even if their wording overlaps.

| Column | Spec |
|---|---|
| Finding | Concise restatement of the reviewer's concern, ≤25 words. Include the `file:line` anchor when the reviewer provided one. Do not paraphrase severity tags into this cell — they go in the next column. |
| Severity | Exactly one of `Critical` / `Important` / `Minor`. Mirror the reviewer's tag verbatim when they tagged. Otherwise infer per the Severity rubric below. |
| Decision | Exactly one of `accept` / `push-back` / `defer`. No other strings. Lowercase, hyphen in `push-back`. |
| Evidence | For `accept` — the commit-shaped one-liner of what the fix will be (`fix: validate token expiry in auth.service.ts:142`). For `push-back` — 1–3 sentences with file:line citations, prior-commit SHA, or referenced precedent. For `defer` — the follow-up issue/ticket reference, or the literal string "follow-up entry queued in Retrospective." |

Rows are ordered by Severity (Critical first, then Important, then Minor), then by file path within a severity band.

## Severity rubric

When the reviewer tagged severity, mirror their tag. When they did not, infer using these anchored rules.

**Critical.** Security defect (auth bypass, injection vector, secret leak, broken access control), correctness bug (data corruption, wrong write path, broken concurrency invariant), layering violation (HTTP framework imports in services, controller running business logic), lint suppression introduced (`biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error` outside the test-file carve-out), test broken or skipped, migration not idempotent, public API contract changed without callers updated.

**Important.** Quality and maintenance concerns that degrade the codebase without shipping broken — DRY violation (duplicated logic ≥3 lines, helper exists but was inlined), unclear naming (variables named for what they ARE not what they DO), inline object type with 2+ properties in a route/service/middleware module, missing edge case (null/undefined/empty array/concurrent access path), bare `Error` throw in domain code, function exceeds 40 LOC, file exceeds 500 LOC, `!` non-null assertion in production code, dead code (unused export, orphan import).

**Minor.** Editorial issues that do not change behavior — style nit, comment wording, whitespace, optional refactor, naming preference where the codebase has no established convention, missing JSDoc.

When the inference is ambiguous between two bands, pick the stricter (higher) one. A finding the reviewer left untagged but described as "could leak" or "race condition" lands in Critical.

## Decision rules

Every row picks exactly one of three Decisions. The semantics are not interchangeable.

**`accept` — the reviewer is right and this PR will fix it.** Use when the codebase confirms the reviewer's claim and the fix fits the current scope. Evidence column carries the commit-shaped one-liner of the fix (verb in imperative, file:line anchor when applicable). The fix lands before Phase 6.

**`push-back` — the reviewer is wrong for THIS codebase.** Use when the codebase contradicts the reviewer's claim, when the suggestion violates YAGNI (no real consumers), when a prior architecture decision in CLAUDE.md contradicts the suggestion, when the suggestion is technically wrong for this stack/version, or when legacy or constraints the reviewer cannot see make the suggestion harmful. Evidence column is 1–3 sentences leading with the technical reason, anchored to a file:line citation, prior commit SHA, or referenced precedent. Bare "I disagree" is banned. Performative agreement masquerading as a push-back (saying push-back then accepting anyway) is banned. The push-back response pattern follows `references/review-and-verify.md` — lead with technical reason, not disagreement.

**`defer` — the concern is valid but out of scope for this PR.** Use when the finding is real but fixing it would widen scope past the work-doc Acceptance Criteria, or when the finding belongs to a separate change-set with its own gate. Evidence column carries the follow-up issue/ticket reference (`#1234`, `JIRA-456`) or the literal string "follow-up entry queued in Retrospective." Defer is not an escape hatch for cheap fixes — see Anti-rationalizations.

**Critical-finding guardrail.** Critical findings MUST resolve to `accept` or `defer-with-user-signoff`. A bare `push-back` on a Critical row is forbidden — the cost of a missed Critical (shipped security defect, lost data, broken release) is too high to gate behind a single agent's judgment. When a Critical finding looks wrong, the response is to escalate via a Phase 5 adjudication reviewer (`references/review-and-verify.md` "Reviewer subagent prompt template") and surface the conflict to the user, NOT to push back unilaterally. The escalation paragraph runs adjacent to the table, citing the Critical row by ID and stating the rebuttal evidence; the user signs off before the row's Decision flips to `push-back`.

**Evidence is non-optional.** Every `push-back` row carries technical evidence. Every `accept` row carries the fix one-liner. Every `defer` row carries the follow-up reference. A row with empty Evidence is incomplete and blocks the table from being presented.

## Worked example

Reviewer findings batch (from a Phase 5 multi-reviewer dispatch on a small auth-token refactor):

1. Reviewer A: `src/auth/token.service.ts:67` — token expiry check uses `Date.now()` directly; should inject a clock for testability.
2. Reviewer A: `src/auth/token.service.ts:142` — refresh-token rotation path does not invalidate the old token before issuing the new one. Critical.
3. Reviewer B: `src/auth/types.ts:8` — inline object type `{ userId: string; exp: number }` on the `TokenPayload` field; extract to a named interface.
4. Reviewer B: `src/auth/token.service.ts` — file is 480 LOC, close to the 500-LOC cap; consider splitting now.
5. Reviewer C: work-doc DoD bullet D3 (CSRF cookie rotation) has no corresponding diff hunk.

Response table:

| Finding | Severity | Decision | Evidence |
|---|---|---|---|
| Refresh-token rotation at `token.service.ts:142` does not invalidate old token before issuing new one | Critical | accept | `fix: invalidate prior refresh token before rotation in token.service.ts:142` — adds `await this.repo.revoke(oldToken.id)` before `issue(newToken)`. |
| Work-doc DoD bullet D3 (CSRF cookie rotation) has no corresponding diff hunk | Critical | accept | `feat: rotate CSRF cookie on token refresh per D3` — adds rotation call in `token.controller.ts:88`; covered by `csrf-rotation.test.ts`. |
| Inline object type `{ userId; exp }` on `TokenPayload` at `types.ts:8`; extract to named interface | Important | accept | `refactor: extract TokenPayload to named interface in auth/interfaces/token-payload.ts` — per code-rules §1.2. |
| Token expiry check at `token.service.ts:67` uses `Date.now()` directly; inject a clock for testability | Important | push-back | No clock abstraction exists in this codebase — grep `src/` for `Clock` returns zero hits. Adding one for a single call-site is YAGNI; existing tests stub `Date.now` via `vi.useFakeTimers()` at `token.service.test.ts:12`, which already covers the testability concern. |
| `token.service.ts` is 480 LOC, near the 500-LOC cap; consider splitting now | Minor | defer | follow-up entry queued in Retrospective — split planned when refresh-token-revocation feature lands (adds ~80 LOC, will trip the cap). |

The table is what gets presented. Critical rows resolve `accept`; the Important push-back row leads with the technical reason (no Clock abstraction, existing fake-timer coverage); the Minor row defers cheaply via a Retrospective entry rather than landing a split that would conflict with planned upcoming work.

## Anti-rationalizations

These thoughts mean STOP and apply the listed reality.

| Thought | Reality |
|---|---|
| "All Critical findings should be accepted — they're Critical for a reason" | Not if the reviewer misread the codebase. Push-back is allowed on a Critical, but only via the Phase 5 adjudication-reviewer escalation path with user sign-off — never as a unilateral row flip. The cost of a missed real Critical is higher than the cost of a one-round escalation. |
| "Minor findings can all be deferred" | No. Cheap fixes (≤5 minutes, single-file edit, no test changes) land as `accept` now. Deferring cheap fixes is sloppiness disguised as scope discipline — the Retrospective becomes a graveyard of one-line edits nobody comes back to. `defer` is for concerns that genuinely belong to a separate change-set. |
| "I'll just say `accept` to be agreeable" | Performative agreement is banned. If you would push back in a real review, push back here with evidence. The point of the table is honest engagement with each finding — silent capitulation produces broken code dressed up as a clean review. |
| "Two findings are basically the same, I'll merge rows" | Never collapse. Each reviewer comment is owed a per-finding response, even when wording overlaps — the reviewer wrote two comments because they meant two distinct concerns, and the response table is how they verify both landed. Collapsing rows hides which concern got which Decision. |
| "The reviewer didn't tag severity so I'll skip the column" | The Severity column is mandatory on every row. When the reviewer did not tag, infer per the Severity rubric and pick the stricter band on tie. |
| "Evidence is overkill for an accept row" | The Evidence cell on an `accept` row is the commit-shaped fix one-liner. It is what the user reads to verify the fix actually addresses the finding before the row gets implemented. Empty Evidence on `accept` means the fix is undefined and the row blocks implementation. |
| "Push-back without a file:line is fine if the reasoning is good" | No. Every push-back row carries a file:line citation, prior commit SHA, or referenced precedent. Reasoning without an anchor is opinion — the codebase is the source of truth. |

## File map

```
SKILL.md                                ← this file (the response-table engine)
```

This skill has no `references/` directory. Cross-references point into the main hackify skill — `skills/hackify/references/review-and-verify.md` for the pushback response pattern and the escalation reviewer template, `skills/hackify/references/parallel-agents.md` for the Phase 5 multi-reviewer dispatch templates that feed this skill on Path A.

## One-line summary

Every reviewer comment becomes one row — `accept` with a fix one-liner, `push-back` with technical evidence and a file:line citation, or `defer` with a follow-up reference. Critical findings never push back without Phase 5 escalation and user sign-off.
