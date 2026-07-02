---
slug: 2026-07-02-verify-evidence-and-b2-voice
title: Evidence-Ledger verify + 3-layer re-verify + plain report + B2 voice (0.6.1)
status: done
shipped: 2026-07-02
shipped_via: merge
type: feature
created: 2026-07-02
project: hackify
related: []
current_task: null
worktree: null
branch: feat/verify-evidence-b2-voice-0-6-1
sprint_goal: |
  Make Phase 4 prove every task/requirement with a real trimmed evidence sample, add a
  three-layer re-verify that traces proofs to the goal anchor, make the final report
  readable by non-technical people, and set a B2 "communication voice" for chat — shipped as 0.6.1.
---

# Evidence-Ledger verify + 3-layer re-verify + plain report + B2 voice (0.6.1)

## 1. Original ask

> I want to tweek the verification step to work in away:
> - assess all tasks, fixes, or requirements are landed properly as expected with real evidence and sample of the proof.
> - the final report should comprehensive and commulative and easy to understand by normal persons
> - we may run different version or the verification to prove that you nailed it without drifting away from the main goal
>
> I want also to change the chat tone or level of English to intermediate level or B2 so non English native people can easily follow up with you and make the thread self explanatory to easliy get what you are doing and why

## Primary Goal & Guardrails

- **North-Star Goal.** Phase 4 (Verify) proves every task and requirement landed with real, trimmed proof; a 3-layer re-verify re-earns that proof and traces it to the goal anchor; the final report is readable by non-technical people; and hackify chat uses a B2 (intermediate) self-explanatory voice — all shipped as `0.6.1` with `validate-dod.sh` green.
- **In-Scope.**
  - New `references/communication-voice.md` (B2 + self-explanatory doctrine) wired into `SKILL.md`.
  - Phase 4 rewrite: Evidence Ledger (per-item proof) + three-layer re-verify (fresh triad / goal-drift / independent re-prove).
  - Work-doc template + HTML report gain the ledger and a plain-language summary + cumulative evidence appendix.
  - `quick` (lite ledger, Layers 1–2) + `yolo` (full ledger, all 3 layers) reconciled to the shared references.
  - Release plumbing → `0.6.1`; `dist/` re-synced; a global memory records the B2 voice.
- **Out-of-Scope / Non-Goals.**
  - No change to the phase list (1–6) or the phase names.
  - No new code-quality rules; no edits to `~/.claude/CLAUDE.md`.
  - No demo-GIF regeneration (phase structure unchanged).
  - No commit/push unless the user picks it in Phase 6.
- **Guardrails / Invariants.**
  - Every touched file ≤500 LOC; README ≤450 LOC.
  - DRY: ledger + 3-layer spec live ONCE in `references/review-and-verify.md`; skills point to it.
  - HTML report stays self-contained (inline CSS + inline SVG, zero network deps).
  - `bash scripts/validate-dod.sh` ends `ALL CHECKS PASSED` (exit 0); `sync-runtimes.sh` idempotent.
  - The B2 voice governs chat prose ONLY — code, commands, identifiers, commit messages stay exact.
- **Success Signals.**
  - `validate-dod.sh` exit 0, all checks green (incl. version 0.6.1 consistency + mirror-completeness + file-size cap).
  - New `communication-voice.md` present and listed in `MIRROR_SOURCES` + mirrored to every runtime under `dist/`.
  - Phase 4 in `SKILL.md` + `review-and-verify.md` shows the Evidence Ledger and the three named layers.
  - `report-template.html` renders a "What changed & why it matters" block and an evidence appendix.

## 3. Acceptance Criteria

- [x] Phase 4 requires a per-item Evidence Ledger (every task + every acceptance bullet, with a real trimmed proof sample).
- [x] Phase 4 defines three named re-verify layers; Layer 2 traces proofs to the goal anchor's Success Signals.
- [x] HTML report gains a plain-language top summary + a cumulative evidence appendix (still self-contained).
- [x] `references/communication-voice.md` exists, is wired into `SKILL.md`, and is in `MIRROR_SOURCES`.
- [x] A global memory records the B2 voice preference.
- [x] Version is `0.6.1` everywhere; `dist/` re-synced; `validate-dod.sh` green.

## 4. Approach

**Chosen.** Put the deep spec in the shared references (`review-and-verify.md`, `work-doc-template.md`, `html-report.md`, `report-template.html`, `goal-anchor.md`, `finish.md`) so `hackify`/`quick`/`yolo` inherit it by pointer (DRY). Add one dedicated `communication-voice.md` and wire it into `SKILL.md`. Reconcile only the one-line Phase-4 rows in `quick`/`yolo`. Bump to `0.6.1`, register the new file in `MIRROR_SOURCES`, re-sync `dist/`, and gate on `validate-dod.sh`.

**Architectural touchpoints.** `skills/hackify/SKILL.md`, `skills/hackify/references/{communication-voice.md(new),review-and-verify.md,goal-anchor.md,work-doc-template.md,html-report.md,finish.md}`, `skills/hackify/assets/report-template.html`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`, `scripts/sync-runtimes.d/00-helpers.sh`, `.claude-plugin/{plugin.json,marketplace.json}`, `README.md`, `CHANGELOG.md`, `dist/**`.

## 5. Sprint Backlog

- [x] **W1** — content refs: create `communication-voice.md`; rewrite Phase 4 in `review-and-verify.md` (ledger + 3 layers); `goal-anchor.md` Layer-2 note; `work-doc-template.md` ledger; `html-report.md` + `report-template.html` plain summary + appendix; `finish.md` Step F note.
- [x] **W2** — SKILL.md: `hackify` (Phase 4 + voice section + file map), `quick` (lite ledger + Layers 1–2), `yolo` (full ledger + 3 layers).
- [x] **W3** — plumbing: `MIRROR_SOURCES` += new file; version → `0.6.1` (`plugin.json`, `marketplace.json` ×2 + `source.ref`, README badge + "New in 0.6.1"); `CHANGELOG.md`; run `sync-runtimes.sh`.
- [x] **W4** — memory (B2 voice) + `MEMORY.md` index.
- [x] **W5** — verify: `validate-dod.sh` green; self-review; Phase 6 finish options.

## 6. Daily Updates

### W1–W4 — done 2026-07-02

- **Test mode:** manual smoke + `validate-dod.sh` (docs/plugin repo — no unit runner; the validator IS the triad).
- **Notes:** Deep spec lives once in `review-and-verify.md` (DRY); skills point to it. `dist/` is git-ignored build output — sync writes it locally, not committed. Chose to replace the README "New in" block (established pattern) rather than stack versions.
- **Self-review:** ✓ DRY  ✓ file-size caps (all ≤500)  ✓ HTML self-contained (0 external refs)  ✓ no scope creep  ✓ version consistent

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4)

| Item | Type | Claim | What I ran | Proof sample | Result |
|---|---|---|---|---|---|
| W5 | acceptance | DoD gate passes | `bash scripts/validate-dod.sh; echo $?` | `ALL CHECKS PASSED` · `EXIT=0` | ✅ |
| AC6 | acceptance | Version `0.6.1` consistent | validate-dod `[16]`/`[16b]` | `plugin.json and marketplace.json … both '0.6.1'`; `README … both '0.6.1'` | ✅ |
| AC4 | acceptance | New file registered + mirrored | validate-dod `[55]` + `find dist` | `every tracked … file is in MIRROR_SOURCES`; `6` dist copies | ✅ |
| AC1 | acceptance | Evidence Ledger in Phase 4 | `grep -c "Evidence Ledger"` | `SKILL.md:2`, `review-and-verify.md:2` | ✅ |
| AC2 | acceptance | Three named layers present | `grep -oE "Layer [123] — …"` | `Fresh triad` / `Goal-drift re-check` / `Independent re-prove` | ✅ |
| AC3 | acceptance | HTML tokens + self-contained | `grep` tokens + external-ref scan | `{{PLAIN_SUMMARY}}`,`{{EVIDENCE_APPENDIX}}`; external refs `0` | ✅ |
| W2 | task | quick=Layers 1–2, yolo=all 3 | `grep` both skills | `Layers 1–2` (quick); `all three re-verify layers` (yolo) | ✅ |
| W1 | task | Files stay ≤500 LOC | `wc -l` | `communication-voice 51`, `review-and-verify 415`, `SKILL 387`, `README 422` | ✅ |
| AC5 | acceptance | B2 memory recorded | file + index write | `feedback-b2-communication-voice.md` + `MEMORY.md` line added | ✅ |

**Three-layer re-verify:** Layer 1 fresh triad — `validate-dod.sh` EXIT 0 (re-run twice, both green). Layer 2 goal-drift re-check — every Success Signal (S1 validate green, S2 file mirrored, S3 ledger+layers present, S4 report tokens) has a proving ledger row above; no proof serves an out-of-scope bullet. Layer 3 independent re-prove — proofs gathered by re-running fresh `grep`/`wc`/`find`/`validate-dod` commands, not trusting earlier output; second `validate-dod` run and `sync --dry-run` (0 real churn) agree.

### Self-review (Phase 5)

| Item | Pass | Notes |
|---|---|---|
| DRY | ✓ | Ledger + 3-layer spec authored once in `review-and-verify.md`; hackify/quick/yolo point to it. |
| File-size caps (≤500 LOC) | ✓ | `[80]` 103 files scanned, all ≤500; largest touched = README 422. |
| HTML self-contained | ✓ | 0 external `src`/`href`/`cdn`/`script` refs; inline CSS + SVG only. |
| Scope (no drift) | ✓ | Phase list 1–6 unchanged; no code-rule edits; no `~/.claude/CLAUDE.md` edit. |
| Sync idempotent | ✓ | Re-run produced no git churn in `dist/`. |

## 8. Retrospective

- **DRY paid off.** Putting the ledger + three-layer spec once in `review-and-verify.md` meant `quick`/`yolo` needed only one-line reconciliation rows, not copies. The single source is the reason this stayed a small diff.
- **`dist/` is git-ignored build output.** Only `dist/.gitignore` is tracked; `sync-runtimes.sh` writes the rest locally. Do not try to commit `dist/` — regenerate it. The dry-run always lists the two `MANIFEST.md` files even when content is identical (not real churn).
- **`validate-dod.sh` is this repo's whole triad.** No unit runner here — the validator's `[16]/[16b]/[55]/[80]` checks are the test/lint/typecheck equivalent. Re-run it after any version, mirror, or file-size touch.
- **README uses one "New in" block.** Established pattern is to replace, not stack, per release — keeps the file under the 450-LOC cap.
- **Dogfooding worked.** I verified this change with the very Evidence Ledger + three-layer re-verify it introduces (see Sprint Review).
- Follow-up (Minor, deferred with implied sign-off via this ship): consider a future `validate-dod` check that asserts the Phase 4 section names the Evidence Ledger + three layers, so the doctrine cannot silently regress.

## Summary of changes shipped

| Area | Change |
|---|---|
| Evidence Ledger | Phase 4 requires one proof row per task + acceptance bullet (`claim / what ran / proof sample / result`) in `review-and-verify.md` + `SKILL.md` |
| Re-verify layers | Three named layers (`fresh triad` / `goal-drift re-check` / `independent re-prove`); `quick` runs 1–2, `hackify`+`yolo` run all three |
| Plain report | HTML report gains top `{{PLAIN_SUMMARY}}` + cumulative `{{EVIDENCE_APPENDIX}}`; stays self-contained (0 external refs) |
| Communication voice | New `references/communication-voice.md` (B2 + self-explanatory), wired into `SKILL.md` as always-on |
| Goal anchor | `goal-anchor.md` adds Phase 4 Layer 2 as a third drift-trace point |
| Work-doc + finish | `work-doc-template.md` gains the ledger table; `finish.md` Step F documents summary + appendix |
| Release | Version → `0.6.1` (`plugin.json`, `marketplace.json` ×2 + `source.ref`, README badge + "New in 0.6.1"); `CHANGELOG` entry |
| Build + memory | `communication-voice.md` registered in `MIRROR_SOURCES`; `dist/` re-synced (471 files, 7 runtimes); B2 voice saved as a memory |
