---
slug: 2026-05-21-file-splits-cleanup-step
title: Split over-cap reference files + extend Phase 6 with cleanup step
status: implementing
type: refactor
created: 2026-05-21
project: hackify
related:
  - 2026-05-21-tech-neutral-principles
current_task: W2:T3+T4+T5+T6+T7+T8+T9+T10+T11+T17
worktree: /Users/corecave/Code/hackify-neutral
branch: refactor/tech-neutral-principles
sprint_goal: |
  Bring `skills/hackify/references/parallel-agents.md` (1783 LOC) and
  `clarify-questions.md` (639 LOC) under the 500-LOC hard cap by splitting them
  into phase-grouped and per-bank subdirectories. Extend hackify Phase 6
  workflow with an explicit cleanup step for leftovers, abandoned code, stale
  files, broken cross-refs. Apply that new cleanup step to this very sprint
  before finishing.
---

# Split over-cap reference files + extend Phase 6 with cleanup step

## 1. Original ask

> Address the two follow-ups noted in the just-shipped
> `2026-05-21-tech-neutral-principles` Retrospective. (1) Split
> `skills/hackify/references/parallel-agents.md` (currently 1783 LOC, well
> over the 500-LOC hard cap) into smaller files organized by template/dispatch
> concern; natural seams appear to be per-template (Spec-review A/B/C /
> Implementation wave / Multi-reviewer A/B/C). (2) Split
> `skills/hackify/references/clarify-questions.md` (currently 639 LOC) into
> per-task-type banks; natural seam is one file per `Type: <name>` section
> plus a universal preamble. (3) Add a clear header comment to
> `scripts/sync-runtimes.sh` reminding authors that `MIRROR_SOURCES` is
> enumerated (not a glob) so new canonical files always need an explicit
> array entry. Preserve every behavioral guarantee: 7-section sub-agent
> contract anchors, 4-section wizard contract anchors, the carve-out
> scan-target tokens, the canonical hard caps. After the splits, the
> original files become forwarding pointers (or are deleted with
> cross-references updated) — and `scripts/sync-runtimes.sh` MIRROR_SOURCES
> must list every new file so dist/ regen carries them all.

Plus the mid-clarify augmentation:

> don't forget to extend last phase with cleanup step for leftovers,
> abandoned code, stale files, …etc.

## 2. Clarifying Q&A

### Q1 — parallel-agents.md split granularity
**Answer (post-spec-review correction):** Phase-grouped where data allows; per-template inside phase-2.5 because the data forces it. The pre-Phase-2.5 estimate ("~500 LOC for phase-2.5") was wrong — actual measurement shows phase-2.5 templates total **1106 LOC**, well over the 500-LOC hard cap. To honor both the user's "phase-grouped" intent AND the sprint's "no file over 500" invariant, the final layout is **9 files** under `parallel-agents/`:

| File | Source lines | LOC |
|---|---|---|
| `README.md` | (new index) | ~20 |
| `template-contract.md` | 1-160 (7-section spec) | ~160 |
| `phase-2.5-spec-review-a-consistency.md` | spec-review template A | ~230 |
| `phase-2.5-spec-review-b-rules.md` | spec-review template B | ~230 |
| `phase-2.5-spec-review-c-dependencies.md` | spec-review template C | ~230 |
| `phase-3-implementation.md` | 844-979 (implementer wave template) | ~135 |
| `phase-3b-debug-evidence.md` | 979-1266 (debug evidence templates) | ~287 |
| `phase-5-multi-review.md` | 1267-1733 (3 reviewer templates, A/B/C inline) | ~467 |
| `phase-5-aggregation.md` | 1734-end (lens / conflict resolution / anti-patterns) | ~50 |

Every file under the 500-LOC cap. Phase grouping preserved everywhere except phase-2.5, which has to split per-template because the data demands it.

### Q2 — clarify-questions.md split granularity
**Answer:** Per-bank (8 files). `wizard-contract.md` (preamble + contract spec) + `universal-preamble.md` + 6 task-type banks (`feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`) + `picking-and-combining.md`.

### Q3 — Layout
**Answer:** Subdirectories. `skills/hackify/references/parallel-agents/<file>.md` + `skills/hackify/references/clarify-questions/<file>.md`. Each subdir gets a `README.md` index documenting its file map.

### Q4 — Originals' fate
**Answer:** Delete originals + update all 11 cross-references. Clean break; no rotting forwarding stubs.

### Q5 — Phase 6 cleanup step (mid-clarify user augmentation)
**Question/Answer:** User asked to extend hackify Phase 6 with an explicit cleanup step for leftovers, abandoned code, stale files, etc. **Answer:** Add a new Step C.5 ("Cleanup sweep") between Step C (execute the choice) and Step D (archive work-doc) in `skills/hackify/SKILL.md` and `references/finish.md`. Step C.5 lists the cleanup classes to sweep: stale cross-references, broken internal links, TODO/FIXME without owners introduced during the sprint, empty directories left after file moves, dead branches, unrelated changes that snuck in (final scope-creep audit), and pre-existing dead code surfaced but deliberately not touched (move to follow-up). Apply the new step verbatim to this very sprint's Phase 6 — eat the dog food.

### Q6 — Continuation on same branch (default — confirmed)
**Answer:** Continue on the existing `refactor/tech-neutral-principles` branch. One branch, one review pass.

### Q7 — Done state (default — confirmed)
**Answer:** Branch left for review at finish. Combined diff (v0.2.6 work + this sprint) will be substantial.

## 3. Acceptance Criteria

- [ ] **No file in `rules/`, `agents/`, `skills/` exceeds 500 LOC** — `find rules agents skills -type f -name '*.md' | xargs wc -l | awk '$1 > 500'` returns no matches (excluding subdir `README.md` indexes which by design stay small).
- [ ] **`skills/hackify/references/parallel-agents/` exists with 12 files** (post-W1 mid-wave discovery added 3 more — T1 missed Phase 1 Research / Phase 4 Cross-package verification / Phase 5 Code-review escalation templates, which would have been silently lost on T12 deletion). Final 12 files: `README.md`, `template-contract.md`, `phase-1-research.md`, `phase-2.5-spec-review-a-consistency.md`, `phase-2.5-spec-review-b-rules.md`, `phase-2.5-spec-review-c-dependencies.md`, `phase-3-implementation.md`, `phase-3b-debug-evidence.md`, `phase-4-cross-package-verification.md`, `phase-5-multi-review.md`, `phase-5-escalation.md`, `phase-5-aggregation.md`. The 7-section template contract anchors (`ROLE`, `INPUTS`, `OBJECTIVE`, `METHOD`, `VERIFICATION`, `SEVERITY`, `OUTPUT`) appear in `template-contract.md` AND in every reviewer/implementer template file as a header/inline reference.
- [ ] **`skills/hackify/references/clarify-questions/` exists** with: `README.md`, `wizard-contract.md`, `universal-preamble.md`, `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`, `picking-and-combining.md`. The 4-section wizard contract anchors (`SCENARIO`, `COMPOSITION`, `QUESTIONS`, `EXIT CRITERIA`) appear in every TASK-TYPE BANK file (the 6 banks: `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`). The CANONICAL specification of those 4 sections lives ONLY in `wizard-contract.md` (single source of truth); the 6 banks REFERENCE the spec, do not restate it (DRY across docs per `rules/code-quality.md:24`). The `universal-preamble.md` is itself a bank-like wizard structure (so anchors also appear there); the `picking-and-combining.md` is closing rules (no wizard structure — anchors not required).
- [ ] **`skills/hackify/references/parallel-agents.md` and `clarify-questions.md` are deleted** (no forwarding stubs).
- [ ] **All cross-references updated** — `grep -rn 'parallel-agents\.md\b\|clarify-questions\.md\b' rules/ agents/ skills/ README.md commands/ scripts/` returns zero lines outside `parallel-agents/`, `clarify-questions/`, `docs/work/`. **Pre-spec-review count was 11; post-spec-review revealed `scripts/validate-dod.d/20-templates.sh` hardcodes the paths (Reviewer A Critical) — adds T17 to update it. Total consumers now: 9 files (the 8 markdown files in W2 + the new validate-dod.d entry).**
- [ ] **`scripts/sync-runtimes.sh`** carries a header-comment block explaining `MIRROR_SOURCES` is enumerated (not a glob); every new split file is listed in `MIRROR_SOURCES`.
- [ ] **`bash scripts/sync-runtimes.sh`** regenerates `dist/` cleanly and is idempotent; every new split file mirrors to all 6 full-mirror runtimes.
- [ ] **`bash scripts/validate-dod.sh`** exits 0 — every DoD content check that previously found a string in `parallel-agents.md` or `clarify-questions.md` continues to find it (in the new file).
- [ ] **Phase 6 cleanup step added** to `skills/hackify/SKILL.md` AND `skills/hackify/references/finish.md` (referenced from `skills/quick/SKILL.md` and `skills/yolo/SKILL.md` if they describe their own Phase 6 explicitly).
- [ ] **Phase 6 cleanup step applied to THIS sprint** — Phase 6 of this work-doc runs the new cleanup sweep and records evidence for **all 8 cleanup classes (a-h)** defined in T13. One-line evidence per class; explicit count (0 / N findings) per class.
- [ ] **Behavioral guarantees preserved** — 7-section sub-agent contract intact across new template files; 4-section wizard contract intact across new bank files; carve-out scan-target tokens preserved per `rules/hard-caps.md`; hook wiring unchanged; DoD validator coverage unchanged.
- [ ] **CHANGELOG.md** v0.2.7 entry documents the splits + Phase 6 cleanup step; `plugin.json` + `marketplace.json` versions lockstep at 0.2.7.

## 4. Approach

**Chosen.** Two parallel "extract-and-author" agents in W1, each handling one source file end-to-end (atomic content moves — the agent has the whole source in context). W2 fans out 9 parallel cross-ref updaters (one per consuming file) plus the sync-runtimes header update. W3 deletes the originals + extends the Phase 6 spec in SKILL.md + finish.md. W4 is the dist regen + version bump + Phase 6 cleanup-on-self application.

**Considered & rejected.**
- *15 parallel new-file authors in W1.* Rejected — risk of content drift between agents (e.g., the 7-section contract anchors restated subtly differently in each template file). Single agent per source preserves atomicity.
- *Forwarding stubs instead of deletion.* Rejected per Q4 — stubs rot.
- *Inline the Phase 6 cleanup as a sentence in SKILL.md without a separate Step.* Rejected — load-bearing checklist deserves its own numbered Step C.5 to survive future Phase 6 invocations.

**Architectural touchpoints.** **9 NEW** under `skills/hackify/references/parallel-agents/` (`README`, `template-contract`, `phase-2.5-spec-review-{a-consistency,b-rules,c-dependencies}`, `phase-3-implementation`, `phase-3b-debug-evidence`, `phase-5-multi-review`, `phase-5-aggregation`); **10 NEW** under `skills/hackify/references/clarify-questions/` (`README`, `wizard-contract`, `universal-preamble`, `feature`, `fix`, `refactor`, `revamp-redesign`, `debug`, `research`, `picking-and-combining`); 9 cross-ref updates (8 markdown consumers + `scripts/validate-dod.d/20-templates.sh`); `scripts/sync-runtimes.sh` (header + MIRROR_SOURCES extension); 2 file deletions; Phase 6 spec extension in `skills/hackify/SKILL.md` + `skills/hackify/references/finish.md`; `CHANGELOG.md` + `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` v0.2.7 bump + README badge; `dist/` regenerated.

### Execution waves (post-spec-review revision)

| Wave | Tasks | Rationale |
|---|---|---|
| **W1** Author new split files | T1, T2 | 2 parallel agents. T1 = all 9 parallel-agents/ files; T2 = all 10 clarify-questions/ files. Single agent per source so content moves atomically. Implementer OUTPUT cap bumped to 300 words (each authors many files). |
| **W2** Cross-ref updates + sync-runtimes + validate-dod housekeeping | T3, T4, T5, T6, T7, T8, T9, T10, T11, T17 | 10 parallel agents updating 8 markdown consumers + `scripts/sync-runtimes.sh` (header + MIRROR_SOURCES) + `scripts/validate-dod.d/20-templates.sh` (PA_FILE/CQ_FILE paths + per-bank iteration for wizard checks). Independent files; no collisions. |
| **W3** Delete originals + Phase 6 spec extension | T12, T13, T14 | 3 parallel. T12 deletes the 2 originals (pre-flight grep enforced). T13 extends Phase 6 in SKILL.md + finish.md (must pull latest after W2 — diff-aware). T14 bumps version to 0.2.7 + CHANGELOG + README badge (diff-aware of T10's README edit). |
| **W4** Dist regen + apply new cleanup step (sequential) | T15, T16 | T15 = `bash scripts/sync-runtimes.sh` regen + validate-dod (expected file count grows ~150 → ~246 = +16 net source files × 6 full-mirror runtimes). T16 = apply the new Phase 6 Step C.5 cleanup sweep to this sprint's state; record evidence for all 8 cleanup classes (a-h). T15 MUST land before T16 starts. |

## 5. Sprint Backlog

### Wave 1 — Author new split files (parallel — 2 tasks)

- [x] **T1** — Author all 9 `skills/hackify/references/parallel-agents/*.md` files (`README.md`, `template-contract.md`, `phase-2.5-spec-review-a-consistency.md`, `phase-2.5-spec-review-b-rules.md`, `phase-2.5-spec-review-c-dependencies.md`, `phase-3-implementation.md`, `phase-3b-debug-evidence.md`, `phase-5-multi-review.md`, `phase-5-aggregation.md`) by extracting content from `skills/hackify/references/parallel-agents.md` (1783 LOC). Source-line ranges per the Q1 table. Preserve 7-section contract anchors verbatim; preserve every template scaffold; preserve carve-out scan-target tokens per `rules/hard-caps.md`. `README.md` is a 15-30 LOC file map. Files: 9 NEW under `skills/hackify/references/parallel-agents/`. → verify: all 9 files exist; each split file ≤500 LOC (especially phase-5-multi-review.md, which sits closest to the cap at ~467); original parallel-agents.md still exists unchanged (T12 deletes it); 7-section contract anchors `ROLE INPUTS OBJECTIVE METHOD VERIFICATION SEVERITY OUTPUT` appear at least once in `template-contract.md` AND in every reviewer/implementer file as a header or inline ref.
- [x] **T2** — Author all 10 `skills/hackify/references/clarify-questions/*.md` files (`README.md`, `wizard-contract.md`, `universal-preamble.md`, `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`, `picking-and-combining.md`) by extracting content from `skills/hackify/references/clarify-questions.md` (639 LOC). Preserve 4-section wizard contract anchors verbatim per bank; preserve every Q/A entry; preserve the per-bank COMPOSITION rules and EXIT CRITERIA. **DRY across docs:** the canonical specification of the 4-section wizard contract MUST live ONLY in `wizard-contract.md`; each bank REFERENCES the contract (single-sentence pointer) rather than restating it. The anchor strings themselves (`SCENARIO`, `COMPOSITION`, `QUESTIONS`, `EXIT CRITERIA`) DO appear in every bank because each bank uses them as section headings; that's expected and not DRY violation. `README.md` is a 15-30 LOC file map. Files: 10 NEW under `skills/hackify/references/clarify-questions/`. → verify: all 10 files exist; each ≤500 LOC; original clarify-questions.md unchanged (T12 deletes it); 4-section wizard contract anchors `SCENARIO COMPOSITION QUESTIONS EXIT CRITERIA` each appear ≥1 in every of the 7 wizard-structure files (universal-preamble + 6 task-type banks); the canonical 4-section CONTRACT SPECIFICATION text appears only in `wizard-contract.md` (banks reference it).

### Wave 2 — Cross-ref updates + sync-runtimes housekeeping (parallel — 9 tasks)

- [ ] **T3** — Update `skills/hackify/SKILL.md` cross-references: replace mentions of `parallel-agents.md` with the specific split file or subdir index; same for `clarify-questions.md`. Preserve the file map table semantics. Files: `skills/hackify/SKILL.md`. → verify: no remaining bare `parallel-agents.md` or `clarify-questions.md` references in this file; all new refs point to actual files under the subdirs.
- [ ] **T4** — Update `skills/quick/SKILL.md` cross-references (clarify-questions mentions). Files: `skills/quick/SKILL.md`. → verify: same as T3.
- [ ] **T5** — Update `skills/writing-skills/SKILL.md` cross-references. Files: `skills/writing-skills/SKILL.md`. → verify: same as T3.
- [ ] **T6** — Update `skills/receiving-code-review/SKILL.md` cross-reference. Files: `skills/receiving-code-review/SKILL.md`. → verify: same as T3.
- [ ] **T7** — Update `agents/spec-reviewer-dependencies.md` cross-reference (parallel-agents mention). Files: `agents/spec-reviewer-dependencies.md`. → verify: same as T3.
- [ ] **T8** — Update `skills/hackify/references/review-and-verify.md` cross-reference. Files: `skills/hackify/references/review-and-verify.md`. → verify: same as T3.
- [ ] **T9** — Update `skills/hackify/references/implement-and-test.md` cross-reference. Files: `skills/hackify/references/implement-and-test.md`. → verify: same as T3.
- [ ] **T10** — Update `README.md` cross-references. Files: `README.md`. → verify: same as T3.
- [ ] **T11** — Update `scripts/sync-runtimes.sh`: add a header-comment block explaining `MIRROR_SOURCES` is enumerated (not a glob) — new canonical files always need an explicit array entry; extend `MIRROR_SOURCES` with all 22 new split files (12 parallel-agents/ + 10 clarify-questions/); remove the 2 old entries (`parallel-agents.md`, `clarify-questions.md`). Files: `scripts/sync-runtimes.sh`. → verify: header comment present (≥3 lines); `grep -c 'parallel-agents/' scripts/sync-runtimes.sh` ≥ 12; `grep -c 'clarify-questions/' scripts/sync-runtimes.sh` ≥ 10; old entries absent.
- [ ] **T17** — Update `scripts/validate-dod.d/20-templates.sh` to point at the new file paths: `PA_FILE` becomes the directory `skills/hackify/references/parallel-agents/`; `CQ_FILE` becomes `skills/hackify/references/clarify-questions/`. Adjust check [9] (template structural conformance) to iterate every `.md` file under `parallel-agents/` (excluding `README.md`) and confirm the 7-section contract anchors appear. Adjust check [13] (no leaked absolute paths) to iterate every file in both subdirs. Adjust check [14] (wizard structural conformance) to iterate every bank file in `clarify-questions/`. Files: `scripts/validate-dod.d/20-templates.sh`. → verify: `bash scripts/validate-dod.sh` exits 0 after T1+T2+T17 land in dist/ (so this check runs after the dist regen in T15 — but T17 itself just edits the script; the actual gate is T15's DoD run); script has no remaining references to `parallel-agents.md` or `clarify-questions.md` as files.

### Wave 3 — Delete originals + Phase 6 spec extension + version bump (parallel — 3 tasks)

- [ ] **T12** — Delete `skills/hackify/references/parallel-agents.md` AND `skills/hackify/references/clarify-questions.md`. Pre-flight: verify no remaining cross-references with `grep -rln 'parallel-agents\.md\b\|clarify-questions\.md\b' rules/ agents/ skills/ README.md commands/ scripts/ | grep -v 'parallel-agents/\|clarify-questions/\|docs/work'` returns empty (W2 must be complete). Files: 2 file DELETIONS. → verify: both files absent; pre-deletion grep returned 0 hits.
- [ ] **T13** — *(Diff-aware: this task edits `skills/hackify/SKILL.md` AFTER T3 has already updated it in W2. The implementer MUST read the post-W2 state of the file and append Phase 6 changes; MUST NOT re-introduce stale `parallel-agents.md` or `clarify-questions.md` paths.)* Extend Phase 6 in `skills/hackify/SKILL.md` (Phase 6 section) AND `skills/hackify/references/finish.md` with a new **Step C.5 — Cleanup sweep**. Step C.5 enumerates cleanup classes to audit before archiving: (a) stale cross-references (links to files / sections that no longer exist after this sprint); (b) broken internal anchor links; (c) TODO/FIXME without owners introduced during the sprint; (d) empty directories left after file moves; (e) dead branches (local or remote) created during the sprint that won't be merged; (f) unrelated changes that snuck in (final scope-creep audit against the work-doc Sprint Backlog); (g) pre-existing dead code surfaced during the sprint but deliberately not touched — move to a follow-up entry in Retrospective, do not silently leave; (h) work-doc references to file paths that just changed. Each class requires a one-line evidence record in the Phase 6 archive. If `skills/quick/SKILL.md` or `skills/yolo/SKILL.md` describe their own Phase 6 explicitly, append a "Step C.5 cleanup sweep applies here too" note. Files: `skills/hackify/SKILL.md`, `skills/hackify/references/finish.md`, plus optional quick/yolo notes. → verify: `grep -F 'Step C.5' skills/hackify/SKILL.md` returns ≥1 line; same for `skills/hackify/references/finish.md`; the 8 cleanup classes (a-h) all listed.
- [ ] **T14** — *(Diff-aware: this task edits `README.md` AFTER T10 has already updated it in W2. The implementer MUST read the post-W2 state of the file and update the version badge only; MUST NOT re-introduce stale cross-refs.)* Bump version 0.2.6 → 0.2.7 in `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (lockstep); add `## [0.2.7]` entry to `CHANGELOG.md` covering: file splits (parallel-agents → 9 files, clarify-questions → 10 files), subdir layout, Phase 6 Step C.5 cleanup sweep, `scripts/sync-runtimes.sh` header comment + MIRROR_SOURCES extension, `scripts/validate-dod.d/20-templates.sh` path update. Update README version badge to 0.2.7. Files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`. → verify: both JSONs report `0.2.7`; CHANGELOG has `## [0.2.7]` heading with 4-6 bullets; README badge updated; DoD check [16] (plugin↔marketplace version equality) passes.

### Wave 4 — Dist regen + apply new cleanup step to this sprint (sequential — 2 tasks)

- [ ] **T15** — Regenerate `dist/` via `bash scripts/sync-runtimes.sh`; second run for idempotency; `bash scripts/validate-dod.sh`. → verify: first run exits 0 with a new file count reflecting the net change (was 150 from v0.2.6 baseline; now ~150 + (22 new − 2 deleted) × 6 full-mirror runtimes = ~270); second run produces zero further changes; validate-dod exits 0 with `ALL CHECKS PASSED` (T17's path updates to validate-dod.d/20-templates.sh are exercised here).
- [ ] **T16** — Apply the new Phase 6 Step C.5 cleanup sweep to THIS sprint. Walk through the 8 cleanup classes (a-h) and record one-line evidence per class in the Phase 6 archive of this work-doc. Files: this work-doc (`docs/work/2026-05-21-file-splits-cleanup-step.md`). → verify: Phase 6 archive contains a "Step C.5 — Cleanup sweep evidence" subsection with all 8 cleanup classes audited and outcome (0 / N findings).

## 6. Daily Updates

### W1 — Author new split files — done 2026-05-21

2 parallel agents (T1, T2) dispatched; mid-wave T1d added to capture 3 template sections T1 missed.

- **T1** (parallel-agents/, 9 files initially) — extracted from 1783-LOC source, all anchors preserved. Implementer correctly noted the line ranges in my Q1 estimate sliced through OUTPUT sections; used real H3 boundaries instead. **Carve-out verify FAILED expectedly** — source had 0 literal tokens because v0.2.6 abstracted them; canonical home is `rules/hard-caps.md:14`. Verify expectation was wrong, not a defect. **Critical mid-wave finding:** Phase 1 Research (164-287), Phase 4 Cross-package (1010-1147), Phase 5 Escalation (1601-1758) templates were not in my 9-file plan — would have been silently lost on T12. Dispatched T1d.
- **T1d** (parallel-agents/, 3 more files) — added `phase-1-research.md` (127 LOC, source 164-286), `phase-4-cross-package-verification.md` (142 LOC, source 1010-1147), `phase-5-escalation.md` (164 LOC, source 1601-1760). README updated with 3 new rows. Subdir now totals 12 files.
- **T2** (clarify-questions/, 10 files) — extracted from 639-LOC source. 4-section contract spec lives ONLY in `wizard-contract.md`; banks reference it. Every wizard-bearing file (universal-preamble + 6 banks) carries all 4 anchors as section markers (those are bank-content scaffolds, not spec restatement — expected). `picking-and-combining.md` correctly omits anchors (closing rules, not a wizard).
- **Wave verification.** parallel-agents/: 12 files, max LOC 455 (phase-5-multi-review.md). clarify-questions/: 10 files, max LOC 98 (feature.md). All under 500 LOC cap. 7-section anchors all ≥1 in template-contract.md. 4-section anchors 1/1/1/1 in feature.md (sanity check). Sources unchanged at 1783 and 639. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED` (still reads old paths — will switch over after T17).
- **Self-review.** ✓ DRY (specs centralized) ✓ no suppressions ✓ source files untouched ✓ all caps respected ✓ no scope creep (T1d was a direct corollary of the T1 discovery; not new feature).



## 7. Sprint Review (Phase 4 / 5)

_(populated during Phases 4 and 5)_

## 8. Retrospective

_(populated during Phase 6)_
