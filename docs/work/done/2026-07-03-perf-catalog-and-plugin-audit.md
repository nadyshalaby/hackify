---
slug: 2026-07-03-perf-catalog-and-plugin-audit
title: Performance catalog + whole-plugin audit (0.7.0)
status: done
type: feature
created: 2026-07-03
project: hackify
related: []
current_task: null
worktree: null
branch: main
sprint_goal: |
  Make performance a first-class, enforced concern across every hackify scanning
  surface (always-on rules, deterministic scout, reviewers, checklists), fix every
  defect the whole-plugin audit found, and ship it all as one combined 0.7.0 release.
---

# Performance catalog + whole-plugin audit (0.7.0)

## 1. Original ask

> I want to list all performance violation patterns and practises that people oftenly fall into to be avoided by the AI all the time (litrally mention all of them and extend all places that should scan them) and add preditable scout task to early lint them and stage them for fixing as part of the post-implementation review phase. the producted final code ready to be commit MUST be the most performance optimized code we ever coded.
>
> Then review all parts of the hackify skill and address issues/gaps/optimizations and fix them right away. also you may suggest using claude updated features in the tasks that may match the type of work we are doing

## Primary Goal & Guardrails

- **North-Star Goal.** Every hackify-driven task ships code screened against a comprehensive performance-violation catalog at implement, verify, and review time — and this release itself passes its own new bar.
- **In-Scope.**
  - Canonical deep catalog `rules/performance.md` + tight always-on `rules/perf-guardrails.md` (third UserPromptSubmit injection) + deterministic scout protocol `skills/hackify/references/perf-scout.md`.
  - New Phase 5 Reviewer D (performance): `agents/code-reviewer-performance.md` + §D in the phase-5 template.
  - Scout mandated at every Phase 3 wave-end AND Phase 5 start; findings staged into the address-all decision table.
  - Wiring into: core SKILL.md, review-and-verify.md, work-doc-template.md, expert-mindset (both files), quick, yolo, review-triage, lawkeeper catalog, summary command.
  - Registration + validator hardening (MIRROR_SOURCES, 60-primitives, 55-mirror, 50-companions, 20-templates, 70-invariants, check-collisions).
  - Fix ALL 25 auditor findings (R1/R2/R3 register below), every severity.
  - Claude-feature adoption notes in runtime-adapters.md, plus minimal native-tier pointer lines in core phase text (portable wording preserved).
  - Release plumbing: CHANGELOG 0.7.0 entry extension, README, sync-runtimes regen, demo-GIF regen, single combined release commit.
- **Out-of-Scope / Non-Goals.**
  - No compiled/AST perf linter binary — the scout stays grep + semantic-reviewer based (portable).
  - No rewrite of lawkeeper's scanner engine — only catalog pointer + doc alignment.
  - No change to the 7-runtime portability doctrine; no edits to the plugin cache; no new runtime mirrors.
  - No perf work on user projects — this sprint changes the plugin only.
- **Guardrails / Invariants.**
  - `bash scripts/validate-dod.sh` passes at every wave-END, run ONCE by the parent after all wave agents merge (mid-wave reds while same-wave registrations land are expected and are not failures); ≤500 LOC per file; template-contract 7 sections for new agent + template.
  - *Ruling (Phase 5, user-signed Q3-A):* the ≤500 cap binds code/doctrine primitives (the validator's enforced scope); `CHANGELOG.md` (608 lines) is an append-only historical log and is exempt — revisit archiving only if it becomes unwieldy.
  - The uncommitted v0.7.0 WIP (phase-ledger, expert-mindset, inject-context) survives intact — no clobbering.
  - Portable primitive wording everywhere except runtime-adapters native-tier rows. B2 voice in all prose.
  - Per user decision Q6-B/Q7-B: wave commits are SUSPENDED; one combined 0.7.0 release commit lands in Phase 6.
- **Success Signals.**
  - Fresh `validate-dod.sh` ALL CHECKS PASSED (with the new perf invariants enforcing).
  - Grep proof per surface: injection entry in hooks.json, Reviewer D in SKILL.md/yolo/template/agents, scout step at wave-end + Phase 5, perf rows in checklists.
  - Catalog covers ≥10 domains, every violation with stable ID + severity + detection + wrong→right pair.
  - Finding→fix mapping table complete for all 25 audit findings.
  - Dogfood proof: the new perf-scout + Reviewer D ran on THIS sprint's own diff in Phase 5; their reports sit in the Evidence Ledger.
  - Demo GIF regenerated; single 0.7.0 release commit contains WIP + sprint.

## 2. Clarifying Q&A

### Q1 — Where the perf law binds
**Question:** Always-on injection vs on-demand placement?
**Answer:** A — Two-tier: tight `perf-guardrails.md` always-on + deep `rules/performance.md` on demand (mirrors hard-caps ↔ code-quality split).

### Q2 — Scout timing
**Question:** When does the deterministic perf-scout run?
**Answer:** A — Every Phase 3 wave-end AND Phase 5 start; surviving findings staged into the decision table.

### Q3 — Dedicated perf reviewer
**Question:** Reviewer D vs fold into Reviewer B?
**Answer:** A — Dedicated Reviewer D with the scout report as input; Phase 5 default becomes A/B/C/D.

### Q4 — Audit scope
**Question:** Whole plugin vs core skill vs docs only?
**Answer:** A — Whole plugin (core + references + rules + agents + hooks + scripts + companions + metadata).

### Q5 — Claude-feature adoption depth
**Question:** Adopt-where-fits vs suggestions-only vs aggressive?
**Answer:** A — Adopt where they fit, framed as native-tier notes in runtime-adapters.md + phase text; portability preserved.

### Q6 — Uncommitted v0.7.0 WIP
**Question:** Commit first, combine, or ignore?
**Answer:** B — One combined release: WIP + this sprint land together in one commit at the end. Wave commits suspended.

### Q7 — Version
**Question:** 0.8.0 or fold into unreleased 0.7.0?
**Answer:** B — Fold into 0.7.0; extend its CHANGELOG entry.

## 3. Acceptance Criteria

- [x] AC1 — `rules/performance.md` exists: ≥10 domains (algorithmic, memory/allocation, data-access/N+1, network/API, async/concurrency, frontend/rendering, caching, I/O+serialization, build/bundle, logging/observability), each violation with stable ID `perf.<domain>.<slug>`, severity, why-it-hurts, detection hint, wrong→right micro-pair; ≤500 LOC.
- [x] AC2 — Always-on tier live: `rules/perf-guardrails.md` exists and `hooks/hooks.json` has a third UserPromptSubmit entry pointing at it; a validate-dod check proves both (and that all hook targets exist on disk).
- [x] AC3 — Deterministic scout: `references/perf-scout.md` protocol (JS/TS + Python + SQL grep tables keyed to catalog IDs, staging format, false-positive triage); SKILL.md mandates it at every wave-end + Phase 5 start; quick + yolo mirror it; perf rows/lenses present in review-and-verify.md, work-doc-template.md, review-triage severity rubric, and lawkeeper catalog pointer (grep proof each).
- [x] AC4 — Phase 5 default is FOUR parallel reviewers (A security, B quality, C plan, D performance) in core + yolo; `agents/code-reviewer-performance.md` registered and validator passes with 8 agents.
- [x] AC5 — All 25 audit findings (register below) fixed — Critical, Important, AND Minor.
- [x] AC6 — Claude-feature native-tier notes in runtime-adapters.md (structured-output findings, background subagents, effort/model tiers, task-tracker ordering) without breaking portable wording.
- [ ] AC7 — `bash scripts/validate-dod.sh` → ALL CHECKS PASSED on the final tree; CHANGELOG 0.7.0 extended; README updated; dist/ mirrors regenerated; demo GIF regenerated; ONE combined 0.7.0 release commit.
- [x] AC8 — Dogfood + probes: Phase 5 of THIS sprint dispatches all four reviewers including the new Reviewer D AND runs the new perf-scout on the sprint's own diff (both reports in the Evidence Ledger); every new/changed validator check is proven able to FAIL via a red-path probe (mutate → expect fail → restore).

## 4. Approach

**Chosen.** Two-tier performance law mirroring the existing caps pattern: tight always-on `rules/perf-guardrails.md` (third injection) distilled from canonical `rules/performance.md`; deterministic scout protocol keyed to catalog IDs runs at wave-end + Phase 5 and stages findings into the decision table; dedicated Reviewer D joins Phase 5 (core + yolo), perf lens joins quick 5-lite. All registration/validator surfaces updated so the validator itself enforces the new invariants. The 25 auditor findings are fixed inside file-disjoint wave tasks. Claude-feature adoption lands as native-tier notes (adapters + minimal phase-text pointers). One combined 0.7.0 release (Q6-B/Q7-B): wave commits suspended, single release commit in Phase 6, GIF + dist regenerated.

**Considered & rejected.** Full catalog always-on — permanent token tax (Q1-B). Perf folded into Reviewer B — shallow treatment (Q3-B). AST linter binary — breaks 7-runtime portability; grep + semantic reviewer meets the bar.

**Architectural touchpoints.** rules/, hooks/, agents/, skills/hackify/SKILL.md + references/, skills/{quick,yolo,review-triage,lawkeeper,skillsmith}, commands/summary.md, scripts/{validate-dod.d,sync-runtimes.d,check-collisions.sh}, CHANGELOG, README, dist/.

### Execution waves

| Wave | Tasks | Agents | Depends on |
|---|---|---|---|
| W1 | T1 perf doctrine trio · T2 hook/scanner fixes · T3 doc Critical fixes | 3 | — |
| W2 | T4 Reviewer D + phase-5 template · T5 core SKILL.md wiring · T6 checklists + mindset wiring · T7a registration (helpers/primitives/mirror) | 4 | W1 (catalog IDs + new files exist) |
| W3 | T8 quick+yolo mirrors · T9 triage/summary/skillsmith/lawkeeper · T10 runtime-adapters + Claude features · T7b validator hardening | 4 | W2 (core wording settled) |
| W4 | T11 release plumbing + sync-runtimes + demo GIF | 1 | W3 |

## 5. Sprint Backlog

Wave commits suspended per Q6-B — tasks tick + log at wave-end; ONE release commit in Phase 6. Verification cadence: `validate-dod.sh` runs ONCE per wave, by the parent, at wave-END after all agents merge; per-task verify lines that name validate-dod checks are evaluated at that wave-end run, never mid-wave.

- [x] **T1 (W1)** — Perf doctrine trio: author `rules/performance.md` (canonical catalog per AC1 — CONTENT BUDGET: entries are dense table rows (ID | violation | why | detect | fix direction); NO per-entry code blocks in this file; wrong→right micro-examples live in perf-scout.md beside their grep patterns), `rules/perf-guardrails.md` (tight always-on stub ≤90 lines; MUST carry a "canonical source: rules/performance.md — do not restate" pointer; this inverts the hard-caps direction where the always-on file is canonical — state the direction in BOTH files), `skills/hackify/references/perf-scout.md` (deterministic protocol: per-language grep tables keyed to catalog IDs, run points, staging format, false-positive triage, micro-examples for top offenders), + third UserPromptSubmit entry in `hooks/hooks.json`. PRE-AUTHORIZED FALLBACK if the catalog overflows 500 LOC: split into `rules/performance.md` (index + doctrine) + `rules/performance.d/<domain>.md` parts; T7a syncs MIRROR_SOURCES to the actual shape. Files: `rules/performance.md` (new), `rules/perf-guardrails.md` (new), `skills/hackify/references/perf-scout.md` (new), `hooks/hooks.json`. → verify: files exist, each ≤500 LOC; `jq` shows 3 UserPromptSubmit entries; every scout pattern cites an existing catalog ID; stub carries the canonical pointer. *(Oversized on purpose: single-author coherence for the 3-file doctrine set.)*
- [x] **T2 (W1)** — Hook/scanner fixes (R2-5, R2-7, R2-9): wrap `detect()` fail-open in `hooks/scan_edit.py` + `hooks/scan_bash.py`; pair each heredoc with its own redirect target in scan_bash.py; replace `\btee\b` GNU-ism in `hooks/block-banned-tokens.sh`. Files: those 3 + extend `hooks/test_block_banned_tokens.sh`. → verify: `python3 -m py_compile` both; run `hooks/test_block_banned_tokens.sh` extended with fail-open + multi-heredoc + tee-filter cases — all green on macOS.
- [x] **T3 (W1)** — Doc Critical fixes (R1-2, R1-1a, R1-6, R1-8a): retitle finish.md summary section to `## Step F — Summary table + HTML report`; add rules/code-quality.md load step to `phase-2.5-spec-review-b-rules.md`; fix phase-ledger.md:26 sibling link; add canonical-pointer note (goal-anchor.md) beside the 2.5-a drift verdict copy. Files: `skills/hackify/references/finish.md`, `.../parallel-agents/phase-2.5-spec-review-b-rules.md`, `.../parallel-agents/phase-2.5-spec-review-a-consistency.md`, `.../phase-ledger.md`. → verify: `grep '## Step F' finish.md`; `grep code-quality` in 2.5-b; link target exists.
- [x] **T4 (W2)** — Reviewer D: author `agents/code-reviewer-performance.md` (7-section contract, OUTPUT cap, loads rules/performance.md, consumes the scout report); `phase-5-multi-review.md` — add Reviewer D section + fix §B to load/cite rules/code-quality.md (R1-1b) + canonical-pointer beside §C drift verdict (R1-8b). Files: `agents/code-reviewer-performance.md` (new), `skills/hackify/references/parallel-agents/phase-5-multi-review.md`. → verify: 7 sections present; grep 'Reviewer D' + 'code-quality' in the template.
- [x] **T5 (W2)** — Core SKILL.md wiring: Phase 3 wave-end scout step; Phase 4 perf acceptance rows; Phase 5 four-reviewer default A/B/C/D (and update the multi-concern rule: a 5th reviewer may be added for a second concern — hard cap rises 4→5); Phase 2.5 Reviewer B perf-risk mention; parallel-agents table row; Phase 1 always-on load list (R1-5); quick description 6-item fix (R3-3); hard-caps restatement → pointer + top caps (R1-7a); canonical-pointer beside both drift-verdict copies (R1-8c); minimal native-tier pointer lines where Phase 1/Phase 5 text references runtime-adapters (A3); file-map rows for the 3 new files; fix the stale quote of the old finish.md section title at SKILL.md:290 → new Step F title (T3 follow-up); update the always-on injection description to name all three injected rules files. Work the edit sites as an in-task checklist. Files: `skills/hackify/SKILL.md`. → verify: grep 'Reviewer D', 'perf-scout', 'perf-guardrails' in SKILL.md; SKILL-related validate-dod checks green at wave-end.
- [x] **T6 (W2)** — Checklists + mindset wiring (R1-4, R1-7b): review-and-verify.md (perf items in the self-review checklist, A–D reviewer list, escalation lens, hard-caps pointer); work-doc-template.md (perf self-review rows); expert-mindset hat gets its phase anchor in `skills/hackify/references/expert-mindset.md` + `rules/expert-mindset.md`. Files: those 4. → verify: grep perf rows in all 4.
- [x] **T7a (W2)** — Registration (R2-1, R2-2, C1): 00-helpers.sh — MIRROR_SOURCES += the new rules/references files (synced to T1's actual shape) AND CLAUDE_CODE_EXTRA += `agents/code-reviewer-performance.md`; 60-primitives.sh — add `code-reviewer-performance` to AGENTS_EXPECTED and derive the count from the array length (kill the hard-coded 7); 55-mirror-completeness.sh — forward-check `agents/` + `hooks/` too. Files: `scripts/sync-runtimes.d/00-helpers.sh`, `scripts/validate-dod.d/60-primitives.sh`, `scripts/validate-dod.d/55-mirror-completeness.sh`. → verify: wave-end `validate-dod.sh` ALL CHECKS PASSED with 8 agents; red-path probe per changed check (mutate → expect fail → restore).
- [x] **T7b (W3)** — Validator hardening (R2-3, R2-4, R2-6, R2-8, R2-10, A4): 50-runtimes-and-companions.sh — [25] += codewalk + lawkeeper, delete dead assignments; 20-templates.sh — extend template-contract checks over `agents/*.md`; 70-invariants-and-new.sh — new checks: EVERY hook command path in hooks.json (UserPromptSubmit AND PreToolUse) exists on disk, perf-guardrails is injected, Reviewer D agent present, perf-scout referenced by SKILL.md; check-collisions.sh — add `lawkeeper` slug. Files: `scripts/validate-dod.d/50-runtimes-and-companions.sh`, `scripts/validate-dod.d/20-templates.sh`, `scripts/validate-dod.d/70-invariants-and-new.sh`, `scripts/check-collisions.sh`. → verify: wave-end `validate-dod.sh` ALL CHECKS PASSED with new invariants live; red-path probe per new check (mutate → expect fail → restore).
- [x] **T8 (W3)** — quick + yolo mirrors: quick 5-lite gains perf lens + wave-end scout; yolo Phase 5 → A/B/C/D + scout staging; yolo Option-1 redefinition note (R3-5). Files: `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`. → verify: grep perf-scout + Reviewer D (yolo) / perf lens (quick).
- [x] **T9 (W3)** — Companion fixes: review-triage adds perf class to severity rubric + fixes :55/:59 refs (R3-2); commands/summary.md sprint-label extraction + Retrospective target + version tag (R3-1, R3-4, R3-6a); skillsmith SEVERITY frontmatter fix + stale tags (R3-7, R3-6b); lawkeeper rule-catalog perf category cites rules/performance.md as canonical + notes the deterministic scout. Files: `skills/review-triage/SKILL.md`, `commands/summary.md`, `skills/skillsmith/SKILL.md`, `skills/lawkeeper/references/rule-catalog.md`, `agents/code-reviewer-security.md` (T4 follow-up, added at dispatch). Parent micro-records (Daily Updates): `skills/hackify/SKILL.md` 16-item count, `scripts/validate-dod.sh` header ranges. → verify: all link targets resolve; grep 'Daily Updates' in summary.md.
- [x] **T10 (W3)** — runtime-adapters + Claude features (R1-3): "seven"→"eight" primitives; native-tier enhancement notes: structured-output schemas for reviewer/scout findings, background subagents for research/long scans, per-agent effort/model tiers (cheap scout, deep reviewers), task-tracker dependency ordering (blockedBy) for the phase ledger, back-to-back wizard batches; scout maps to the shell primitive on every tier. Files: `skills/hackify/references/runtime-adapters.md`. → verify: grep 'eight'; new native-tier notes present; no Claude tool names outside native-tier rows.
- [x] **T11 (W4)** — Release plumbing (absorbs former T12 per C6): extend CHANGELOG 0.7.0 entry (perf catalog + Reviewer D + scout + audit fixes); README feature + file-map updates; marketplace.json description check; THEN run `bash scripts/sync-runtimes.sh` AFTER every mirrored-source edit, marketplace.json included (C7), to regen dist/ mirrors; THEN demo-GIF regen (memory rule — phase behavior changed): run `scripts/gen-demo-gif.py`, confirm `docs/assets/hackify-demo.gif` updated (docs/assets is unmirrored — safe after sync). Files: `CHANGELOG.md`, `README.md`, `.claude-plugin/marketplace.json`, `dist/**`, `docs/assets/hackify-demo.gif`. → verify: wave-end validate-dod green incl. [55]; git status shows dist regen + GIF modified.

### Findings register (input to T-tasks; from 3 parallel background audits)

**R1 — core docs.** R1-1 Critical: Reviewer B templates never load rules/code-quality.md (SKILL.md:349/:107 claims they do) → T3/T4. R1-2 Critical: finish.md has no `## Step F` heading though 4 files cite it → T3. R1-3 Important: runtime-adapters.md:55 "seven primitives" vs 8 → T10. R1-4 Important: Performance hat unwired (no phase anchor) → T6 (+whole sprint). R1-5 Important: SKILL.md Phase 1 never lists the load-from-Phase-1 files → T5. R1-6 Minor: phase-ledger.md:26 wrong sibling link → T3. R1-7 Minor: hard-cap list restated in 3+ places → pointers in T5/T6. R1-8 Minor: drift-verdict duplicated in 5 places (identical-by-design) → canonical pointers in T3/T4/T5.

**R2 — infra.** R2-1 Important: 60-primitives pins agent count 7 → T7. R2-2 Important: agents/+hooks/ not forward-checked by [55] → T7. R2-3 Important: [25] skips codewalk+lawkeeper → T7. R2-4 Important: agents/*.md never contract-checked → T7. R2-5 Important: scan_edit/scan_bash exit-0 contract violation → T2. R2-6 Minor: check-collisions missing lawkeeper → T7. R2-7 Minor: `\btee\b` GNU-ism → T2. R2-8 Minor: dead assignments 50-runtimes:68-70 → T7. R2-9 Minor: heredoc target misattribution → T2. R2-10 Minor: hooks.json targets not existence-checked → T7.

**R3 — companions.** R3-1 Important: summary command parses legacy labels only → T9. R3-2 Important: review-triage broken refs :55/:59 → T9. R3-3 Minor: SKILL.md:17 quick 4-step vs 6-item → T5. R3-4 Minor: summary.md:21 Post-mortem → Retrospective → T9. R3-5 Minor: yolo Option-1 label diverges from core → T8. R3-6 Minor: stale version tags (summary v0.1.3, skillsmith v0.2.0) → T9. R3-7 Minor: skillsmith frontmatter marks SEVERITY mandatory for all → T9.

## 6. Daily Updates

### T1 — Perf doctrine trio — done 2026-07-03 (W1)

- **Test mode:** none (docs + one JSON edit; no runtime surface)
- **Notes:** `rules/performance.md` 184 lines — 95 stable IDs across 10 domain tables + severity model + "When NOT to optimize"; `rules/perf-guardrails.md` 24 lines with canonical pointer (direction stated in both files); `references/perf-scout.md` 242 lines — 43 BSD-grep-safe patterns keyed to catalog IDs + staging table + triage rules + top-10 micro examples; `hooks/hooks.json` third UserPromptSubmit entry. Fallback split NOT needed. Merges: unbatched-writes consolidation, cache/memory cross-refs.
- **Self-review:** ✓ allowlist ✓ caps ✓ no suppressions ✓ B2 voice
- **Verification:** `jq` hook count = 3; all 43 scout-cited IDs resolve in catalog; `wc -l` within caps.

### T2 — Hook/scanner fixes — done 2026-07-03 (W1)

- **Test mode:** test-first (harness extended first; watched RED)
- **Notes:** fail-open wrap for `detect()` paths in scan_edit.py + scan_bash.py (explicit exit-0 handlers, contract cited); per-heredoc redirect-target pairing in scan_bash.py; portable tee ERE in block-banned-tokens.sh (BSD-safe). Pre-existing scope limit (`cat <<EOF | tee f.ts`) documented in docstring.
- **Self-review:** ✓ allowlist ✓ ≤40-line functions ✓ no bare excepts-without-action
- **Verification:** RED 33/38 (multi-heredoc + fail-open cases) → GREEN 38/38, exit 0; `py_compile` both OK; `bash -n` OK.

### T3 — Doc Critical fixes — done 2026-07-03 (W1)

- **Test mode:** none (docs)
- **Notes:** finish.md gains real `## Step F — Summary table + HTML report` heading (:364), Steps A–E untouched; 2.5-b template now loads/cites `rules/code-quality.md` (METHOD + VERIFICATION + OUTPUT enum); 2.5-a carries goal-anchor canonical pointer; phase-ledger.md:26 sibling link fixed. Follow-up routed to T5: SKILL.md:290 stale old-title quote.
- **Self-review:** ✓ allowlist ✓ template contract 7/7 intact ✓ surgical diffs
- **Verification:** 5/5 greps pass (`## Step F` ×1; code-quality present; goal-anchor present; zero bad ledger links).

### T4 — Reviewer D + phase-5 template — done 2026-07-03 (W2)

- **Test mode:** none (docs)
- **Notes:** `agents/code-reviewer-performance.md` new (70 lines, 7-section contract, 7 catalog-ID citations); phase-5-multi-review.md gains §D + §B now loads `rules/code-quality.md` (R1-1b) + §C goal-anchor canonical pointer (R1-8b); wording updated three→four reviewers, cap 4→5. Cap conflict solved by lossless §B consolidation (495/500 lines). Follow-ups routed: sibling agents' stale "THREE reviewers" wording → T9; `PA_MULTI_REVIEW_HEADINGS` §D → T7b.
- **Self-review:** ✓ allowlist ✓ contract ✓ real 20-templates.sh run zero FAILs
- **Verification:** greps for 'Reviewer D', 'code-quality', 'goal-anchor' all present; §D body byte-identical agent↔template.

### T5 — Core SKILL.md wiring — done 2026-07-03 (W2)

- **Test mode:** none (docs)
- **Notes:** all 13 sites landed (wave-end scout step, Phase 4 perf rows, A/B/C/D default, cap 5, 2.5-B perf risk, parallel table, Phase 1 load trio, quick 6-item fix, caps→pointer + 3 injected files + perf-law intro, drift canonical ×2, Step F quote, file-map rows + native-tier line). 412→426 lines (≤500). Parent micro-fix after wave: "14-item"→"16-item" at :245 (count changed by T6).
- **Self-review:** ✓ allowlist ✓ ≤500 ✓ WIP ledger section intact
- **Verification:** grep proofs — Reviewer D ×5, perf-scout ×5, perf-guardrails ×3, performance.md ×5, old Step-F quote ×0.

### T6 — Checklists + mindset wiring — done 2026-07-03 (W2)

- **Test mode:** none (docs)
- **Notes:** review-and-verify.md — +3 perf items (checklist now 16), A/B/C/D list, escalation template gains `{{reviewer_d_report}}`, caps→pointer (R1-7b); work-doc-template — 2 perf self-review rows + scout ledger example row; Performance hat anchored in both expert-mindset files (R1-4). Used REAL catalog prefixes (`perf.data.*`). Follow-ups: README "14-item" ×2 → T11; template caps rows kept (they ARE the checklist instrument — disposition to Retrospective).
- **Self-review:** ✓ allowlist ✓ caps ✓ real IDs verified against catalog
- **Verification:** greps — perf ≥1 in all 4 files, Reviewer D ×4, perf-scout ×7.

### T7a — Registration — done 2026-07-03 (W2)

- **Test mode:** test-after + red-path probes (trap-restored, zero git mutations)
- **Notes:** MIRROR_SOURCES += 3 perf files; CLAUDE_CODE_EXTRA += code-reviewer-performance (C1); AGENTS_EXPECTED += new agent with count DERIVED from array (R2-1); [55] forward-check now covers agents/ + hooks/ (R2-2) with one documented exclusion (`hooks/test_block_banned_tokens.sh` — sync copies only the EXTRA enumeration). Informational: copilot-cli emitter ignores rules/ files (pre-existing, all entries equally) → noted for T11.
- **Self-review:** ✓ allowlist ✓ ≤40-line functions ✓ bash 3.2 safe
- **Verification:** probes RED then restored-PASS ([55] hard-caps pull, [55] agents pull, [30] bogus name + derived count "expected 8"); `bash -n` ×3 clean; wave-end full validator ALL CHECKS PASSED with 8 agents.

### T7b — Validator hardening — done 2026-07-03 (W3)

- **Test mode:** test-after + red-path probes (trap-restored, zero git mutations)
- **Notes:** [25] += codewalk + lawkeeper; dead assignments removed (R2-8); agents/*.md now contract-checked as [36] (SEVERITY asserted for code-reviewer-* only); §D heading added to PA_MULTI_REVIEW_HEADINGS (T4 follow-up); [37] hook targets exist+executable, [38] perf-guardrails injected, [39] Reviewer D + perf-scout invariants; check-collisions += lawkeeper (8 slugs). Parent follow-up applied: validate-dod.sh header ranges updated ([36], [37]-[39]).
- **Self-review:** ✓ allowlist ✓ bash 3.2 safe ✓ no dead code
- **Verification:** 6 probe families RED→restored-PASS; full validator ALL CHECKS PASSED first run.

### T8 — quick + yolo mirrors — done 2026-07-03 (W3)

- **Test mode:** none (docs)
- **Notes:** quick — scout in verify, 5-lite lens = quality + correctness + goal drift + performance, perf-guardrails named; stale "3-lens" refs → 4-lens (drift removal, in-scope). yolo — wave-end scout, A/B/C/D, Phase 5 scout staging into auto-fix loop, Option-1 redefinition note with validator token intact, perf-guardrails named. Real catalog prefixes used (perf.frontend/perf.obs/perf.caching — not the draft shorthand).
- **Self-review:** ✓ allowlist (+36/−8 across exactly 2 files) ✓ tokens preserved (real check run, FAILED=0)
- **Verification:** perf-scout quick×1 yolo×3; validator token lists green; 107/98 lines.

### T9 — Companion fixes — done 2026-07-03 (W3)

- **Test mode:** none (docs)
- **Notes:** review-triage — full-path refs fixed (R3-2), 4-lens trigger surface, perf severity classes citing the catalog; summary command — sprint-label extraction + legacy fallback (R3-1), Retrospective target (R3-4), 0.7.0 tag; skillsmith — SEVERITY review/audit-only frontmatter (R3-7), five version pins removed (R3-6b incl. one beyond the audit's four); lawkeeper rule-catalog — rules/performance.md canonical + 13 IDs mapped + perf-scout seed note, scanner delegation unchanged (Non-Goal honored); security agent — FOUR/A–D wording (T4 follow-up; quality + plan-consistency had no stale wording).
- **Self-review:** ✓ allowlist ✓ YAML valid ✓ 7/7 sections intact
- **Verification:** greps — bare refs 0; Daily Updates/Sprint Backlog/Retrospective present; v0.2.0 = 0; performance.md ×6 in rule-catalog. New Minors staged for Phase 5 decision table: skillsmith:108 "all 7 sections" imprecise; review-triage worked example still 3-reviewer (illustrative).

### T10 — runtime-adapters + Claude features — done 2026-07-03 (W3)

- **Test mode:** none (docs)
- **Notes:** stale "seven primitives" fixed (R1-3); new "Native-tier enhancements (optional, never load-bearing)" section — structured subagent outputs, background subagents, per-agent model/effort tiers, task-tracker dependency ordering, batched wizard rounds — each with degrade path + per-runtime honesty (Claude Code native ×5; unknowns marked); scout deliberately excluded (rides shell primitive on every tier); Claude tool names confined to native-tier cells.
- **Self-review:** ✓ allowlist ✓ 99 lines ✓ portability doctrine intact
- **Verification:** greps — 'seven' 0, 'Native-tier enhancements' 1, 'degrade' ×6, 'must' 0 in section.

### T11 — Release plumbing (absorbed T12 GIF) — done 2026-07-03 (W4)

- **Test mode:** none for docs; script runs verified
- **Notes:** CHANGELOG 0.7.0 entry extended (4 Added / 3 Changed / new Fixed; WIP bullets untouched); README — four reviewers, 16-item ×2, three injected files ×4, file-map rows, stale quick "four-phase" ×4 + diagram fixes; marketplace.json consistent (no change). `sync-runtimes.sh` OK — 508 files across 7 runtimes (dist/ is gitignored; regen proven via sync output + mtimes). Validator ALL CHECKS PASSED incl. [37]-[39]. Demo GIF regenerated per memory rule — output byte-identical (deterministic generator; depicted phase names + install commands unchanged): the run is the compliance, the identical bytes are the outcome.
- **Self-review:** ✓ allowlist ✓ no hand-edited dist ✓ README claims spot-verified pre-write
- **Verification:** CHANGELOG 'performance' ×6 (0.7.0-entry-scoped; whole-file count is 7 — scope annotated per reviewer C); README '14-item' 0, 'Three parallel reviewers' 0; sync + validator outputs trimmed in Sprint Review ledger. Verify-line reality note (reviewer C): dist/ regen cannot appear in `git status` (tracked `dist/.gitignore` = `*`) — proven via sync output + mtimes; GIF regenerated byte-identical (deterministic generator) — the run satisfies the memory rule.

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4)

| Item | Type | Claim | What I ran | Proof sample | Result |
|---|---|---|---|---|---|
| T1 | task | catalog + stub + scout + 3rd injection authored | `jq`, `wc -l`, `comm` ID-diff | `3 entries; 184/24/242 lines; unresolved IDs: 0` | ✅ |
| T2 | task | scanners fail-open, per-heredoc attribution, BSD tee | `bash hooks/test_block_banned_tokens.sh` | `38/38 passed` (was 33/38 RED pre-fix) | ✅ |
| T3 | task | Step F heading + Reviewer-B code-quality load + links | greps | `## Step F — Summary table + HTML report` ×1; `code-quality` in 2.5-b ×3 | ✅ |
| T4 | task | Reviewer D agent + template §D | validator [36] + greps | `agents/ = 8`; §D byte-identical agent↔template | ✅ |
| T5 | task | 13-site core SKILL.md wiring | grep counts + `wc -l` | `perf-scout×5, Reviewer D×5, 426 lines` | ✅ |
| T6 | task | 16-item checklist + perf rows + hat anchors | greps | `review-and-verify: perf-scout×5, Reviewer D×4` | ✅ |
| T7a | task | registration + derived agent count | red-path probes + validator | `[30] "expected 8" (derived); [55] covers agents/+hooks/` | ✅ |
| T7b | task | checks [25]+2, [36]–[39] live + fail-able | probe FAIL lines | `FAIL target rules/hard-caps-MISSING.md missing on disk` → restored PASS | ✅ |
| T8 | task | quick/yolo mirrors, validator tokens intact | real token-check run | `TOTAL FAILED=0; perf-scout quick×1 yolo×3` | ✅ |
| T9 | task | companions + security agent aligned | greps | `bare refs 0; v0.2.0 = 0; rule-catalog performance.md ×6` | ✅ |
| T10 | task | eight primitives + native-tier section | greps | `'seven' 0; 'Native-tier enhancements' ×1; degrade ×6` | ✅ |
| T11 | task | CHANGELOG/README/sync/GIF | script runs | `OK — synced 508 files across 7 runtimes`; GIF regenerated (md5 unchanged — deterministic) | ✅ |
| AC1 | acceptance | 10-domain catalog, stable IDs + severity, ≤500 | `grep -oE 'perf\.[a-z-]+\.'` + `wc -l` | `10 domains; 96 ID refs; 184 LOC` | ✅ |
| AC2 | acceptance | 3rd always-on injection, targets exist on disk | `jq` + validator [37]/[38] | `hard-caps.md / expert-mindset.md / perf-guardrails.md` | ✅ |
| AC3 | acceptance | scout protocol + every mirror surface | `comm` + surface greps | `unresolved 0; SKILL×5 quick×1 yolo×3 r-a-v×5 wdt×2 triage(classes) lawkeeper×6` | ✅ |
| AC4 | acceptance | four-reviewer default, 8 agents registered | `ls agents/ | wc -l` + greps | `8; validator [30]/[36]/[39] green` | ✅ |
| AC5 | acceptance | all 25 findings fixed | register → Daily Updates map | every R-id appears in a done task entry (T1–T11) | ✅ |
| AC6 | acceptance | native-tier notes, portability intact | greps | `section ×1; 'must' 0 inside it; stale 'seven' 0` | ✅ |
| AC7 | acceptance | final tree green + release artifacts | fresh `validate-dod.sh` | `ALL CHECKS PASSED`; README `14-item` 0; commit itself lands in Phase 6 | ✅ (commit pending) |
| AC8 | acceptance | red-path probes + Phase-5 dogfood | probes in T7a/T7b updates; Phase 5 run | probes ✅; dogfood ✅ — scout run (3 candidates, all false-positive per guards) + FOUR reviewers incl. new Reviewer D (upheld all dismissals, zero perf findings, quantified +~1.2k tokens/prompt always-on cost as deliberate) | ✅ |
| dogfood | acceptance | this release passes its own perf bar | perf-scout tables over own diff + Reviewer D contract run | staging table in Phase 5 section; D verdict: no Critical/Important/Minor | ✅ |

**Three-layer re-verify:** Layer 1 fresh triad ✅ (`ALL CHECKS PASSED` + `38/38 passed`, fresh run post-W4) · Layer 2 goal-drift re-check ✅ (every Success Signal traces to a row above; two signals — single commit, dogfood — are phase-scheduled by design and gated in Phases 5/6) · Layer 3 independent re-prove ✅ — fresh subagent re-earned every proof with its own commands: AC1–AC6 + AC8-probe all confirmed (95 IDs/10 domains; 3rd injection + [37] green; 43/43 scout IDs resolve; 8 agents + FOUR default at SKILL:238; representative fixes verified; adapters clean; validator `ALL CHECKS PASSED` 110 files; hooks `38/38`), AC7 ⚠️ solely because the combined release commit is Phase 6 work. New observation staged for the Phase 5 decision table: CHANGELOG.md is 608 lines — over the general 500 guardrail but outside the validator's enforced cap scope (historical append-only log).

### Perf-scout — phase-5 (dogfood on this sprint's own diff) — 2026-07-03

Scope: whole sprint diff. Pattern-covered code files: `hooks/scan_edit.py`, `hooks/scan_bash.py` (Python). No JS/TS/SQL files in the diff. Shell validators + markdown-quoting-patterns handed to Reviewer D as semantic/run-context items.

| Finding | Catalog ID | file:line | Evidence | Proposed fix | Status |
|---|---|---|---|---|---|
| Whole-file read of allowlist | perf.io.whole-file-read | hooks/scan_edit.py:93 | `set(handle.read().splitlines())` | — | false-positive: config-sized allowlist in a one-shot hook process |
| Whole-payload stdin read | perf.io.whole-file-read | hooks/scan_edit.py:108 | `text = sys.stdin.read()` | — | false-positive: single bounded tool payload; streaming adds complexity, no win |
| Whole-payload stdin read | perf.io.whole-file-read | hooks/scan_bash.py:80 | `cmd = sys.stdin.read()` | — | false-positive: same run context |

Loop-window patterns: zero hits. All three dispositions submitted to Reviewer D for re-judgment per protocol — **Reviewer D upheld all three dismissals** (no Critical defaults, no co-sign required) and returned zero findings of its own; it also quantified the always-on cost honestly: +2 hook processes ≈ +20–30ms CPU (parallel matchers ≈ unchanged wall-clock) and ~+1.2k tokens/prompt of injected doctrine — deliberate, AC'd in T1.

### Decision table (Phase 5 address-all — 4 reviewers, deduplicated)

Zero Critical. Rulings Q1–Q4 user-signed via wizard.

| # | Finding | Severity | Decision | Evidence / fix |
|---|---|---|---|---|
| I1 | scan_bash.py heredoc pairing bypass for redirect-after-body forms (`{ …<<EOF… } > app.ts`) — live-verified regression | Important | fix (Q1-A superset blocking) | counts match → positional; else every heredoc × ALL targets; test-first RED→GREEN |
| I2 | hooks.json — 6 unquoted `${CLAUDE_PLUGIN_ROOT}` expansions; spaces in install path silently kill all 3 injections | Important | fix | quote script + argument in all 3 entries; jq + validator [37]/[38] re-proven |
| I3 | parallel-agents/README.md + phase-5-escalation.md still say "three reviewers (A/B/C)" | Important | fix | update to four/A–D |
| I4 | CHANGELOG 0.7.0 "Injection hook generalized" bullet lists 2 of 3 injected files (self-contradicting entry) | Important | fix | enumeration completed |
| I5 | Reviewer D prompt duplicated byte-identical (agent file ↔ template §D) with no canonical pointer — the convention this sprint added elsewhere | Important | fix | template §D = canonical; keep-in-sync pointer in both copies |
| I6 | quick-mode co-sign law unexecutable (no Reviewer D in quick) | Important | fix (Q2-A) | perf-scout TRIAGE + quick Phase 4: 5-lite single reviewer co-signs Critical-default dismissals |
| I7 | CHANGELOG.md 608 lines vs ≤500 guardrail letter | Important | ruled exempt (Q3-A) | append-only log outside cap intent + validator scope; ruling recorded in Guardrails |
| I8 | untracked new files referenced by tracked manifests — forgotten `git add` at release ships broken pointers | Important | process guard | Phase 6 Step C: `git add -A` (untracked included) before the single 0.7.0 commit |
| M1 | inject-context.sh header enumerates 2 of 3 injected files | Minor | fix | header names all three |
| M2 | fail-open exits are fully silent (caller also 2>/dev/null) | Minor | fix | one stderr line before exit 0 in both scanners |
| M3 | 70-invariants: unquoted `for t in $HOOK_TARGETS` | Minor | fix | while-read iteration |
| M4 | commands/summary.md reintroduced a version pin ("v0.7.0 … contract") | Minor | fix | pin dropped |
| M5 | MIRROR_SOURCES WIP entries out of alphabetical order | Minor | fix | reordered |
| M6 | work-doc allowlist bookkeeping (security agent + validate-dod.sh untraced) | Minor | fixed (parent) | T9 Files amended; parent records named |
| M7 | work-doc frontmatter lagged actual phase | Minor | fixed (parent) | status: reviewing, current_task: phase-5-review |
| M8 | T11 ledger proof "performance ×6" scope unstated (whole-file = 7) | Minor | fixed (parent) | scope annotated in Daily Updates |
| M9 | communication-voice example says "3 reviewers" | Minor | fix | example → 4 |
| M10 | T11 verify line not literally reproducible (gitignored dist; deterministic GIF) | Minor | fixed (parent) | reality note added to T11 entry |
| M11 | skillsmith:108 "all 7 sections" imprecise vs SEVERITY-conditional contract | Minor | fix | wording: SEVERITY review/audit-only |
| M12 | review-triage worked example still shows a 3-reviewer batch | Minor | fix | example updated to the 4-lens default |
| D1 | expert-mindset.md basename shared across rules/ + references/ | Minor | defer (Q4-A, user-signed push-back) | headers state the tight/deep pairing explicitly; rename churns 6+ registration points for zero behavior; Retrospective follow-up |
| M13 | CHANGELOG scanner bullet under-described shipped behavior (38 vs 41 cases; superset rule + breadcrumb omitted) | Minor | fixed (parent, post-fixer) | bullet amended: superset rule, stderr breadcrumb, 29 → 41 |

**Loop closed 2026-07-03:** all fix rows executed by the address-all fixer (18 files) + parent (M6–M8, M10, M13); I1 test-first RED 38/41 → GREEN 41/41; re-verify after the batch: `validate-dod.sh` **ALL CHECKS PASSED** + hooks suite **41/41** + [37] red-path probe re-proven on the quoted form. Remaining rows: 2 rulings (I7 exempt, I8 executes at the Phase 6 commit) + 1 user-signed deferral (D1). Decision table empty.

### Self-review (Phase 5)

Parent self-review against `references/review-and-verify.md`'s 16-item checklist (canonical list lives there). Diff is docs + bash + python; JS/TS-only items pass vacuously.

| Item | Pass | Notes |
|---|---|---|
| DRY | ✓ | doctrine points to canonical files; Reviewer D copies carry keep-in-sync pointers (I5) |
| Layering / single responsibility | ✓ | validator checks stay one-concern-per-file; hooks stay thin |
| Named types | ✓ | n/a (no TS); python uses named helpers |
| No lint suppressions | ✓ | zero introduced (reviewer B ban-scan on all hunks) |
| File caps ≤500 | ✓ | max touched: phase-5-multi-review.md 497; CHANGELOG ruled exempt (Q3-A) |
| Function caps ≤40/3/3 | ✓ | all changed bash/python functions ≤27 LOC (reviewer B measured) |
| Dead code removed | ✓ | `nums`/`bares`, `_last_target_between` deleted |
| Edge cases | ✓ | fail-open paths tested; quoted expansions; superset heredoc rule |
| Naming for intent | ✓ | perf.<domain>.<slug> ID scheme; check names descriptive |
| Error handling explicit | ✓ | fail-open exits cite contract + stderr breadcrumb |
| No security regressions | ✓ | heredoc bypass FIXED (I1); tee regex superset-verified; no secrets |
| No new `!` / empty catches / bare Error | ✓ | reviewer B: 0/0/0 (test fixtures excluded by design) |
| No perf violations (rules/performance.md) | ✓ | Reviewer D: zero findings; 3 scout candidates dismissed per guards |
| Scout candidates dispositioned | ✓ | 3/3 with reasons; D upheld all |
| Bounded sets / parallel I/O | ✓ | validators use sorted `comm`, no O(n²); hook hot path quantified |
| No sync blocking on hot paths | ✓ | hooks are one-shot bounded processes (D verdict) |

## Phase 6 — Cleanup sweep evidence (Step C.5)

| Class | Evidence |
|---|---|
| a. Stale cross-references | `inject-hard-caps` sweep: 0 hits outside CHANGELOG history/archives; stale counts ("three reviewers", "14-item", "seven primitives", "v0.2.0") fixed in Phase 5 — re-greps 0 |
| b. Broken anchor links | Reviewer B verified every cross-file link/ID reference resolves; T3/T9 grep proofs for all edited link targets |
| c. TODO/FIXME without owner | `git diff HEAD` grep: none |
| d. Empty directories | `find -type d -empty`: none |
| e. Dead branches | none created this sprint (all work on `main`); pre-existing `refactor/tech-neutral-principles` + its worktree predate the sprint — surfaced, left untouched |
| f. Unrelated changes | Reviewer C scope audit: every changed file traces to a task, the recorded WIP carve-out (Q6-B), or a parent record; no Out-of-Scope/Non-Goal violated |
| g. Pre-existing issues in touched files | validator ALL CHECKS PASSED; hooks suite 41/41; all changed functions ≤27 LOC (reviewer-measured); 0 suppressions / `!` / empty catches |
| h. Work-doc path references | doc cites only live paths after all renames (dangling-ref grep: 0); no sibling work-doc affected |

**Step D.5 codewalk:** skipped — plugin/docs repo; no application entry-point files (controllers, CLI apps, queue handlers, UI actions) were touched.

## 8. Retrospective

- Phase 2.5 spec review was the highest-leverage step: it caught 3 release-shaped design gaps on paper (validator timing vs suspended wave commits, `CLAUDE_CODE_EXTRA` registration for the new agent, catalog 500-LOC overflow risk) before any code existed.
- Our own T2 fix introduced the sprint's only behavioral regression (heredoc redirect-after-body bypass). Lesson: fixes to BLOCKING security controls need bypass-shaped tests, not only attribution-shaped ones — the dogfooded four-reviewer run caught it live.
- The perf-scout's first real run (on this sprint's own diff) behaved as designed: 3 candidates, 3 documented false-positive dispositions, all upheld by Reviewer D — the triage protocol carried its weight on first contact.
- Reviewer D quantified the always-on injection cost (~+1.2k tokens/prompt, +2 hook processes): future always-on additions should ship with the same cost note up front.
- `gen-demo-gif.py` is deterministic — phase-content changes do not alter the GIF unless the depicted phase names or install commands change; the memory rule is updated so regeneration expectations stay honest.
- The combined WIP+sprint release (Q6-B) worked because the WIP carve-out was recorded in the work-doc up front — Reviewer C could separate authorization cleanly. Keep that pattern for any multi-feature tree.
- Deferred with user sign-off (D1): `expert-mindset.md` basename is shared between `rules/` and `references/` while sibling pairs use distinct names — revisit if a third always-on pair lands.
- Follow-up: consider archiving pre-0.5.0 CHANGELOG entries if the file keeps growing (ruled exempt from the 500-line cap this sprint, Q3-A).

## Summary of changes shipped

| Area | Change |
|---|---|
| Performance catalog | New canonical `rules/performance.md` — 95 stable `perf.<domain>.<slug>` IDs across 10 domains, each with severity, why-it-hurts, detection hint, fix direction, plus a "When NOT to optimize" guard |
| Always-on guardrails | New `rules/perf-guardrails.md` injected on every prompt as the third `UserPromptSubmit` entry; points to the catalog as canonical |
| Perf-scout | New `references/perf-scout.md` — BSD-safe grep tables (JS/TS, Python, SQL) keyed to catalog IDs; runs at every wave-end + Phase 5 start; staging + triage + co-sign rules |
| Reviewer D | New `agents/code-reviewer-performance.md`; Phase 5 default is now FOUR parallel lenses (A/B/C/D), multi-concern cap 4→5 |
| Core SKILL wiring | 13 sites: wave-end scout step, Phase 4 perf acceptance rows, A/B/C/D default, Phase 1 always-on load list, caps restatements → canonical pointers, Step F title, file map |
| Companion skills | quick 5-lite gains perf lens + co-sign carry-over; yolo mirrors A/B/C/D + scout auto-fix staging; review-triage gains perf severity classes; lawkeeper catalog cites the canonical catalog |
| Validator hardening | Agent count derived from roster; `[55]` covers `agents/`+`hooks/`; `[25]` +codewalk+lawkeeper; new `[36]`–`[39]` checks (agent contracts, hook targets, perf invariants) — every new check proven fail-able |
| Hook scanners | Fail-open hardened with stderr breadcrumb; per-heredoc attribution with superset blocking (bypass fixed); BSD-safe `tee` filter; test suite 29 → 41 cases |
| hooks.json | Third injection entry (perf-guardrails); all `${CLAUDE_PLUGIN_ROOT}` expansions quoted against paths with spaces |
| Docs audit | 25 audit findings fixed at every severity: `Step F` heading restored, Reviewer B templates now load `rules/code-quality.md`, summary command parses sprint labels, broken refs + stale counts/pins removed |
| Claude features | `runtime-adapters.md` native-tier section: structured subagent outputs, background subagents, model/effort tiers, task-tracker ordering, batched wizards — each with a degrade path |
| Phase ledger + mindset (WIP) | Pre-existing v0.7.0 work shipped in this release: trackable ordered phase ledger (todo tracker) + always-on expert-mindset injection + generalized `inject-context.sh` |
| Release plumbing | v0.7.0: CHANGELOG entry extended, README rewired (four reviewers, 16-item checklist, three named injections), `dist/` regenerated (508 files / 7 runtimes), demo GIF regenerated |
