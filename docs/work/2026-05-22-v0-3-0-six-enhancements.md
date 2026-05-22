---
slug: v0-3-0-six-enhancements
title: v0.3.0 — six plugin enhancements (validator cap + sync prune + marketplace pin + collisions + evals + label sweep)
status: planning
type: feature
created: 2026-05-22
project: hackify
current_task: T0.1
worktree: null
branch: main
sprint_goal: Ship v0.3.0 with all six flagged enhancements: file-size-cap validator, prune-on-mirror, two-channel marketplace pin + `scripts/release.sh`, collision-detection, evals for 6 non-hackify skills, README version-label sweep. Eat own dog food by tagging the release via the new `release.sh`.
---

## Original Ask

> do you think the plugin has something that needs enhancement and why
>
> all of them

## Clarifying Q&A

- **Q1 — sync-runtimes.sh 528-LOC violation?** A: split during this sprint (modular `scripts/sync-runtimes.d/<runtime>.sh` mirroring the validate-dod.d pattern).
- **Q2 — marketplace tag-pin shape?** A: two entries — `hackify` (tag-pinned to latest release) + `hackify-edge` (ref: main).
- **Q3 — Tag-on-version-bump discipline?** A: `scripts/release.sh` helper. Manual invocation, single command, no CI dependency.
- **Q4 — README version-label sweep style?** A: convert all stale labels to "(since vX.Y.Z)" framing, preserving introduction-version provenance.
- **Defaults applied (no pushback):** validator cap scope = `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/`, plus `skills/*/references/`; prune strategy = `rm -rf dist/<runtime>/skills/` before each mirror run; collision-detection wired as soft warning (non-fatal); eval depth = 3 cases per skill (happy + edge + non-trigger); single v0.3.0 release on main, no feature branch.

## Acceptance Criteria

- [ ] `scripts/sync-runtimes.sh` is ≤500 LOC after split; per-runtime emitters extracted to `scripts/sync-runtimes.d/<runtime>.sh`; original output preserved (270 files mirrored across 7 runtimes; idempotent on second run).
- [ ] `scripts/validate-dod.d/80-file-size-caps.sh` exists, runs as part of `validate-dod.sh`, and fails red on any file >500 LOC across `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/`, plus `skills/*/references/`.
- [ ] `scripts/sync-runtimes.sh` (post-split orchestrator) prunes `dist/<runtime>/skills/` before each mirror; renaming a source skill no longer leaves stale destination dirs.
- [ ] `.claude-plugin/marketplace.json` declares two plugin entries: `hackify` (tag-pinned to `v0.3.0`) + `hackify-edge` (ref: main). Both reference the same source URL.
- [ ] `scripts/release.sh` exists, reads `version` from `.claude-plugin/plugin.json`, asserts the tag does not already exist (locally OR on origin), refuses on dirty working tree (`git status --porcelain` non-empty), refuses on missing/empty `version` field, creates annotated `v<version>` tag at HEAD with message `Release v<version>`, prints the planned commands, prompts before pushing, and surfaces a clear rollback hint on push failure (leaves the local tag in place, does not auto-delete).
- [ ] `scripts/release.sh` supports a `--dry-run` flag that prints the tag + push commands without executing.
- [ ] `scripts/check-collisions.sh` handles four empty-state branches gracefully: missing `~/.claude/plugins/`, empty `~/.claude/plugins/cache/`, plugin dir present but zero `SKILL.md` files, malformed frontmatter (no `name:` line). Each branch prints one informational line and exits 0 — never errors.
- [ ] Each `evals/evals.json` conforms to the exact top-level schema of `skills/hackify/evals/evals.json`: top-level keys `skill_name` (string) and `evals` (array); each eval object has `id` (int), `name` (kebab-case string), `prompt` (string), `assertions` (array of `{text: string}`), and `files` (array, may be empty). Deviation fails review.
- [ ] `scripts/sync-runtimes.d/00-helpers.sh` exports the complete helper surface used by every per-runtime emitter — `mirror_canonical_files`, `prune_runtime_dist`, `write_install_notes`, `print_runtime_summary`, plus the existing color printers and `MIRROR_SOURCES` / `CLAUDE_CODE_EXTRA` arrays. No per-runtime emitter contains logic that already exists in `00-helpers.sh` (DRY-violation gate).
- [ ] `scripts/check-collisions.sh` exists, scans installed Claude Code plugins under `~/.claude/plugins/`, extracts every `name:` from `*/SKILL.md` frontmatter, and reports substring overlaps with hackify's seven slugs (`hackify`, `quick`, `yolo`, `groom`, `skillsmith`, `review-triage`, `codewalk`).
- [ ] `scripts/validate-dod.d/90-collisions.sh` invokes `check-collisions.sh` as a soft warning — prints `WARN` lines but never exits non-zero (so a hostile sibling can't break our CI).
- [ ] Each of the 6 non-hackify skills (`groom`, `skillsmith`, `review-triage`, `codewalk`, `yolo`, `quick`) has `evals/evals.json` with 3 cases (1 happy-path trigger + 1 edge case + 1 explicit non-trigger), schema-compatible with `skills/hackify/evals/evals.json`.
- [ ] `README.md` has zero stale current-version labels — `(v0.2.2)` reads `(since v0.2.2)`; `Hackify v0.2.0 ships for seven runtimes` reads `Hackify ships for seven runtimes (since v0.2.0)`; equivalent treatment for every other in-prose version label.
- [ ] `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (both entries) + README badge bumped to `0.3.0` in lockstep.
- [ ] `CHANGELOG.md` has a `## [0.3.0] - 2026-05-22` entry documenting the six enhancements + rationale, ASCII-hyphen date separator, ordered above `[0.2.9]`.
- [ ] `bash scripts/validate-dod.sh` exits 0 with `ALL CHECKS PASSED` (including new check 80 file-size + 90 collisions soft-warning).
- [ ] `bash scripts/sync-runtimes.sh` runs twice idempotently with 270-file output, no stale dist dirs.
- [ ] `scripts/release.sh` is dog-fooded to ship v0.3.0 — manually invoked, creates `v0.3.0` tag, pushes main + tag to origin.

## Approach

Strict order matters: the sync-runtimes.sh split (W1) MUST land before the file-size cap validator (W3) goes live, otherwise the validator fails red on the orchestrator's current 528 LOC and blocks every subsequent CI run. Once that prerequisite is in place, four mostly-independent enhancement bundles (validator cap, prune, marketplace+release, collisions, evals, label sweep) parallelize across waves.

Parallel-agent dispatch IS worthwhile for this sprint — the eval-authoring work alone is 6 independent JSON files, the collision-detection has 2 independent scripts, and the README sweep is its own file. Phase 2.5 spec-review (3 parallel reviewers) is mandatory per hackify; Phase 5 multi-reviewer (3 parallel reviewers) is also mandatory given the diff size will exceed the one-line-typo carve-out.

## Execution waves

- **W1a — Author shared helpers (1 task, sequential).** T1.1 — `scripts/sync-runtimes.d/00-helpers.sh` defines the full helper surface that per-runtime emitters depend on.
- **W1b — Author 7 per-runtime emitters (parallel, depends on W1a).** T1.2 — each emitter sources `00-helpers.sh` (existence dependency); 7 truly independent files, batch-dispatched.
- **W1c — Slim orchestrator (1 task, sequential, depends on W1b).** T1.3 — orchestrator sources helpers + all 7 emitters; must land after both are stable.
- **W2 — Verify split (sequential).** T2.1 — run `bash scripts/sync-runtimes.sh` twice; 270 files, idempotent, byte-identical to pre-split spot-checks.
- **W3a — 8 independent new files in parallel.** T3.3a + T3.3b (release.sh base + edge-cases), T3.4 (check-collisions.sh), T3.6–T3.11 (6 eval JSONs). Zero file overlap, no inter-task dep.
- **W3b — Touch sync-runtimes.sh + README (parallel, depends on W1c + W2).** T3.2 (prune step in orchestrator) + T3.12 (README label sweep). Different files; W3b runs after W1c so the orchestrator surface is stable.
- **W3c — Wire-up tasks (parallel, depends on W3a + W3b).** T3.1 (file-size cap validator — depends on W1c + T3.2 keeping orchestrator ≤500 LOC) + T3.5 (collision soft-warning wrapper — depends on T3.4 artifact existing).
- **W4 — Version bump + marketplace + CHANGELOG (parallel, depends on W3c).** T4.1 (marketplace two-entry rewrite) + T4.2 (version bump + README badge, after T3.12 README sweep) + T4.3 (CHANGELOG entry).
- **W5 — Verify + ship (sequential).** T5.1 → T5.2 → T5.3 → T5.4. Dog-food `scripts/release.sh` to tag + push.

## Sprint Backlog

### W1a — shared helpers (prerequisite for W1b)

- [ ] **T1.1** — Create `scripts/sync-runtimes.d/00-helpers.sh` exporting the full helper surface used by every per-runtime emitter: `MIRROR_SOURCES` array, `CLAUDE_CODE_EXTRA` array, `write_or_announce_copy()`, `mirror_canonical_files()`, `prune_runtime_dist()` (rm -rf `dist/<runtime>/skills/`), `write_install_notes()` shared wrapper, `print_runtime_summary()`, plus color printers. Files: `scripts/sync-runtimes.d/00-helpers.sh` (new). → verify: file exists, sourceable in isolation, defines all 8 expected symbols, file ≤500 LOC.

### W1b — per-runtime emitters (parallel, depends on W1a)

- [ ] **T1.2** — Create 7 per-runtime emitter modules in one parallel batch: `scripts/sync-runtimes.d/{claude-code,codex-cli,codex-app,gemini-cli,opencode,cursor,copilot-cli}.sh`. Each module sources `00-helpers.sh` (existence checked), contains ONLY runtime-specific install-notes prose + the call to `mirror_canonical_files <runtime>` + any per-runtime extras (e.g., claude-code mirrors `CLAUDE_CODE_EXTRA`). No duplicated mirror/prune/summary logic — those live in helpers. Files: 7 new files under `scripts/sync-runtimes.d/`. → verify: each file ≤500 LOC (target ≤120 LOC each), sources 00-helpers, defines an `emit_<runtime>()` function, contains no copy of any helper logic (grep guard against re-defining symbols from 00-helpers).

### W1c — slim orchestrator (sequential, depends on W1b)

- [ ] **T1.3** — Slim `scripts/sync-runtimes.sh` orchestrator to ≤150 LOC: source `00-helpers.sh` + all 7 per-runtime modules, dispatch each runtime's `emit_<runtime>` function, print final summary. Files: `scripts/sync-runtimes.sh`. → verify: file ≤150 LOC, output of orchestrator identical to pre-split (270 files across 7 runtimes), exit 0.

### W2 — verify split

- [ ] **T2.1** — `bash scripts/sync-runtimes.sh` first run produces 270 files; second run produces zero diff (idempotent). Spot-check 3 random files in `dist/claude-code/`, `dist/cursor/`, `dist/gemini-cli/` against pre-split content. → verify: byte-identical for the spot-checked files.

### W3a — 8 independent new files (parallel, depends on W2)

- [ ] **T3.3a (enhancement #3b base)** — Create `scripts/release.sh`: reads `version` from `.claude-plugin/plugin.json` via `jq` or `grep`-fallback, refuses on empty/missing `version`, asserts no `v<version>` tag exists locally (`git tag -l`) AND on origin (`git ls-remote --tags origin v<version>`), refuses on dirty working tree (`git status --porcelain` non-empty), creates annotated tag at HEAD with message `Release v<version>`, prints planned `push` commands, prompts before executing. On push failure: leave local tag in place, print rollback hint `git tag -d v<version>`. Files: `scripts/release.sh` (new). → verify: file exists, executable, runs without error against a freshly-tagged state and exits with a clear "tag already exists" message.
- [ ] **T3.3b (enhancement #3b dry-run)** — Add `--dry-run` flag to `scripts/release.sh` that prints all tag + push commands without executing. Files: `scripts/release.sh`. → verify: `bash scripts/release.sh --dry-run` exits 0 and prints commands; no tag created; no push attempted.
- [ ] **T3.4 (enhancement #4a)** — Create `scripts/check-collisions.sh`: discovers installed Claude Code plugins under `~/.claude/plugins/cache/*/*/`, extracts every `name:` frontmatter value from `*/SKILL.md` files, compares against hackify's 7 slugs (`hackify`, `quick`, `yolo`, `groom`, `skillsmith`, `review-triage`, `codewalk`). Reports `EXACT MATCH` / `SUBSTRING OVERLAP` / `OK` per slug. Handles 4 empty-state branches gracefully: missing `~/.claude/plugins/`, empty `~/.claude/plugins/cache/`, zero `SKILL.md` files in any plugin dir, malformed frontmatter (no `name:` line). Each branch prints ONE informational line and exits 0 — never errors. Files: `scripts/check-collisions.sh` (new). → verify: file exists, executable, runs cleanly on this machine producing a report; spot-check with a temporarily-renamed plugin dir confirms graceful empty-state handling.
- [ ] **T3.6 (enhancement #5a)** — Author `skills/groom/evals/evals.json` with 3 cases: (1) happy: "let's discuss adding rate limiting"; (2) edge: "groom this backlog item"; (3) non-trigger: "add rate limiting" (should route to hackify, NOT groom). Schema matches `skills/hackify/evals/evals.json` exactly. Files: `skills/groom/evals/evals.json` (new). → verify: valid JSON; top-level keys `skill_name`+`evals`; each eval has `id`+`name`+`prompt`+`assertions[].text`+`files`; assertions array ≥3 items per case.
- [ ] **T3.7 (enhancement #5b)** — Author `skills/skillsmith/evals/evals.json` (happy: "author a new hackify skill"; edge: "make a hackify-style skill"; non-trigger: "write a script that…"). Files: `skills/skillsmith/evals/evals.json` (new). → verify: same schema as T3.6.
- [ ] **T3.8 (enhancement #5c)** — Author `skills/review-triage/evals/evals.json` (happy: paste of mock review findings + "respond to these"; edge: "address review findings"; non-trigger: "review this PR"). Files: `skills/review-triage/evals/evals.json` (new). → verify: same schema as T3.6.
- [ ] **T3.9 (enhancement #5d)** — Author `skills/codewalk/evals/evals.json` (happy: "walk me through the login flow"; edge: "trace this call stack from POST /api/orders"; non-trigger: "explain why this test fails"). Files: `skills/codewalk/evals/evals.json` (new). → verify: same schema as T3.6.
- [ ] **T3.10 (enhancement #5e)** — Author `skills/yolo/evals/evals.json` (happy: "yolo — add this feature"; edge: "go full auto"; non-trigger: "do it" — too ambiguous per yolo's description). Files: `skills/yolo/evals/evals.json` (new). → verify: same schema as T3.6.
- [ ] **T3.11 (enhancement #5f)** — Author `skills/quick/evals/evals.json` (happy: "quick fix the typo on line 42"; edge: "small change to the README"; non-trigger: "refactor everywhere" — full hackify territory). Files: `skills/quick/evals/evals.json` (new). → verify: same schema as T3.6.

### W3b — touch shared files (parallel, depends on W1c + W2)

- [ ] **T3.2 (enhancement #2)** — Wire `prune_runtime_dist()` (already authored in T1.1 helpers) into `scripts/sync-runtimes.sh` orchestrator — call it as the first action of each per-runtime dispatch loop iteration before the emitter runs. Files: `scripts/sync-runtimes.sh`. → verify: `grep -c prune_runtime_dist scripts/sync-runtimes.sh` returns ≥1; running orchestrator twice still produces idempotent 270-file output; deleting a known dist file then re-running orchestrator restores it (proves prune-then-mirror works).
- [ ] **T3.12 (enhancement #6)** — Sweep `README.md` for stale current-version-implying labels: `(v0.2.2)` → `(since v0.2.2)`, `Hackify v0.2.0 ships for seven runtimes` → `Hackify ships for seven runtimes (since v0.2.0)`, `(v0.2.0) sprint vocabulary` → `(since v0.2.0) sprint vocabulary`, plus equivalent treatment for the other 4 in-prose `vX.Y.Z` mentions. Files: `README.md`. → verify: `grep -nE '\(v0\.[0-9]+\.[0-9]+\)' README.md` returns 0 hits (the parens-only form no longer appears); current-version surface is limited to the badge, the Install snippet, and the plugin.json link.

### W3c — wire-up (parallel, depends on W3a + W3b)

- [ ] **T3.1 (enhancement #1)** — Create `scripts/validate-dod.d/80-file-size-caps.sh`. Iterate `find skills agents rules scripts hooks commands -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \)`, plus `skills/*/references/`. For each, fail red if `wc -l < file` > 500. Sources `00-helpers.sh` color printers. Depends on W1c + T3.2 keeping the orchestrator ≤500 LOC. Files: `scripts/validate-dod.d/80-file-size-caps.sh` (new). → verify: module exists, has `[80]` check group header, exits 0 against the current post-split tree; deliberately oversize a temp file and confirm check fails red.
- [ ] **T3.5 (enhancement #4b)** — Create `scripts/validate-dod.d/90-collisions.sh`: invokes `scripts/check-collisions.sh` (T3.4 artifact, must exist), captures output, prints any `WARN` / `SUBSTRING OVERLAP` lines in yellow, always exits 0 (soft warning). Files: `scripts/validate-dod.d/90-collisions.sh` (new). → verify: module exists, has `[90]` check group header, returns 0 even if check-collisions reports overlap.

### W4 — version bump + marketplace + CHANGELOG

- [ ] **T4.1** — Rewrite `.claude-plugin/marketplace.json` as a two-entry array: entry 1 `name: hackify` with `ref: v0.3.0`, entry 2 `name: hackify-edge` with `ref: main`. Both reference the same source URL. Files: `.claude-plugin/marketplace.json`. → verify: parses as JSON, has 2 plugin entries with distinct names + refs.
- [ ] **T4.2** — Bump `.claude-plugin/plugin.json` to `version: 0.3.0`; bump README badge to `version-0.3.0`. Files: `.claude-plugin/plugin.json`, `README.md`. → verify: both JSONs report 0.3.0; badge URL contains 0.3.0.
- [ ] **T4.3** — Write `CHANGELOG.md` `## [0.3.0] - 2026-05-22` entry under Added (validator check, release script, collision script, eval files), Changed (sync-runtimes.sh split + prune, marketplace two-entry rewrite, README label framing), Rationale (close known gaps + dog-food the release script). Files: `CHANGELOG.md`. → verify: entry above [0.2.9]; ASCII-hyphen date format; 8+ bullets across Added + Changed.

### W5 — verify + ship

- [ ] **T5.1** — Run `bash scripts/sync-runtimes.sh` twice; confirm 270 files, zero diff on second run, no stale dist dirs. → verify: `find dist -type d -name brainstorm -o -name writing-skills -o -name receiving-code-review` returns 0 paths.
- [ ] **T5.2** — Run `bash scripts/validate-dod.sh`; expect `ALL CHECKS PASSED` including new `[80]` file-size + `[90]` collisions soft-warning. → verify: exit 0; output includes both new check group headers.
- [ ] **T5.3** — Commit all changes with conventional subject `feat: v0.3.0 — six enhancements …`. → verify: `git log --oneline -1` shows the commit on main.
- [ ] **T5.4** — Dog-food `bash scripts/release.sh`: reads 0.3.0 from plugin.json, creates `v0.3.0` annotated tag at HEAD, pushes main + tag. → verify: `git tag -l v0.3.0` exists locally; `git ls-remote --tags origin v0.3.0` shows the tag at origin.

## Daily Updates

_(populated as waves complete)_

## Sprint Review

_(populated at Phase 4)_

## Retrospective

_(populated at Phase 6)_
