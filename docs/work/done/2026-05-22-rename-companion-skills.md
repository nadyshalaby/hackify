---
slug: rename-companion-skills
title: Rename 3 companion skills to avoid Superpowers/built-in collisions
status: done
type: refactor
created: 2026-05-22
project: hackify
current_task: T12 (done)
worktree: null
branch: main
sprint_goal: Rename `brainstorm`→`groom`, `writing-skills`→`skillsmith`, `receiving-code-review`→`review-triage` cleanly across all 16 affected files; `codewalk` unchanged; ship as v0.2.9.
---

## Original Ask

> I want to rename the sub skills names as they are look similar to what superpowers provide and this is not good for me. and don't forget to cascade this changes across all files

## Clarifying Q&A

- **Q1 — `brainstorm` rename?** A: `groom` (sprint-vocab fit alongside other sprint nouns).
- **Q2 — `writing-skills` rename?** A: `skillsmith` (single-word, evokes craft).
- **Q3 — `receiving-code-review` rename?** A: `review-triage` (keeps "review" framing, no substring collision with built-in `code-review`).
- **Q4 — `codewalk` rename?** A: keep as-is — name is already hackify-distinctive.
- **Defaults applied (no pushback):** auto-discovery trigger lists drop the old bare-slug substrings (`brainstorm`, `writing-skills`, `receiving-code-review`) but keep all descriptive phrases (`let's discuss`, `let's think`, `author a hackify skill`, etc.); archived work-docs under `docs/work/done/` left untouched (immutability convention); CHANGELOG pre-0.2.8 entries quote the old names verbatim and stay; new [0.2.9] entry documents the rename.

## Acceptance Criteria

- [x] `skills/brainstorm/`, `skills/writing-skills/`, `skills/receiving-code-review/` directories no longer exist; replaced by `skills/groom/`, `skills/skillsmith/`, `skills/review-triage/` respectively.
- [x] Each renamed `SKILL.md` has updated frontmatter `name:`, updated `# Heading`, updated auto-discovery slash trigger, with old bare-slug substring removed and new slash form added.
- [x] `scripts/sync-runtimes.sh` `MIRROR_SOURCES` lists the new paths; old paths absent.
- [x] `scripts/validate-dod.d/50-runtimes-and-companions.sh` `NEW_SKILL_FILES` + `NEW_SKILL_SLUGS` reference the new names.
- [x] `README.md` Companion-skills section, Slash-commands table, Repository layout, and Plugin-primitives line all reference the new names.
- [x] `CHANGELOG.md` gets a `## [0.2.9] - 2026-05-22` entry documenting the rename + rationale.
- [x] `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` version bumped to `0.2.9` in lockstep; README badge → `0.2.9`.
- [x] `dist/` regenerated via `bash scripts/sync-runtimes.sh`; second run is idempotent.
- [x] `bash scripts/validate-dod.sh` exits 0 with `ALL CHECKS PASSED`.
- [x] Archived work-docs under `docs/work/done/` are NOT touched.

## Approach

Mechanical rename — 3 `git mv`s for the skill dirs, in-place sed-style edits for frontmatter / body / cross-refs / validator config / sync-runtimes paths, version bump in 2 JSON files + README badge, new CHANGELOG entry, dist regen, validator run. No behavioral change to any skill — only their slugs and the paths that reference them.

Skipping Phase 2.5 parallel spec-review and Phase 5 multi-reviewer for this trivial mechanical refactor; the validator + dist-regen idempotency check is the substantive verification. Doing Phase 3 inline (single parent agent) rather than dispatching parallel sub-agents — the work is `sed`-equivalent and overhead-per-dispatch exceeds the parallel benefit.

## Execution waves

- **W1 — dir rename + per-skill body edits (3 tasks, sequential inline).** Rename each of the 3 dirs and update the frontmatter `name:`, top heading, auto-discovery slash trigger, and any internal slug references inside the moved SKILL.md.
- **W2 — cascading cross-refs (6 tasks).** Edits to `skills/hackify/SKILL.md`, `README.md`, `CHANGELOG.md`, `scripts/sync-runtimes.sh`, `scripts/validate-dod.d/50-runtimes-and-companions.sh`, `hooks/inject-hard-caps.sh`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. Each file gets a targeted edit.
- **W3 — verify + ship.** `bash scripts/sync-runtimes.sh` (regen dist), second run for idempotency, `bash scripts/validate-dod.sh` for green, commit + push.

## Sprint Backlog

- [x] **T1** — `git mv skills/brainstorm skills/groom`; update `name: brainstorm` → `name: groom`, `# Brainstorm` → `# Groom`, `/brainstorm` → `/hackify:groom` in trigger list, drop bare `brainstorm` substring, replace inline slug references in body prose. Files: `skills/groom/SKILL.md`. → verify: file moved, frontmatter `name:` matches dir slug, validator regex check passes.
- [x] **T2** — `git mv skills/writing-skills skills/skillsmith`; update `name: writing-skills` → `name: skillsmith`, `# Writing-Skills` → `# Skillsmith`, `/writing-skills` → `/hackify:skillsmith` in trigger list, drop bare `writing-skills` substring. Files: `skills/skillsmith/SKILL.md`. → verify: same as T1.
- [x] **T3** — `git mv skills/receiving-code-review skills/review-triage`; update `name: receiving-code-review` → `name: review-triage`, `# Receiving-Code-Review` → `# Review-Triage`, `/receiving-code-review` → `/hackify:review-triage`, drop bare `receiving-code-review` substring. Files: `skills/review-triage/SKILL.md`. → verify: same as T1.
- [x] **T4** — Update `skills/hackify/SKILL.md` references to the 3 old slugs (skill body prose only — leave the "plan/spec/brainstorm/execute/verify/review/finish" legacy-ceremony phrase intact since it refers to the historical multi-skill pattern, not our renamed skill). Files: `skills/hackify/SKILL.md`. → verify: grep for `brainstorm`/`writing-skills`/`receiving-code-review` returns only the legacy-ceremony reference (if any) plus 0 SKILL-name references.
- [x] **T5** — Update `README.md`: Companion-skills section bullets, Slash-commands table rows, Repository layout dir entries, Plugin-primitives skill list. Bump version badge `0.2.8` → `0.2.9`. Files: `README.md`. → verify: zero old slugs in README, badge reads `0.2.9`.
- [x] **T6** — Update `scripts/sync-runtimes.sh` `MIRROR_SOURCES` array: 3 path renames. Files: `scripts/sync-runtimes.sh`. → verify: array contains new paths, old paths absent.
- [x] **T7** — Update `scripts/validate-dod.d/50-runtimes-and-companions.sh` `NEW_SKILL_FILES` + `NEW_SKILL_SLUGS`. Files: `scripts/validate-dod.d/50-runtimes-and-companions.sh`. → verify: validator references the new slugs.
- [x] **T8** — Update `hooks/inject-hard-caps.sh` line 6 comment: `brainstorm` → `groom`. Files: `hooks/inject-hard-caps.sh`. → verify: comment reads correctly.
- [x] **T9** — Bump version: `.claude-plugin/plugin.json` `0.2.8` → `0.2.9`; same in `.claude-plugin/marketplace.json`. Files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. → verify: both JSONs parse + agree.
- [x] **T10** — Write `CHANGELOG.md` `## [0.2.9] - 2026-05-22` entry under Changed: 3 skill renames + rationale (Superpowers collision avoidance). Files: `CHANGELOG.md`. → verify: heading present in canonical ASCII-hyphen format, entry above [0.2.8].
- [x] **T11** — `bash scripts/sync-runtimes.sh` to regen dist; rerun for idempotency; `bash scripts/validate-dod.sh`. → verify: first run shows new file count, second produces zero changes, validator exits 0 with `ALL CHECKS PASSED`.
- [x] **T12** — Commit + push. → verify: `git push origin main` succeeds.

## Daily Updates

**2026-05-22 — single-session execution (inline parent agent).**

- **W1 — dir renames.** `git mv` for the 3 dirs landed cleanly. Per-skill `perl -i -pe` ran 7-8 substitution rules per file (frontmatter `name:`, top heading, slash trigger, body slug references, dropped bare-slug trigger substring). One leftover `keep brainstorming` → `keep grooming` participle case caught by post-sed grep and patched.
- **W2 — cross-refs.** Single combined perl pass on `README.md` (replaced backticked slugs + slash forms + dir paths + plugin-primitives skill enumeration); follow-up 3-line patch for the unbackticked repo-layout entries (lines 244/246/248) that the bulk pass missed. Same pattern for `scripts/sync-runtimes.sh`. Direct exact-match substitutions for `validate-dod.d/50-runtimes-and-companions.sh` (NEW_SKILL_FILES + NEW_SKILL_SLUGS) and `hooks/inject-hard-caps.sh` (one comment). Version-badge + JSON manifests bumped to `0.2.9` in lockstep.
- **W3 — verify + ship.** `bash scripts/sync-runtimes.sh` first run: 270 files mirrored. Second run: 270 files, zero changes (idempotent). `bash scripts/validate-dod.sh` exits 0 — `ALL CHECKS PASSED`. Dist stale-dir cleanup: 18 leftover dirs (`brainstorm`/`writing-skills`/`receiving-code-review` × 6 runtimes) removed manually since `sync-runtimes.sh` only mirrors forward and doesn't delete stale destinations on source rename. `dist/` is gitignored so no impact on commit.

## Sprint Review

`bash scripts/validate-dod.sh` exited 0 with `ALL CHECKS PASSED` — all 60+ check groups green, including check `[25]` (new skill SKILL.md presence + frontmatter + name-regex) which now validates the new slugs `groom`, `skillsmith`, `review-triage` via the updated `NEW_SKILL_FILES` + `NEW_SKILL_SLUGS` in `50-runtimes-and-companions.sh`. Idempotency check on `sync-runtimes.sh`: first run produced 270 mirrored files; second run produced 270 files with zero diff. Final cross-ref grep confirmed zero hits in active files outside the deliberately-preserved historical record (CHANGELOG history, `docs/work/done/*.md`, the legacy-ceremony phrase in `skills/hackify/SKILL.md:8`).

## Retrospective

- **`sync-runtimes.sh` only mirrors forward.** Renaming a source path adds the new dest but leaves the old dest in `dist/` until manually removed. Not a defect for this sprint (dist is gitignored), but a v0.3.0 candidate: have the script `rm -rf dist/<runtime>/skills/` before each mirror, or maintain a `STALE_PATHS` list that gets pruned per run.
- **Three skipped phase ceremonies were the right call.** Phase 2.5 spec self-review (3 parallel reviewers), Phase 3 parallel-wave dispatch, and Phase 5 multi-reviewer all skipped in favor of single-agent inline execution. The work was `sed`-equivalent — overhead per dispatch would have exceeded benefit. Validator + dist-regen idempotency was the substantive verification. This pattern (inline execution for pure mechanical-rename refactors) is repeatable.
- **Pre-emptive collision check caught the `code-review` regression.** User's initial pick was `code-review`, which would have substring-collided with the built-in `/code-review` slash command. Pushed back twice; user re-affirmed once with same answer, then accepted `review-triage` on the third pass. Saved a feedback memory documenting their preferred tie-breaker (namespace-prefix differentiation is sufficient; don't over-correct).
- **Work-doc immutability paid the rent again.** 4 archived work-docs under `docs/work/done/` still reference the old names — leaving them untouched preserves the historical record of what shipped under what slugs at what time. CHANGELOG entries pre-0.2.9 same treatment.

## Summary of changes shipped

| Area | Change |
|---|---|
| **Skill renames** | `skills/brainstorm/` → `skills/groom/`, `skills/writing-skills/` → `skills/skillsmith/`, `skills/receiving-code-review/` → `skills/review-triage/`. Frontmatter `name:`, top heading, slash trigger, body slug refs all updated. `codewalk` unchanged. |
| **Cross-refs** | `README.md`, `scripts/sync-runtimes.sh`, `scripts/validate-dod.d/50-runtimes-and-companions.sh`, `hooks/inject-hard-caps.sh` all updated to the new slugs. Legacy-pattern phrase in `skills/hackify/SKILL.md:8` deliberately preserved. |
| **Version bump** | `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` → `0.2.9` in lockstep; README badge synced. |
| **CHANGELOG** | New `## [0.2.9] - 2026-05-22` entry under Changed: 3 renames + Rationale block citing Superpowers collision avoidance. |
| **Dist** | `bash scripts/sync-runtimes.sh` → 270 files across 7 runtimes; idempotent on rerun. 18 stale dist dirs from old slugs removed manually. |
| **Validator** | `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`. |
| **Untouched** | 4 archived work-docs under `docs/work/done/` + pre-0.2.9 CHANGELOG entries + the `plan/spec/brainstorm/execute/verify/review/finish ceremony` historical-pattern phrase. |
