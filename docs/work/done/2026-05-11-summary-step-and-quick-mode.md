---
slug: summary-step-and-quick-mode
title: v0.1.4 — Phase 6 summary table, /hackify:summary command, and /hackify:quick compressed-flow skill
status: planning
type: feature
created: 2026-05-11
project: hackify
current_task: (none — awaiting gate)
worktree: /Users/corecave/Code/hackify
branch: main
related:
  - docs/work/done/2026-05-11-hackify-skill-to-plugin.md
  - docs/work/done/2026-05-11-prompts-re-engineering.md
---

# v0.1.4 — Phase 6 summary table + /hackify:summary command + /hackify:quick compressed-flow skill

## Original Ask (verbatim, two prompts)

> [prompt 1] I want to add a final summary step and command that can be called that to show all changes made so far in very concise table format like this picture [reference image of 2-column Area/Change table] so the user is totally aligned with the changes

> [prompt 2] I would like to add quick skill+command that do the exact same flow from a to z without filling/creating any work docs or any other documents. and also we can skip unnecessay phases. and this will be used in quick and small tasks like bug fixes and quick direct request tasks that won't take too much effort. it should not consume too much tokens or long time

## Reference design (summary table)

Concise 2-column markdown table:

| Area | Change |
|---|---|
| Plugin manifest | `version` bumped to `0.1.4` |
| Quick mode skill | new `skills/quick/SKILL.md` registers `/hackify:quick` |
| Validator | check `[21]` asserts quick-mode skill has the mandatory frontmatter |

Area = 1–4 word concept/theme label. Change = ≤25 words, backticks for technical terms.

## Reference design (quick mode flow)

```
Phase 1  Clarify       ── full wizard if ambiguity exists; else 0 questions
Phase 3  Implement     ── single agent OR inline if trivial; file allowlist
Phase 4  Verify        ── test + lint + typecheck; no fresh-evidence ceremony
Phase 6F Summary       ── 2-column Area/Change table (mandatory)

Skipped: Phase 2 Plan + Gate, Phase 2.5 Spec review, Phase 5 Multi-reviewer,
         Phase 6 four-options finish.

Note: Phase 3b Debug-when-stuck is NOT in the "skipped" list. Quick mode
does not enter Phase 3b explicitly; instead, the fallback rule (below)
escalates to full hackify if implementation hits trouble. Full hackify
then enters Phase 3b normally.
```

Target: ~1/3 the tokens and wall-clock of the full hackify flow for tasks that fit the carve-out.

## Clarifying Q&A (locked)

1. **Summary table auto-trigger** — print only at Phase 6 step F (full hackify) AND at end of quick mode. Always invokable on-demand via slash command.
2. **Area column** — hand-authored concept/theme labels.
3. **Output destinations** — chat + appended to work-doc Post-mortem (full hackify only; quick mode has no work-doc to append to, so chat only).
4. **Summary command shape** — both phrase-triggered inside main hackify skill AND explicit `commands/summary.md`.
5. **Bundling** — both features ship as v0.1.4.
6. **Quick mode phases** — skip Plan+Gate, Spec review, Multi-reviewer, 4-options finish. Summary table is mandatory.
7. **Quick mode clarify** — full clarify wizard if ambiguity exists; zero questions otherwise.
8. **Quick mode location** — `skills/quick/SKILL.md` (registers as `/hackify:quick`). Single skill, not also a duplicate `commands/quick.md`.

## Assumptions (correct in chat or at gate)

- Release as **v0.1.4 patch**. Two new features → minor bump under strict SemVer, but maintainer's release-cadence preference is patch labels for `0.x.y` development. CHANGELOG flags this.
- Quick mode falls back to FULL hackify on any of 4 testable triggers: (a) implementation-attempt counter reaches 2 (quick mode tracks attempts in its own state); (b) `git diff --name-only HEAD | wc -l` returns > 3 (cross-file scope creep); (c) any path touched matches the security-sensitive glob `*auth*`/`*crypto*`/`*migration*`/`*secret*`/`*token*`/`*password*`; (d) user prompt during the task contains any of the phrases `Phase 5`, `multi-reviewer`, `do full review`. On fallback, quick mode writes a work-doc from scratch from the accumulated context and re-enters Phase 2.
- `commands/summary.md` and `skills/quick/SKILL.md` are independent — `/hackify:summary` and `/hackify:quick` are separate commands. No name collision (different filenames register as different `/hackify:<name>` commands).
- Quick mode's own SKILL.md frontmatter `description` field follows the existing skill auto-discovery convention used by `skills/hackify/SKILL.md` (≤150 word description, names triggers).
- The summary command body itself follows the v0.1.3 7-section sub-agent contract (since it's a generation prompt the assistant executes), with VERIFICATION Shape B (self-checklist — it produces prose).
- Quick mode SKILL.md does NOT need to conform to the 7-section sub-agent contract — that contract is for sub-agent dispatch prompts, not for top-level skill files. (Same as `skills/hackify/SKILL.md` doesn't.)
- Quick mode dispatches at most ONE implementation subagent (per its compression goal). If the task naturally requires multiple parallel agents, that's a signal to fall back to full hackify.

## Definition of Done

- [ ] **D1 (summary command)** `commands/summary.md` exists at plugin root. Frontmatter has `description:` ≤80 chars. Body conforms to the v0.1.3 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION [Shape B] / OUTPUT — no SEVERITY, it's a generation task). ROLE cites Conventional Commits 1.0.0, Keep a Changelog 1.1.0, RFC 2119 keywords. METHOD instructs: locate active work-doc; extract DoD + Implementation Log + Tasks; group changes into 5–12 conceptual themes; author Area (1–4 words) and Change (≤25 words, `backticks` for code spans) per row; emit markdown table.
- [ ] **D2 (Phase 6 step F)** `skills/hackify/SKILL.md` Phase 6 section gains an explicit "Step F — Summary table" between current Step E and the section trailer. Names: generate the table, print to chat, append to the archived work-doc Post-mortem under `## Summary of changes shipped`.
- [ ] **D3 (phrase triggers)** `skills/hackify/SKILL.md` documents the summary phrase triggers ("show summary" / "summarize" / "summary table" / "show me what changed") and the on-demand slash command `/hackify:summary`. One short paragraph.
- [ ] **D4 (summary authoring guide)** `skills/hackify/references/finish.md` gains a `## Summary table — authoring guidance` subsection with Area-label rules, Change-cell rules, grouping heuristics, and a 3–5 row worked example.
- [ ] **D5 (quick mode skill)** `skills/quick/SKILL.md` exists. Frontmatter has `name: quick` (must match regex `^[a-z0-9-]{1,64}$` per Claude Code skill schema) + `description:` (≤1500 chars total — well under Claude Code's 1,536-char cap; names the carve-out "small bug fixes, direct quick-effort requests, single-file edits" with auto-discovery triggers "quick fix", "small change", "/hackify:quick", "just fix"). Body documents the compressed phase list (1 → 3 → 4 → 6F), explicit list of skipped phases with rationale, fallback rule to full hackify with 4 testable triggers, single-implementation-agent cap, summary-table-mandatory clause.
- [ ] **D6 (quick mode skipped phases)** `skills/quick/SKILL.md` lists EXACTLY these skipped phases with one-line rationale each: Phase 2 (Plan+Gate), Phase 2.5 (Spec self-review), Phase 5 (Multi-reviewer), Phase 6 four-options finish. Lists EXACTLY these kept phases: Phase 1 Clarify (full wizard if needed, zero questions otherwise), Phase 3 Implement (single agent or inline), Phase 4 Verify (test + lint + typecheck), Phase 6 Step F (Summary table — mandatory).
- [ ] **D7 (quick mode fallback)** `skills/quick/SKILL.md` documents the 4 testable fallback triggers exactly as named in the Assumptions section: (a) implementation-attempt counter reaches 2 (skill body MUST define how the counter is maintained — propose: increment in the agent's report after each implementation pass); (b) `git diff --name-only HEAD | wc -l` returns > 3; (c) any path touched matches the security-sensitive glob `*auth*`/`*crypto*`/`*migration*`/`*secret*`/`*token*`/`*password*`; (d) user prompt during the task contains any of `Phase 5`, `multi-reviewer`, `do full review`. Each trigger is testable inside the quick-mode flow; vague signals like "feels big" are explicitly forbidden.
- [ ] **D8 (main SKILL.md mentions quick)** `skills/hackify/SKILL.md` "When to invoke" section adds a one-line carve-out note pointing readers at `/hackify:quick` for small/quick tasks.
- [ ] **D9 (version)** `.claude-plugin/plugin.json` `version` and `.claude-plugin/marketplace.json` `plugins[0].version` both `0.1.4`.
- [ ] **D10 (CHANGELOG)** `CHANGELOG.md` `## [0.1.4]` entry at top with patch-label-minor-scope caveat; `### Added` lists: Phase 6 summary table step, `/hackify:summary` slash command, phrase triggers, summary authoring guidance, `/hackify:quick` compressed-flow skill, quick-mode skipped-phase list, fallback-to-full-hackify rule.
- [ ] **D11 (validator)** `scripts/validate-dod.sh` extended with new checks (existing `[1]`–`[17]` unchanged and still pass):
   - `[18]` `commands/summary.md` exists; frontmatter contains `description:`; body contains the literal `Area` and `Change` tokens (used for the table header).
   - `[19]` `skills/hackify/SKILL.md` Phase 6 section contains the literal `Summary table` AND `/hackify:summary`.
   - `[20]` `skills/hackify/references/finish.md` contains the literal `Summary table` AND both `Area` and `Change` as table-cell header markers.
   - `[21]` `skills/quick/SKILL.md` exists; frontmatter has `name:` and `description:` fields.
   - `[22]` `skills/quick/SKILL.md` contains the literal `Skipped phases` AND lists Phase 2, Phase 2.5, Phase 5, four-options.
   - `[23]` `skills/quick/SKILL.md` contains the literal `Summary table` (so quick-mode summary is documented as mandatory).
- [ ] **D12 (validator clean)** `validate-dod.sh` exits 0 across `[1]`–`[23]`.
- [ ] **D13 (token scrub)** 0 hits for Syanat / SyanatBackend / SyanatFrontend / graphify / corecave / nadyshalaby across `skills/`, `commands/`, `README.md`, `CHANGELOG.md`.
- [ ] **D14 (no regression to v0.1.3 contracts)** Reviewer C explicitly verifies that `skills/hackify/references/parallel-agents.md` (11 templates), `skills/hackify/references/clarify-questions.md` (7 wizard banks), AND `skills/hackify/references/review-and-verify.md` (escalation reviewer) are NOT modified by this task. Baseline retrieval: `git show v0.1.3:<path>` for each of the three files.
- [ ] **D15 (commit + tag + push)** Single commit. Tag `v0.1.4`. Push commit AND tag.
- [ ] **D16 (work-doc archive dogfoods feature)** Archive at `docs/work/done/2026-05-11-summary-step-and-quick-mode.md` with Post-mortem ≥6 bullets AND the Area/Change Summary table appended under `## Summary of changes shipped` (dogfooding the very feature this release adds).

## Approach

Ship two related ergonomics features in one release. The summary feature adds a Phase 6 Step F to the existing full-hackify flow that prints and persists a 2-column Area/Change table, plus an on-demand slash command. The quick-mode feature adds a separate `skills/quick/SKILL.md` skill registering `/hackify:quick` for small tasks: skips Plan+Gate, Spec review, Multi-reviewer, and the 4-options finish, keeps Clarify (only if ambiguous), Implement, Verify, and the mandatory Summary table. Quick mode falls back to full hackify on signal (multi-file scope creep, security-sensitive code, failed attempts). Validator gains six new checks. Single commit, single tag, dogfooded by the work-doc archive itself.

### Execution waves

```
Wave 1 (parallel inline — 6 disjoint file scopes):
  T1  commands/summary.md (new file)
  T2  skills/quick/SKILL.md (new file)
  T3  skills/hackify/SKILL.md edits (Phase 6 Step F + phrase triggers + "when to invoke" carve-out)
  T4  skills/hackify/references/finish.md edits (Summary table authoring subsection)
  T5  plugin.json + marketplace.json version bump (single file each; trivially serial)
  T6  CHANGELOG.md v0.1.4 entry

Wave 2 (validator extension; depends on Wave 1's new file paths existing):
  T7  Extend scripts/validate-dod.sh with checks [18]–[23]

Wave 3 (verify):
  T8  Run validate-dod.sh; loop on failures

Wave 4 (review — three parallel reviewers, prompts conform to v0.1.3 7-section contract):
  T9  Reviewer A — contract conformance + DoD coverage matrix
  T10 Reviewer B — weak-model robustness of commands/summary.md AND skills/quick/SKILL.md
  T11 Reviewer C — regression check: v0.1.3 templates/banks NOT modified; validator [1]–[17] still pass

Wave 5 (finish):
  T12 Apply review patches (Critical immediately; Important before tag); re-run validator; commit; tag v0.1.4; push commit + tag; archive work-doc with Post-mortem + Summary table (dogfooding)
```

## Tasks

- [ ] **T1** — Ensure `commands/` directory exists (`mkdir -p /Users/corecave/Code/hackify/commands`), then author `commands/summary.md` at plugin root. Frontmatter `description:` (e.g. "Print a concise 2-column Area/Change table of every change shipped in the current hackify task. Append to the archived work-doc when invoked at Phase 6 finish; print-only when invoked mid-flight."). Body conforms to the v0.1.3 7-section sub-agent contract: ROLE (senior technical writer; standards: Conventional Commits 1.0.0, Keep a Changelog 1.1.0, RFC 2119; rejects vague Area labels, Change cells over 25 words, prose preambles); INPUTS (`{{work_doc_path}}` resolved by locating most-recent `docs/work/*.md` or `docs/work/done/*.md`; `{{invocation_phase}}` either `mid-flight` or `phase-6-finish`); OBJECTIVE (single noun-phrase: "a 2-column Area/Change markdown table"); METHOD (locate work-doc → extract changes → group into 5–12 themes → author Area+Change per row → emit table); VERIFICATION Shape B self-checklist (≥5 yes/no items); OUTPUT (markdown table + 1-line follow-up offer + nothing else; word cap `≤500 words` to allow for larger projects).

- [ ] **T2** — Ensure `skills/quick/` directory exists (`mkdir -p /Users/corecave/Code/hackify/skills/quick`), then author `skills/quick/SKILL.md`. Frontmatter: `name: quick`, `description:` (≤150 words; names auto-discovery triggers: "/hackify:quick", "quick fix", "small change", "just fix the", "one-line fix"; names the carve-out: small bug fixes, direct quick-effort tasks, single-file edits, polish/typo work). Body sections: "Workflow shape" (compressed 4-phase list 1→3→4→6F with arrow diagram), "Skipped phases" (Phase 2, 2.5, 5, 6-four-options with one-line rationale each), "Kept phases" (Phase 1 clarify-if-needed, Phase 3 single-agent or inline, Phase 4 verify, Phase 6F summary-mandatory), "Fallback to full hackify" (4 trigger conditions: 2+ failed implementation attempts; >3 files touched; security-sensitive code; user explicitly requests Phase 5 review), "When NOT to use quick mode" (cross-file refactors, redesigns, debug investigations, anything with security or migration surface), "Anti-rationalizations" table (3–5 rows; e.g. "It's just a small fix" → "Run quick. If it touches >3 files, fall back.").

- [ ] **T3** — Edit `skills/hackify/SKILL.md`:
   - In Phase 6 section, after Step E (worktree cleanup), insert `**Step F — Summary table.**` paragraph: generate Area/Change table, print to chat, append to archived work-doc Post-mortem under `## Summary of changes shipped`. Reference `references/finish.md` for authoring guidance.
   - In Phase 6 section, add a short paragraph documenting phrase triggers ("show summary", "summarize", "summary table", "show me what changed") and the explicit slash command `/hackify:summary`. Both invoke the same logic.
   - In "When to invoke" section near the top, add one bullet noting `/hackify:quick` as a compressed-flow alternative for small bug fixes and quick direct-effort tasks.

- [ ] **T4** — Edit `skills/hackify/references/finish.md`. Add a new `## Summary table — authoring guidance` subsection after the existing Phase 6 4-options content. Contents: Area-label rules (1–4 words; concept/theme NOT file-path NOT DoD-ID; mirror user's reference image), Change-cell rules (≤25 words; backticks for code spans; present-tense action verbs), grouping heuristics (cluster by file family OR DoD bullet OR conceptual theme; merge near-duplicates), worked example (3–5 rows reflecting a generic feature add).

- [ ] **T5** — Bump `.claude-plugin/plugin.json` `version` to `0.1.4`; bump `.claude-plugin/marketplace.json` `plugins[0].version` to `0.1.4`.

- [ ] **T6** — Add `## [0.1.4]` entry to top of `CHANGELOG.md`. Patch-label-minor-scope caveat. `### Added` bullets: (a) Phase 6 Step F summary table prints + appends to work-doc Post-mortem; (b) `/hackify:summary` slash command for on-demand invocation; (c) phrase triggers route to the summary command; (d) `references/finish.md` authoring guidance + worked example; (e) `/hackify:quick` compressed-flow skill for small tasks (1→3→4→6F); (f) quick-mode skipped phases (2, 2.5, 5, 6-four-options) with one-line rationale; (g) fallback-to-full-hackify rule (4 triggers). `### Changed` bullets: SKILL.md main file gains Phase 6 Step F + phrase-triggers paragraph + "When to invoke" quick-mode pointer. `### Validator` bullet: checks `[18]`–`[23]` added.

- [ ] **T7** — Extend `scripts/validate-dod.sh` with six new check sections, preserving `[1]`–`[17]` unchanged:
   - `[18]` `test -f commands/summary.md` AND `head -10 commands/summary.md | grep -q '^description:'` AND `grep -qF 'Area' commands/summary.md && grep -qF 'Change' commands/summary.md`.
   - `[19]` `awk '/^## Phase 6/{flag=1; next} flag && /^## /{flag=0} flag' skills/hackify/SKILL.md | grep -qF 'Summary table'` AND `grep -qF '/hackify:summary' skills/hackify/SKILL.md`.
   - `[20]` `grep -qF 'Summary table' skills/hackify/references/finish.md` AND `grep -qF '| Area |' skills/hackify/references/finish.md` (worked-example header).
   - `[21]` `test -f skills/quick/SKILL.md` AND `head -10 skills/quick/SKILL.md | grep -qE '^name:' && head -10 skills/quick/SKILL.md | grep -qE '^description:'`.
   - `[22]` `grep -qF 'Skipped phases' skills/quick/SKILL.md` AND `grep -qF 'Phase 2' skills/quick/SKILL.md && grep -qF 'Phase 2.5' skills/quick/SKILL.md && grep -qF 'Phase 5' skills/quick/SKILL.md && grep -qF 'four-options' skills/quick/SKILL.md`.
   - `[23]` `grep -qF 'Summary table' skills/quick/SKILL.md` (quick mode documents the mandatory summary step).

- [ ] **T8** — Run `bash scripts/validate-dod.sh`. Paste output. Loop on failures.

- [ ] **T9** — Dispatch parallel foreground subagent **Reviewer A — contract conformance + DoD coverage**. Prompt follows v0.1.3 7-section contract. Audits: does `commands/summary.md` body conform to the sub-agent template contract? Does `skills/quick/SKILL.md` frontmatter follow the same auto-discovery convention as `skills/hackify/SKILL.md`? Does every D1–D16 DoD bullet have validator automation OR a clear manual check? ≤300 words.

- [ ] **T10** — Dispatch parallel foreground subagent **Reviewer B — weak-model robustness**. Read `commands/summary.md` AND `skills/quick/SKILL.md` simulating Haiku-class execution. Flag: any METHOD step requiring unstated context; "use judgment" wording in either file; ambiguity in "locate active work-doc"; quick-mode skipped-phase list that a weak model could misread as "skip everything"; fallback triggers that aren't testable. ≤350 words.

- [ ] **T11** — Dispatch parallel foreground subagent **Reviewer C — regression check**. Verify by diff: `skills/hackify/references/parallel-agents.md` (11 templates) UNMODIFIED, `skills/hackify/references/clarify-questions.md` (7 wizard banks) UNMODIFIED, `skills/hackify/references/review-and-verify.md` UNMODIFIED. Verify `scripts/validate-dod.sh` checks `[1]`–`[17]` still pass on the v0.1.4 tree. Verify token scrub clean. ≤200 words.

- [ ] **T12** — Apply review patches (Critical immediately; Important before tag; Minor → CHANGELOG follow-ups for v0.1.5). Re-run validator. Commit with conventional-commit message. Tag `v0.1.4`. Push commit AND tag. Archive work-doc to `docs/work/done/2026-05-11-summary-step-and-quick-mode.md` with Post-mortem (≥6 bullets) AND the Area/Change Summary table appended under `## Summary of changes shipped` — dogfooding the v0.1.4 feature within v0.1.4's own work-doc.

## Implementation Log

_(filled in per completed task during Phase 3.)_

## Verification

_(filled in during Phase 4 — paste fresh `validate-dod.sh` output covering `[1]`–`[23]`.)_

## Post-mortem

_(filled in during Phase 6 — MUST include the Area/Change Summary table under `## Summary of changes shipped`.)_
