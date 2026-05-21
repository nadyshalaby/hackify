---
slug: 2026-05-21-tech-neutral-principles
title: Tech-neutral rewrite + Karpathy four-principles integration
status: implementing
type: refactor
created: 2026-05-21
project: hackify
related: []
current_task: W1:T1+T2+T3+T4+T22
worktree: /Users/corecave/Code/hackify-neutral
branch: refactor/tech-neutral-principles
sprint_goal: |
  Rewrite hackify's prose (rules, agents, skills, hooks-content, README) in language-agnostic
  voice while adding a canonical four-principles doc and a polyglot anti-patterns doc, so
  hackify reads as ecosystem-neutral and the principles we believe in are surfaced explicitly.
---

# Tech-neutral rewrite + Karpathy four-principles integration

## 1. Original ask

> Take the best from multica-ai/andrej-karpathy-skills (the four principles: Think Before
> Coding, Simplicity First, Surgical Changes, Goal-Driven Execution; the "→ verify:"
> per-step plan format; the EXAMPLES.md anti-pattern format) and rewrite most of the
> hackify plugin (rules/, agents/, skills/, hooks/, README) to be **technology-neutral** —
> strip TypeScript/biome/bun/Node-specific assumptions and replace them with
> language-agnostic phrasings that emphasize only the core terminologies and concepts
> hackify believes in (DRY, named types, file allowlist, test-first, surgical diff,
> evidence-before-claims, multi-reviewer dispatch, work-doc per task, etc.). Preserve
> every behavioral guarantee; change only the prose and examples.

## 2. Clarifying Q&A

### Q1 — Neutrality voice
**Question:** How aggressive should the technology-neutralization be?
**Answer:** Pure abstract. Strip all tool names from prose. Use only language-agnostic terms: `linter`, `test runner`, `type system`, `package manager`, `router/service/middleware module`. Examples become pseudocode or plain-English diffs.

### Q2 — Karpathy four principles placement
**Question:** Where should the four principles live in hackify's information architecture?
**Answer:** New `rules/four-principles.md` as the canonical deep doc, plus a short 5-line stub in `skills/hackify/SKILL.md` that links to it. Mirrors the existing `rules/code-quality.md` ↔ `rules/hard-caps.md` split.

### Q3 — Anti-patterns examples doc
**Question:** Should hackify ship an EXAMPLES.md analogue?
**Answer:** Yes — new `skills/hackify/references/anti-patterns.md` with polyglot wrong/right diffs. Linked from Phase 3 implementation guidance and Phase 5 reviewer prompts.

### Q4 — Rewrite coverage
**Question:** How wide should the rewrite reach?
**Answer:** Everything — rules + skills + README + sub-agents + the *content* injected by the hard-caps hook. (The hook script itself was inspected and is already neutral — only `rules/hard-caps.md` needs rewriting.)

### Q5 — `→ verify:` plan format (default — confirmed)
**Question:** How does `→ verify:` land in the work-doc template?
**Answer (default):** Add as a **SHOULD** in the Sprint Backlog format — each task is encouraged to carry a one-line `→ verify: <check>` suffix; not template-mandated, because not every task is test-shaped.

### Q6 — `dist/` artifacts (default — confirmed)
**Question:** Hand-edit `dist/<runtime>/` or regenerate?
**Answer (default):** Source-only edits; `bash scripts/sync-runtimes.sh` regenerates `dist/` as the last task. The script is idempotent by design.

### Q7 — Worktree (default — confirmed)
**Answer (default):** Isolated worktree `../hackify-neutral` on branch `refactor/tech-neutral-principles`. Already created.

### Q8 — Done state (default — confirmed)
**Answer (default):** Branch left for your review. Diff will span ~20 files; you'll want to inspect before merging.

## 3. Acceptance Criteria

- [ ] **Banned-term sweep — zero hits.** The regex `\b(typescript|biome|bun|npm|pnpm|node\.js|node_modules|jest|vitest|eslint|prettier|nestjs|next\.js|next |react|tsx|\.tsx|package\.json)\b` (case-insensitive) returns zero hits across `rules/`, `agents/`, `skills/`, `README.md`. **Carve-outs:** (a) the lint-suppression brand-name tokens `biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error` MAY remain literal anywhere they appear as scan targets of the no-suppression rule (because removing them would gut the rule); (b) `dist/` is a regenerated artifact; (c) `CHANGELOG.md` keeps historical version names; (d) `scripts/` is operational; (e) this work-doc records the regex itself. All other ecosystem brand names removed.
- [ ] `rules/four-principles.md` exists with the four principles (Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution) authored in hackify voice + cross-references from every relevant phase.
- [ ] `skills/hackify/references/anti-patterns.md` exists with ≥6 worked wrong/right examples in polyglot pseudocode (no single language keyword token dominates more than half the code blocks).
- [ ] `skills/hackify/SKILL.md` carries a ≤10-line "Working principles" summary block whose body is link + 1-sentence pointer only — principle names appear ≤1 time each in SKILL.md (no in-line restatement of principle content). Canonical text lives only in `rules/four-principles.md`.
- [ ] `skills/hackify/references/work-doc-template.md` adds a `→ verify: <one-line check>` SHOULD suffix to the Sprint Backlog format and at least one example task line using it.
- [ ] `rules/hard-caps.md` replaces ecosystem-specific filename globs (`*.routes.ts`, `*.service.ts`, etc.) with language-agnostic role-based phrasings (e.g., "router / service / middleware / guard / controller modules"). Lint-suppression brand tokens preserved per AC#1 carve-out (a).
- [ ] `skills/hackify/references/code-rules.md` and `skills/hackify/references/runtime-adapters.md` audited and neutralized (T24).
- [ ] Every behavioral guarantee preserved: same phase structure, same 4-section wizard contract, same 7-section sub-agent contract, same hard caps, same hooks wiring, same DoD validator coverage.
- [ ] `bash scripts/validate-dod.sh` exits 0 (matches the pre-rewrite baseline).
- [ ] `bash scripts/sync-runtimes.sh` regenerates `dist/` cleanly AND is idempotent (a second run produces no further diff). For every canonical source file under `skills/`, `commands/`, `.claude-plugin/`, the regenerated counterpart exists under each `dist/<runtime>/` target that ships it.
- [ ] `CHANGELOG.md` carries a `## v0.2.6` (or equivalent) entry; `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` `version` fields bumped in lockstep; DoD check [16] (plugin↔marketplace version equality) still passes.
- [ ] No new lint suppressions, no `!` non-null assertions, no empty catches anywhere in the diff.

## 4. Approach

**Chosen.** Pure abstract voice throughout. Two new canonical docs: `rules/four-principles.md` (the principles) and `skills/hackify/references/anti-patterns.md` (the worked examples). Rewrite every existing prose file in three concentric waves: rules first (foundation), then the hackify skill + references (workflow body), then companions + agents + README (perimeter). `dist/` is regenerated as the final task. Wave plan ordered so each wave only touches files no parallel sibling in the wave touches.

**Considered & rejected.**
- *Hybrid voice (abstract main + polyglot appendix).* Rejected — doubles surface area and dilutes the "we believe in these concepts" signal the user explicitly asked for.
- *Inline principles into SKILL.md instead of new file.* Rejected — bloats SKILL.md by ~80 lines and duplicates with existing rules; canonical-source split is the established pattern.
- *Skip anti-patterns doc this round.* Rejected — the user explicitly cited EXAMPLES.md as one of the three things to take.

**Architectural touchpoints.** `rules/code-quality.md`, `rules/hard-caps.md`, `rules/four-principles.md` (new), `skills/hackify/SKILL.md`, `skills/hackify/references/{work-doc-template,implement-and-test,parallel-agents,finish,review-and-verify,clarify-questions,debug-when-stuck,frontend-design,anti-patterns}.md` (last is new), `skills/{quick,yolo,brainstorm,receiving-code-review,writing-skills}/SKILL.md`, `agents/{wave-task-implementer,code-reviewer-{security,quality,plan-consistency},spec-reviewer-{consistency,rules,dependencies}}.md`, `README.md`, `CHANGELOG.md`, `dist/` (regenerated).

### Execution waves (post-spec-review tightening)

Reviewer C pulled CHANGELOG (T22) and rules-foundation (T3, T4) into W1 alongside the new docs — no file collisions; CHANGELOG narrative is already fixed by the Sprint Goal. T24 (newly added by spec review) joins W4. T23 (dist regen) still runs last because it depends on every prior wave.

| Wave | Tasks | Rationale |
|---|---|---|
| **W1** Foundation + rules + changelog | T1, T2, T3, T4, T22 | All independent files. Foundation docs (T1, T2) are net-new; rules (T3, T4) and CHANGELOG (T22) have no upstream deps. T3's cross-ref to T1 lands as part of the same wave. |
| **W2** Hackify skill + template + companion skills A | T5, T6, T13, T14 | `skills/hackify/SKILL.md`, `references/work-doc-template.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md` — four independent files. T5's stub references T1 (already landed in W1). |
| **W3** Hackify references A | T7, T8, T9, T10 | Four independent files in `skills/hackify/references/`: implement-and-test, parallel-agents, finish, review-and-verify. Biggest neutralization volume. |
| **W4** Hackify references B + companion skills B + audit | T11, T12, T15, T16, T24 | clarify-questions, debug-when-stuck + frontend-design, brainstorm, receiving-code-review, plus newly-added T24 (code-rules + runtime-adapters audit). All independent files. |
| **W5** Companion skill + sub-agents A | T17, T18, T19 | writing-skills SKILL.md + wave-task-implementer + 3 code-reviewers. T19 batches 3 sibling agent files (similar shape, identical neutralization rule). |
| **W6** Sub-agents B + perimeter | T20, T21 | 3 spec-reviewer agents + README. Independent files. |
| **W7** Dist regen | T23 | Depends on every prior wave. Solo task. |

## 5. Sprint Backlog

Flat checklist. One commit per task. Each task `→ verify:` line states the gate that proves it landed.

**True banned-term hit counts (verified via `grep -EciI` against the AC regex; supersedes initial estimates):**

| File | Hits |
|---|---|
| skills/hackify/references/parallel-agents.md | 32 |
| skills/hackify/references/implement-and-test.md | 28 |
| rules/code-quality.md | 9 |
| skills/hackify/references/finish.md | 8 |
| agents/wave-task-implementer.md | 8 |
| skills/hackify/references/review-and-verify.md | 7 |
| README.md | 7 |
| skills/hackify/SKILL.md | 6 |
| agents/code-reviewer-quality.md | 5 |
| skills/hackify/references/work-doc-template.md | 4 |
| skills/hackify/references/clarify-questions.md | 3 |
| skills/brainstorm/SKILL.md | 3 |
| skills/receiving-code-review/SKILL.md | 2 |
| agents/spec-reviewer-rules.md | 2 |
| agents/code-reviewer-security.md | 2 |
| skills/writing-skills/SKILL.md | 1 |
| skills/hackify/references/frontend-design.md | 1 |
| skills/hackify/references/debug-when-stuck.md | 1 |
| rules/hard-caps.md | 1 |
| skills/hackify/references/code-rules.md | 0 (audit only) |
| skills/hackify/references/runtime-adapters.md | 0 (audit only) |

### Wave 1 — Foundation + rules + changelog (parallel — 5 tasks)

- [ ] **T1** — Author `rules/four-principles.md`: write the four principles in hackify voice (Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution); cross-link to `rules/hard-caps.md`, `rules/code-quality.md`, `skills/hackify/SKILL.md` Phases 1/3/5. Files: `rules/four-principles.md` (NEW). → verify: file exists; ≥4 H2 sections, one per principle; grep finds at least one relative link to each of the three cross-reference targets.
- [ ] **T2** — Author `skills/hackify/references/anti-patterns.md`: ≥6 worked wrong/right diffs in polyglot pseudocode covering over-abstraction, drive-by refactor, hidden assumption, vague goal, lint-suppression rationalization, scope creep across files. Files: `skills/hackify/references/anti-patterns.md` (NEW). → verify: file exists; ≥6 H3 example sections; per-block census of language keywords (`function|def|fn|public|interface|let|const|fun|val|var|impl|sub`) — no single keyword appears in >50% of fenced code blocks.
- [ ] **T3** — Neutralize `rules/code-quality.md` (9 hits): strip ecosystem terms; add ≤5-line cross-reference block pointing to `rules/four-principles.md` (link + 1-sentence pointer; do NOT restate the four-principles content). Files: `rules/code-quality.md`. → verify: full AC banned-term regex returns 0 hits in this file; grep finds the relative reference to `rules/four-principles.md`.
- [ ] **T4** — Neutralize `rules/hard-caps.md` (1 hit): replace `*.routes.ts`/`*.service.ts`/`*.middleware.ts`/`*.guard.ts`/`*.controller.ts` filename globs with role-based language ("router / service / middleware / guard / controller modules"); keep the lint-suppression brand tokens `biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error` LITERAL per AC#1 carve-out (a). Files: `rules/hard-caps.md`. → verify: full AC banned-term regex returns 0 hits EXCEPT the carve-out tokens; `bash hooks/inject-hard-caps.sh` (with `CLAUDE_PLUGIN_ROOT` set to the worktree root) outputs valid JSON with an `additionalContext` field that includes the rewritten file content.
- [ ] **T22** — Add `CHANGELOG.md` v0.2.6 entry summarizing the rewrite; bump `version` in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` in lockstep. Files: `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. → verify: `CHANGELOG.md` contains a `## v0.2.6` heading with a 3–6-bullet summary referencing four-principles, anti-patterns, and neutralization; both JSON files report identical `version` strings; DoD check [16] (plugin↔marketplace version equality) still passes.

### Wave 2 — Hackify skill + template + companion skills A (parallel — 4 tasks)

- [ ] **T5** — Neutralize `skills/hackify/SKILL.md` (6 hits): strip ecosystem terms; insert a ≤10-line "Working principles" stub whose body is link + 1-sentence pointer per principle (NO inline restatement of principle content); keep all phase structure and counts intact. Files: `skills/hackify/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; each principle name (`Think Before Coding`, `Simplicity First`, `Surgical Changes`, `Goal-Driven Execution`) appears ≤1 time in the file; `bash scripts/validate-dod.sh` still finds all required phase strings.
- [ ] **T6** — Neutralize `skills/hackify/references/work-doc-template.md` (4 hits): replace ecosystem-specific test/lint/typecheck commands with `<test runner command>`/`<linter command>`/`<typecheck command>` placeholders; add `→ verify: <check>` SHOULD suffix to the Sprint Backlog format with one example task line. Files: `skills/hackify/references/work-doc-template.md`. → verify: full AC banned-term regex returns 0 hits; grep finds the `→ verify:` exemplar AND a SHOULD-strength sentence describing the convention; template-contract DoD check still passes.
- [ ] **T13** — Neutralize `skills/quick/SKILL.md`. Files: `skills/quick/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; full phase shape preserved.
- [ ] **T14** — Neutralize `skills/yolo/SKILL.md`. Files: `skills/yolo/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; auto-pass behavior intact.

### Wave 3 — Hackify references A (parallel — 4 tasks)

- [ ] **T7** — Neutralize `skills/hackify/references/implement-and-test.md` (28 hits): rewrite per-stack quick reference into per-discipline phrasing; keep TDD discipline intact. Files: `skills/hackify/references/implement-and-test.md`. → verify: full AC banned-term regex returns 0 hits; TDD discipline section preserved.
- [ ] **T8** — Neutralize `skills/hackify/references/parallel-agents.md` (32 hits, largest offender): rewrite templates without ecosystem assumptions; preserve the 7-section sub-agent template contract. Files: `skills/hackify/references/parallel-agents.md`. → verify: full AC banned-term regex returns 0 hits; the 7-section template heading set (`ROLE`, `INPUTS`, `OBJECTIVE`, `METHOD`, `VERIFICATION`, `SEVERITY`, `OUTPUT`) appears unchanged.
- [ ] **T9** — Neutralize `skills/hackify/references/finish.md` (8 hits): replace commit/PR examples that hardcode ecosystem brands. Files: `skills/hackify/references/finish.md`. → verify: full AC banned-term regex returns 0 hits; 4-options menu structure preserved.
- [ ] **T10** — Neutralize `skills/hackify/references/review-and-verify.md` (7 hits): rewrite per-stack quick reference; preserve the 14-item self-review checklist. Files: `skills/hackify/references/review-and-verify.md`. → verify: full AC banned-term regex returns 0 hits; 14 self-review checklist items still present and countable.

### Wave 4 — Hackify references B + companion skills B + audit (parallel — 5 tasks)

- [ ] **T11** — Neutralize `skills/hackify/references/clarify-questions.md` (3 hits) + add cross-ref to `anti-patterns.md`. Files: `skills/hackify/references/clarify-questions.md`. → verify: full AC banned-term regex returns 0 hits; all 7 task-type banks present; the 4-section wizard contract (`SCENARIO`/`COMPOSITION`/`QUESTIONS`/`EXIT CRITERIA`) intact; grep finds the anti-patterns cross-reference.
- [ ] **T12** — Neutralize `skills/hackify/references/debug-when-stuck.md` (1 hit) + `skills/hackify/references/frontend-design.md` (1 hit). Files: both. → verify: full AC banned-term regex returns 0 hits across both files; debug-method 4-phase structure preserved.
- [ ] **T15** — Neutralize `skills/brainstorm/SKILL.md` (3 hits). Files: `skills/brainstorm/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; 4-section wizard contract intact.
- [ ] **T16** — Neutralize `skills/receiving-code-review/SKILL.md` (2 hits). Files: `skills/receiving-code-review/SKILL.md`. → verify: full AC banned-term regex returns 0 hits.
- [ ] **T24** — Audit and (if needed) neutralize `skills/hackify/references/code-rules.md` (0 hits — forwarding stub; verify it still forwards correctly to `rules/code-quality.md`) and `skills/hackify/references/runtime-adapters.md` (0 hits — but inspect every section for ecosystem assumptions). Files: both. → verify: full AC banned-term regex returns 0 hits across both files; `code-rules.md`'s forwarding pointer still resolves; `runtime-adapters.md` documents each runtime mapping in language-agnostic primitive names.

### Wave 5 — Companion skill + sub-agents A (parallel — 3 tasks)

- [ ] **T17** — Neutralize `skills/writing-skills/SKILL.md` (1 hit). Files: `skills/writing-skills/SKILL.md`. → verify: full AC banned-term regex returns 0 hits.
- [ ] **T18** — Neutralize `agents/wave-task-implementer.md` (8 hits): replace per-stack test commands with placeholders. Files: `agents/wave-task-implementer.md`. → verify: full AC banned-term regex returns 0 hits; 7-section sub-agent contract preserved.
- [ ] **T19** — Neutralize all 3 code reviewer agents: `agents/code-reviewer-security.md` (2 hits), `agents/code-reviewer-quality.md` (5 hits), `agents/code-reviewer-plan-consistency.md` (0 hits — audit only). Files: all three. → verify: full AC banned-term regex returns 0 hits across all three; 7-section contract preserved in each.

### Wave 6 — Sub-agents B + perimeter (parallel — 2 tasks)

- [ ] **T20** — Neutralize all 3 spec reviewer agents: `agents/spec-reviewer-consistency.md` (0 hits — audit only), `agents/spec-reviewer-rules.md` (2 hits), `agents/spec-reviewer-dependencies.md` (0 hits — audit only). Files: all three. → verify: full AC banned-term regex returns 0 hits across all three; 7-section contract preserved.
- [ ] **T21** — Neutralize `README.md` (7 hits): rewrite the "what hackify enforces" section in abstract voice; keep the install snippet only if it's a runtime-target name (e.g., `claude-code`, `cursor`, `codex-cli`) — those are runtime identifiers, not ecosystem brands. Files: `README.md`. → verify: full AC banned-term regex returns 0 hits in the body prose (runtime-target identifiers explicitly carved out and noted in a comment in the file or this work-doc).

### Wave 7 — Dist regen (sequential — 1 task)

- [ ] **T23** — Regenerate `dist/` via `bash scripts/sync-runtimes.sh`; run a second time to confirm idempotency; run `bash scripts/validate-dod.sh`. Files: `dist/` tree (regenerated). → verify: first `sync-runtimes.sh` run exits 0; second run produces zero further `git diff` output under `dist/`; `validate-dod.sh` exits 0; spot-check via `diff -r` that at least one representative runtime target (`dist/claude-code/skills/hackify/`) mirrors the canonical source after the rewrite.

## 6. Daily Updates

_(populated per task during Phase 3)_

## 7. Sprint Review (Phase 4 / 5)

_(populated during Phases 4 and 5)_

## 8. Retrospective

_(populated during Phase 6)_
