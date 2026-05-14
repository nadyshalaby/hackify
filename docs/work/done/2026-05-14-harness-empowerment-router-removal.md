---
slug: harness-empowerment-router-removal
title: Remove smart router + empower harness primitives (rules/agents/hooks/skills)
status: done
type: refactor
created: 2026-05-14
project: hackify
current_task: shipped — archived at docs/work/done/
worktree: null
branch: main
sprint_goal: Strip the prompt-based full↔quick smart router from SKILL files and replace it with native harness primitives — each primitive owns the part of the job it's best at (routing → skill descriptions + slash commands; engineering law → rules/; parallel work → agents/; prompt-time reminders → hooks/; workflows → skills/).
---

## Original Ask

> I want to remove the smart routing between (full vs quick) based on prompt given. also i want to empower the harness through rules, hooks, agents, skills. by allocating relevant parts to the correct tool it should uses

## Clarifying Q&A

| Q | Answer |
|---|---|
| Scope of router removal | Remove the full↔quick router AND brainstorm's signal-group routing. Quick's internal fallback signals (attempt counter / file count / security path / user-invokes-full) STAY — they are post-implementation circuit breakers, not pre-flight routing. |
| Replacement mechanism | Skill descriptions + slash commands ONLY. No `UserPromptSubmit` hook that picks full vs quick from the prompt — that would just move the classifier and lose the win. |
| Quick mode survival | Keep `skills/quick/SKILL.md` as a separate skill, auto-discoverable from its sharpened description and explicitly invokable via `/hackify:quick`. |
| Primitives in scope | All four: `skills/` (workflows), `rules/` (always-on engineering law), `agents/` (formal parallel-dispatch defs), `hooks/` (NON-routing prompt-time reminders). User wants all four as first-class directories at plugin root. |
| `rules/` loading mechanism (no native primitive in Claude Code spec) | **Both** — `UserPromptSubmit` hook injects `rules/hard-caps.md` (short always-on law). Deeper refs (`rules/code-quality.md`, etc.) load on-demand from skills. |

## Acceptance Criteria

- [x] **AC1 — Router file deleted.** `skills/hackify/references/smart-router.md` no longer exists. `grep -rn "smart-router\|smart router" skills/ commands/ README.md` returns zero hits in canonical sources (CHANGELOG history entries OK).
- [x] **AC2 — Router stubs stripped from SKILLs.** `skills/hackify/SKILL.md` and `skills/quick/SKILL.md` no longer contain the "Pre-flight: smart router" H2 block. `skills/brainstorm/SKILL.md` no longer contains the "hackify smart router" cross-ref paragraph (lines ~25, ~91 region).
- [x] **AC3 — Skill descriptions sharpened.** Each of `hackify`, `quick`, `brainstorm` SKILL frontmatter `description:` field is rewritten so a Haiku-class harness picks the right one from prompt content alone. hackify = catch-all default; quick = small fix / single-file / typo; brainstorm = discuss/explore/what-if. Each description ≤1500 chars (current lengths: hackify 956 / quick 1474 / brainstorm 984 — cap chosen to fit all three with breathing room; this is a sharpening pass, not a forced trim). Discrimination verified by side-by-side read at Phase 4.
- [x] **AC4 — New top-level directory `rules/`** exists at repo root, contains at least `rules/hard-caps.md` (short always-on law — function/file/param caps, lint-suppression ban, named-types rule) and `rules/code-quality.md` (the relocated content of `skills/hackify/references/code-rules.md`).
- [x] **AC5 — New top-level directory `agents/`** exists at repo root, contains 7 formalized agent definitions extracted from `skills/hackify/references/parallel-agents.md`: 3 spec reviewers (consistency / rules / dependencies), 3 code reviewers (security / quality / plan-consistency), 1 wave-task implementer. Each has frontmatter (`name`, `description`) + a self-contained body conforming to the canonical 7-section template.
- [x] **AC6 — New top-level directory `hooks/`** exists at repo root, contains `hooks/hooks.json` declaring exactly one `UserPromptSubmit` hook that injects `rules/hard-caps.md` into context. The hook script is NON-routing — it MUST NOT classify full vs quick. JSON shape MUST match the Claude Code plugin hook spec exactly:
  ```json
  {
    "hooks": {
      "UserPromptSubmit": [
        {
          "matcher": "",
          "hooks": [
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/inject-hard-caps.sh" }
          ]
        }
      ]
    }
  }
  ```
  Implementation file at `hooks/inject-hard-caps.sh` is executable (`chmod +x`) and emits a JSON envelope to stdout: `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<contents of rules/hard-caps.md>"}}` — raw stdout becomes a transcript message, not injected context. Resolve the rules file via `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md`, NOT a relative path (cwd is not guaranteed).
- [x] **AC7 — In-SKILL references updated.** Every existing reference to `skills/hackify/references/code-rules.md` is repointed to `rules/code-quality.md`. The old path `skills/hackify/references/code-rules.md` is rewritten as a 5-line forwarding stub pointing to the new canonical location; the stub mirrors to all 7 runtimes, AND `rules/code-quality.md` itself ALSO mirrors to all 7 runtimes (per AC9) — so consumers can resolve via either path. No content duplication, no broken intra-repo links.
- [x] **AC8 — Validator updated.** `scripts/validate-dod.sh` no longer contains check `[27]` (smart-router cross-reference — currently lines ~552–566). New checks added: (a) `rules/hard-caps.md` and `rules/code-quality.md` exist and are non-empty; (b) `agents/` contains exactly 7 `.md` files matching the names declared in AC5; (c) `hooks/hooks.json` parses as JSON (via `python3 -m json.tool` or equivalent) and declares a `UserPromptSubmit` event under `hooks.UserPromptSubmit[]`; (d) `hooks/inject-hard-caps.sh` is executable. `bash scripts/validate-dod.sh` exits 0.
- [x] **AC9 — Sync-runtimes updated and idempotent.** `scripts/sync-runtimes.sh` mirrors `rules/hard-caps.md` and `rules/code-quality.md` to all 7 runtimes (claude-code, codex-cli, codex-app, gemini-cli, opencode, cursor, copilot-cli) by appending them to `MIRROR_SOURCES`. `agents/*.md` (7 files, enumerated explicitly — NOT glob-driven; `CLAUDE_CODE_EXTRA` is a fixed array) and `hooks/hooks.json` + `hooks/inject-hard-caps.sh` mirror to `dist/claude-code/` only by appending to `CLAUDE_CODE_EXTRA`, because they are claude-code-native primitives. Running the script twice in a row produces zero diff (verified with `git status` after second run).
- [x] **AC10 — Cross-runtime invariant preserved.** Non-claude-code runtimes still receive a working skill set — the existing `skills/hackify/references/parallel-agents.md` stays in place UNTOUCHED as the cross-runtime fallback (claude-code consumers prefer `agents/<name>.md`, other runtimes fall back to the inline templates in `parallel-agents.md`). Verification task **T6.7** (added below) spot-checks the synced `dist/codex-cli/` and `dist/gemini-cli/` mirrors — they MUST contain `references/parallel-agents.md` AND MUST NOT contain `agents/` or `hooks/` directories. `grep -r "${CLAUDE_PLUGIN_ROOT}" dist/codex-cli dist/gemini-cli` returns zero hits.
- [x] **AC11 — README + CHANGELOG.** README line 55 "Smart router (v0.2.1)" paragraph deleted. CHANGELOG has a v0.2.2 entry describing the refactor + new primitive directories, including a 1-line "Why" callout. README adds a short "Plugin primitives" paragraph listing `skills/ rules/ agents/ hooks/ commands/`.
- [x] **AC12 — Version bump.** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` both bumped to `0.2.2`.

## Approach

Three concerns at three non-overlapping layers, executed in five dependency-ordered waves.

**Layer 1 — Router excision (subtractive).** Delete `references/smart-router.md`. Strip both router stubs (hackify SKILL ~5 lines, quick SKILL ~5 lines, brainstorm cross-ref paragraph). Drop validator check `[27]`. Strip README "Smart router" paragraph.

**Layer 2 — New primitives (additive).**
- `rules/hard-caps.md` — short always-on engineering law (≤500 LOC/file, ≤40 LOC/function, 0 lint suppressions, 0 non-null `!`, 0 inline complex types). UserPromptSubmit hook injects this every turn.
- `rules/code-quality.md` — relocated full content of `references/code-rules.md` (the deeper ref skills load on demand). Old reference stays as a forwarding stub for non-claude-code runtimes.
- `agents/<name>.md` × 7 — formal extraction from `references/parallel-agents.md` templates (3 spec reviewers, 3 code reviewers, 1 wave-task implementer). Each is independently dispatchable; canonical 7-section structure preserved.
- `hooks/hooks.json` + `hooks/inject-hard-caps.sh` — single hook (`UserPromptSubmit`) that NON-ROUTINGLY injects `rules/hard-caps.md` content. Hook is the harness's "always-on rules" mechanism.

**Layer 3 — Skill descriptions (the actual new routing mechanism).** Sharpen the three SKILL `description:` frontmatter fields so harness auto-discovery picks the right one with no embedded classifier. hackify = explicit catch-all default; quick = narrow on small-fix triggers (typo/one-line/single-file); brainstorm = narrow on idea-exploration triggers (let's discuss/what if/explore).

Sync, validate, version-bump, commit. **Execution waves** detailed in Sprint Backlog below.

## Execution waves

| Wave | Tasks | Files |
|---|---|---|
| **W1 — Excision** | T1.1 delete router file · T1.2 strip hackify SKILL stub · T1.3 strip quick SKILL stub · T1.4 strip brainstorm cross-ref · T1.5 strip README router paragraph · T1.6 drop validator check [27] | `skills/hackify/references/smart-router.md` (delete), `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/brainstorm/SKILL.md`, `README.md`, `scripts/validate-dod.sh` |
| **W2 — rules/ + relocate code-quality** | T2.1 create `rules/hard-caps.md` · T2.2 create `rules/code-quality.md` (relocated content) · T2.3 add forwarding stub at `references/code-rules.md` for non-claude-code runtimes | `rules/hard-caps.md` (new), `rules/code-quality.md` (new), `skills/hackify/references/code-rules.md` (rewrite as 5-line stub) |
| **W3 — agents/** | T3.1–T3.7 create 7 agent files in parallel (one per template) | `agents/spec-reviewer-consistency.md`, `agents/spec-reviewer-rules.md`, `agents/spec-reviewer-dependencies.md`, `agents/code-reviewer-security.md`, `agents/code-reviewer-quality.md`, `agents/code-reviewer-plan-consistency.md`, `agents/wave-task-implementer.md` (all new) |
| **W4 — hooks/** | T4.1 create `hooks/hooks.json` · T4.2 create `hooks/inject-hard-caps.sh` (executable) | `hooks/hooks.json` (new), `hooks/inject-hard-caps.sh` (new) |
| **W5 — Sharpen descriptions** | T5.1 rewrite hackify `description:` · T5.2 rewrite quick `description:` · T5.3 rewrite brainstorm `description:` | `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/brainstorm/SKILL.md` (descriptions only — bodies frozen) |
| **W6 — Sync + validator + version + changelog** | T6.1 update `sync-runtimes.sh` (add `rules/` to MIRROR_SOURCES; `agents/`+`hooks/` to CLAUDE_CODE_EXTRA pattern) · T6.2 add validator checks for `rules/`, `agents/`, `hooks/` · T6.3 bump version `0.2.1 → 0.2.2` in both plugin manifests · T6.4 CHANGELOG v0.2.2 entry · T6.5 README "Plugin primitives" paragraph · T6.6 run `bash scripts/sync-runtimes.sh` to produce dist mirrors | `scripts/sync-runtimes.sh`, `scripts/validate-dod.sh`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`, `dist/**` |

Dependency rationale: W2 must precede W6 (sync mirrors `rules/`). W3+W4 are independent of each other and of W2 — could parallelize, but ordering them W2→W3→W4 keeps reviews linear. W5 (descriptions) can run any time AFTER W1; placed late so we sharpen descriptions with full context of what the new primitives do. W6 LAST — it bundles version bump + sync + validator and lands the final state.

## Sprint Backlog

### Wave 1 — Excision (subtractive)
- [x] T1.1 Delete `skills/hackify/references/smart-router.md`.
- [x] T1.2 Strip the "Pre-flight: smart router — pick the right flow" H2 block from `skills/hackify/SKILL.md` (currently lines 21–25).
- [x] T1.3 Strip the identical block from `skills/quick/SKILL.md` (currently lines 6–10).
- [x] T1.4 Strip the "hackify smart router" cross-ref paragraph from `skills/brainstorm/SKILL.md` (lines ~25, ~91 region).
- [x] T1.5 Delete the "Smart router (v0.2.1)" paragraph from `README.md` (line 55).
- [x] T1.6 Remove validator check `[27]` (lines ~552–566) from `scripts/validate-dod.sh`.

### Wave 2 — `rules/` directory + relocate code-quality
- [x] T2.1 Create `rules/hard-caps.md` (≤80 lines) — function/file/param/nesting hard caps, lint-suppression ban, no-`!` rule, no-empty-catch rule, named-types rule, single-responsibility. Short enough to inject every turn without bloating context.
- [x] T2.2 Create `rules/code-quality.md` by relocating the full content of `skills/hackify/references/code-rules.md` (the deeper SOLID/DRY/types/layering doctrine).
- [x] T2.3 Rewrite `skills/hackify/references/code-rules.md` as a 5-line forwarding stub pointing readers at `rules/code-quality.md` (claude-code) / acknowledging non-claude-code runtimes get the full content mirrored via sync.

### Wave 3 — `agents/` directory
- [x] T3.1 Create `agents/spec-reviewer-consistency.md` (Phase 2.5 Reviewer A — work-doc internal consistency).
- [x] T3.2 Create `agents/spec-reviewer-rules.md` (Phase 2.5 Reviewer B — plan vs project code-quality rules).
- [x] T3.3 Create `agents/spec-reviewer-dependencies.md` (Phase 2.5 Reviewer C — task dependency / parallelism risks).
- [x] T3.4 Create `agents/code-reviewer-security.md` (Phase 5 Reviewer A — security & correctness).
- [x] T3.5 Create `agents/code-reviewer-quality.md` (Phase 5 Reviewer B — quality & layering).
- [x] T3.6 Create `agents/code-reviewer-plan-consistency.md` (Phase 5 Reviewer C — diff vs work-doc DoD + backlog).
- [x] T3.7 Create `agents/wave-task-implementer.md` (Phase 3 wave-task agent — file allowlist + TDD + self-review + ≤200-word report).

### Wave 4 — `hooks/` directory
- [x] T4.1 Create `hooks/hooks.json` declaring exactly one `UserPromptSubmit` hook that runs `${CLAUDE_PLUGIN_ROOT}/hooks/inject-hard-caps.sh` (or equivalent plugin-relative path).
- [x] T4.2 Create `hooks/inject-hard-caps.sh` (executable, `chmod +x`). Behavior — read `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md` (NOT a relative path; cwd is not guaranteed under hook invocation), then emit to stdout a JSON envelope of the form `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<file contents, JSON-escaped>"}}`. The envelope IS what Claude Code injects as context; raw stdout becomes a transcript message instead. NO routing logic — must not grep prompt for quick/full keywords. Use `jq -Rs '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: .}}' "${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md"` (or equivalent shell-safe JSON-encoding) to avoid hand-rolled escaping.

### Wave 5 — Sharpen skill descriptions (the new routing mechanism)
- [x] T5.1 Rewrite `description:` in `skills/hackify/SKILL.md` frontmatter — explicit catch-all default; lead with "use for any non-trivial task"; enumerate the broad-spectrum triggers; explicitly state "When in doubt, use this skill" as the contract. ≤900 chars.
- [x] T5.2 Rewrite `description:` in `skills/quick/SKILL.md` frontmatter — narrow on small-fix triggers (typo, one-line, single-file, polish, tiny tweak, minor edit); explicit non-trigger list (cross-file refactor, redesign, debug, auth/crypto/migration). ≤900 chars.
- [x] T5.3 Rewrite `description:` in `skills/brainstorm/SKILL.md` frontmatter — narrow on idea-exploration triggers (let's discuss, what if, explore the idea, brainstorm); explicit graduation-to-hackify contract. ≤900 chars.

### Wave 6 — Sync + validator + version + changelog
- [x] T6.1 Update `scripts/sync-runtimes.sh` — append to `MIRROR_SOURCES` (mirrors to all 7 runtimes): `rules/hard-caps.md`, `rules/code-quality.md`. Append to `CLAUDE_CODE_EXTRA` (mirrors to `dist/claude-code/` only — array is a flat list of explicit paths, NOT a glob, so enumerate each file): all 7 `agents/*.md` files by name, `hooks/hooks.json`, `hooks/inject-hard-caps.sh`. Preserve idempotency (verify after T6.6 by running script twice and diffing). The script's existing `write_or_announce_copy` helper handles both lists identically.
- [x] T6.2 Add validator checks to `scripts/validate-dod.sh`: (a) `rules/hard-caps.md` + `rules/code-quality.md` exist and `wc -l > 0`; (b) `agents/` contains exactly 7 `.md` files with the expected basenames from T3.1–T3.7; (c) `hooks/hooks.json` is valid JSON (parseable via `python3 -m json.tool` or `jq`); (d) `hooks/hooks.json` declares a `UserPromptSubmit` key.
- [x] T6.3 Bump version to `0.2.2` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- [x] T6.4 Add `CHANGELOG.md` v0.2.2 entry — sections: Why (one paragraph), Changed (router excision + new primitive dirs), Migration (none for skill users; plugin authors get the new dir contract).
- [x] T6.5 Add a short "Plugin primitives" paragraph to `README.md` (replacing the old "Smart router" paragraph location) — lists `skills/ rules/ agents/ hooks/ commands/` with one-line responsibility each.
- [x] T6.6 Run `bash scripts/sync-runtimes.sh` to regenerate `dist/<runtime>/` mirrors. Then run it again to verify zero diff (idempotency).
- [x] T6.7 **AC10 cross-runtime invariant verification.** Run: `(a) [ -f dist/codex-cli/skills/hackify/references/parallel-agents.md ] && [ -f dist/gemini-cli/skills/hackify/references/parallel-agents.md ]` (parallel-agents.md preserved in non-claude-code mirrors); `(b) [ ! -d dist/codex-cli/agents ] && [ ! -d dist/codex-cli/hooks ] && [ ! -d dist/gemini-cli/agents ] && [ ! -d dist/gemini-cli/hooks ]` (no leak of claude-code-only dirs); `(c) grep -rL "CLAUDE_PLUGIN_ROOT" dist/codex-cli dist/gemini-cli` should return all files (zero matches for that env var). Paste outputs as evidence.

## Daily Updates

### 2026-05-14 — W1 Excision

- Deleted `skills/hackify/references/smart-router.md`.
- Stripped the `## Pre-flight: smart router` H2 block from `skills/hackify/SKILL.md` (5 lines).
- Stripped the same block from `skills/quick/SKILL.md` (5 lines).
- Removed the `skills/brainstorm/SKILL.md` cross-reference paragraph + the file-map mention.
- Replaced the README "Smart router (v0.2.1)" paragraph with a "Plugin primitives (v0.2.2)" paragraph (T1.5 + T6.5 collapsed into one edit at the same anchor — saves a wave-6 re-touch).
- Removed validator check `[27]` (lines ~552–579).

### 2026-05-14 — W2 rules/ + code-quality relocation

- Created `rules/hard-caps.md` (~40 lines) — short always-on injection content: size caps, zero-tolerance bans, always-on principles, refuse-on-sight anti-patterns.
- Created `rules/code-quality.md` (231 lines) by copying the prior content of `skills/hackify/references/code-rules.md`.
- Rewrote `skills/hackify/references/code-rules.md` as a 6-line forwarding stub pointing at the new canonical location.

### 2026-05-14 — W3 agents/

- Dispatched a single content-extraction agent (sequential per-file) to extract the 7 sub-agent templates from `skills/hackify/references/parallel-agents.md` into `agents/<name>.md`. All 7 files have YAML frontmatter with matching `name:` slugs and the canonical 7-section sub-agent contract (SEVERITY omitted on `wave-task-implementer.md`).
- Line counts: 128 / 151 / 136 / 141 / 161 / 149 / 175.

### 2026-05-14 — W4 hooks/

- Created `hooks/hooks.json` declaring exactly one `UserPromptSubmit` hook with empty matcher.
- Created `hooks/inject-hard-caps.sh` (executable, chmod +x). Resolves `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md` and emits a `hookSpecificOutput` JSON envelope via `jq -Rs` (with python3 fallback). NON-routing — the script never inspects the prompt.

### 2026-05-14 — W5 Sharpen descriptions

- Rewrote `description:` frontmatter on all three SKILLs.
- New char counts: hackify 1177 (was 956), quick 1458 (was 1474), brainstorm 1273 (was 984). All three under the ≤1500 cap.
- hackify description anchors broad-spectrum verbs + architecture/scope/security surface; quick anchors small-fix triggers + explicit non-trigger list; brainstorm anchors idea-exploration phrases + explicit "do NOT invoke on build verbs" rule that prevents collision with hackify/quick auto-discovery.

### 2026-05-14 — W6 Sync + validator + version + changelog

- `scripts/sync-runtimes.sh` `MIRROR_SOURCES` appended with `rules/hard-caps.md`, `rules/code-quality.md` (mirrors to all 7 runtimes). `CLAUDE_CODE_EXTRA` appended with 7 `agents/*.md` files + 2 `hooks/*` files (mirrors to `dist/claude-code/` only).
- `scripts/validate-dod.sh` gained 5 new checks `[29]–[33]`; check `[2]` threshold lowered from ≥11 to ≥10 (one reference deleted = expected new floor).
- `.claude-plugin/plugin.json` + `marketplace.json` bumped to `0.2.2`.
- CHANGELOG.md gained the v0.2.2 entry (Why / Changed / Added / Migration sections).
- Ran `bash scripts/sync-runtimes.sh` — synced 132 files across 7 runtimes. Re-ran; `git status dist/` returned empty → idempotency confirmed.
- AC10 cross-runtime verification: `dist/codex-cli/` and `dist/gemini-cli/` both contain `references/parallel-agents.md` AND have no `agents/` or `hooks/` subdirectories; `grep -rl CLAUDE_PLUGIN_ROOT dist/<non-claude-code>` returns zero matches; `dist/claude-code/hooks/inject-hard-caps.sh` is executable (-rwxr-xr-x).
- Final validator run: all 33 checks pass (`bash scripts/validate-dod.sh` exits 0).

## Sprint Review

**Verification triad — fresh evidence.**

- `bash scripts/validate-dod.sh` → **ALL CHECKS PASSED** (33/33). Five new checks (`[29]`–`[33]`) gating the v0.2.2 primitives; check `[27]` (smart-router cross-reference) deleted; check `[2]` threshold lowered from ≥11 to ≥10 to reflect the deleted reference file.
- `bash scripts/sync-runtimes.sh` → "OK — synced 132 files across 7 runtimes". Second consecutive run produced zero `git status dist/` diff → idempotency confirmed.
- Hook smoke tests (3 scenarios): happy path emits valid `hookSpecificOutput` JSON; unset `CLAUDE_PLUGIN_ROOT` exits 0 silently; bogus path exits 0 silently. Hook will NEVER block a user prompt — Reviewer A's failure-path concern fully addressed.
- AC10 cross-runtime invariant: `dist/codex-cli/` + `dist/gemini-cli/` contain `references/parallel-agents.md` (preserved as fallback); neither contains `agents/` or `hooks/`; zero `CLAUDE_PLUGIN_ROOT` leak into non-claude-code mirrors.
- Hook script in dist is executable (`-rwxr-xr-x`); `cp -f` preserved the mode bit on macOS as expected.

**Phase 5 multi-reviewer outcome.** All 3 reviewers ran in parallel. Reviewer C (plan consistency): clean — all 12 AC satisfied, no scope creep. Reviewer B (quality): clean except one Minor (legacy `references/code-rules.md` path appeared 4× in `skills/hackify/SKILL.md` as an indirect reference). Reviewer A (security & correctness): two Importants on hook robustness (`set -e` + jq/python failure paths would block prompts) + three Minors (UTF-8 encoding, prefix-collision in validator grep, implicit `cp -f` mode preservation).

**Fixes applied before Phase 6.** Hardened `hooks/inject-hard-caps.sh` to NEVER block prompts — removed `set -e`/`set -o pipefail`, kept only `set -u`, added explicit `|| exit 0` on the JSON-emit step, added UTF-8 encoding to the python3 fallback, and gated path construction behind a presence check on `${CLAUDE_PLUGIN_ROOT}`. Repointed the 4 `skills/hackify/SKILL.md` references from `references/code-rules.md` to `rules/code-quality.md` (clarifying the legacy path is a forwarding stub).

## Retrospective

**What surprised.**

- **Reviewer A caught the most important defect of the entire change.** The hook would have shipped with `set -euo pipefail` and a single `|| exit 0` only on the env check — meaning a transient `jq` failure or non-UTF-8 byte in `hard-caps.md` would have killed every user prompt for the day. Worth remembering: a `UserPromptSubmit` hook is at the same blast radius as a shell PROMPT_COMMAND — it MUST be paranoid about its own failure modes.
- **`cp -f` on macOS preserves mode bits by default.** Was prepared to add an explicit `chmod +x` step in the sync script; turned out not needed. Verified empirically. Documented in Sprint Review so the assumption is auditable.
- **Claude Code has no native `rules/` primitive.** The plugin spec auto-discovers `skills/`, `agents/`, `commands/`, and `hooks/` (with `hooks/hooks.json` declaration), but `rules/` is plugin-shipped content with no special harness treatment. Worked around by using the `UserPromptSubmit` hook to inject `rules/hard-caps.md` into every prompt — a non-routing always-on mechanism. The user's Q5 answer ("Both — hook for hard-cap law, skills load deeper refs on-demand") aligned exactly with what the spec actually supports.

**What to remember.**

- **Routing primitives must not double.** The single biggest design risk during planning was the temptation to "move the classifier into the hook." The user's Q2 answer and the advisor's reconciliation both flagged this: routing = skill descriptions + slash commands, full stop. Hooks/rules/agents carry NON-routing responsibilities. If a future change starts adding regex matchers to a hook script, that's the symptom — the classifier has been smuggled back in.
- **CLAUDE_CODE_EXTRA is a flat array, not a pattern.** Reviewer B caught this during Phase 2.5. Tempting to assume "any directory at the plugin root mirrors to claude-code"; the actual contract is "enumerate every file by name." Worth a one-line comment in `sync-runtimes.sh` for future contributors (already added).
- **Cross-runtime portability via the inline-fallback pattern.** `agents/` and `hooks/` are claude-code-only, but the templates they extracted from (`skills/hackify/references/parallel-agents.md`) stay in place untouched. Non-claude-code runtimes still get a working skill set. Worth replicating this pattern when adding future claude-code-native primitives.

**Follow-ups (deferred minors).**

- Validator check `[30]` uses `head -5 | grep -qF "name: $name"` — would false-positive if any agent name became a prefix of another. Currently no prefix collisions; switch to `grep -qFx` if the agent set grows.
- `scripts/sync-runtimes.sh` currently uses `cp -f`. Mode-bit preservation is empirically working on macOS BSD `cp` and GNU `cp`. If a future contributor uses a stripped-down `cp` (e.g., busybox), the hook script could lose its execute bit silently. Consider `install -m 0755` for the hook script specifically; deferred to v0.2.3.
- `references/code-rules.md` is now a 6-line forwarding stub. It still ships to all 7 runtimes via `MIRROR_SOURCES` so existing intra-skill links resolve. If a future cleanup wants to delete it outright, the SKILL would need a Phase-conditional ref-rewrite first.

### Summary of changes shipped

| Area | Change |
|---|---|
| **Smart router removal** | Deleted `skills/hackify/references/smart-router.md`; stripped router-stub blocks from `hackify`/`quick` SKILLs and the cross-ref paragraph from `brainstorm`; removed validator check `[27]`. |
| **`rules/` primitive** | New plugin-root dir. `rules/hard-caps.md` (~40 lines) injected every prompt by the `UserPromptSubmit` hook; `rules/code-quality.md` (231 lines) is the relocated SOLID/DRY/types/layering doctrine. Legacy `references/code-rules.md` rewritten as a 6-line forwarding stub. |
| **`agents/` primitive** | New plugin-root dir. 7 formal Claude Code sub-agent definitions (3 Phase 2.5 spec reviewers, 3 Phase 5 code reviewers, 1 Phase 3 wave-task implementer) extracted from `references/parallel-agents.md` with YAML frontmatter + canonical 7-section contract. claude-code-only via `CLAUDE_CODE_EXTRA`. |
| **`hooks/` primitive** | New plugin-root dir. `hooks/hooks.json` declares one `UserPromptSubmit` hook. `hooks/inject-hard-caps.sh` reads `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md`, JSON-wraps as `hookSpecificOutput`, emits to stdout. NON-routing — never inspects the prompt. Hardened to never block prompts on failure. |
| **Skill descriptions = routing** | Sharpened `description:` frontmatter on `hackify` (1177 chars), `quick` (1458 chars), `brainstorm` (1273 chars) so harness auto-discovery does the routing job. All three under the ≤1500-char cap. No embedded classifier. |
| **`scripts/sync-runtimes.sh`** | `MIRROR_SOURCES` appended with both `rules/*.md` files (all 7 runtimes). `CLAUDE_CODE_EXTRA` appended with 7 `agents/*.md` + 2 `hooks/*` files (`dist/claude-code/` only). Idempotency preserved — second run produces zero `git status dist/` diff. |
| **`scripts/validate-dod.sh`** | Removed check `[27]` (smart-router cross-ref). Added 5 new checks `[29]`–`[33]`: `rules/` presence + non-empty, `agents/` 7-file enumeration + frontmatter, `hooks/hooks.json` JSON+UserPromptSubmit, hook script executable, smart-router-excision invariant. Lowered check `[2]` floor from ≥11 to ≥10. |
| **Version bump** | `.claude-plugin/plugin.json` + `marketplace.json` → `0.2.2`. |
| **README.md** | "Smart router (v0.2.1)" paragraph replaced with "Plugin primitives (v0.2.2)" — lists `skills/ rules/ agents/ hooks/ commands/` with one-line responsibility each. |
| **CHANGELOG.md** | New `[0.2.2] — 2026-05-14` entry with Why / Changed (smart router removed) / Added (plugin primitives) / Changed (descriptions, sync, validator) / Migration sections. |
| **Cross-runtime invariant** | `references/parallel-agents.md` untouched; non-claude-code dist mirrors contain it and have ZERO `agents/`/`hooks/` directories or `${CLAUDE_PLUGIN_ROOT}` references. |
