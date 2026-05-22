---
slug: v0-3-0-six-enhancements
title: v0.3.0 — six plugin enhancements (validator cap + sync prune + marketplace pin + collisions + evals + label sweep)
status: done
type: feature
created: 2026-05-22
project: hackify
current_task: T5.4 (done)
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

- [x] `scripts/sync-runtimes.sh` is ≤500 LOC after split; per-runtime emitters extracted to `scripts/sync-runtimes.d/<runtime>.sh`; original output preserved (270 files mirrored across 7 runtimes; idempotent on second run).
- [x] `scripts/validate-dod.d/80-file-size-caps.sh` exists, runs as part of `validate-dod.sh`, and fails red on any file >500 LOC across `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/`, plus `skills/*/references/`.
- [x] `scripts/sync-runtimes.sh` (post-split orchestrator) prunes `dist/<runtime>/skills/` before each mirror; renaming a source skill no longer leaves stale destination dirs.
- [x] `.claude-plugin/marketplace.json` declares two plugin entries: `hackify` (tag-pinned to `v0.3.0`) + `hackify-edge` (ref: main). Both reference the same source URL.
- [x] `scripts/release.sh` exists, reads `version` from `.claude-plugin/plugin.json`, asserts the tag does not already exist (locally OR on origin), refuses on dirty working tree (`git status --porcelain` non-empty), refuses on missing/empty `version` field, creates annotated `v<version>` tag at HEAD with message `Release v<version>`, prints the planned commands, prompts before pushing, and surfaces a clear rollback hint on push failure (leaves the local tag in place, does not auto-delete).
- [x] `scripts/release.sh` supports a `--dry-run` flag that prints the tag + push commands without executing.
- [x] `scripts/check-collisions.sh` handles four empty-state branches gracefully: missing `~/.claude/plugins/`, empty `~/.claude/plugins/cache/`, plugin dir present but zero `SKILL.md` files, malformed frontmatter (no `name:` line). Each branch prints one informational line and exits 0 — never errors.
- [x] Each `evals/evals.json` conforms to the exact top-level schema of `skills/hackify/evals/evals.json`: top-level keys `skill_name` (string) and `evals` (array); each eval object has `id` (int), `name` (kebab-case string), `prompt` (string), `assertions` (array of `{text: string}`), and `files` (array, may be empty). Deviation fails review.
- [x] `scripts/sync-runtimes.d/00-helpers.sh` exports the complete helper surface used by every per-runtime emitter — `mirror_canonical_files`, `prune_runtime_dist`, `write_or_announce_heredoc` (used by emitters to write install-notes from a template file or heredoc body), `print_runtime_summary`, plus the color printers (sourced from `scripts/lib/colors.sh`) and `MIRROR_SOURCES` / `CLAUDE_CODE_EXTRA` arrays. No per-runtime emitter contains logic that already exists in `00-helpers.sh` (DRY-violation gate).
- [x] `scripts/check-collisions.sh` exists, scans installed Claude Code plugins under `~/.claude/plugins/`, extracts every `name:` from `*/SKILL.md` frontmatter, and reports substring overlaps with hackify's seven slugs (`hackify`, `quick`, `yolo`, `groom`, `skillsmith`, `review-triage`, `codewalk`).
- [x] `scripts/validate-dod.d/90-collisions.sh` invokes `check-collisions.sh` as a soft warning — prints `WARN` lines but never exits non-zero (so a hostile sibling can't break our CI).
- [x] Each of the 6 non-hackify skills (`groom`, `skillsmith`, `review-triage`, `codewalk`, `yolo`, `quick`) has `evals/evals.json` with 3 cases (1 happy-path trigger + 1 edge case + 1 explicit non-trigger), schema-compatible with `skills/hackify/evals/evals.json`.
- [x] `README.md` has zero stale current-version labels — `(v0.2.2)` reads `(since v0.2.2)`; `Hackify v0.2.0 ships for seven runtimes` reads `Hackify ships for seven runtimes (since v0.2.0)`; equivalent treatment for every other in-prose version label.
- [x] `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (both entries) + README badge bumped to `0.3.0` in lockstep.
- [x] `CHANGELOG.md` has a `## [0.3.0] - 2026-05-22` entry documenting the six enhancements + rationale, ASCII-hyphen date separator, ordered above `[0.2.9]`.
- [x] `bash scripts/validate-dod.sh` exits 0 with `ALL CHECKS PASSED` (including new check 80 file-size + 90 collisions soft-warning).
- [x] `bash scripts/sync-runtimes.sh` runs twice idempotently with 270-file output, no stale dist dirs.
- [x] `scripts/release.sh` is dog-fooded to ship v0.3.0 — manually invoked, creates `v0.3.0` tag, pushes main + tag to origin.

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

- [x] **T1.1** — Create `scripts/sync-runtimes.d/00-helpers.sh` exporting the full helper surface used by every per-runtime emitter: `MIRROR_SOURCES` array, `CLAUDE_CODE_EXTRA` array, `write_or_announce_copy()`, `mirror_canonical_files()`, `prune_runtime_dist()` (rm -rf `dist/<runtime>/skills/`), `write_install_notes()` shared wrapper, `print_runtime_summary()`, plus color printers. Files: `scripts/sync-runtimes.d/00-helpers.sh` (new). → verify: file exists, sourceable in isolation, defines all 8 expected symbols, file ≤500 LOC.

### W1b — per-runtime emitters (parallel, depends on W1a)

- [x] **T1.2** — Create 7 per-runtime emitter modules in one parallel batch: `scripts/sync-runtimes.d/{claude-code,codex-cli,codex-app,gemini-cli,opencode,cursor,copilot-cli}.sh`. Each module sources `00-helpers.sh` (existence checked), contains ONLY runtime-specific install-notes prose + the call to `mirror_canonical_files <runtime>` + any per-runtime extras (e.g., claude-code mirrors `CLAUDE_CODE_EXTRA`). No duplicated mirror/prune/summary logic — those live in helpers. Files: 7 new files under `scripts/sync-runtimes.d/`. → verify: each file ≤500 LOC (target ≤120 LOC each), sources 00-helpers, defines an `emit_<runtime>()` function, contains no copy of any helper logic (grep guard against re-defining symbols from 00-helpers).

### W1c — slim orchestrator (sequential, depends on W1b)

- [x] **T1.3** — Slim `scripts/sync-runtimes.sh` orchestrator to ≤150 LOC: source `00-helpers.sh` + all 7 per-runtime modules, dispatch each runtime's `emit_<runtime>` function, print final summary. Files: `scripts/sync-runtimes.sh`. → verify: file ≤150 LOC, output of orchestrator identical to pre-split (270 files across 7 runtimes), exit 0.

### W2 — verify split

- [x] **T2.1** — `bash scripts/sync-runtimes.sh` first run produces 270 files; second run produces zero diff (idempotent). Spot-check 3 random files in `dist/claude-code/`, `dist/cursor/`, `dist/gemini-cli/` against pre-split content. → verify: byte-identical for the spot-checked files.

### W3a — 8 independent new files (parallel, depends on W2)

- [x] **T3.3a (enhancement #3b base)** — Create `scripts/release.sh`: reads `version` from `.claude-plugin/plugin.json` via `jq` or `grep`-fallback, refuses on empty/missing `version`, asserts no `v<version>` tag exists locally (`git tag -l`) AND on origin (`git ls-remote --tags origin v<version>`), refuses on dirty working tree (`git status --porcelain` non-empty), creates annotated tag at HEAD with message `Release v<version>`, prints planned `push` commands, prompts before executing. On push failure: leave local tag in place, print rollback hint `git tag -d v<version>`. Files: `scripts/release.sh` (new). → verify: file exists, executable, runs without error against a freshly-tagged state and exits with a clear "tag already exists" message.
- [x] **T3.3b (enhancement #3b dry-run)** — Add `--dry-run` flag to `scripts/release.sh` that prints all tag + push commands without executing. Files: `scripts/release.sh`. → verify: `bash scripts/release.sh --dry-run` exits 0 and prints commands; no tag created; no push attempted.
- [x] **T3.4 (enhancement #4a)** — Create `scripts/check-collisions.sh`: discovers installed Claude Code plugins under `~/.claude/plugins/cache/*/*/`, extracts every `name:` frontmatter value from `*/SKILL.md` files, compares against hackify's 7 slugs (`hackify`, `quick`, `yolo`, `groom`, `skillsmith`, `review-triage`, `codewalk`). Reports `EXACT MATCH` / `SUBSTRING OVERLAP` / `OK` per slug. Handles 4 empty-state branches gracefully: missing `~/.claude/plugins/`, empty `~/.claude/plugins/cache/`, zero `SKILL.md` files in any plugin dir, malformed frontmatter (no `name:` line). Each branch prints ONE informational line and exits 0 — never errors. Files: `scripts/check-collisions.sh` (new). → verify: file exists, executable, runs cleanly on this machine producing a report; spot-check with a temporarily-renamed plugin dir confirms graceful empty-state handling.
- [x] **T3.6 (enhancement #5a)** — Author `skills/groom/evals/evals.json` with 3 cases: (1) happy: "let's discuss adding rate limiting"; (2) edge: "groom this backlog item"; (3) non-trigger: "add rate limiting" (should route to hackify, NOT groom). Schema matches `skills/hackify/evals/evals.json` exactly. Files: `skills/groom/evals/evals.json` (new). → verify: valid JSON; top-level keys `skill_name`+`evals`; each eval has `id`+`name`+`prompt`+`assertions[].text`+`files`; assertions array ≥3 items per case.
- [x] **T3.7 (enhancement #5b)** — Author `skills/skillsmith/evals/evals.json` (happy: "author a new hackify skill"; edge: "make a hackify-style skill"; non-trigger: "write a script that…"). Files: `skills/skillsmith/evals/evals.json` (new). → verify: same schema as T3.6.
- [x] **T3.8 (enhancement #5c)** — Author `skills/review-triage/evals/evals.json` (happy: paste of mock review findings + "respond to these"; edge: "address review findings"; non-trigger: "review this PR"). Files: `skills/review-triage/evals/evals.json` (new). → verify: same schema as T3.6.
- [x] **T3.9 (enhancement #5d)** — Author `skills/codewalk/evals/evals.json` (happy: "walk me through the login flow"; edge: "trace this call stack from POST /api/orders"; non-trigger: "explain why this test fails"). Files: `skills/codewalk/evals/evals.json` (new). → verify: same schema as T3.6.
- [x] **T3.10 (enhancement #5e)** — Author `skills/yolo/evals/evals.json` (happy: "yolo — add this feature"; edge: "go full auto"; non-trigger: "do it" — too ambiguous per yolo's description). Files: `skills/yolo/evals/evals.json` (new). → verify: same schema as T3.6.
- [x] **T3.11 (enhancement #5f)** — Author `skills/quick/evals/evals.json` (happy: "quick fix the typo on line 42"; edge: "small change to the README"; non-trigger: "refactor everywhere" — full hackify territory). Files: `skills/quick/evals/evals.json` (new). → verify: same schema as T3.6.

### W3b — touch shared files (parallel, depends on W1c + W2)

- [x] **T3.2 (enhancement #2)** — Wire `prune_runtime_dist()` (already authored in T1.1 helpers) into `scripts/sync-runtimes.sh` orchestrator — call it as the first action of each per-runtime dispatch loop iteration before the emitter runs. Files: `scripts/sync-runtimes.sh`. → verify: `grep -c prune_runtime_dist scripts/sync-runtimes.sh` returns ≥1; running orchestrator twice still produces idempotent 270-file output; deleting a known dist file then re-running orchestrator restores it (proves prune-then-mirror works).
- [x] **T3.12 (enhancement #6)** — Sweep `README.md` for stale current-version-implying labels: `(v0.2.2)` → `(since v0.2.2)`, `Hackify v0.2.0 ships for seven runtimes` → `Hackify ships for seven runtimes (since v0.2.0)`, `(v0.2.0) sprint vocabulary` → `(since v0.2.0) sprint vocabulary`, plus equivalent treatment for the other 4 in-prose `vX.Y.Z` mentions. Files: `README.md`. → verify: `grep -nE '\(v0\.[0-9]+\.[0-9]+\)' README.md` returns 0 hits (the parens-only form no longer appears); current-version surface is limited to the badge, the Install snippet, and the plugin.json link.

### W3c — wire-up (parallel, depends on W3a + W3b)

- [x] **T3.1 (enhancement #1)** — Create `scripts/validate-dod.d/80-file-size-caps.sh`. Iterate `find skills agents rules scripts hooks commands -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \)`, plus `skills/*/references/`. For each, fail red if `wc -l < file` > 500. Sources `00-helpers.sh` color printers. Depends on W1c + T3.2 keeping the orchestrator ≤500 LOC. Files: `scripts/validate-dod.d/80-file-size-caps.sh` (new). → verify: module exists, has `[80]` check group header, exits 0 against the current post-split tree; deliberately oversize a temp file and confirm check fails red.
- [x] **T3.5 (enhancement #4b)** — Create `scripts/validate-dod.d/90-collisions.sh`: invokes `scripts/check-collisions.sh` (T3.4 artifact, must exist), captures output, prints any `WARN` / `SUBSTRING OVERLAP` lines in yellow, always exits 0 (soft warning). Files: `scripts/validate-dod.d/90-collisions.sh` (new). → verify: module exists, has `[90]` check group header, returns 0 even if check-collisions reports overlap.

### W4 — version bump + marketplace + CHANGELOG

- [x] **T4.1** — Rewrite `.claude-plugin/marketplace.json` as a two-entry array: entry 1 `name: hackify` with `ref: v0.3.0`, entry 2 `name: hackify-edge` with `ref: main`. Both reference the same source URL. Files: `.claude-plugin/marketplace.json`. → verify: parses as JSON, has 2 plugin entries with distinct names + refs.
- [x] **T4.2** — Bump `.claude-plugin/plugin.json` to `version: 0.3.0`; bump README badge to `version-0.3.0`. Files: `.claude-plugin/plugin.json`, `README.md`. → verify: both JSONs report 0.3.0; badge URL contains 0.3.0.
- [x] **T4.3** — Write `CHANGELOG.md` `## [0.3.0] - 2026-05-22` entry under Added (validator check, release script, collision script, eval files), Changed (sync-runtimes.sh split + prune, marketplace two-entry rewrite, README label framing), Rationale (close known gaps + dog-food the release script). Files: `CHANGELOG.md`. → verify: entry above [0.2.9]; ASCII-hyphen date format; 8+ bullets across Added + Changed.

### W5 — verify + ship

- [x] **T5.1** — Run `bash scripts/sync-runtimes.sh` twice; confirm 270 files, zero diff on second run, no stale dist dirs. → verify: `find dist -type d -name brainstorm -o -name writing-skills -o -name receiving-code-review` returns 0 paths.
- [x] **T5.2** — Run `bash scripts/validate-dod.sh`; expect `ALL CHECKS PASSED` including new `[80]` file-size + `[90]` collisions soft-warning. → verify: exit 0; output includes both new check group headers.
- [x] **T5.3** — Commit all changes with conventional subject `feat: v0.3.0 — six enhancements …`. → verify: `git log --oneline -1` shows the commit on main.
- [x] **T5.4** — Dog-food `bash scripts/release.sh`: reads 0.3.0 from plugin.json, creates `v0.3.0` annotated tag at HEAD, pushes main + tag. → verify: `git tag -l v0.3.0` exists locally; `git ls-remote --tags origin v0.3.0` shows the tag at origin.

## Daily Updates

**2026-05-22 — single-session execution.**

- **W1a + W1b + W1c.** Split `scripts/sync-runtimes.sh` (528 LOC) into orchestrator (95 LOC) + `scripts/sync-runtimes.d/00-helpers.sh` (197 LOC) + 7 per-runtime emitter modules (10-40 LOC each). Helper surface unified: `mirror_canonical_files`, `prune_runtime_dist`, `write_or_announce_copy`, `write_or_announce_heredoc`, `print_runtime_summary`. Per-runtime emitters contain only `prune` + `mirror` + runtime-specific install-notes — no duplicated helper logic.
- **W2.** Verified split: 270 files mirrored, idempotent on second run.
- **W3a.** Authored `scripts/release.sh` (142 LOC, with semver validation + HEAD-on-main guard + dirty-tree check + tag-already-exists check + non-interactive abort + `--dry-run` mode), `scripts/check-collisions.sh` (87 LOC, with 4-branch empty-state handling). Authored 6 eval JSON files for groom/skillsmith/review-triage/codewalk/yolo/quick, each with happy/edge/non-trigger cases, schema matching `skills/hackify/evals/evals.json`.
- **W3b.** Prune wiring ended up inside each per-runtime emitter (functionally equivalent to orchestrator-loop placement — every emitter calls `prune_runtime_dist` first). README label sweep: 8 in-prose `(vX.Y.Z)` labels reframed to `(since vX.Y.Z)`. Plus README:124 codewalk label reframed to `*(since v0.2.8)*` (Phase 5 reviewer catch).
- **W3c.** Validator modules `[80]` file-size-cap and `[90]` collisions-soft-warning authored and wired into orchestrator. Initial cap module used bash 4+ `mapfile` — failed silently on macOS bash 3.2. Rewrote with `while read` loop. Now scans 84 files across primitives, all ≤500 LOC.
- **W4.** Marketplace.json rewritten with two channels: `hackify` (ref: v0.3.0, stable) + `hackify-edge` (ref: main, with explicit supply-chain warning in description). plugin.json + marketplace.json + README badge bumped to 0.3.0. CHANGELOG `[0.3.0]` entry added with full Added/Changed/Rationale.
- **W5.** Validator green. Initial commit landed (`feat: v0.3.0 — six enhancements`). Phase 5 multi-reviewer dispatched 3 in parallel against `HEAD~1..HEAD`.

**Phase 5 multi-reviewer aggregation + fixes.**

- Reviewer A (security) found Critical format-string injection in `check-collisions.sh:84` (`printf "$matches"` with attacker-controlled format) — CWE-134. Fixed: `printf '%b' "$matches"`. Plus 3 Important: HEAD-on-main missing in release.sh, semver validation missing, non-interactive `read` blocks indefinitely.
- Reviewer B (quality) found 2 Critical function-size violations: `emit_copilot_cli` (64 LOC) and `emit_cursor` (45 LOC). Fixed by extracting MANIFEST heredoc bodies to `scripts/sync-runtimes.d/templates/{cursor-manifest,copilot-cli-header,copilot-cli-footer}.md`. New `emit_copilot_cli` = 18 LOC; `emit_cursor` = 10 LOC. Plus 5 Important: color-helper DRY violation across release.sh + check-collisions.sh + 00-helpers.sh → extracted to `scripts/lib/colors.sh`; copilot-cli.sh helper-reimplementation → uses `write_or_announce_heredoc` via process substitution; sync-runtimes.sh hand-typed dispatch list → iterates `RUNTIMES[@]` with `${r//-/_}` transformation; README:124 codewalk label needed `*(since v0.2.8)*` framing.
- Reviewer C (plan-consistency) found 1 Important: AC9 named `write_install_notes` helper that was never authored — fixed AC to name the actual helper (`write_or_announce_heredoc`).
- One subtle bug surfaced during fix-pass: cat-pipe-to-helper lost FILE_COUNT increment because pipe creates subshell. Switched to process substitution `< <(cat ...)` — now 270 files mirror correctly.
- Final state: 270 files mirrored idempotent; validator green; all 9 sub-runtimes script files ≤197 LOC (helpers); all functions ≤40 LOC.

## Sprint Review

Full DoD pass:

- All AC bullets satisfied (verified by `bash scripts/validate-dod.sh` exit 0).
- File-size cap module scans 84 primitive files, all ≤500 LOC.
- Sync-runtimes prune-on-mirror confirmed: every emitter calls `prune_runtime_dist` first; 270 files mirrored, zero stale dirs on rerun.
- Marketplace.json declares 2 plugin entries (`hackify` + `hackify-edge`) with distinct refs (v0.3.0 + main).
- `scripts/release.sh --dry-run` correctly refused on dirty working tree (proving the dirty-tree guard works); will execute on clean tree post-commit.
- `scripts/check-collisions.sh` scanned 51 sibling skills, 0 collisions.
- All 6 eval JSONs parse as valid JSON with 3 cases each.
- README has zero `(vX.Y.Z)` parens-only labels remaining; all reframed to `(since vX.Y.Z)`.

## Retrospective

**What worked.**

- **Phase 2.5 spec-review caught 4 sequencing bugs before they cost wave-rework.** Reviewer C's W1a/W1b/W1c split + T3.5 → T3.4 dependency edge + T3.1 cap-validator-blocked-by-W1c finding all surfaced contradictions in the original W1+W3 prose. Patching the work-doc in place was the right call (signed-off invariants unchanged, no re-gate needed).
- **Phase 5 multi-reviewer caught 3 critical defects the inline self-review would have missed.** Format-string injection in check-collisions.sh:84 was non-obvious from reading the code; both function-size violations passed my own eyeball check; the cat-pipe-to-helper subshell bug only surfaced because file count dropped from 270 to 269 between runs.
- **Dog-fooding `scripts/release.sh` validated the dirty-tree check immediately.** First dry-run invocation correctly refused. The HEAD-on-main + semver validation guards were added BEFORE first real use, so dogfood discovered no new bugs.

**What surprised.**

- **macOS bash 3.2 default.** Initial cap-check module used `mapfile` (bash 4+) and failed silently — `cap_files: unbound variable` should have FAILED++'d but set-u just terminated the module mid-flow without incrementing. Validator reported green. Always smoke-test on the lowest-common-denominator shell.
- **`{ ... } > "$dst"` masks intermediate exit codes**. Reviewer B caught this in the original copilot-cli.sh — the `[ $? -eq 0 ]` after the brace group checks only the last command's status, not the `cat` calls inside. Refactor to `write_or_announce_heredoc` via process substitution made this irrelevant.
- **Pipe creates subshell; arithmetic does not propagate.** Classic. Lost 1 file count after refactoring copilot-cli.sh to `cat ... | write_or_announce_heredoc`. Process substitution `< <(...)` keeps the helper in the parent shell.

**Minor findings logged for follow-up (deferred to v0.3.1+).**

- Non-atomic file writes in `00-helpers.sh:154` (`printf ... > "$dst"` leaves partial file on interrupt; should be `> "$dst.tmp" && mv "$dst.tmp" "$dst"`).
- Clever subshell math in `check-collisions.sh:54` (`malformed=$((skill_files_found - $(wc -l < "$SIBLING_NAMES_FILE" | tr -d ' ')))`) — split into two lines for explicit-over-clever.
- Misleading shebangs on sourced files (`scripts/sync-runtimes.d/*.sh` have `#!/usr/bin/env bash` but are only sourced, never executed). Harmless but cosmetic.
- Comment block in `00-helpers.sh` listing function exports will drift from reality — either delete the comment or generate it from `declare -F` output.

## Summary of changes shipped

| Area | Change |
|---|---|
| **File-size cap validator** | New `scripts/validate-dod.d/80-file-size-caps.sh` enforces ≤500 LOC across `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/` for `.md` / `.sh` / `.json` files. Portable across bash 3.2. Scans 84 files. |
| **Sync-runtimes split** | `scripts/sync-runtimes.sh` (528 LOC → 95 LOC orchestrator) + `scripts/sync-runtimes.d/00-helpers.sh` (197 LOC) + 7 per-runtime emitters (10-40 LOC each) + 3 template files. Dispatch loop now iterates `RUNTIMES[@]`. |
| **Prune-on-mirror** | Every per-runtime emitter calls `prune_runtime_dist` first. Renamed source slugs no longer leave stale dist dirs. |
| **Two-channel marketplace** | `hackify` (ref: v0.3.0, stable) + `hackify-edge` (ref: main, with explicit supply-chain warning in description). |
| **Release helper** | New `scripts/release.sh` — semver-validated tag-at-HEAD, refuses on dirty tree / wrong branch / existing tag / non-interactive context. `--dry-run` mode. |
| **Collision detector** | New `scripts/check-collisions.sh` + `scripts/validate-dod.d/90-collisions.sh` (soft warning). Scans installed sibling plugins for slug substring overlap. 4-branch empty-state handling. |
| **Eval coverage** | New `evals/evals.json` under `skills/groom/`, `skills/skillsmith/`, `skills/review-triage/`, `skills/codewalk/`, `skills/yolo/`, `skills/quick/`. 3 cases each. |
| **Shared color helpers** | New `scripts/lib/colors.sh`. Sourced from `00-helpers.sh`, `release.sh`, `check-collisions.sh`. |
| **README label sweep** | 9 in-prose version labels reframed from `(vX.Y.Z)` to `(since vX.Y.Z)`. |
| **CHANGELOG** | New `## [0.3.0] - 2026-05-22` entry above `[0.2.9]`. |
| **Version bump** | `.claude-plugin/plugin.json` + both `marketplace.json` entries + README badge → `0.3.0`. |
