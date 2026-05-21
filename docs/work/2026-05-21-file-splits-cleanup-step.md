---
slug: 2026-05-21-file-splits-cleanup-step
title: Split over-cap reference files + extend Phase 6 with cleanup step
status: planning
type: refactor
created: 2026-05-21
project: hackify
related:
  - 2026-05-21-tech-neutral-principles
current_task: null
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
**Answer:** Phase-grouped (4 files). `template-contract.md` (~120 LOC, the 7-section spec) + `phase-2.5-spec-review.md` (~500 LOC, 3 reviewer templates) + `phase-3-implementation.md` (~300 LOC, implementer + debug evidence templates) + `phase-5-multi-review.md` (~600 LOC, 3 reviewer templates + aggregation patterns).

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
- [ ] **`skills/hackify/references/parallel-agents/` exists** with: `README.md`, `template-contract.md`, `phase-2.5-spec-review.md`, `phase-3-implementation.md`, `phase-5-multi-review.md`. The 7-section template contract anchors (`ROLE`, `INPUTS`, `OBJECTIVE`, `METHOD`, `VERIFICATION`, `SEVERITY`, `OUTPUT`) appear in `template-contract.md` AND in every reviewer/implementer template file as a header/inline reference.
- [ ] **`skills/hackify/references/clarify-questions/` exists** with: `README.md`, `wizard-contract.md`, `universal-preamble.md`, `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`, `picking-and-combining.md`. The 4-section wizard contract anchors (`SCENARIO`, `COMPOSITION`, `QUESTIONS`, `EXIT CRITERIA`) appear in every bank file.
- [ ] **`skills/hackify/references/parallel-agents.md` and `clarify-questions.md` are deleted** (no forwarding stubs).
- [ ] **All 11 cross-references updated** — `grep -rn 'parallel-agents\.md\b' rules/ agents/ skills/ README.md commands/ | grep -v 'parallel-agents/' | grep -v 'docs/work'` returns zero lines (except internal sub-dir self-refs). Same for `clarify-questions\.md`.
- [ ] **`scripts/sync-runtimes.sh`** carries a header-comment block explaining `MIRROR_SOURCES` is enumerated (not a glob); every new split file is listed in `MIRROR_SOURCES`.
- [ ] **`bash scripts/sync-runtimes.sh`** regenerates `dist/` cleanly and is idempotent; every new split file mirrors to all 6 full-mirror runtimes.
- [ ] **`bash scripts/validate-dod.sh`** exits 0 — every DoD content check that previously found a string in `parallel-agents.md` or `clarify-questions.md` continues to find it (in the new file).
- [ ] **Phase 6 cleanup step added** to `skills/hackify/SKILL.md` AND `skills/hackify/references/finish.md` (referenced from `skills/quick/SKILL.md` and `skills/yolo/SKILL.md` if they describe their own Phase 6 explicitly).
- [ ] **Phase 6 cleanup step applied to THIS sprint** — Phase 6 of this work-doc runs the new cleanup sweep and records evidence (stale refs found = 0, broken links = 0, scope creep = 0, etc.).
- [ ] **Behavioral guarantees preserved** — 7-section sub-agent contract intact across new template files; 4-section wizard contract intact across new bank files; carve-out scan-target tokens preserved per `rules/hard-caps.md`; hook wiring unchanged; DoD validator coverage unchanged.
- [ ] **CHANGELOG.md** v0.2.7 entry documents the splits + Phase 6 cleanup step; `plugin.json` + `marketplace.json` versions lockstep at 0.2.7.

## 4. Approach

**Chosen.** Two parallel "extract-and-author" agents in W1, each handling one source file end-to-end (atomic content moves — the agent has the whole source in context). W2 fans out 9 parallel cross-ref updaters (one per consuming file) plus the sync-runtimes header update. W3 deletes the originals + extends the Phase 6 spec in SKILL.md + finish.md. W4 is the dist regen + version bump + Phase 6 cleanup-on-self application.

**Considered & rejected.**
- *15 parallel new-file authors in W1.* Rejected — risk of content drift between agents (e.g., the 7-section contract anchors restated subtly differently in each template file). Single agent per source preserves atomicity.
- *Forwarding stubs instead of deletion.* Rejected per Q4 — stubs rot.
- *Inline the Phase 6 cleanup as a sentence in SKILL.md without a separate Step.* Rejected — load-bearing checklist deserves its own numbered Step C.5 to survive future Phase 6 invocations.

**Architectural touchpoints.** `skills/hackify/references/parallel-agents/{README,template-contract,phase-2.5-spec-review,phase-3-implementation,phase-5-multi-review}.md` (5 NEW); `skills/hackify/references/clarify-questions/{README,wizard-contract,universal-preamble,feature,fix,refactor,revamp-redesign,debug,research,picking-and-combining}.md` (10 NEW); 8 cross-ref updates in `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/writing-skills/SKILL.md`, `skills/receiving-code-review/SKILL.md`, `agents/spec-reviewer-dependencies.md`, `skills/hackify/references/review-and-verify.md`, `skills/hackify/references/implement-and-test.md`, `README.md`; `scripts/sync-runtimes.sh` (header + MIRROR_SOURCES extension); 2 file deletions (original `parallel-agents.md`, `clarify-questions.md`); Phase 6 spec extension in `skills/hackify/SKILL.md` + `skills/hackify/references/finish.md`; `CHANGELOG.md` + `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` v0.2.7 bump; `dist/` regenerated.

### Execution waves

| Wave | Tasks | Rationale |
|---|---|---|
| **W1** Author new split files | T1, T2 | 2 parallel agents. T1 = all 5 parallel-agents/ files; T2 = all 10 clarify-questions/ files. Single agent per source so content moves atomically. |
| **W2** Cross-ref updates + sync-runtimes housekeeping | T3, T4, T5, T6, T7, T8, T9, T10, T11 | 9 parallel agents updating 8 consuming files + sync-runtimes (header comment + MIRROR_SOURCES extension). Independent files; no collisions. |
| **W3** Delete originals + Phase 6 spec extension | T12, T13, T14 | 3 parallel. T12 deletes the 2 originals. T13 extends Phase 6 in SKILL.md + finish.md. T14 bumps version to 0.2.7 + CHANGELOG. |
| **W4** Dist regen + apply new cleanup step | T15, T16 | 2 sequential. T15 = `bash scripts/sync-runtimes.sh` regen + validate-dod. T16 = apply the just-authored Phase 6 cleanup step to this sprint's state; record evidence in Phase 6 Step C.5 evidence section. |

## 5. Sprint Backlog

### Wave 1 — Author new split files (parallel — 2 tasks)

- [ ] **T1** — Author all 5 `skills/hackify/references/parallel-agents/*.md` files (`README.md`, `template-contract.md`, `phase-2.5-spec-review.md`, `phase-3-implementation.md`, `phase-5-multi-review.md`) by extracting content from `skills/hackify/references/parallel-agents.md` (1783 LOC). Preserve 7-section contract anchors verbatim; preserve every template scaffold; preserve carve-out scan-target tokens per `rules/hard-caps.md`. `README.md` is a 10-30 LOC file map. Files: 5 NEW under `skills/hackify/references/parallel-agents/`. → verify: all 5 files exist; each split file ≤500 LOC; original parallel-agents.md still exists (unchanged — T12 deletes it); 7-section contract anchors `ROLE INPUTS OBJECTIVE METHOD VERIFICATION SEVERITY OUTPUT` appear at least once in `template-contract.md` AND in every reviewer/implementer file as a header or inline ref.
- [ ] **T2** — Author all 10 `skills/hackify/references/clarify-questions/*.md` files (`README.md`, `wizard-contract.md`, `universal-preamble.md`, `feature.md`, `fix.md`, `refactor.md`, `revamp-redesign.md`, `debug.md`, `research.md`, `picking-and-combining.md`) by extracting content from `skills/hackify/references/clarify-questions.md` (639 LOC). Preserve 4-section wizard contract anchors verbatim per bank; preserve every Q/A entry; preserve the per-bank COMPOSITION rules and EXIT CRITERIA. `README.md` is a 10-30 LOC file map. Files: 10 NEW under `skills/hackify/references/clarify-questions/`. → verify: all 10 files exist; each ≤500 LOC; original clarify-questions.md unchanged (T12 deletes it); 4-section wizard contract anchors `SCENARIO COMPOSITION QUESTIONS EXIT CRITERIA` each appear ≥1 in every bank file (universal-preamble + 6 task-type banks = 7 files × 4 anchors).

### Wave 2 — Cross-ref updates + sync-runtimes housekeeping (parallel — 9 tasks)

- [ ] **T3** — Update `skills/hackify/SKILL.md` cross-references: replace mentions of `parallel-agents.md` with the specific split file or subdir index; same for `clarify-questions.md`. Preserve the file map table semantics. Files: `skills/hackify/SKILL.md`. → verify: no remaining bare `parallel-agents.md` or `clarify-questions.md` references in this file; all new refs point to actual files under the subdirs.
- [ ] **T4** — Update `skills/quick/SKILL.md` cross-references (clarify-questions mentions). Files: `skills/quick/SKILL.md`. → verify: same as T3.
- [ ] **T5** — Update `skills/writing-skills/SKILL.md` cross-references. Files: `skills/writing-skills/SKILL.md`. → verify: same as T3.
- [ ] **T6** — Update `skills/receiving-code-review/SKILL.md` cross-reference. Files: `skills/receiving-code-review/SKILL.md`. → verify: same as T3.
- [ ] **T7** — Update `agents/spec-reviewer-dependencies.md` cross-reference (parallel-agents mention). Files: `agents/spec-reviewer-dependencies.md`. → verify: same as T3.
- [ ] **T8** — Update `skills/hackify/references/review-and-verify.md` cross-reference. Files: `skills/hackify/references/review-and-verify.md`. → verify: same as T3.
- [ ] **T9** — Update `skills/hackify/references/implement-and-test.md` cross-reference. Files: `skills/hackify/references/implement-and-test.md`. → verify: same as T3.
- [ ] **T10** — Update `README.md` cross-references. Files: `README.md`. → verify: same as T3.
- [ ] **T11** — Update `scripts/sync-runtimes.sh`: add a header-comment block explaining `MIRROR_SOURCES` is enumerated (not a glob) — new canonical files always need an explicit array entry; extend `MIRROR_SOURCES` with all 15 new split files (5 parallel-agents/ + 10 clarify-questions/); remove the 2 old entries (`parallel-agents.md`, `clarify-questions.md`). Files: `scripts/sync-runtimes.sh`. → verify: header comment present (≥3 lines); `grep -c 'parallel-agents/' scripts/sync-runtimes.sh` ≥ 5; `grep -c 'clarify-questions/' scripts/sync-runtimes.sh` ≥ 10; old entries absent.

### Wave 3 — Delete originals + Phase 6 spec extension + version bump (parallel — 3 tasks)

- [ ] **T12** — Delete `skills/hackify/references/parallel-agents.md` AND `skills/hackify/references/clarify-questions.md`. Pre-flight: verify no remaining cross-references with `grep -rln 'parallel-agents\.md\b\|clarify-questions\.md\b' rules/ agents/ skills/ README.md commands/ scripts/ | grep -v 'parallel-agents/\|clarify-questions/\|docs/work'` returns empty (W2 must be complete). Files: 2 file DELETIONS. → verify: both files absent; pre-deletion grep returned 0 hits.
- [ ] **T13** — Extend Phase 6 in `skills/hackify/SKILL.md` (Phase 6 section) AND `skills/hackify/references/finish.md` with a new **Step C.5 — Cleanup sweep**. Step C.5 enumerates cleanup classes to audit before archiving: (a) stale cross-references (links to files / sections that no longer exist after this sprint); (b) broken internal anchor links; (c) TODO/FIXME without owners introduced during the sprint; (d) empty directories left after file moves; (e) dead branches (local or remote) created during the sprint that won't be merged; (f) unrelated changes that snuck in (final scope-creep audit against the work-doc Sprint Backlog); (g) pre-existing dead code surfaced during the sprint but deliberately not touched — move to a follow-up entry in Retrospective, do not silently leave; (h) work-doc references to file paths that just changed. Each class requires a one-line evidence record in the Phase 6 archive. If `skills/quick/SKILL.md` or `skills/yolo/SKILL.md` describe their own Phase 6 explicitly, append a "Step C.5 cleanup sweep applies here too" note. Files: `skills/hackify/SKILL.md`, `skills/hackify/references/finish.md`, plus optional quick/yolo notes. → verify: `grep -F 'Step C.5' skills/hackify/SKILL.md` returns ≥1 line; same for `skills/hackify/references/finish.md`; the 8 cleanup classes (a-h) all listed.
- [ ] **T14** — Bump version 0.2.6 → 0.2.7 in `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (lockstep); add `## [0.2.7]` entry to `CHANGELOG.md` covering: file splits (parallel-agents, clarify-questions), subdir layout, Phase 6 Step C.5 cleanup sweep, `scripts/sync-runtimes.sh` header comment + MIRROR_SOURCES extension. Update README version badge to 0.2.7. Files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`. → verify: both JSONs report `0.2.7`; CHANGELOG has `## [0.2.7]` heading with 4-6 bullets; README badge updated; DoD check [16] (plugin↔marketplace version equality) passes.

### Wave 4 — Dist regen + apply new cleanup step to this sprint (sequential — 2 tasks)

- [ ] **T15** — Regenerate `dist/` via `bash scripts/sync-runtimes.sh`; second run for idempotency; `bash scripts/validate-dod.sh`. → verify: first run exits 0 with a new file count reflecting the +13 net split files (was 150, now ~163); second run produces zero further changes; validate-dod exits 0 with `ALL CHECKS PASSED`.
- [ ] **T16** — Apply the new Phase 6 Step C.5 cleanup sweep to THIS sprint. Walk through the 8 cleanup classes (a-h) and record one-line evidence per class in the Phase 6 archive of this work-doc. Files: this work-doc (`docs/work/2026-05-21-file-splits-cleanup-step.md`). → verify: Phase 6 archive contains a "Step C.5 — Cleanup sweep evidence" subsection with all 8 cleanup classes audited and outcome (0 / N findings).

## 6. Daily Updates

_(populated per task during Phase 3)_

## 7. Sprint Review (Phase 4 / 5)

_(populated during Phases 4 and 5)_

## 8. Retrospective

_(populated during Phase 6)_
