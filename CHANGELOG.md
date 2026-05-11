# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
