---
slug: 2026-05-21-tech-neutral-principles
title: Tech-neutral rewrite + Karpathy four-principles integration
status: implementing
type: refactor
created: 2026-05-21
project: hackify
related: []
current_task: W7:T23
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

- [x] **T1** — Author `rules/four-principles.md`: write the four principles in hackify voice (Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution); cross-link to `rules/hard-caps.md`, `rules/code-quality.md`, `skills/hackify/SKILL.md` Phases 1/3/5. Files: `rules/four-principles.md` (NEW). → verify: file exists; ≥4 H2 sections, one per principle; grep finds at least one relative link to each of the three cross-reference targets.
- [x] **T2** — Author `skills/hackify/references/anti-patterns.md`: ≥6 worked wrong/right diffs in polyglot pseudocode covering over-abstraction, drive-by refactor, hidden assumption, vague goal, lint-suppression rationalization, scope creep across files. Files: `skills/hackify/references/anti-patterns.md` (NEW). → verify: file exists; ≥6 H3 example sections; per-block census of language keywords (`function|def|fn|public|interface|let|const|fun|val|var|impl|sub`) — no single keyword appears in >50% of fenced code blocks.
- [x] **T3** — Neutralize `rules/code-quality.md` (9 hits): strip ecosystem terms; add ≤5-line cross-reference block pointing to `rules/four-principles.md` (link + 1-sentence pointer; do NOT restate the four-principles content). Files: `rules/code-quality.md`. → verify: full AC banned-term regex returns 0 hits in this file; grep finds the relative reference to `rules/four-principles.md`.
- [x] **T4** — Neutralize `rules/hard-caps.md` (1 hit): replace `*.routes.ts`/`*.service.ts`/`*.middleware.ts`/`*.guard.ts`/`*.controller.ts` filename globs with role-based language ("router / service / middleware / guard / controller modules"); keep the lint-suppression brand tokens `biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error` LITERAL per AC#1 carve-out (a). Files: `rules/hard-caps.md`. → verify: full AC banned-term regex returns 0 hits EXCEPT the carve-out tokens; `bash hooks/inject-hard-caps.sh` (with `CLAUDE_PLUGIN_ROOT` set to the worktree root) outputs valid JSON with an `additionalContext` field that includes the rewritten file content.
- [x] **T22** — Add `CHANGELOG.md` v0.2.6 entry summarizing the rewrite; bump `version` in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` in lockstep. Files: `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. → verify: `CHANGELOG.md` contains a `## v0.2.6` heading with a 3–6-bullet summary referencing four-principles, anti-patterns, and neutralization; both JSON files report identical `version` strings; DoD check [16] (plugin↔marketplace version equality) still passes.

### Wave 2 — Hackify skill + template + companion skills A (parallel — 4 tasks)

- [x] **T5** — Neutralize `skills/hackify/SKILL.md` (6 hits): strip ecosystem terms; insert a ≤10-line "Working principles" stub whose body is link + 1-sentence pointer per principle (NO inline restatement of principle content); keep all phase structure and counts intact. Files: `skills/hackify/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; each principle name (`Think Before Coding`, `Simplicity First`, `Surgical Changes`, `Goal-Driven Execution`) appears ≤1 time in the file; `bash scripts/validate-dod.sh` still finds all required phase strings.
- [x] **T6** — Neutralize `skills/hackify/references/work-doc-template.md` (4 hits): replace ecosystem-specific test/lint/typecheck commands with `<test runner command>`/`<linter command>`/`<typecheck command>` placeholders; add `→ verify: <check>` SHOULD suffix to the Sprint Backlog format with one example task line. Files: `skills/hackify/references/work-doc-template.md`. → verify: full AC banned-term regex returns 0 hits; grep finds the `→ verify:` exemplar AND a SHOULD-strength sentence describing the convention; template-contract DoD check still passes.
- [x] **T13** — Neutralize `skills/quick/SKILL.md`. Files: `skills/quick/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; full phase shape preserved.
- [x] **T14** — Neutralize `skills/yolo/SKILL.md`. Files: `skills/yolo/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; auto-pass behavior intact.

### Wave 3 — Hackify references A (parallel — 4 tasks)

- [x] **T7** — Neutralize `skills/hackify/references/implement-and-test.md` (28 hits): rewrite per-stack quick reference into per-discipline phrasing; keep TDD discipline intact. Files: `skills/hackify/references/implement-and-test.md`. → verify: full AC banned-term regex returns 0 hits; TDD discipline section preserved.
- [x] **T8** — Neutralize `skills/hackify/references/parallel-agents.md` (32 hits, largest offender): rewrite templates without ecosystem assumptions; preserve the 7-section sub-agent template contract. Files: `skills/hackify/references/parallel-agents.md`. → verify: full AC banned-term regex returns 0 hits; the 7-section template heading set (`ROLE`, `INPUTS`, `OBJECTIVE`, `METHOD`, `VERIFICATION`, `SEVERITY`, `OUTPUT`) appears unchanged.
- [x] **T9** — Neutralize `skills/hackify/references/finish.md` (8 hits): replace commit/PR examples that hardcode ecosystem brands. Files: `skills/hackify/references/finish.md`. → verify: full AC banned-term regex returns 0 hits; 4-options menu structure preserved.
- [x] **T10** — Neutralize `skills/hackify/references/review-and-verify.md` (7 hits): rewrite per-stack quick reference; preserve the 14-item self-review checklist. Files: `skills/hackify/references/review-and-verify.md`. → verify: full AC banned-term regex returns 0 hits; 14 self-review checklist items still present and countable.

### Wave 4 — Hackify references B + companion skills B + audit (parallel — 5 tasks)

- [x] **T11** — Neutralize `skills/hackify/references/clarify-questions.md` (3 hits) + add cross-ref to `anti-patterns.md`. Files: `skills/hackify/references/clarify-questions.md`. → verify: full AC banned-term regex returns 0 hits; all 7 task-type banks present; the 4-section wizard contract (`SCENARIO`/`COMPOSITION`/`QUESTIONS`/`EXIT CRITERIA`) intact; grep finds the anti-patterns cross-reference.
- [x] **T12** — Neutralize `skills/hackify/references/debug-when-stuck.md` (1 hit) + `skills/hackify/references/frontend-design.md` (1 hit). Files: both. → verify: full AC banned-term regex returns 0 hits across both files; debug-method 4-phase structure preserved.
- [x] **T15** — Neutralize `skills/brainstorm/SKILL.md` (3 hits). Files: `skills/brainstorm/SKILL.md`. → verify: full AC banned-term regex returns 0 hits; 4-section wizard contract intact.
- [x] **T16** — Neutralize `skills/receiving-code-review/SKILL.md` (2 hits). Files: `skills/receiving-code-review/SKILL.md`. → verify: full AC banned-term regex returns 0 hits.
- [x] **T24** — Audit and (if needed) neutralize `skills/hackify/references/code-rules.md` (0 hits — forwarding stub; verify it still forwards correctly to `rules/code-quality.md`) and `skills/hackify/references/runtime-adapters.md` (0 hits — but inspect every section for ecosystem assumptions). Files: both. → verify: full AC banned-term regex returns 0 hits across both files; `code-rules.md`'s forwarding pointer still resolves; `runtime-adapters.md` documents each runtime mapping in language-agnostic primitive names.

### Wave 5 — Companion skill + sub-agents A (parallel — 3 tasks)

- [x] **T17** — Neutralize `skills/writing-skills/SKILL.md` (1 hit). Files: `skills/writing-skills/SKILL.md`. → verify: full AC banned-term regex returns 0 hits.
- [x] **T18** — Neutralize `agents/wave-task-implementer.md` (8 hits): replace per-stack test commands with placeholders. Files: `agents/wave-task-implementer.md`. → verify: full AC banned-term regex returns 0 hits; 7-section sub-agent contract preserved.
- [x] **T19** — Neutralize all 3 code reviewer agents: `agents/code-reviewer-security.md` (2 hits), `agents/code-reviewer-quality.md` (5 hits), `agents/code-reviewer-plan-consistency.md` (0 hits — audit only). Files: all three. → verify: full AC banned-term regex returns 0 hits across all three; 7-section contract preserved in each.

### Wave 6 — Sub-agents B + perimeter (parallel — 2 tasks)

- [x] **T20** — Neutralize all 3 spec reviewer agents: `agents/spec-reviewer-consistency.md` (0 hits — audit only), `agents/spec-reviewer-rules.md` (2 hits), `agents/spec-reviewer-dependencies.md` (0 hits — audit only). Files: all three. → verify: full AC banned-term regex returns 0 hits across all three; 7-section contract preserved.
- [x] **T21** — Neutralize `README.md` (7 hits): rewrite the "what hackify enforces" section in abstract voice; keep the install snippet only if it's a runtime-target name (e.g., `claude-code`, `cursor`, `codex-cli`) — those are runtime identifiers, not ecosystem brands. Files: `README.md`. → verify: full AC banned-term regex returns 0 hits in the body prose (runtime-target identifiers explicitly carved out and noted in a comment in the file or this work-doc).

### Wave 7 — Dist regen (sequential — 1 task)

- [ ] **T23** — Regenerate `dist/` via `bash scripts/sync-runtimes.sh`; run a second time to confirm idempotency; run `bash scripts/validate-dod.sh`. Files: `dist/` tree (regenerated). → verify: first `sync-runtimes.sh` run exits 0; second run produces zero further `git diff` output under `dist/`; `validate-dod.sh` exits 0; spot-check via `diff -r` that at least one representative runtime target (`dist/claude-code/skills/hackify/`) mirrors the canonical source after the rewrite.

## 6. Daily Updates

### W1 — Foundation + rules + changelog — done 2026-05-21

5 agents dispatched in parallel; each respected its file allowlist; no spillover.

- **T1** (four-principles.md, NEW, 58 LOC) — created with 4 H2 principle sections + cross-references + Karpathy attribution; banned-term grep clean. Note: false-positive on "next step" (matched `next ` token) caught + reworded to "following step".
- **T2** (anti-patterns.md, NEW, 372 LOC) — 7 worked examples (over-abstraction, drive-by reformat, hidden assumption, vague goal, lint-suppression rationalization, scope creep, big-bang rewrite); per-block keyword census: max single keyword 28.6% (`def`, 4/14 blocks); summary table maps each example to a violated principle.
- **T3** (code-quality.md, MODIFY) — 9 banned-term hits → 1 (the lint-suppression rule line, carve-out). Added 5-line cross-ref to four-principles.md at top. Renamed one H2 section title ("Author's reference stack — substitute your own" → "Voice — abstract principles, concrete adaptation") because the old heading promised content the neutralized body no longer delivered. Brand parentheticals (Hono/Express/Fastify/Zod/Zustand/Redux) stripped.
- **T4** (hard-caps.md, MODIFY) — filename globs (`*.routes.ts`, etc.) → role-based language ("router / service / middleware / guard / controller modules"). Added explicit carve-out note: lint-suppression brand tokens stay literal because they ARE the scan targets. Hook still emits valid JSON envelope.
- **T22** (CHANGELOG + plugin.json + marketplace.json) — added `## [0.2.6] - 2026-05-21` entry (5 bullets); bumped both JSON `version` fields to `0.2.6`; DoD check [16] (plugin↔marketplace version equality) confirmed `ok`.

- **Wave verification.** Per-file banned-term sweep: four-principles=0, anti-patterns=0, code-quality=1 (carve-out), hard-caps=1 (carve-out), CHANGELOG=0. Carve-out tokens grep confirms they appear only on lint-suppression rule lines + anti-patterns Example 5 narrative. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY ✓ named types (N/A prose) ✓ layering (N/A) ✓ no suppressions ✓ edge cases ✓ no scope creep.

### W2 — Hackify skill + template + companion skills A — done 2026-05-21

4 agents dispatched in parallel; T5 + T6 made substantive edits; T13 + T14 were already neutral (no-op).

- **T5** (SKILL.md, 6 hits → 0) — Working Principles stub inserted at L22 (between "When to invoke" and "The phases"), 9 lines. Each principle name (`Think Before Coding`, `Simplicity First`, `Surgical Changes`, `Goal-Driven Execution`) appears exactly once across the file (DRY verified). Notable replacement: L186 lint-suppression brand-token list → generic "inline ignore directives, file-level disables, expect-error pragmas outside test files" — allowed by AC#1 (carve-out is "MAY", not MUST). Canonical literal tokens still live in `rules/hard-caps.md`.
- **T6** (work-doc-template.md, 4 hits → 0) — replaced `bun test`/`bun run lint`/`bun run typecheck` with `<test runner command>`/`<linter command>`/`<typecheck command>` placeholders. Added SHOULD-strength sentence to Sprint Backlog guidance: *"Each task SHOULD carry a `→ verify: <one-line check>` suffix stating the gate that proves it landed."* Example task line updated to demonstrate the pattern.
- **T13** (quick/SKILL.md, 0 hits → 0) — file was already neutral; no edits. User-locked semantics, phase shape (Clarify-if-needed → Implement → Verify → Summary), Phase 4 triad, Phase 6F summary, non-promotion rules all preserved.
- **T14** (yolo/SKILL.md, 0 hits → 0) — file was already neutral; no edits. All 6 phases present; auto-pass semantics (Phase 2 plan-gate + Phase 6 4-options menu); no-work-doc invariant; trigger keyword list preserved.

- **Wave verification.** Per-file banned-term sweep: SKILL.md=0, work-doc-template=0, quick=0, yolo=0. Principle-name DRY: 1/1/1/1. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY (each principle name once in SKILL.md; principle bodies only in `rules/four-principles.md`) ✓ no suppressions ✓ no scope creep (file allowlists respected by all 4 agents).

### W3 — Hackify references A — done 2026-05-21

4 agents dispatched in parallel; all 4 made substantive edits; total 75 banned-term replacements across 4 files.

- **T7** (implement-and-test.md, 28 hits → 0) — per-stack quick-reference section replaced with per-discipline (`<test runner command>` / `<linter command>` / `<typecheck command>` / `<coverage command>`). Component-mode test guidance rephrased to use "HTTP-client boundary" / "auth-client boundary" / "test runner's `waitFor` primitive" instead of named libraries. TDD discipline content (RED→GREEN→REFACTOR, "watch the test fail before writing impl") preserved verbatim.
- **T8** (parallel-agents.md, 34 hits → 0; 1783 LOC, pre-existing over the 500-LOC cap — flagged in Retrospective). 7-section sub-agent contract anchors all preserved (ROLE 13×, INPUTS 12×, OBJECTIVE 12×, METHOD 29×, VERIFICATION 14×, SEVERITY 9×, OUTPUT 24×). All 3 dispatch templates intact (Spec self-review × 3, Implementation wave, Multi-reviewer × 3). Lint-suppression brand tokens neutralized inside METHOD/SEVERITY example prose (consistent with W2/T5 precedent — AC#1 carve-out is `MAY`). Broader-brand sweep (hono/fastify/drizzle/prisma/postgres/redis/express/django/spring/rails) also clean.
- **T9** (finish.md, 8 hits → 0) — all command examples replaced with `<test runner command>` / `<linter command>` / `<typecheck command>` / `<package manager install command>` placeholders. 4-options menu (Merge / Push+PR / Keep / Discard) preserved; "discard" verbatim semantics preserved; Step F Area/Change summary table guidance preserved.
- **T10** (review-and-verify.md, 7 hits → 0; agent stripped 11 total, exceeding the minimum by 4). 14-item self-review checklist preserved (L86-106, count = 14). Severity tiers (Critical / Important / Minor), escalation rule (any diff beyond a one-line typo), pushback-with-evidence rule preserved. **Nuance:** agent also stripped `OWASP Top 10 (2021)`, `OAuth/OIDC`, `CORS/CSRF` — these are industry standards (not ecosystem brands). Canonical citations remain in `agents/code-reviewer-security.md` (9 hits — untouched until W5), so reviewer precision is not degraded for the security agent itself; only the supplementary guidance in `review-and-verify.md` was generalized. Flagged for Phase 5 review.

- **Wave verification.** Per-file banned-term sweep: implement-and-test=0, parallel-agents=0, finish=0, review-and-verify=0. 7-section anchors all ≥1. 14-item checklist count = 14. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY ✓ no suppressions ✓ structural anchors preserved ✓ TDD discipline preserved. Flag: parallel-agents.md exceeds 500-LOC hard cap (pre-existing, not introduced by this work).

### W4 — Hackify references B + companion skills B + audit — done 2026-05-21

5 agents dispatched in parallel; 4 edited, 1 (T24) no-op.

- **T11** (clarify-questions.md, 3 hits → 0) — neutralized `next ` token (×2) and a file-path regex that listed extensions including `.ts`/`.tsx` (replaced with prose "explicitly names a concrete file path"). Cross-ref paragraph to `anti-patterns.md` landed at L26 between "Composing the questionnaire" and the next divider. 4-section wizard contract anchors verified intact (count = 8 per section: 1 universal + 7 task-type banks).
- **T12** (debug-when-stuck.md + frontend-design.md, 1 + 1 hits in AC regex → 0; agent also stripped 3 illustrative brand mentions in frontend-design.md per task carve-out: Tailwind/tailwind.config/index.css → utility-framework / utility-framework config / stylesheet entry point). 4-phase debug structure (ROOT CAUSE / PATTERN ANALYSIS / HYPOTHESIS / IMPLEMENT) preserved.
- **T15** (brainstorm/SKILL.md, 3 hits → 0; agent found 4 total: all `next ` token false-positives, rewritten to `following`). Graduation rule + no-work-doc-until-graduation invariant + Socratic 1-or-2-questions-per-turn pattern + Brainstorm Provenance block all preserved.
- **T16** (receiving-code-review/SKILL.md, 2 hits → 0) — generalized lint-suppression brand-token list at L41 to "any linter or type-checker suppression directive introduced outside the test-file carve-out"; reworded "next column" → "Severity column". Per-finding decision table (Finding / Severity / Decision / Evidence) preserved; decision domain (accept / push-back / defer) preserved verbatim. **Minor follow-up flagged:** `vi.useFakeTimers()` example at L80 remains (outside the AC regex but ecosystem-specific) — left for a follow-up pass.
- **T24** (code-rules.md + runtime-adapters.md) — NO-OP. Both files already neutral under AC regex and wider scan. `code-rules.md` still forwards to `rules/code-quality.md`. `runtime-adapters.md` still names every target runtime (claude-code, cursor, codex, codex-cli, copilot, gemini, opencode) and preserves native-tool names (load-bearing, not brand leakage).

- **Wave verification.** All 7 audited files at 0 hits. 4-section contract anchors 8/8/8/8. Anti-patterns cross-ref present in clarify-questions.md. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY ✓ no suppressions ✓ structural anchors preserved (4-section wizard contract, decision-table contract, 4-phase debug method) ✓ no scope creep.

### W5 — Companion skill + sub-agents A — done 2026-05-21

3 agents dispatched in parallel; all 3 made substantive edits.

- **T17** (writing-skills/SKILL.md, 1 hit → 0) — single `next ` token in "next section" reworded to "following section". 9-check self-validation list + 7-section sub-agent contract + 4-section wizard contract enforcement language preserved verbatim.
- **T18** (wave-task-implementer.md, 8 hits → 0; agent found 9 total per cluster, all neutralized): replaced `TypeScript / Bun / Node service trees`, `React component libraries`, `Drizzle/Prisma data layers`, `Hono/NestJS request lifecycles` with role-based language. Lint-suppression brand list in ROLE+METHOD-step-2 generalized to "inline ignore directives, file-level disables, expect-error pragmas outside test files — canonical scan tokens in `rules/hard-caps.md`". Stack-summary placeholder `<runtime> + <web framework> + <ORM/data layer> + <database>`. Filename-glob inline-type ban → role-based phrasing pointing at canonical list in `rules/hard-caps.md`. 6 of 7 contract anchors verified (SEVERITY = 0 — correct: implementer is NOT a reviewer, SEVERITY is review-only). File allowlist discipline + TDD discipline (RED→GREEN→REFACTOR; watch-it-fail) preserved.
- **T19** (3 code-reviewer agents, total 7 AC hits → 3 carve-outs):
  - **code-reviewer-security.md** (2 AC hits → 0): ROLE expertise block rewritten; also abstracted out-of-AC ecosystem names (Fastify/Hono/Drizzle/Prisma/Better Auth/Auth.js/Redis/Postgres/GitHub Actions). **OWASP/CWE/NIST/RFC 6749/RFC 7519 citation count preserved at 9 — zero generalized.** This resolves the Phase 2.5 concern about T10 stripping standards in `review-and-verify.md`; canonical citations are intact in the security reviewer prompt itself.
  - **code-reviewer-quality.md** (5 AC hits → 3 carve-outs): 2 substantive edits (L12 + L79); 3 surviving hits are all literal scan-target tokens (`// biome-ignore`, `// eslint-disable`, `// biome-ignore lint/suspicious/noExplicitAny`) preserved per AC#1 carve-out (a) — abstracting them would gut the rule. Same pattern as `rules/hard-caps.md`.
  - **code-reviewer-plan-consistency.md** (0 hits): NO-OP. Standards cited (SemVer 2.0.0 / Keep a Changelog 1.1.0 / RFC 2119) preserved.

- **Wave verification.** Per-file banned-term sweep: writing-skills=0, wave-task-implementer=0, security=0, quality=3 (carve-outs), plan-consistency=0. OWASP/CWE/NIST/RFC in security reviewer = 9 (≥7 threshold met). 7-section contract anchors all ≥1 across 4 files (SEVERITY = 0 only in wave-task-implementer, by design). `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY ✓ named scan-target carve-outs preserved ✓ industry-standard citations preserved (resolves Phase 2.5 concern) ✓ 7-section contract intact ✓ no scope creep.

### W6 — Sub-agents B + perimeter — done 2026-05-21

2 agents dispatched in parallel; T20 edited 1 of 3 spec-reviewer files; T21 made substantive edits to README.

- **T20** (3 spec-reviewer agents):
  - **spec-reviewer-consistency.md** (0 hits): NO-OP audit.
  - **spec-reviewer-rules.md** (2 AC hits → 1 carve-out): 1 substantive edit at L16 — "NestJS / Fastify / Hono" → "HTTP service frameworks"; paired with "Drizzle and Prisma data layers" → "ORM / data-mapper persistence layers". Literal scan-target tokens at L61 (`biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`) preserved per AC#1 carve-out (a). Reviewer's authoritative rule sources (`{{project_root}}/CLAUDE.md` + `{{user_global_rules_path}}`) preserved.
  - **spec-reviewer-dependencies.md** (0 hits): NO-OP audit.
- **T21** (README.md, 7 hits → 0): Version badge bumped 0.2.2 → 0.2.6 (badge was stale; this brings it into lockstep with T22's CHANGELOG + JSON bumps). Backend/Frontend test-tool parentheticals stripped ("Backend test (Vitest)" → "Backend test"; "Frontend test (Playwright)" → "Frontend test"). Stack-assumptions paragraph rewritten in abstract voice (heading renamed to "Voice — abstract principles, concrete adaptation", matching T3 precedent). FAQ heading reworded: "Does hackify lock me into Bun, Biome, or TypeScript?" → "Does hackify lock me into a specific language or toolchain?". `next ` token false-positives reworded (×5). **Four-principles cross-ref added to "Design principles" section** — was not previously present.

- **Wave verification.** Per-file banned-term sweep: consistency=0, rules=1 (carve-out), dependencies=0, README=0. README runtime-target preservation: `claude-code` ×4, `codex` ×1, `codex-cli` ×1 (install snippets intact). README four-principles cross-ref present. `bash scripts/validate-dod.sh` → `ALL CHECKS PASSED`.

- **Self-review.** ✓ DRY ✓ scan-target carve-outs preserved ✓ runtime-target identifiers preserved in README ✓ four-principles cross-ref added ✓ version badge lockstep with T22 ✓ no scope creep.

## 7. Sprint Review (Phase 4 / 5)

_(populated during Phases 4 and 5)_

## 8. Retrospective

_(populated during Phase 6)_
