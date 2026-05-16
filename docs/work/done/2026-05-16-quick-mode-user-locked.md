---
slug: quick-mode-user-locked
title: Quick mode — user-locked, no auto-fallback
status: done
type: refactor
created: 2026-05-16
project: hackify
current_task: shipped
worktree: (none)
branch: main
sprint_goal: Strip the 4 auto-fallback triggers from quick mode so explicit `/hackify:quick` locks the mode until the user explicitly promotes to full hackify.
---

## Original Ask

> I am still getting routed by the ai to full mode even if I enforced my choice by using /quick mode. It shouldn't happen until I tell him to do. Quick mode if I want to tackle any task at once without using boring routine of creating work-doc and I expect that I can't resume my work if I ended the session and closed the chat. I prefer full mode if I am working on a big task/module/milestone that I am planning to work on it multiple days or weeks so the document will give me the privilege to track my progress and control it (pause/resume) as I want.
>
> (Follow-up) When I say /quick it should comply to my order and use quick mode.

## Clarifying Q&A

**Q1 — How should the 4 auto-fallback triggers (attempt≥2, files>3, sensitive path, full-review phrase) behave in quick mode going forward?**
A1 — **Remove all 4 triggers entirely.** Quick mode never auto-falls back. Only an explicit user request (e.g., "switch to full", `/hackify:hackify`) promotes to full mode.

## Acceptance Criteria

- [ ] **AC1.** `skills/quick/SKILL.md` frontmatter description — the sentence "Falls back to full hackify automatically on any of 4 testable signals — …" is removed and replaced with one sentence stating quick mode is user-locked until the user explicitly promotes. The "Do NOT auto-fire on cross-file refactors…" carve-out routing sentence stays (it governs auto-discovery, not runtime).
- [ ] **AC2.** `skills/quick/SKILL.md` body — the "Fallback to full hackify" section (4 trigger bullets) is replaced with a "Promotion to full hackify (user-initiated only)" section that (a) lists the explicit user phrases that trigger a promotion (recommended set: `switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`), and (b) preserves verbatim the existing 4-step write-work-doc-and-handoff procedure body (STOP implementation → write work-doc → re-enter Phase 2 → preserve intent + partial diff in Daily Updates).
- [ ] **AC3.** `skills/quick/SKILL.md` anti-rationalizations table — rows that reference attempt-counter / fall-back triggers are removed; clarify/verify/summary discipline rows stay. One replacement row added explaining quick mode never auto-promotes.
- [ ] **AC4.** `skills/quick/SKILL.md` — every remaining mention of the words "fallback" / "fall back" / "escalate" / "attempt counter" / `wc -l` / `.quick-<slug>.md` is either removed or rewritten to mean user-initiated promotion. `grep -nE "fallback|fall back|escalate|attempt counter|wc -l|\.quick-" skills/quick/SKILL.md` returns only promotion-context matches (or zero).
- [ ] **AC5.** `skills/quick/SKILL.md` MUST-RETAIN tokens for validate-dod checks `[22]` and `[23]`: the strings `Skipped phases`, `Phase 2`, `Phase 2.5`, `Phase 5`, `four-options`, and `Summary table` all remain present in the file body. `grep -c` for each ≥ 1.
- [ ] **AC6.** `skills/quick/SKILL.md` documents the non-resumability expectation explicitly — the body contains a sentence (or table row) stating quick mode does NOT create a work-doc and therefore cannot be paused/resumed; users wanting pause/resume must invoke full hackify. Addresses the user's "I expect I can't resume my work" Original Ask sentence.
- [ ] **AC7.** `skills/hackify/SKILL.md` line 17 — the parenthetical "falls back to full hackify on signal (≥2 failed attempts, >3 files touched, security-sensitive path, user requests Phase 5)" is replaced verbatim with "stays in quick mode until you explicitly switch to full hackify."
- [ ] **AC8.** `README.md` — the lines 95–104 paragraph and table describing the 4 fallback triggers and the on-fallback work-doc handoff are replaced with a "User-initiated promotion to full hackify" subsection. The line 28 callout positive target reads: "a sibling skill `/hackify:quick` runs a compressed four-phase flow that stays in quick mode until you explicitly promote to full hackify."
- [ ] **AC9.** `CHANGELOG.md` — a new `## [0.2.3] - 2026-05-16` entry is added at the top describing the contract change with two subsections: `### Changed` (quick mode is now user-locked; promotion is user-initiated only) and `### Removed` (4 auto-fallback signals, scratch `.quick-<slug>.md` attempt-counter file).
- [ ] **AC10.** `.claude-plugin/plugin.json` — `version` is bumped from `0.2.2` to `0.2.3`.
- [ ] **AC11.** `bash scripts/sync-runtimes.sh` exits 0; `dist/<runtime>/skills/quick/SKILL.md` for all 7 runtimes contains the new wording and matches the canonical source byte-for-byte.
- [ ] **AC12.** `bash scripts/validate-dod.sh` exits 0; checks `[21]`, `[22]`, `[23]` (quick-mode frontmatter, skipped-phase tokens, summary-table token) still pass.

## Approach

**Core change.** Quick mode's runtime-fallback contract is removed entirely. The four signal-based triggers (attempt counter ≥2, diff >3 files, security-sensitive path, full-review phrase) no longer cause an automatic mode switch. The promotion path (write work-doc from accumulated context, hand off to full hackify Phase 2) is preserved — but it only fires when the user types an explicit promotion phrase.

**What stays.** The carve-out routing list ("Do NOT auto-fire on cross-file refactors, redesigns, debug…") in the description stays — that controls auto-discovery (which skill the harness picks when the user doesn't type a slash command), not runtime fallback. Phase 1 clarify-if-ambiguous, Phase 3 one-agent implement, Phase 4 verify-triad, Phase 6F summary-table all stay unchanged.

**What changes.** Frontmatter description loses the fallback sentence and gains a "user-locked" sentence. The body's "Fallback" section is renamed and re-scoped to user-initiated promotion. The anti-rationalizations table loses the trigger-themed rows. README and main hackify SKILL.md update their cross-references. Version bumps to 0.2.3 with a CHANGELOG entry. Runtime-dist files are rebuilt via `scripts/sync-runtimes.sh`.

**Why patch and not minor.** No phase added or removed. No new file. No file removed. Workflow shape is unchanged. Only one contract — runtime fallback — is relaxed. Backwards-compatible for any user who didn't rely on auto-fallback.

### Execution waves

```
Wave 1 (parallel — five independent files, no collision edges)
  T1 — skills/quick/SKILL.md (frontmatter + body + anti-rationalizations)
  T2 — skills/hackify/SKILL.md (line 17 cross-reference)
  T3 — README.md (lines 28, 95–104)
  T4 — .claude-plugin/plugin.json (version bump)
  T5 — CHANGELOG.md (new entry at top)

Wave 2 (serial — reads canonical sources)
  T6 — bash scripts/sync-runtimes.sh   (rebuilds dist/ for all 7 runtimes)
       Prerequisite scope: sync-runtimes.sh mirrors skills/ + commands/ + .claude-plugin/ only.
       T6 therefore strictly depends on T1 + T2 + T4. T3 (README.md) and T5 (CHANGELOG.md)
       are doc-only and NOT consumed by sync-runtimes.sh — if Wave 1 partial-fails on T3/T5,
       T6 can still proceed safely.

Wave 3 (serial — depends on Wave 2)
  T7 — bash scripts/validate-dod.sh    (must exit 0; transitively depends on T1+T2 for AC12)
```

## Sprint Backlog

- [x] **T1 — Edit `skills/quick/SKILL.md`** — Update frontmatter description (line 3) to remove the "Falls back…" sentence and add a "User-locked mode" sentence. Replace the body's "Fallback to full hackify" section (lines ~40–47) with a "Promotion to full hackify (user-initiated only)" section listing explicit promotion phrases (`switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`). Rename "Fallback procedure" section (lines ~49–51) to "Promotion procedure" — KEEP the 4-step body verbatim (STOP → write work-doc → re-enter Phase 2 → preserve intent + partial diff in Daily Updates); only gate it on explicit user phrases. Remove the two anti-rationalization rows about fallback/attempt-counter; add one row stating quick mode never auto-promotes. Update incidental phrases ("Spread = fallback fires", "User can force it via the fallback trigger", "If fallback fired", line 8 "fallback re-enters full hackify by name", line 33 "User can force it via the fallback trigger") to match the new contract. Add a one-sentence non-resumability note (satisfies AC6). MUST-RETAIN strings: `Skipped phases`, `Phase 2`, `Phase 2.5`, `Phase 5`, `four-options`, `Summary table` (satisfies AC5). Files: `skills/quick/SKILL.md`. Test mode: manual smoke (markdown content review + grep check for AC4 + AC5 tokens).
- [x] **T2 — Edit `skills/hackify/SKILL.md` line 17**. Replace VERBATIM "falls back to full hackify on signal (≥2 failed attempts, >3 files touched, security-sensitive path, user requests Phase 5)" with VERBATIM "stays in quick mode until you explicitly switch to full hackify." (satisfies AC7). Files: `skills/hackify/SKILL.md`. Test mode: manual smoke.
- [x] **T3 — Edit `README.md`** — Replace line 28 callout VERBATIM with: "For small fixes and single-file edits, a sibling skill `/hackify:quick` runs a compressed four-phase flow that stays in quick mode until you explicitly promote to full hackify." Replace lines 95–104 paragraph and 4-row trigger list with a "User-initiated promotion to full hackify" subsection listing the explicit promotion phrases and the write-work-doc-then-hand-off procedure (satisfies AC8). Files: `README.md`. Test mode: manual smoke.
- [x] **T4 — Bump version in `.claude-plugin/plugin.json`** from `0.2.2` to `0.2.3`. Files: `.claude-plugin/plugin.json`. Test mode: manual smoke (JSON validity is checked by validate-dod.sh).
- [x] **T5 — Append CHANGELOG.md entry** — Insert a `## [0.2.3] - 2026-05-16` block at the top of the file (after the header). Two subsections: `### Changed` (quick mode is now user-locked; promotion is user-initiated only) and `### Removed` (4 auto-fallback signals, scratch `.quick-<slug>.md` attempt-counter file). Files: `CHANGELOG.md`. Test mode: manual smoke.
- [ ] **T6 — Run `bash scripts/sync-runtimes.sh`** — Rebuild `dist/<runtime>/skills/quick/SKILL.md` and `dist/<runtime>/skills/hackify/SKILL.md` for all 7 runtimes from canonical. Confirm exit 0 and that the new wording appears in at least the `dist/claude-code/` copy. Files: `dist/` (auto-generated). Test mode: shell command, exit-code check + spot-grep.
- [ ] **T7 — Run `bash scripts/validate-dod.sh`** — Confirm exit 0, no FAIL lines. Specifically check that `[21]`, `[22]`, `[23]` (quick-mode skill frontmatter, skipped-phase tokens, summary-table token) still pass — the new wording must preserve "Skipped phases", `Phase 2`, `Phase 2.5`, `Phase 5`, `four-options`, `Summary table`. Files: none modified. Test mode: shell command, exit-code check.

## Daily Updates

### 2026-05-16 — Wave 1 (parallel canonical edits)

- **T1 `skills/quick/SKILL.md`** — DONE. Frontmatter description replaced; body "Fallback to full hackify" section renamed to "Promotion to full hackify (user-initiated only)" with 5 explicit promotion phrases; "Fallback procedure" renamed to "Promotion procedure" with 4-step body preserved verbatim; 3 anti-rationalization rows removed and 1 replacement row added; incidental phrases on lines 8, 23, 33, 38, 74, 89 rewritten to user-initiated promotion semantics. Non-resumability sentence added to frontmatter description. Grep verification — MUST-RETAIN tokens (`Skipped phases`, `Phase 2`, `Phase 2.5`, `Phase 5`, `four-options`, `Summary table`) all ≥1. MUST-NOT-RETAIN tokens — `fallback`/`fall back`/`attempt counter`/`wc -l`/`.quick-` return zero; one allowed reference to `attempt-counter` (with hyphen) remains in a negation clause inside the new Promotion section ("No diff-size, file-count, attempt-counter, or path-pattern check ever auto-promotes") which satisfies AC4's "rewritten to mean user-initiated promotion" allowance.
- **T1 follow-up patch (parent inline)** — T1 agent flagged that the "When NOT to use quick mode" table (rows 62, 65) still referenced removed triggers verbatim (">3-file trigger fires", "Security-sensitive trigger fires immediately"). Parent applied a 2-row in-place rewording so the routing-guidance cells describe the destination phase, not the removed trigger.
- **T2 `skills/hackify/SKILL.md`** — DONE. Line 17 cross-reference replaced verbatim.
- **T3 `README.md`** — DONE. Line 28 callout and lines 95–104 fallback-trigger paragraph replaced with `### User-initiated promotion to full hackify` subsection. Grep verification all 4 checks pass.
- **T4 `.claude-plugin/plugin.json`** — DONE. `version` field `0.2.2` → `0.2.3`. `jq -e '.version == "0.2.3"'` exit 0; `jq -e .` exit 0.
- **T5 `CHANGELOG.md`** — DONE. New `## [0.2.3] - 2026-05-16` entry inserted at line 8, above existing `## [0.2.2]` block at line 29. Three subsections present: `### Changed` (line 12), `### Removed` (line 19), `### Rationale` (line 25).

Wave-end commit deferred to Wave 3 (after validate-dod.sh confirms 0 failures). Advancing to Wave 2.

## Sprint Review

- **Phase 2.5 spec self-review** — 3 reviewers, all returned APPROVED-WITH-PATCHES. Patches applied to work-doc before Phase 3 (AC list grew from 9 → 12, pinned validate-dod MUST-RETAIN tokens, annotated T6 prerequisite scope).
- **Phase 3 implementation** — 5 parallel wave-task agents in one message; all 5 returned DONE with file allowlists respected. T1 sub-agent flagged "When NOT to use quick mode" table inconsistency as out-of-scope follow-up; parent applied a 2-row in-place patch.
- **Phase 4 verify** — `bash scripts/validate-dod.sh` first run failed on plugin/marketplace version parity. Patched `.claude-plugin/marketplace.json` 0.2.2 → 0.2.3, re-synced runtimes, re-validated. ALL CHECKS PASSED.
- **Phase 5 multi-reviewer** — 3 parallel reviewers (security / quality / plan-consistency); all APPROVED. AC1–AC12 fully mapped to diff hunks. No Critical or Important findings.
- **Phase 6** — user chose option 1 + push. Single commit on main, push to origin, work-doc archived.

## Retrospective

- **What surprised.** validate-dod.sh enforces version parity across `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json`. The original T4 task description only named plugin.json; the parity check caught the gap at Phase 4. Future version-bump work-docs should name both files explicitly in the AC list.
- **What surprised — frontmatter description budget.** Phase 5 Security reviewer flagged the new `skills/quick/SKILL.md` frontmatter description at ~1,150 chars exceeds the harness's ≤1,024-char sweet-spot for auto-discovery. Not blocking, but a hygiene note: if quick mode's auto-discovery match quality degrades, tighten the frontmatter description.
- **Declined finding (Phase 2.5 Rules reviewer).** Suggested adding an in-quick-mode "refuse-and-ask before proceeding when an auth/crypto/migration path is detected" advisory. Declined — the user explicitly chose "Remove all 4 triggers entirely", which includes no runtime advisory. The carve-out routing table in the skill description ("Do NOT auto-fire on cross-file refactors, redesigns, debug…") and the "When NOT to use quick mode" table both stay; they govern auto-discovery, not runtime fallback.
- **Minor stylistic notes (Phase 5).** CHANGELOG header uses ` - ` while `0.2.2` used ` — ` (em dash); promotion-phrase list in README/CHANGELOG is a subset of the SKILL list (canonical phrases vs full alias set). Both intentional doc-shape choices; not patched.
- **Memory note — demo GIF.** `MEMORY.md` says refresh `docs/assets/hackify-demo.gif` when phases/version/install commands change. Phases and install commands did NOT change in this release. Version bumped 0.2.2 → 0.2.3. The GIF demonstrates the full 6-phase workflow, not quick mode; no visible change in this release's content. Flagging for future consideration but not refreshing in this commit.
- **What to remember.** When a skill description embeds multiple separable contracts (auto-discovery routing AND runtime fallback), separating them in the description body — not just the rules section — would have made the user's mental model align with the runtime behavior from the start.

## Summary of changes shipped

| Area | Change |
|---|---|
| `Quick mode contract` | Quick mode is now user-locked. Once invoked, it stays in quick mode for the entire task. |
| `Runtime fallback removed` | Removed 4 auto-fallback signals (`attempt counter`, `wc -l > 3`, `*auth*/*crypto*/*migration*` path glob, full-review phrase scan). |
| `Promotion path` | Renamed "Fallback to full hackify" → "Promotion to full hackify (user-initiated only)"; 4-step write-work-doc-and-handoff procedure preserved verbatim. |
| `Explicit promotion phrases` | New trigger surface: `switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`, `do full review`, `run Phase 5`, `run multi-reviewer` (case-insensitive, most recent message only). |
| `Skill frontmatter` | Replaced "Falls back to full hackify automatically…" sentence with a "User-locked mode" sentence; added non-resumability note. |
| `Anti-rationalizations` | Removed 3 rows referencing attempt-counter / file-count / auth-path triggers; added 1 row stating quick mode never auto-promotes. |
| `Auto-discovery routing` | Unchanged. "Do NOT auto-fire on cross-file refactors / redesigns / debug…" carve-out preserved — governs which skill the harness picks, not the runtime fallback. |
| `Cross-references` | `skills/hackify/SKILL.md` line 17 and `README.md` lines 28 + 95–104 updated to match the new contract. |
| `Version bump` | `0.2.2` → `0.2.3` in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` (parity enforced by validate-dod.sh check `[11]`). |
| `CHANGELOG` | New `## [0.2.3] - 2026-05-16` entry with `Changed`, `Removed`, and `Rationale` subsections. |
| `Runtime distribution` | `scripts/sync-runtimes.sh` re-ran successfully; 132 files mirrored across 7 runtimes (`claude-code`, `codex-cli`, `codex-app`, `gemini-cli`, `opencode`, `cursor`, `copilot-cli`). |
| `Validation` | `scripts/validate-dod.sh` exits 0; all 33 check groups pass including `[21]`/`[22]`/`[23]` quick-mode token retention. |
