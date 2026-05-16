# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2026-05-16

> **Patch-level scope, patch-level label.** Adds a new sibling skill `/hackify:yolo` (full-autopilot mode) and a one-sentence exploration nudge to quick mode. No phase change to full or quick.

### Added

- **`skills/yolo/SKILL.md`** — new full-autopilot sibling skill. Same workflow phases as `/hackify:hackify` (Clarify with exploration, in-chat Plan, Spec-review, parallel Implement, Verify, Multi-reviewer, Finish) but two gates auto-pass: Phase 2 plan sign-off and Phase 6 4-options finish menu. The in-chat plan block (assistant message) replaces the on-disk work-doc as the Phase 2.5 / Phase 5 reviewer audit subject. Phase 5 multi-reviewer findings auto-fix in-place at every severity (Critical AND Important); Minor findings logged to chat (no Retrospective doc exists). Phase 6 default is commit to current branch locally, no push — user inspects with `git log -1` / `git diff HEAD~1` afterward. Auto-discovery triggers include `/hackify:yolo`, `yolo`, `just do it`, `don't ask me` and 7 other autonomy phrases — the canonical list lives in `skills/yolo/SKILL.md` frontmatter. No work-doc → no pause/resume across sessions.
- **`scripts/sync-runtimes.sh`** — `MIRROR_SOURCES` array gains the entry `"skills/yolo/SKILL.md"` so the new skill mirrors into all 7 runtime distributions.
- **`scripts/validate-dod.sh`** — two new check groups. Check `[34]` validates `skills/yolo/SKILL.md` exists, has `name: yolo` frontmatter matching the slug regex, has `description:` frontmatter, and the body contains the 10 required tokens (`Phase 1`, `Phase 2.5`, `Phase 3`, `Phase 4`, `Phase 5`, `Phase 6`, `in-chat plan`, `auto-pass`, `commit to current branch locally`, `no work-doc`). Check `[35]` validates `skills/quick/SKILL.md` contains the verbatim string `read it end-to-end before judging ambiguity`. A new positive-match helper `check_token_present` (mirror of the existing `check_no_token` shape) is added and reused by both check groups.

### Changed

- **`skills/quick/SKILL.md`** — the Phase 1 row in the "Kept phases" table gains a bolded sentence: `**If the ask names a file or symbol but not a fix, read it end-to-end before judging ambiguity.**` No other change to quick mode.
- **`skills/hackify/SKILL.md`** — the "When to invoke" section gains a new bullet introducing YOLO as the full-autopilot alternative alongside the existing Compressed-flow alternative.
- **`README.md`** — hero callout "Two flows, one discipline" rewritten to "Three flows, one discipline"; the flow comparison table gains a `Hackify YOLO` row between the existing Full and Quick rows; a new `### YOLO mode` subsection describes when to use YOLO and the no-work-doc trade-off; the slash-command reference table gains a `/hackify:yolo <ask>` row.

### Rationale

Full hackify and quick mode together left a middle-ground gap: substantive tasks where the user trusts the pipeline and doesn't want to gate on plan sign-off or the finish menu, but still wants spec-review, parallel implementation, and multi-reviewer rigor. YOLO fills it. The auto-fix-Critical contract is deliberate — the user opted into autopilot; surfacing findings mid-flow would defeat the purpose. The "When NOT to use YOLO" table flags auth/crypto/migration/secret as the load-bearing carve-out where auto-fix is risky. The quick-mode exploration nudge is unrelated and small: it tells the AI to read a named file end-to-end before judging ambiguity, addressing a quiet failure mode where the AI guessed at intent instead of consulting the file the user named.

## [0.2.3] - 2026-05-16

> **Patch-level scope, patch-level label.** Quick mode is now user-locked. Workflow phases are unchanged; only one runtime contract — auto-fallback — is removed.

### Changed

- **`skills/quick/SKILL.md`** — quick mode is now user-locked. Once `/hackify:quick` is invoked (explicitly or via auto-discovery), it stays in quick mode for the entire task. Promotion to full hackify requires an explicit user phrase: `switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`, `do full review`, `run Phase 5`, or `run multi-reviewer` (case-insensitive, scanned in the most recent user message only). The promotion procedure (write work-doc from accumulated context, hand off to full hackify Phase 2, preserve intent + partial diff in Daily Updates) is preserved verbatim under the new section heading "Promotion to full hackify (user-initiated only)" — only the trigger surface changes from automatic to manual.
- **`skills/quick/SKILL.md`** frontmatter description — the "Falls back to full hackify automatically on any of 4 testable signals" sentence replaced with a "User-locked mode" sentence stating quick mode stays in quick mode until the user explicitly promotes; also documents non-resumability (no work-doc → no pause/resume across sessions). The auto-discovery routing guidance ("Do NOT auto-fire on cross-file refactors, redesigns, debug…") is preserved — it controls which skill the harness picks when no slash command is typed, not the runtime fallback contract.
- **`skills/hackify/SKILL.md`** line 17 — the cross-reference to quick mode's fallback signals replaced with `stays in quick mode until you explicitly switch to full hackify`.
- **`README.md`** lines 28 and 95–104 — fallback-trigger paragraph and 4-row trigger list replaced with a "User-initiated promotion to full hackify" subsection listing the explicit promotion phrases.

### Removed

- **Four auto-fallback signals from `/hackify:quick`** — (a) implementation-attempt counter reaching 2, (b) `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | wc -l > 3`, (c) `grep -iE 'auth|crypto|migration|secret|token|password'` against touched paths, (d) most-recent-user-message scan for `Phase 5` / `multi-reviewer` / `do full review`. Triggers (a)–(c) are removed entirely; (d) is preserved as an explicit user-initiated promotion phrase, no longer described as a fallback.
- **Scratch `.quick-<slug>.md` attempt-counter file** — no longer created; the attempt counter is gone.
- **Anti-rationalization rows** in `skills/quick/SKILL.md` that referenced fallback triggers ("It's only one file, no need to check the diff scope" / "Attempt 2 failed but I have a great idea for attempt 3" / "The diff touches an `auth_helper.ts` file but it is just a comment edit") — removed; one replacement row added stating quick mode never auto-promotes.

### Rationale

The 4-signal auto-fallback was intended as a safety net but conflicted with user-stated intent: when a user explicitly invokes `/hackify:quick`, they have opted into a single-session, no-work-doc, no-resume flow and expect the AI to comply for the duration of the task. Silently switching modes mid-task violated that contract. The carve-out routing list in the skill description (which steers auto-discovery toward full hackify for cross-file refactors / redesigns / auth-crypto-migration work) remains the safety net at the routing layer, before quick mode is ever invoked.

## [0.2.2] — 2026-05-14

> **Patch label, refactor + additive scope.** Removes the prompt-based smart router that picked between full hackify, quick, and brainstorm — routing is now handled entirely by each skill's frontmatter `description` field via the harness's native auto-discovery. In its place, hackify graduates to a four-primitive plugin layout: `skills/` (workflows), `rules/` (always-on engineering law), `agents/` (formal sub-agent definitions), `hooks/` (UserPromptSubmit reminders). Each primitive owns the concern it is best at — and ONLY that concern. The hook is explicitly NON-routing: it injects `rules/hard-caps.md` into context every prompt, never classifies full vs quick from prompt content. Moving the classifier into the hook would just relocate the problem; this release deletes the classifier instead.

### Why

The v0.2.1 smart-router classifier was a custom prompt-content matcher embedded in two SKILL files plus a shared reference. Claude Code already does this work natively via skill `description` auto-discovery. The router added a second classifier on top of the native one, doubling the surface area, requiring its own validator check, and creating an ongoing maintenance contract between three files. v0.2.2 deletes the router, sharpens the three SKILL descriptions to do the same job through harness-native means, and uses the recovered conceptual space to ship the three plugin primitives that were always implicit in hackify's design.

### Changed — Smart router removed

- **`skills/hackify/references/smart-router.md`** — **deleted.** The canonical classifier file from v0.2.1 is gone. Routing is now description-based.
- **`skills/hackify/SKILL.md`** — `## Pre-flight: smart router — pick the right flow` stub block removed.
- **`skills/quick/SKILL.md`** — same stub block removed.
- **`skills/brainstorm/SKILL.md`** — `## When to invoke` section cross-reference paragraph to the smart router removed; `## File map` reference rewritten to point at description-based routing.
- **`README.md`** — "Smart router (v0.2.1)" paragraph removed; replaced with a "Plugin primitives (v0.2.2)" paragraph that lists `skills/ rules/ agents/ hooks/ commands/` and their respective concerns.
- **`scripts/validate-dod.sh`** — check `[27]` (smart-router cross-reference) deleted in W1; a new check `[33]` (router-excision invariant) added at the tail of the script to assert the file stays deleted and neither SKILL re-introduces a link to it.

### Added — Plugin primitives at the repo root

- **`rules/hard-caps.md`** — new short always-on engineering law (~40 lines). Function/file/param/nesting caps, lint-suppression ban, no-`!` rule, no-empty-catch rule, named-types rule, single-responsibility, refuse-on-sight anti-patterns. Injected into every prompt by the new UserPromptSubmit hook so the hard caps are always loaded.
- **`rules/code-quality.md`** — relocated canonical content of the deeper SOLID / DRY / types / layering doctrine (formerly `skills/hackify/references/code-rules.md`). 231 lines, skill-loaded on demand by Phase 2.5 Reviewer B and Phase 5 Reviewer B. The legacy `references/code-rules.md` path is preserved as a 6-line forwarding stub so existing intra-skill links keep working; both paths mirror to all 7 runtimes via `sync-runtimes.sh`.
- **`agents/`** — 7 formal Claude Code sub-agent definitions extracted from the templates in `skills/hackify/references/parallel-agents.md`. Three Phase 2.5 spec reviewers (`spec-reviewer-consistency`, `spec-reviewer-rules`, `spec-reviewer-dependencies`), three Phase 5 code reviewers (`code-reviewer-security`, `code-reviewer-quality`, `code-reviewer-plan-consistency`), and one Phase 3 wave task implementer (`wave-task-implementer`). Each file has YAML frontmatter (`name`, `description`) plus the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT — SEVERITY omitted on the implementer). claude-code-only — non-claude-code runtimes fall back to the inline templates in `parallel-agents.md`, which stays untouched.
- **`hooks/hooks.json`** + **`hooks/inject-hard-caps.sh`** — single UserPromptSubmit hook. The shell script emits a JSON envelope (`{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<rules>"}}`) so the harness treats the rules as injected context rather than a transcript message. NON-routing — the script never inspects the user prompt; it just reads `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md`. claude-code-only.

### Changed — Skill descriptions are the new routing mechanism

- **`skills/hackify/SKILL.md`** description — sharpened (1177 chars) to enumerate broad-spectrum verbs (`add`, `build`, `implement`, `refactor`, `redesign`, `restyle`, `migrate`, `debug`, `polish`, `audit`) AND architecture/scope/security surface (`auth`, `crypto`, `migration`, `secret`, `token`, `password`, `schema`, `data model`, `API surface`, `refactor everywhere`, `across all`). Explicit "When in doubt, invoke this skill" contract preserved.
- **`skills/quick/SKILL.md`** description — sharpened (1458 chars) to lead with explicit small-fix triggers (`quick fix`, `small change`, `just fix the`, `one-line fix`, `tiny edit`, `small fix`, `small bug`, `quick patch`, `minor tweak`, `just rename`, `fix typo`); explicit non-trigger list (cross-file refactor, redesign, debug, auth/crypto/migration); four fallback signals (attempt counter, file count, security path, user-invokes-full) kept intact as post-implementation circuit breakers.
- **`skills/brainstorm/SKILL.md`** description — sharpened (1273 chars) to enumerate idea-exploration triggers (`/brainstorm`, `let's discuss`, `let's think`, `what if`, `brainstorm`, `explore the idea`, `what do you think`, `considering`, `thinking about`); explicit non-trigger rule for build verbs that route to hackify/quick directly.

### Changed — sync-runtimes + validator

- **`scripts/sync-runtimes.sh`** `MIRROR_SOURCES` appended with `rules/hard-caps.md` and `rules/code-quality.md` (mirrors to all 7 runtimes). `CLAUDE_CODE_EXTRA` appended with the 7 `agents/*.md` files + `hooks/hooks.json` + `hooks/inject-hard-caps.sh` (mirrors to `dist/claude-code/` only). Both arrays remain explicit flat enumerations, not globs.
- **`scripts/validate-dod.sh`** — gained five new checks: `[29]` rules/ existence + non-empty, `[30]` agents/ has exactly the 7 expected files with matching frontmatter `name:`, `[31]` hooks/hooks.json parses as JSON and declares `UserPromptSubmit`, `[32]` `hooks/inject-hard-caps.sh` is executable, `[33]` smart-router file stays deleted and no SKILL re-introduces a link to it.

### Migration

No migration for skill users — slash commands, descriptions, and the work-doc contract are unchanged on the user-facing surface. Plugin authors who fork hackify pick up the new four-primitive contract: `rules/` for always-on law, `agents/` for parallel-dispatch defs, `hooks/` for prompt-time reminders, `skills/` for workflows.

## [0.2.1] — 2026-05-11

> **Patch label, refactor-only scope.** Pure refactor — no new features, no bug fixes against shipped behavior. Extracts the smart-router block to a single canonical reference shared by both SKILLs, hardens two validator checks flagged in the v0.2.0 Retrospective, and honestly retires the v0.2.0 AC10 gross target as a documented incompatibility (the router block was post-v0.2.0 additive prose, not pre-existing prose, so its extraction is gross-neutral against AC10's anchor). Wins are measured in net SKILL-file line reduction (−37 / −39) and single-source-of-truth architecture for the router rules.

### Changed — Smart-router single source of truth

- **`skills/hackify/references/smart-router.md`** — new canonical reference (62 lines). Holds the H1 title, rationale paragraph, three verbatim H3 signal-group sections (`### Signal group (i) — Brainstorm triggers`, `### Signal group (ii) — Full-mode triggers`, `### Signal group (iii) — Quick-eligible`), the 5-row decision table, the explicit default-to-full fallback rule (signal-group count ≠ 1), a `## Consumers` subsection naming both SKILLs that link here, and a `## Stub template (verbatim — for T2.1 and T2.2)` subsection containing the exact byte-stable stub used in both SKILL files.
- **`skills/hackify/SKILL.md`** smart-router section replaced with a 5-line stub linking to `references/smart-router.md`. File shrinks 386 → 349 lines (−37).
- **`skills/quick/SKILL.md`** smart-router section replaced with the same byte-stable stub. File shrinks 134 → 95 lines (−39).
- **Eliminates the ~42-line near-verbatim duplication** flagged in the v0.2.0 Retrospective as documented-but-fragile. Future router-rule edits land in ONE place; both SKILLs inherit by reference.

### Changed — Validator hardening

- **`scripts/validate-dod.sh` check `[2]`** (references count) switched from hardcoded equality (`-eq 10`) to minimum threshold (`-ge 11`), closing the v0.2.0 Retrospective follow-up that flagged the `eq N` pattern as fragile across version bumps.
- **`scripts/validate-dod.sh` check `[27]`** (router classifier) rescoped: greps each SKILL for the literal repo-rooted markdown link `(/skills/hackify/references/smart-router.md)` — not the bare filename, which would leak into CHANGELOG/README/work-doc occurrences — and separately greps `references/smart-router.md` for the three exact verbatim H3 headings. Same "router is documented" invariant, new anchors aligned to the post-extraction layout.
- **Stub link path** uses the repo-rooted leading-slash form `(/skills/hackify/references/smart-router.md)` so the same byte-stable stub works from both `skills/hackify/SKILL.md` AND `skills/quick/SKILL.md` (bare relative paths break for the second consumer because the reference lives under `skills/hackify/references/`, not `skills/quick/references/`).

### Changed — v0.2.0 AC10 disposition (retired, not recovered)

- **AC10 disposition reframed honestly.** The v0.2.0 work-doc Retrospective flagged AC10's gross-20%-on-pre-existing-prose target as missed and deferred to v0.2.1. v0.2.1 reframes that disposition: the router block was post-v0.2.0 additive prose, NOT pre-existing prose, so its extraction is gross-neutral against AC10's anchor. AC10's gross target is hereby **retired as a documented incompatibility** rather than "recovered." v0.2.1's win is measured in net SKILL-file line reduction (−37 / −39 across the two SKILLs) and single-source-of-truth architecture for the router.

## [0.2.0] — 2026-05-11

> **Minor-level scope, minor-level label.** First release where the plugin source is tool-agnostic: the canonical hackify source no longer hard-codes Claude Code tool names, and a runtime-sync script emits per-runtime distributions. Ships three new skills (`brainstorm`, `writing-skills`, `receiving-code-review`), a sprint-style work-doc vocabulary, a smart pre-Phase-1 router shared by full and quick modes, wave-end persistence + pause-checkpoint behavior, and a tightened token + soft-language pass on both SKILL files. No breaking change to the workflow phases, the 7-section sub-agent contract, or the Wizard contract; archived pre-0.2.0 work-docs work without migration.

### Added — Multi-runtime support

- **Tool-agnostic prose pass on `skills/hackify/SKILL.md`.** Concrete Claude Code tool names replaced with runtime primitive names (`wizard tool` / `subagent dispatcher` / `file-read op` / `file-write op` / `file-edit op` / `search` / `shell`). Wizard contract, Template contract, and 7-section sub-agent contract tokens preserved verbatim.
- **`references/runtime-adapters.md`** — new reference. 7×8 primitive-to-native-tool mapping table plus a 3-tier (`native` / `best-effort` / `not supported`) plugin-support matrix covering Claude Code, OpenAI Codex CLI, OpenAI Codex App, Google Gemini CLI, OpenCode, Cursor, and GitHub Copilot CLI.
- **`scripts/sync-runtimes.sh`** — new script (479 lines, POSIX/macOS-portable, `--dry-run` aware, idempotent). Converts the canonical hackify source into runtime-specific plugin packages under `dist/<runtime>/`. New `dist/.gitignore` (`*` plus `!.gitignore`) keeps generated output untracked while pinning the directory shape.
- **`## Runtime primitives — where the tool names go`** — new trailing section in `skills/hackify/SKILL.md` cross-referencing `references/runtime-adapters.md` so authors land on the mapping table the first time they hit a primitive.

### Added — New skills

- **`skills/brainstorm/SKILL.md`** (97 lines) — Socratic pre-task refinement mode. Auto-discovery triggers: `/brainstorm`, "let's discuss", "let's think", "what if", "brainstorm", "explore the idea". Graduation rule: when the user signals "build this", lazily creates the work-doc with a `## Brainstorm Provenance` block and hands off to Phase 1 of full hackify. One-doc-per-task philosophy preserved.
- **`skills/writing-skills/SKILL.md`** (128 lines) — hackify-specific meta-skill for authoring new hackify-conformant skills. Bundles a 9-check self-validation checklist covering frontmatter, triggers, required sections, the 7-section sub-agent contract, the Wizard contract, OUTPUT word-caps, soft-language scan, file size, and path conventions.
- **`skills/receiving-code-review/SKILL.md`** (109 lines) — structured per-finding response. Required table columns: Finding / Severity / Decision / Evidence; Decision ∈ {`accept`, `push-back`, `defer`}. Two trigger paths: Phase 5 internal multi-reviewer findings AND external feedback paste (PR comments, Slack quotes). Critical-findings guardrail: no bare push-back without Phase 5 escalation.

### Added — Sprint-style work-doc

- **`references/work-doc-template.md`** body sections relabeled to sprint vocabulary: `Definition of Done` → `Acceptance Criteria`, `Tasks` → `Sprint Backlog`, `Implementation Log` → `Daily Updates`, `Verification` → `Sprint Review`, `Post-mortem` → `Retrospective`. New `sprint_goal` frontmatter field. Back-compat: `skills/hackify/SKILL.md` resume-mode accepts either label set, so archived pre-v0.2.0 docs in `docs/work/done/` work without migration.

### Added — Smart router

- **Pre-Phase-1 router block** added to both `skills/hackify/SKILL.md` and `skills/quick/SKILL.md`. Three signal groups: (i) brainstorm triggers, (ii) full-mode triggers (auth/crypto/migration keywords, multi-file scope keywords, architecture keywords, prompt length > 80 chars, explicit `/hackify:hackify`), (iii) quick-eligible. Default-to-full rule fires when the matched signal-group count ≠ 1.

### Added — Wave-end persistence + pause checkpoint

- **Phase 3 wave-end persistence rule.** Parent MUST update the work-doc (tick checkboxes, append a Daily Updates entry, run verification, advance `current_task`) BEFORE dispatching wave N+1. Stops the "all waves done, no work-doc updates" failure mode.
- **Pause-keyword detection** during an active wave. Trigger words: `pause`, `stop`, `exit`, `later`, `tomorrow`, `come back`, `pick this up later`. Match runs the 5-step Pause Checkpoint procedure ending with the surface text "Resume with 'continue work on <slug>'".

### Changed — Token + Haiku pass

- **`skills/hackify/SKILL.md`** Token-efficiency pass: 422 → 378 lines (T4.1, net 10.4%). Mandatory pause-checkpoint + wave-end-persistence insertion (T4.3) then added 8 lines, landing the final file at **386 lines**. Net AC10 target (≤380) missed by 6 lines because T4.3 is contract-required. Gross 20% target on pre-existing prose was deemed incompatible with AC fidelity; both gaps documented in the v0.2.0 work-doc Retrospective.
- **`skills/quick/SKILL.md`** 162 → 134 lines (net 17.3%, gross ~28 lines). Three prose-to-table conversions land most of the saving.
- **Soft-language audit** across both SKILL files: 0 matches for `if reasonable`, `consider`, `maybe`, `try to`, `usually`, `as appropriate`, `where possible` outside the Anti-rationalizations block and explicit examples.

### Changed — Validator

- **`scripts/validate-dod.sh`** extended with five new check groups: `[24]` `sync-runtimes` dry-run output; `[25]` new-skill SKILL.md presence + frontmatter + `name` regex (`^[a-z0-9-]{1,64}$`) for `brainstorm`, `writing-skills`, `receiving-code-review`; `[26]` sprint vocabulary tokens present in `references/work-doc-template.md`; `[27]` router classifier block present in both SKILL files; `[28]` pause-keyword list present in `skills/hackify/SKILL.md`.

### Fixed — Internal

- **`references/` count check** in `scripts/validate-dod.sh` updated from 9 to 10 to reflect the new `runtime-adapters.md` added by T3.2.

## [0.1.4] — 2026-05-11

> **Patch label, minor-level scope.** Two new ergonomics features ship under a patch label per release-cadence preference. No breaking change to the workflow shape or template contracts; v0.1.3 templates and wizard banks ship unchanged.

### Added — Summary table feature

- **Phase 6 Step F — Summary table.** Full hackify now ends with a concise 2-column Area/Change markdown table printed to chat AND appended to the archived work-doc under `## Summary of changes shipped`. Authoring rules + worked example in `references/finish.md`.
- **`/hackify:summary` slash command** at `commands/summary.md` — invokable any time during a task to print the current Area/Change recap on demand. Body conforms to the v0.1.3 7-section sub-agent contract (Shape B Self-checklist VERIFICATION; SEVERITY omitted as it is a generation task).
- **Phrase triggers** — saying "show summary", "summarize", "summary table", or "show me what changed" routes to the same logic as `/hackify:summary`.
- **Authoring guidance** — `references/finish.md` gains a "Summary table — authoring guidance" subsection covering Area-label rules (1–4 words, concept/theme), Change-cell rules (≤25 words, backticks for tech terms), grouping heuristics, and a 5-row worked example.

### Added — Compressed-flow `/hackify:quick` skill

- **New skill at `skills/quick/SKILL.md`** registers `/hackify:quick` as a compressed alternative to full hackify for small bug fixes, single-file edits, polish/typo work, and quick direct-effort tasks.
- **Workflow shape:** Phase 1 Clarify (full wizard if ambiguous; zero questions otherwise) → Phase 3 Implement (single agent or inline) → Phase 4 Verify (test + lint + typecheck) → Phase 6 Step F (Summary table — mandatory).
- **Skipped phases:** Phase 2 Plan+Gate, Phase 2.5 Spec self-review, Phase 5 Multi-reviewer, Phase 6 four-options finish. Phase 3b Debug-when-stuck is NOT skipped — the fallback rule below escalates to full hackify which handles Phase 3b normally.
- **Fallback-to-full-hackify** triggers (all testable predicates): (a) implementation-attempt counter reaches 2; (b) `git diff --name-only HEAD | wc -l > 3`; (c) any touched path matches `*auth*`/`*crypto*`/`*migration*`/`*secret*`/`*token*`/`*password*`; (d) user prompt during the task contains `Phase 5`, `multi-reviewer`, or `do full review`. Fallback procedure writes a work-doc from accumulated context and re-enters full hackify Phase 2.
- **Single-implementation-agent cap** — quick mode dispatches at most one implementation subagent. Needing parallel agents is a fallback signal.

### Changed

- **`skills/hackify/SKILL.md`** Phase 6 section gains explicit Step F (Summary table) between Step E and the section trailer; "When to invoke" section gains a one-line carve-out pointing readers at `/hackify:quick` for small tasks.

### Validator

- **Checks `[18]`–`[23]` added** to `scripts/validate-dod.sh`: `[18]` `commands/summary.md` exists with `description:` frontmatter and `Area`/`Change` body tokens; `[19]` SKILL.md Phase 6 section contains `Summary table` and references `/hackify:summary`; `[20]` `references/finish.md` contains the Summary-table authoring subsection with `| Area |` worked-example header; `[21]` `skills/quick/SKILL.md` exists with `name:` (regex `^[a-z0-9-]{1,64}$`) and `description:` frontmatter; `[22]` quick-mode SKILL.md contains `Skipped phases` and the 4 skipped-phase tokens (Phase 2, Phase 2.5, Phase 5, four-options); `[23]` quick-mode SKILL.md contains `Summary table` (mandatory step is documented).

## [0.1.3] — 2026-05-11

> **Patch label, minor-level scope.** Despite being a patch release, this is a substantial rewrite of every sub-agent prompt and every clarify-wizard bank in the plugin. The label reflects the maintainer's release-cadence preference, not the underlying change size. Users upgrading from 0.1.2 should expect templates to look different — the workflow phases and DoD shapes are unchanged.

### Closed — the six canonical bugs from the v0.1.0 post-mortem

1. **Soft severity language let unverifiable schema findings get downgraded.** Reviewer A flagged `"source": "."` as "Important — may break under future schema tightening." That qualifier let it be deferred. Result: v0.1.0 install rejected; v0.1.1 + v0.1.2 reshipping cost.
2. **No cross-file consistency requirement in author prompts.** The README author agent had no rule binding its hero tagline to the `plugin.json` / `marketplace.json` descriptions. Phase 5 caught the four-way drift after the fact.
3. **No inline verification scripts in many templates.** Agents reported "done" without running the checks that would have caught their own gaps (evals.json contamination almost shipped).
4. **No anchored severity rubrics.** "Mark Critical / Important / Minor" without anchored examples produced inconsistent reviewer outputs.
5. **No placeholder syntax for dispatch-time values.** Each dispatching call handwrote paths and constraints; drift between calls was inevitable.
6. **Research-phase prompts didn't verify the architectural behaviors the plan depended on.** The "commands inside a plugin are namespaced" property wasn't asked about explicitly — only Phase 2.5 caught it.

### Added

- **`references/parallel-agents.md` "Template Contract" preamble** — canonical 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT). Every sub-agent template in the file conforms. ROLE has 5 mandatory elements: identity + seniority, domain expertise, named standards (cited from a version-pinned allowlist — OWASP Top 10 2021, NIST SP 800-63B, RFC 6749, RFC 7519, WCAG 2.2 AA, SOLID, Clean Code, Conventional Commits 1.0.0, Semantic Versioning 2.0.0, Keep a Changelog 1.1.0, ISO 8601, Postel's law, expand-then-contract migrations), rejected anti-patterns (≥3), behavioral bias (`Bias to:` / `Bias against:`). VERIFICATION comes in two shapes: Executable bash for filesystem-touching templates, Self-checklist yes/no list for prose-producing ones.
- **`references/clarify-questions.md` "Wizard Contract" preamble** — canonical 4-section structure for every task-type bank (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA). Recommended-first rule documented (option A suffixed " (Recommended)"). Decision-rule COMPOSITION replaces free-choice "use judgment" guidance.
- **`{{snake_case}}` placeholders** for every dispatch-time runtime value. Placeholders are documentation to the dispatching agent (not the sub-agent); a sub-agent receiving literal `{{...}}` text is a dispatch bug.
- **Verbatim canonical SEVERITY line** in every review template: "If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important."
- **`scripts/validate-dod.sh`** extended with six new checks: [9] template structural conformance, [10] SEVERITY conditional (review templates have it, build/research don't), [11] canonical SEVERITY phrase, [12] ROLE 5-element substance check, [13] no leaked absolute paths in template bodies, [14] wizard structural conformance. Existing checks [1]–[8] unchanged.

### Changed

- All 11 sub-agent templates in `references/parallel-agents.md` rewritten to the 7-section contract: Phase 1 Research, Phase 2.5 Spec-review A/B/C, Phase 3 Implementation wave, Phase 3b Debug evidence, Phase 4 Cross-package verification, Phase 5 Multi-reviewer A/B/C, Phase 5 Code-review escalation. Six are review/audit templates (SEVERITY mandatory); four are build/research (SEVERITY omitted); Code-review escalation is a single-specialist review (SEVERITY mandatory).
- All 7 clarify wizard banks in `references/clarify-questions.md` rewritten to the 4-section contract: Universal preamble, feature, fix, refactor, revamp/redesign, debug, research.
- The escalation reviewer in `references/review-and-verify.md` rewritten to the 7-section contract.
- `skills/hackify/SKILL.md` adds two short cross-references pointing readers at the Template Contract and the Wizard Contract; no other content drift.

### Migration notes (for users running 0.1.2)

- Existing in-flight work-docs need no migration — the workflow shape is unchanged.
- Custom sub-agent prompts in user projects can adopt the 7-section contract incrementally. Running `bash scripts/validate-dod.sh` from the plugin source after editing surfaces the same checks the plugin's own templates pass.

## [0.1.2] — 2026-05-11

### Fixed

- `marketplace.json` plugin source switched from `github` type (which delegates to the user's local git protocol — SSH by default for many setups) to the explicit `url` type with an HTTPS clone URL. Public-repo HTTPS clones need no SSH key or GitHub auth, so the plugin now installs for any user who can `git clone https://github.com/nadyshalaby/hackify.git` from their machine. Resolves "Permission denied (publickey)" install errors on machines without GitHub SSH access.

### Added

- README "Troubleshooting" section covering the three most common install failures: source-type rejection (fixed in 0.1.1), SSH host-key prompts (one-liner with `ssh-keyscan`), and SSH auth errors (the protocol switch shipped in 0.1.2).

## [0.1.1] — 2026-05-11

### Fixed

- `marketplace.json` `plugins[0].source` was set to the bare string `"."`, which the current Claude Code plugin-marketplace schema rejects with "This plugin uses a source type your Claude Code version does not support." Replaced with the documented typed-object form `{"source": "github", "repo": "nadyshalaby/hackify"}`. `/plugin install hackify@hackify-marketplace` now succeeds against the published GitHub repo.

## [0.1.0] — 2026-05-11

### Added

- Initial public release.
- Single skill `hackify` invokable as `/hackify:hackify` after install.
- Six-phase workflow: Clarify → Plan + Gate → Spec self-review → Implement (parallel waves) → Verify → Review (parallel reviewers) → Finish.
- Per-task markdown work-doc convention at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`.
- Nine reference files covering: clarify question banks, code rules, debug playbook, finish protocol, frontend-design heuristics, TDD walkthrough, parallel-agent dispatch templates, review checklist, work-doc template.
- Optional `evals/evals.json` for use with the `skill-creator` plugin (harmless if not installed).
- Self-hosted marketplace metadata in `.claude-plugin/marketplace.json` so the plugin is installable via `/plugin marketplace add nadyshalaby/hackify` → `/plugin install hackify@hackify-marketplace`.

## Maintenance notes

- **Every release MUST bump `version` in `.claude-plugin/plugin.json`.** Claude Code uses that field to detect updates for installed users — pushing further commits without a version bump is invisible to existing installs.
- Pair every `version` bump with a new entry in this CHANGELOG and a corresponding git tag (`v0.x.y`).
- Breaking workflow changes (e.g., a renamed phase, a removed reference file, a different work-doc schema) bump the minor version while the plugin is on `0.x.y`, and the major version once it reaches `1.0.0`.
