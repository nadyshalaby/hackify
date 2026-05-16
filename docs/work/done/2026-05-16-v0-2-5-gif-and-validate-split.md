---
slug: v0-2-5-gif-and-validate-split
title: v0.2.5 — Demo GIF refresh + validate-dod.sh modular split
status: done
type: refactor
created: 2026-05-16
project: hackify
current_task: shipped
worktree: (none)
branch: main
sprint_goal: Close two v0.2.4 retrospective follow-ups in one commit — refresh the README hero GIF via a committed Python generator script, and split `scripts/validate-dod.sh` (723 LOC, over the 500 hard cap) into a `scripts/validate-dod.d/*.sh` module set sourced from a thin orchestrator.
---

## Original Ask

> regenerate the demo GIF and do the follow-ups

(Follow-ups from `docs/work/done/2026-05-16-v0-2-4-yolo-mode.md` Retrospective: "validate-dod.sh is now 723 lines… right fix is splitting by responsibility" + "demo GIF shows the 6-phase full workflow which is unchanged in this release… let me know if you want it refreshed".)

## Clarifying Q&A

**Q1 — Which version label should the new GIF display?**
A1 — **No version label.** Drop the number entirely; the hero shows just "Hackify". Eliminates version drift forever — future bumps no longer require GIF refresh unless phases or install commands change.

**Q2 — Should the Python generator script be committed to the repo?**
A2 — **Yes — commit as `scripts/gen-demo-gif.py`.** Solves the v0.2.1 "no source committed" problem the user hit. Future GIF refreshes re-run `python3 scripts/gen-demo-gif.py` against a tracked source.

## Acceptance Criteria

- [ ] **AC1.** New file `scripts/gen-demo-gif.py` exists. Pure Python 3 + Pillow. Produces a 1200×675 animated GIF at the explicit output path. Single `main()` function ≤40 LOC (verify: `awk '/^def main\(/{flag=1;n=0} flag{n++} /^def [^m]/{if(flag){print n;exit}}' scripts/gen-demo-gif.py` returns ≤40), file ≤200 LOC. Script header docstring documents `requires Pillow (pip install Pillow>=10)`.
- [ ] **AC2.** `scripts/gen-demo-gif.py` renders the README hero with the SAME visual structure as the v0.2.1 GIF — dark navy background, title "Hackify" (NO version number), subtitle "One end-to-end dev workflow for every task in Claude Code", top-right "MIT | github.com/nadyshalaby/hackify" badge, 6 phase tiles in a row (1 Clarify / 2 Plan / 3 Implement / 4 Verify / 5 Review / 6 Finish with their existing taglines), arrow connectors, bottom phase-pipeline text, "anchored to a single per-task markdown work-doc" caption, "Install via Claude Code plugin marketplace" footer panel.
- [ ] **AC3.** Animation: 7 frames @ 600 ms each, infinite loop. Sequential phase highlight — each phase tile lights up brighter when "active" and dims back when the next one activates. Frame 0 = phase 1 active, frame 5 = phase 6 active, frame 6 = all six dimmed back to resting state (one settle frame, not two — Pillow's GIF encoder collapses byte-identical consecutive frames). Total loop duration = 7 × 600 ms = 4.2 s.
- [ ] **AC4.** Running `python3 scripts/gen-demo-gif.py` from repo root writes `docs/assets/hackify-demo.gif`. Output GIF is 1200×675, 7 frames, 600 ms/frame, infinite loop. Verified via `python3 -c "from PIL import Image; im = Image.open('docs/assets/hackify-demo.gif'); print(im.size, im.n_frames, im.info.get('duration'), im.info.get('loop'))"` returning `(1200, 675) 7 600 0`.
- [ ] **AC5.** (deleted by Phase 2.5 review — AC2's "title 'Hackify' (NO version number)" is the real visual guard; a binary grep against an LZW-compressed GIF was a no-op verification.)
- [ ] **AC6.** New directory `scripts/validate-dod.d/` exists with exactly 8 module files: `00-helpers.sh`, `10-required-files.sh`, `20-templates.sh`, `30-version-and-summary.sh`, `40-quick-skill.sh`, `50-runtimes-and-companions.sh`, `60-primitives.sh`, `70-invariants-and-new.sh`.
- [ ] **AC7.** Each module file is well under the 500 LOC hard cap (soft target: ≤250 LOC). `20-templates.sh` may run ~215 LOC because the shared template-state arrays (`ALL_TEMPLATES`, `REVIEW_TEMPLATES`, `BUILD_TEMPLATES`, `WIZARD_BANKS`, `CANONICAL_SEVERITY`, `ALLOWLIST`) defined inside check `[8]` are consumed by checks `[9]`–`[15]`, so the 9 check groups must coexist in one module. Each module starts with `# shellcheck shell=bash` so linters can analyze without a `source` parent.
- [ ] **AC8.** Module-to-check-group mapping is preserved exactly — all 34 existing check groups land in a module:
  - `00-helpers.sh`: no checks; defines `red`/`green`/`yellow`, `check_file`, `check_jq`, `check_no_token`, `check_token_present`, `check_line_range`, `section_body`, `check_role`.
  - `10-required-files.sh`: checks `[1]`–`[6]`.
  - `20-templates.sh`: checks `[7]`, `[8]`, `[9]`, `[10]`, `[11]`, `[12]`, `[13]`, `[14]`, `[15]`.
  - `30-version-and-summary.sh`: checks `[16]`, `[17]`, `[18]`, `[19]`, `[20]`.
  - `40-quick-skill.sh`: checks `[21]`, `[22]`, `[23]`, `[35]`.
  - `50-runtimes-and-companions.sh`: checks `[24]`, `[25]`, `[26]`, `[28]`.
  - `60-primitives.sh`: checks `[29]`, `[30]`, `[31]`, `[32]`.
  - `70-invariants-and-new.sh`: checks `[33]`, `[34]`.
- [ ] **AC9.** `scripts/validate-dod.sh` rewritten as a thin orchestrator ≤60 LOC. Responsibilities: shebang + `set -uo pipefail`, define `REPO_ROOT` + `FAILED=0`, `cd "$REPO_ROOT"`, source each of the 8 `scripts/validate-dod.d/*.sh` modules in order (explicit list — no glob → no `shellcheck disable=SC1090` suppression), final summary block (`ALL CHECKS PASSED` / `N CHECK(S) FAILED`) with appropriate exit code.
- [ ] **AC10.** No new lint suppressions anywhere. Zero `shellcheck disable` directives in the orchestrator or any module. Helpers and orchestrator preserve the exit-code-accumulating pattern (`set -e` intentionally omitted).
- [ ] **AC11.** `bash scripts/validate-dod.sh` exits 0 with all 34 check groups still passing — identical output structure to the pre-refactor script. Each `yellow "[N]"` line still prints; each green `ok` and red `FAIL` line preserved.
- [ ] **AC12.** `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` both have `version: "0.2.5"`.
- [ ] **AC13.** `CHANGELOG.md` gains a new `## [0.2.5] - 2026-05-16` entry with subsections `### Added` (gen-demo-gif.py, validate-dod.d/ modules), `### Changed` (demo GIF refresh; validate-dod.sh thinned to orchestrator), `### Rationale` (closes v0.2.4 retro follow-ups; no behavior change).
- [ ] **AC14.** `bash scripts/sync-runtimes.sh` exits 0 (sanity check — only `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` from MIRROR_SOURCES changed, but runtime sync should still complete cleanly).

## Approach

**Two follow-ups, one commit.** Both are pure-internal: the GIF refresh updates one binary asset + adds one generator script; the validate-dod split is a behavior-preserving refactor. No skill content, no plugin contract change.

**GIF generator.** Python 3 + Pillow (already verified installed). One main function, ≤40 LOC, that takes an output path and writes the 7-frame GIF. Layout matches the v0.2.1 design exactly minus the version label. Frame-level animation: each phase tile has two colors — a "dim" resting state and a "bright" active state. Frame `n` for `n in 0..5` paints phase `n+1` bright; frames 6–7 paint all six dim (a brief settle pause). Title is just "Hackify" — no number.

**Validate-dod split.** Replace the 723-line monolith with a thin orchestrator that explicitly sources 8 named modules in order. Helpers go to module 00; check groups partition by responsibility into modules 10–70. Module sourcing is by explicit `source "$DOD_MODULES_DIR/NN-name.sh"` calls — no glob, so shellcheck has nothing to complain about. The exit-code accumulation pattern (every helper writes into `FAILED` on miss; the orchestrator exits non-zero at the end) is preserved unchanged.

**Why one commit.** Both deliverables are housekeeping with no functional surface. The CHANGELOG documents them together as v0.2.5; downstream consumers see a single version bump.

### Execution waves

```
Wave 1 (parallel — 12 independent file creates/edits, no file collision)
  T1  — NEW  scripts/gen-demo-gif.py
  T3  — NEW  scripts/validate-dod.d/00-helpers.sh
  T4  — NEW  scripts/validate-dod.d/10-required-files.sh
  T5  — NEW  scripts/validate-dod.d/20-templates.sh
  T6  — NEW  scripts/validate-dod.d/30-version-and-summary.sh
  T7  — NEW  scripts/validate-dod.d/40-quick-skill.sh
  T8  — NEW  scripts/validate-dod.d/50-runtimes-and-companions.sh
  T9  — NEW  scripts/validate-dod.d/60-primitives.sh
  T10 — NEW  scripts/validate-dod.d/70-invariants-and-new.sh
  T11 — REWRITE scripts/validate-dod.sh (thin orchestrator)
  T12 — EDIT .claude-plugin/plugin.json + marketplace.json (version 0.2.4 → 0.2.5)
  T13 — EDIT CHANGELOG.md (new [0.2.5] entry)

Wave 2 (parallel — 2 tasks, no overlap with Wave 1 outputs)
  T2  — RUN  python3 scripts/gen-demo-gif.py docs/assets/hackify-demo.gif
  T15 — RUN  bash scripts/sync-runtimes.sh   (mirror new versions to dist/)

Wave 3 (serial — depends on Wave 1 module set + Wave 1 orchestrator + Wave 2 GIF)
  T14 — RUN  bash scripts/validate-dod.sh    (must exit 0; all 34 checks pass)
```

**Why T12 touches 2 files in one task.** Both version-bump edits are one-line `0.2.4` → `0.2.5` swaps. Splitting into T12a + T12b would just double the dispatch overhead with no parallelism win (still in the same wave). Acceptable single-task scope.

**Why T15 is in Wave 2 (not Wave 3).** `sync-runtimes.sh` reads `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` to mirror version, AND reads `skills/` etc. None of the Wave 1 module edits touch files in `MIRROR_SOURCES`, so T15 only depends on T12 from Wave 1. Independent of T2 (GIF generator run).

## Sprint Backlog

- [x] **T1 — Create `scripts/gen-demo-gif.py`** — Python 3 + Pillow script. Single `main(output_path: str) -> None` function. Reads no external assets — all colors, fonts, geometry are constants in the script. Renders 7 frames at 1200×675; saves as animated GIF with 600 ms/frame, infinite loop. Constants block at top: canvas size, colors (`BG_NAVY = "#0F1419"`, etc.), 6 phase tuples `(number, name, tagline)`. Uses `PIL.ImageDraw` for tiles, `PIL.ImageFont` with `truetype` for text (falls back to default font if system font missing). The main function builds a list of 8 `PIL.Image` objects, then calls `frames[0].save(output_path, save_all=True, append_images=frames[1:], duration=600, loop=0, optimize=True)`. Script accepts `output_path` as `sys.argv[1]` or defaults to `docs/assets/hackify-demo.gif`. Files: `scripts/gen-demo-gif.py` (new). Test mode: manual smoke — Wave 2 T2 runs it and AC4's Pillow inspection confirms metadata.
- [x] **T3 — Create `scripts/validate-dod.d/00-helpers.sh`** — Extract from existing `scripts/validate-dod.sh` lines 13–72 + line 206 (`section_body`) + lines 270–290 (`check_role`). File starts with `# shellcheck shell=bash` then the existing comment block ("Validate the hackify plugin… set -e is intentionally omitted"), then defines: `red`, `green`, `yellow`, `check_file`, `check_jq`, `check_no_token`, `check_token_present`, `check_line_range`, `section_body`, `check_role`. NO check groups. NO `cd` call (orchestrator handles that). NO `REPO_ROOT` definition (orchestrator handles that). NO `FAILED=0` init (orchestrator handles that — module uses but doesn't initialize). Files: `scripts/validate-dod.d/00-helpers.sh` (new). Verify: `bash -n scripts/validate-dod.d/00-helpers.sh` exit 0.
- [x] **T4 — Create `scripts/validate-dod.d/10-required-files.sh`** — Extract from existing `scripts/validate-dod.sh` check groups `[1]` (lines 75–83), `[2]` (lines 85–93), `[3]` (lines 94–98), `[4]` (lines 99–108), `[5]` (lines 109–124), `[6]` (lines 125–148). File starts with `# shellcheck shell=bash`. Body is the 6 check group blocks verbatim, in numeric order. Files: `scripts/validate-dod.d/10-required-files.sh` (new). Verify: `bash -n` exit 0.
- [x] **T5 — Create `scripts/validate-dod.d/20-templates.sh`** — Extract check groups `[7]` (lines 149–151), `[8]` (lines 152–205), `[9]` body lines 211–222 ONLY (NOT line 206–208 `section_body` definition — that lives in `00-helpers.sh` per T3), `[10]` (lines 223–251), `[11]` (lines 252–268), `[12]` body lines 286–292 ONLY (NOT lines 270–285 `check_role` definition — that lives in `00-helpers.sh` per T3), `[13]` (lines 293–320), `[15]` (lines 321–342), `[14]` (lines 468–482). Note: `[14]` appears out of numeric order in the original — preserve the same out-of-order position inside this module (last block in file). The shared template-state arrays at lines 161–205 (defined inside `[8]` body) must remain inside `[8]` since `[9]`–`[15]` consume them. ASSUME `section_body` and `check_role` are already defined by `00-helpers.sh` (sourced earlier); do not redefine them. File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/20-templates.sh` (new). Verify: `bash -n` exit 0; `grep -c "yellow \"\[" scripts/validate-dod.d/20-templates.sh` returns 9; `grep -c "^section_body()" scripts/validate-dod.d/20-templates.sh` returns 0 (must be 0 — function only defined in helpers); `grep -c "^check_role()" scripts/validate-dod.d/20-templates.sh` returns 0.
- [x] **T6 — Create `scripts/validate-dod.d/30-version-and-summary.sh`** — Extract check groups `[16]` (lines 343–352), `[17]` (lines 353–372), `[18]` (lines 373–394), `[19]` (lines 395–409), `[20]` (lines 410–423). File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/30-version-and-summary.sh` (new). Verify: `bash -n` exit 0; 5 check groups present.
- [x] **T7 — Create `scripts/validate-dod.d/40-quick-skill.sh`** — Extract check groups `[21]` (lines 424–443), `[22]` (lines 444–459), `[23]` (lines 460–467), `[35]` (lines 713–722). File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/40-quick-skill.sh` (new). Verify: `bash -n` exit 0; 4 check groups present.
- [x] **T8 — Create `scripts/validate-dod.d/50-runtimes-and-companions.sh`** — Extract check groups `[24]` (lines 483–500), `[25]` (lines 501–535), `[26]` (lines 536–562), `[28]` (lines 563–586). File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/50-runtimes-and-companions.sh` (new). Verify: `bash -n` exit 0; 4 check groups present.
- [x] **T9 — Create `scripts/validate-dod.d/60-primitives.sh`** — Extract check groups `[29]` (lines 587–599), `[30]` (lines 600–631), `[31]` (lines 632–651), `[32]` (lines 652–663). File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/60-primitives.sh` (new). Verify: `bash -n` exit 0; 4 check groups present.
- [x] **T10 — Create `scripts/validate-dod.d/70-invariants-and-new.sh`** — Extract check groups `[33]` (lines 664–679), `[34]` (lines 680–712). File starts with `# shellcheck shell=bash`. Files: `scripts/validate-dod.d/70-invariants-and-new.sh` (new). Verify: `bash -n` exit 0; 2 check groups present.
- [x] **T11 — Rewrite `scripts/validate-dod.sh`** — Replace the entire existing 723-line file with a thin orchestrator. New content: shebang `#!/usr/bin/env bash`, comment block explaining the orchestrator pattern + why `-e` is omitted, `set -uo pipefail`, `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`, `FAILED=0`, `DOD_MODULES_DIR="$REPO_ROOT/scripts/validate-dod.d"`, `cd "$REPO_ROOT"`, 8 explicit `source "$DOD_MODULES_DIR/NN-name.sh"` calls (in order: 00, 10, 20, 30, 40, 50, 60, 70), final block `if [ "$FAILED" -eq 0 ]; then green "ALL CHECKS PASSED"; exit 0; else red "$FAILED CHECK(S) FAILED"; exit 1; fi`. Target ≤60 LOC total. NO `shellcheck disable` directives. Files: `scripts/validate-dod.sh` (rewrite). Verify: `bash -n scripts/validate-dod.sh` exit 0; `wc -l scripts/validate-dod.sh` ≤ 60.
- [x] **T12 — Bump version in plugin.json + marketplace.json** — Two one-line edits: `.claude-plugin/plugin.json` `"version": "0.2.4"` → `"version": "0.2.5"`; `.claude-plugin/marketplace.json` `plugins[0].version "0.2.4"` → `"0.2.5"`. Preserve all other fields and 2-space indent. Files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. Verify: `jq -e '.version == "0.2.5"' .claude-plugin/plugin.json` exit 0; `jq -e '.plugins[0].version == "0.2.5"' .claude-plugin/marketplace.json` exit 0.
- [x] **T13 — Append CHANGELOG.md `[0.2.5]` entry** — Insert new `## [0.2.5] - 2026-05-16` block at top of `CHANGELOG.md`, immediately above the existing `## [0.2.4]` block. Three subsections: `### Added` (lists `scripts/gen-demo-gif.py` + `scripts/validate-dod.d/*.sh` modules), `### Changed` (demo GIF refreshed; version label removed from GIF; `scripts/validate-dod.sh` thinned to ≤60-line orchestrator), `### Rationale` (closes 2 v0.2.4 retro follow-ups; no behavior change). Files: `CHANGELOG.md`. Verify: (a) `grep -c "^## \[0.2.5\] - 2026-05-16" CHANGELOG.md` returns exactly 1; (b) the new block's grep-line-number is less than the existing `## [0.2.4]` block's grep-line-number (order-based, not hard-coded line 8).
- [x] **T2 — Run `python3 scripts/gen-demo-gif.py docs/assets/hackify-demo.gif`** — Execute the generator from repo root. Produces or overwrites `docs/assets/hackify-demo.gif`. Confirm metadata with the Pillow one-liner from AC4. Files: `docs/assets/hackify-demo.gif` (regenerated binary). Wave 2.
- [x] **T15 — Run `bash scripts/sync-runtimes.sh`** — Mirror new plugin.json + marketplace.json versions across 7 runtime distributions. Confirm exit 0. Wave 2.
- [x] **T14 — Run `bash scripts/validate-dod.sh`** — Final verification: all 34 check groups pass. Must exit 0; `ALL CHECKS PASSED` printed. Wave 3.

## Daily Updates

### 2026-05-16 — Wave 1 (parallel canonical edits, 12 tasks)
All 12 wave-task-implementer agents returned DONE. T1 wrote `scripts/gen-demo-gif.py` (153 LOC; main 21 LOC; ≤3 params, ≤3 nesting). T3 extracted 10 helpers into `00-helpers.sh` (90 LOC; check_role 16 LOC max). T4–T10 extracted check groups [1]–[35] across 7 modules (max 188 LOC `20-templates.sh` with shared template-state arrays). T11 rewrote validate-dod.sh as 43-LOC orchestrator with 8 explicit `source` calls. T12 bumped both manifests to 0.2.5. T13 inserted CHANGELOG `[0.2.5]` entry.

### 2026-05-16 — Wave 2 (parallel, 2 tasks)
T15 sync-runtimes — 138 files across 7 runtimes. T2 ran `gen-demo-gif.py` → 7-frame GIF (NOT 8 — Pillow collapses byte-identical consecutive frames even with `optimize=False`). Patched script + AC3/AC4 + CHANGELOG mid-flight to align on 7 frames.

### 2026-05-16 — Wave 3 (verify)
T14 `bash scripts/validate-dod.sh` exits 0; ALL CHECKS PASSED across all 34 check groups distributed in 7 modules (1 helpers module + 7 check modules). Modular orchestrator validates identically to the pre-refactor 723-line monolith.

### 2026-05-16 — Phase 5 multi-reviewer + patches
3 reviewers returned APPROVED-WITH-PATCHES. 4 Important findings patched: (1) `gen-demo-gif.py:134` stale "Build 8 frames" docstring → "Build 7 frames (6 phase highlights + 1 settle)"; (2) `gen-demo-gif.py` argv parsing gains a dev-only safety comment about untrusted argv being out of scope; (3) `00-helpers.sh` `check_no_token` switches `grep -rci` → `grep -rcFi` for symmetry with `check_token_present`'s fixed-string mode; (4) work-doc Approach section "8 frame" drift replaced with "7 frame". Re-validation: ALL CHECKS PASSED.

## Sprint Review

- **Phase 2.5 spec self-review** — 3 reviewers; verdicts NEEDS-REWORK (Rules — 3 Criticals) + APPROVED-WITH-PATCHES (Consistency — 2 Importants) + APPROVED-WITH-PATCHES (Dependencies — 2 Importants). All 3 Criticals + 4 Importants patched into the work-doc before Phase 3 dispatch: AC5 deleted (binary GIF grep was a no-op), AC7 cap relaxed from 200→250 to accommodate shared template-state in `20-templates.sh`, T5 instructions tightened to NOT redefine `section_body`/`check_role`, AC1 added main() LOC verification, T1 mandated Pillow docstring declaration, T13 swapped brittle line-8 assertion for order-based check.
- **Phase 3 implementation** — 12 parallel wave-task agents in one message; all 12 returned DONE with file allowlists respected. Largest module 188 LOC (`20-templates.sh`), smallest 48 LOC (`40-quick-skill.sh`); orchestrator 43 LOC. Total bash code in the new modular layout: ~720 LOC across 9 files (1 orchestrator + 8 modules), down from 723 LOC in one file.
- **Phase 4 verify** — `bash scripts/validate-dod.sh` exits 0 on first run. All 34 check groups pass via the new sourced-module architecture.
- **Phase 5 multi-reviewer** — 3 parallel reviewers returned APPROVED-WITH-PATCHES; 4 Importants patched in-place. Path-traversal risk in `gen-demo-gif.py` accepted as Important-with-doc-comment (dev-only tool, untrusted argv not in scope).
- **Phase 6** — user chose option 1 (commit + push). Single conventional commit on main, push to origin/main, work-doc archived.

## Retrospective

- **Surprised — Pillow GIF encoder collapses identical frames.** Even with `optimize=False`, Pillow's GIF89a encoder dedupes byte-identical consecutive frames. Two `render_frame(-1)` settle calls produced an 8-frame intent but a 7-frame actual GIF. Fix: drop the duplicate settle frame and accept 7 frames as the design. Patched script + AC3 + AC4 + CHANGELOG mid-flight. Future GIF design should account for this encoder behavior or render frame-7 with subtle pixel variation.
- **Surprised — Phase 2.5 saved a full wave of rework.** Reviewer B (Rules) caught the AC5 binary-grep no-op, AC7 module-size mismatch, and T3↔T5 helper duplication risk BEFORE Phase 3 dispatch. Without the spec-review gate, T5 would have shipped a `20-templates.sh` that redefined `section_body` and `check_role`, causing source-order errors at T14. Phase 2.5 is genuinely load-bearing for refactors, not just spec drafts.
- **Surprised — `20-templates.sh` was the structural hot spot.** The shared template-state arrays (`ALL_TEMPLATES`, `REVIEW_TEMPLATES`, `BUILD_TEMPLATES`, `WIZARD_BANKS`, `CANONICAL_SEVERITY`, `ALLOWLIST`) defined inside check `[8]`'s body are consumed by `[9]`–`[15]`. Splitting `20-templates.sh` into two modules would have orphaned the arrays from their consumers — a hidden cross-module dependency that only surfaced when Reviewer C built the dependency graph in Phase 2.5.
- **Quality nit accepted — `[14]` out of numeric order.** Reviewer C flagged that `[14]` runs after `[15]` in `20-templates.sh` (preserved from the original monolith's line 468 position). The numeric-order break is cosmetic; check `[14]` (wizard structural conformance) shares no state with neighboring checks. Decision: preserve the original execution timing rather than renumber.
- **What to remember — pixel-rendered text needs visual verification, not byte greps.** The deleted AC5 (`grep -c "v0.2.1" docs/assets/hackify-demo.gif`) would have passed even on an unrefreshed GIF because GIF stores compressed pixels, not ASCII glyph names. AC2's "title 'Hackify' (NO version number)" is the real visual guard; future GIF-related ACs should use Pillow metadata checks or human-visible-output assertions, never binary greps for rendered text.
- **What to remember — version-bump events no longer require GIF refresh.** With the version label removed from the GIF (per Q1), `MEMORY.md`'s "refresh on phases/version/install changes" can drop the version trigger. Phases unchanged → no refresh needed. Install commands unchanged → no refresh needed. Net win: 1 fewer thing to keep in sync per release.
- **Follow-up logged — `gen-demo-gif.py` argv hardening.** Phase 5 security reviewer flagged the dev-only-tool path-traversal vector. Documented as dev-only with an inline comment. A proper fix (resolve + assert within repo root) is appropriate IF this script ever runs from CI or accepts untrusted input. Not blocking v0.2.5.

## Summary of changes shipped

| Area | Change |
|---|---|
| `GIF refresh` | `docs/assets/hackify-demo.gif` regenerated. Title is just "Hackify" — version label removed forever. 1200×675, 7 frames @ 600 ms, infinite loop. |
| `GIF generator (new)` | `scripts/gen-demo-gif.py` (153 LOC, Pillow-based) committed as the canonical source. Future regenerations: `python3 scripts/gen-demo-gif.py`. Solves the v0.2.1 "no source committed" gap. |
| `validate-dod refactor` | `scripts/validate-dod.sh` shrunk from 723 LOC → 43 LOC. Pure orchestrator: define vars, `cd` to repo root, explicit `source` of 8 named modules, summary block. |
| `validate-dod modules (new)` | 8 new files in `scripts/validate-dod.d/`: `00-helpers.sh` (color printers + 7 check helpers), 7 check modules grouping the 34 check groups by responsibility (required-files, templates, version+summary, quick-skill, runtimes+companions, primitives, invariants+yolo). |
| `check group preservation` | All 34 check groups (indices 1–35 minus 27) preserved exactly. Execution order identical except `[14]` now runs after `[15]` (was original out-of-order position in the monolith). |
| `helper extraction` | `section_body` and `check_role` moved from inline-inside-checks to `00-helpers.sh`. Zero duplicate definitions across the module set. |
| `lint discipline` | Zero `shellcheck disable` directives anywhere. Orchestrator uses explicit named sources (not glob), so SC1090 doesn't fire. |
| `helper hardening` | `check_no_token` switched from `grep -rci` to `grep -rcFi` for symmetry with `check_token_present`'s fixed-string mode (prevents regex meta-char false matches on future tokens). |
| `Pillow encoder note` | Documented that GIF encoder collapses byte-identical consecutive frames; 7-frame design honors this. |
| `Version bump` | `0.2.4` → `0.2.5` in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json`. |
| `CHANGELOG` | New `## [0.2.5] - 2026-05-16` entry with `Added`, `Changed`, `Rationale` subsections. |
| `Runtime distribution` | `bash scripts/sync-runtimes.sh` re-synced 138 files across 7 runtimes. |
| `Validation` | `bash scripts/validate-dod.sh` exits 0; all 34 check groups pass via the new modular orchestrator. |
