---
slug: strengthen-workflow-phases
title: Strengthen four workflow phases across all entry skills (0.6.0)
status: implementing
type: revamp
created: 2026-07-01
project: hackify
current_task: W4:T18 (verify)
worktree: none (in-place)
branch: feat/strengthen-workflow-phases
sprint_goal: Make clarify, summary, review, and cleanup materially more thorough across hackify/quick/yolo/groom, shipped as 0.6.0 with every DoD check green.
related: []
---

## 1. Original Ask

Verbatim, four bullets:

1. Strengthen the **clarification phase** in all entry skills to ask whatever questions it has to give maximum task understanding and avoid drifting away from the main goal. It should act as a grooming session that drives all plan decisions and implementation logic.
2. The **summary phase**, after it finishes working on work-docs, should give a visually styled, easy-to-read HTML report supported with all elements/graphs/stats needed to help the developer grasp what has been done, plus any follow-up steps / action items / instructions.
3. The **review phase** should address all problems found (as the lawkeeper skill works).
4. The **cleanup sweep phase** shouldn't leave pre-existing errors and should offer to fix them. The code after this phase should be the best version we have no comments on.

## Primary Goal & Guardrails

> Dogfooding the new anchor this sprint adds. Every task and every reviewer traces back here.

- **North-Star Goal.** Make the four named phases (Clarify, Summary, Review, Cleanup) materially more thorough across all four entry skills (`hackify`, `quick`, `yolo`, `groom`), shipped as a coherent `0.6.0` — with every `validate-dod.sh` check green and every capped file ≤500 LOC.
- **In-Scope.** The four phase enhancements; 3 new supporting files (`goal-anchor.md`, `html-report.md`, `report-template.html`); the goal-anchor drift-check in Phase 2.5 + Phase 5 reviewers; release plumbing (version → 0.6.0, CHANGELOG, README badge/blurb, MIRROR_SOURCES registration).
- **Out-of-Scope / Non-Goals.** Rewriting lawkeeper's scanner; whole-repo pre-existing fixes (that stays lawkeeper's job); regenerating the demo GIF binary (phase set/names unchanged → tags still accurate; recorded as a deliberate deferral); new eval corpora; changing the phase SET or names; editing `codewalk`/`skillsmith`/`review-triage` except where cross-referenced.
- **Guardrails / Invariants (a change that violates one is a Critical finding).**
  - All `validate-dod.sh` checks stay green; `check-collisions.sh` green; `sync-runtimes.sh --dry-run` green.
  - ≤500 LOC per capped file (`skills/ agents/ rules/ scripts/ hooks/ commands/` `*.md/*.sh/*.json`).
  - Preserve the Wizard Contract (SCENARIO/COMPOSITION/QUESTIONS/EXIT CRITERIA) and Template Contract (ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/SEVERITY/OUTPUT + canonical severity phrase + OUTPUT word cap) anchors in every touched template/bank.
  - Preserve `quick`'s "Skipped phases" identity tokens (`Phase 2`, `Phase 2.5`, `Phase 5`, `four-options`, `Summary table`, the exploration-nudge sentence) and `yolo`'s required tokens (`auto-pass`, `no work-doc`, `commit to current branch locally`, all phase numbers, `in-chat plan`).
  - No personal tokens (`corecave`, `nadyshalaby`) or absolute `/Users/…` paths in shipped `skills/`/`README`/`.claude-plugin` content; the HTML template uses generic placeholders only.
  - No lint suppressions, no non-null `!`, no bare `Error` — and the HTML asset must not trip the banned-token hooks.
  - Self-contained HTML report: inline CSS + inline SVG charts, ZERO external network dependencies.
- **Success Signals.** `validate-dod.sh` exits 0; the HTML report renders with charts from sample data (screenshot); the diff visibly satisfies all four Original-Ask bullets in every entry skill at its agreed scope.

## 2. Clarifying Q&A

Answered via wizard (two batches). Locked decisions:

| # | Question | Decision |
|---|---|---|
| 1 | Clarify strengthening approach | **1A — Goal anchor + deep wizard.** Persisted "Primary Goal & Guardrails" block captured in Phase 1; raise the ~16-Q cap; grooming-style coverage checklist; keep the batched wizard format. |
| 2 | HTML report deps & delivery | **2A — Self-contained, augments table.** Single portable `.html` (inline CSS + inline SVG charts, zero network deps) beside the archived work-doc; Area/Change markdown table still prints to chat. |
| 3 | "Address all problems" model | **3A — All severities, gated loop + re-scan.** Adopt lawkeeper's loop in Phase 5: surface every finding incl. Minor in a decision table, fix in severity order, re-run to prove zero remaining. Full hackify batches approval via wizard; yolo auto-fixes all; quick gets a single-lens pass. |
| 4 | Cleanup pre-existing errors | **4A — Detect + offer to fix (touched scope).** Baseline pre-existing lint/type/test + dead code in touched files; present & OFFER to fix before archive (auto-fix in yolo). Class (g) flips defer → offer-to-fix. "No comments" = nothing a reviewer would flag. |
| 5 | How far `quick` goes | **5C — Full parity.** quick gains trimmed clarify + HTML report + single-lens address-all review + offer-to-fix cleanup. Reconciled with DoD [22]: quick KEEPS its "Skipped phases" list (skips Plan+Gate, Spec-review, the 3-reviewer Phase 5, and the 4-options menu) but gains the lighter single-lens review + cleanup + report. |
| 6 | Anchor enforcement strength | **6A — Hard check in 2.5 + 5, no extra gate.** Phase 2.5 (Reviewer A) and Phase 5 (Reviewer C) each trace every task / changed hunk to the goal; untraceable → drift finding (Important); guardrail/non-goal violation → Critical. No re-gate. |

## 3. Acceptance Criteria

> Bracketed `[n]` refer to canonical DoD check IDs defined in `scripts/validate-dod.d/*.sh` (e.g. `[80]` = `80-file-size-caps.sh`, `[55]` = `55-mirror-completeness.sh`, `[22]` = `40-quick-skill.sh`). Implementers: resolve a `[n]` by grepping `scripts/validate-dod.d/` for its check body; each task below also states the concrete requirement in plain terms.

- [ ] `bash scripts/validate-dod.sh` exits 0, all checks green — paste output.
- [ ] `bash scripts/check-collisions.sh` exits 0 — paste output.
- [ ] `bash scripts/sync-runtimes.sh --dry-run` succeeds, covers 7 runtimes, includes the 3 new files — paste tail.
- [ ] **Clarify:** `## Primary Goal & Guardrails` in `work-doc-template.md` (no renumbering of numbered sprint headings); goal-anchor question added to `universal-preamble.md` with the 4-section wizard contract intact; new `references/goal-anchor.md` documents capture + enforcement; drift-check present in Phase 2.5 Reviewer A mirror-pair and Phase 5 Reviewer C mirror-pair with all Template-Contract anchors + canonical severity phrase intact.
- [ ] **Summary:** `skills/hackify/assets/report-template.html` exists, self-contained (no `http`/`https`/`cdn` external refs), renders valid HTML with every stat section + inline SVG charts — screenshot evidence; `references/html-report.md` documents emission (when/where/stats/compute/fill); `SKILL.md` Phase 6 Step F + `finish.md` + `commands/summary.md` emit it; Area/Change table retained (DoD [18][19][20] green).
- [ ] **Review:** Phase 5 in `SKILL.md` + `review-and-verify.md` document the address-all loop (decision table → fix in severity order incl. Minor → re-run review/verify to zero); severity table no longer defers Minor by default (defer only with explicit user sign-off); quick = single-lens address-all; yolo = auto-fix all severities.
- [ ] **Cleanup:** Step C.5 class (g) flips defer → offer-to-fix; `finish.md` documents baseline capture + offer-to-fix for pre-existing lint/type/test/dead-code in the touched scope; yolo auto-fixes; whole-repo pre-existing stays out of scope (cross-reference lawkeeper).
- [ ] **Entry-skill scope:** all four skills reflect their agreed scope; quick retains "Skipped phases" tokens + exploration nudge (DoD [22][35]); yolo retains required tokens (DoD [34]).
- [ ] **Release:** version = `0.6.0` in `plugin.json` + `marketplace.json` (both plugins) + README badge; `marketplace.json` `.plugins[0].source.ref` = `v0.6.0`; README stays 250–450 LOC; CHANGELOG has a `0.6.0` entry covering all four enhancements; 3 new files registered in `MIRROR_SOURCES`.
- [ ] No new lint suppressions, non-null `!`, personal tokens, or absolute paths in shipped content (DoD [6] green); banned-token hooks pass on the HTML template.

## 4. Approach

**Strategy.** All substantial new prose goes into **3 new files** (keeps the tight `SKILL.md`/`finish.md`/`review-and-verify.md` under the 500-LOC cap and honors the project's own file-separation doctrine). Existing files get **concise pointers** to the new files. Every agent reads the **Design Spec** below verbatim so terminology, filenames, and section anchors stay identical across ~14 files.

### Design Spec (single source of truth for all agents)

- **Anchor name:** `Primary Goal & Guardrails` — a work-doc body section (NOT frontmatter) with sub-parts: *North-Star Goal* (1 sentence), *In-Scope*, *Out-of-Scope / Non-Goals*, *Guardrails / Invariants*, *Success Signals*. Placed right after `## 1. Original Ask`, unnumbered, so numbered sprint headings are untouched (DoD [26]).
- **New file `skills/hackify/references/goal-anchor.md`:** doctrine — Phase 1 captures the anchor (grooming coverage checklist: goal, scope boundary, non-goals, constraints, acceptance all pinned before code); persisted as the work-doc section (in-chat block for quick/yolo which have no work-doc); enforced by the drift-check.
- **Drift-check wording (reviewers):** "Trace every {task | changed hunk} to `Primary Goal & Guardrails`. Serves no in-scope bullet and not required by one → **drift finding (Important)**: justify against the anchor or revert. Violates a Guardrail or a Non-Goal → **Critical**."
- **New file `skills/hackify/references/html-report.md`:** when emitted (Phase 6 Step F, alongside the Area/Change table), where written (`<project>/docs/work/done/<slug>.report.html` for full hackify; `<project>/docs/work/reports/<YYYY-MM-DD>-<slug>.report.html` for quick/yolo), the stat set, how to compute each stat from git + the work-doc, how to fill the template placeholders.
- **Stat set (Q2):** tasks done (n/total), files changed, LOC added/removed, commits, reviewer findings by severity (Critical/Important/Minor + fixed count), phase timeline (which phases ran + outcome), action items / follow-ups (from Retrospective). Charts are **inline SVG** (severity donut/bars, files+LOC bar, phase-timeline strip) — no JS charting lib.
- **New asset `skills/hackify/assets/report-template.html`:** self-contained (`<style>` inline; inline SVG; no external `<script src>`/`<link href>`/CDN). Placeholder tokens: `{{TITLE}}`, `{{SLUG}}`, `{{GENERATED_AT}}`, `{{SPRINT_GOAL}}`, `{{STAT_TASKS}}`, `{{STAT_FILES}}`, `{{STAT_LOC_ADD}}`, `{{STAT_LOC_DEL}}`, `{{STAT_COMMITS}}`, `{{SEVERITY_CHART_SVG}}`, `{{PHASE_TIMELINE}}`, `{{FINDINGS_TABLE}}`, `{{ACTION_ITEMS}}`, `{{AREA_CHANGE_TABLE}}`, `{{NEXT_STEPS}}`. Generic placeholders only — no personal tokens/absolute paths.
- **Address-all review loop (Phase 5):** after reviewers return → build a decision table (reuse review-triage columns Finding / Severity / Decision / Evidence) → fix in severity order **including Minor** (no Retrospective deferral; defer only with explicit user sign-off) → **re-run the review + verify triad to prove zero remaining**. Full hackify: batch approval via wizard for non-trivial fixes (lawkeeper §5.2 propose-then-ask). yolo: auto-fix all, no gate. quick: single reviewer (not the 3-lens panel) + same address-all + re-scan.
- **Pre-existing cleanup (Step C.5):** capture a baseline of pre-existing lint/type/test errors + dead code in the touched scope; at cleanup, surface any pre-existing issue in touched files and **offer to fix** (auto-fix in yolo; offer-with-approval in hackify + quick). Class (g) becomes "offer-to-fix now; defer only if too large, with explicit sign-off." Whole-repo pre-existing beyond touched files → cross-reference lawkeeper.

### Execution waves

- **Wave 1 — Foundations** (5 tasks, all new/independent files, no collisions): T1 goal-anchor.md, T2 html-report.md, T3 report-template.html, T4 work-doc-template.md anchor section, T5 universal-preamble.md goal question.
- **Wave 2a — Core hackify surface** (4 tasks, distinct files): T6 hackify/SKILL.md, T7 finish.md, T8 review-and-verify.md, T9 commands/summary.md. Lands the canonical phase prose first.
- **Wave 2b — Companions + reviewers** (5 tasks, distinct files; after 2a): T10 quick/SKILL.md, T11 yolo/SKILL.md, T12 groom/SKILL.md, T13 Phase-2.5 Reviewer-A pair, T14 Phase-5 Reviewer-C pair.
- **Wave 3 — Release plumbing** (3 tasks): T15 MIRROR_SOURCES, T16 version bump (plugin.json + marketplace.json + README badge/blurb), T17 CHANGELOG 0.6.0.
- **Wave 4 — Verify** (T18): run the harness triad + render the HTML template; fix all reds.

**Tight-file watch:** `README.md` (413/450 — badge bump + ≤~15-line blurb only), `phase-5-multi-review.md` (455/500 — drift-check ≤~10 lines, Reviewer C section, preserve anchors), `finish.md` (392/500), `review-and-verify.md` (364/500), `SKILL.md` (372/500 — pointers only).

## 5. Sprint Backlog

### Wave 1 — Foundations
- [x] **T1** Create `skills/hackify/references/goal-anchor.md` — Primary Goal & Guardrails doctrine (capture / persist / drift-check). *Files: goal-anchor.md. Test: none (prose; verified by harness).*
- [x] **T2** Create `skills/hackify/references/html-report.md` — HTML report authoring doctrine. *Files: html-report.md. Test: none (prose).*
- [x] **T3** Create `skills/hackify/assets/report-template.html` — self-contained template + placeholders + inline SVG charts. *Files: report-template.html. Test: manual smoke — render + screenshot in Wave 4.*
- [x] **T4** Add `## Primary Goal & Guardrails` to `skills/hackify/references/work-doc-template.md` (no renumber). *Files: work-doc-template.md. Test: DoD [26].*
- [x] **T5** Add goal-anchor capture question to `skills/hackify/references/clarify-questions/universal-preamble.md` (keep 4-section contract). *Files: universal-preamble.md. Test: DoD [14].*

### Wave 2a — Core hackify surface
- [x] **T6** `skills/hackify/SKILL.md` — Phase 1 (anchor + grooming coverage + raise cap), Phase 2.5 & Phase 5 drift-check pointers, Phase 5 address-all loop + severity-table change, Phase 6 Step F HTML pointer, Step C.5 offer-to-fix. Concise pointers; keep Template/Wizard Contract cross-refs ([17]) + Phase-6 `Summary table`/`/hackify:summary` ([19]) + pause-keyword block ([28]). *Files: SKILL.md. Test: DoD [17][19][28][80].*
- [x] **T7** `skills/hackify/references/finish.md` — Step F HTML pointer + Step C.5 baseline & offer-to-fix. Keep `Summary table` + `| Area |` ([20]). *Files: finish.md. Test: DoD [20][80].*
- [x] **T8** `skills/hackify/references/review-and-verify.md` — address-all loop (decision table, fix incl. Minor, re-run to zero) + severity-table update. Preserve escalation Template-Contract anchors + canonical severity + word cap ([10][11][15]). *Files: review-and-verify.md. Test: DoD [10][11][15][80].*
- [x] **T9** `commands/summary.md` — emit the HTML report; keep `Area`/`Change` + description frontmatter ([18]). *Files: summary.md. Test: DoD [18].*
### Wave 2b — Companions + reviewers (after 2a lands + commits)
- [x] **T10** `skills/quick/SKILL.md` — trimmed clarify (goal restatement), single-lens address-all review, offer-to-fix cleanup, HTML report. PRESERVE "Skipped phases" list + `Phase 2`/`Phase 2.5`/`Phase 5`/`four-options` + `Summary table` + exploration-nudge sentence ([22][23][35]). *Files: quick/SKILL.md. Test: DoD [21][22][23][35].*
- [x] **T11** `skills/yolo/SKILL.md` — inherit deep clarify + in-chat anchor; auto-fix all-severity review + re-scan; auto-fix pre-existing cleanup; emit HTML report. PRESERVE tokens ([34]). *Files: yolo/SKILL.md. Test: DoD [34].*
- [x] **T12** `skills/groom/SKILL.md` — graduation writes the `Primary Goal & Guardrails` section (align Groom Provenance → anchor). *Files: groom/SKILL.md. Test: DoD [25].*
- [x] **T13** Drift-check → Phase 2.5 Reviewer A pair: `skills/hackify/references/parallel-agents/phase-2.5-spec-review-a-consistency.md` + `agents/spec-reviewer-consistency.md`. Preserve the ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/SEVERITY/OUTPUT anchors, the canonical severity sentence, and the OUTPUT word-cap line. Insert the drift-check inside METHOD (a new numbered step) — do NOT add a new bolded section header. Edit BOTH files consistently (mirror pair — land together). *Files: those 2. Test: DoD [9][10][11][12][15].*
- [x] **T14** Drift-check → Phase 5 Reviewer C pair: `skills/hackify/references/parallel-agents/phase-5-multi-review.md` (Reviewer C section only; TIGHT 455/500 → ≤10 added lines) + `agents/code-reviewer-plan-consistency.md`. HARD anchor-safety (DoD [9]/[15] slice on these): keep all three `## Phase 5 — Multi-reviewer …` headings byte-identical; add drift text INSIDE Reviewer C's METHOD or SEVERITY prose only; never between `**OUTPUT**` and its `≤… words` cap line; introduce NO new `**bold**` header. Edit BOTH files consistently (mirror pair — land together). *Files: those 2. Test: DoD [9][10][11][12][15][80].*

### Wave 3 — Release plumbing
- [x] **T15** Register these 3 verbatim paths in `scripts/sync-runtimes.d/00-helpers.sh` `MIRROR_SOURCES` (append near the other `references/` + `assets/` entries): `skills/hackify/references/goal-anchor.md`, `skills/hackify/references/html-report.md`, `skills/hackify/assets/report-template.html`. Every `git ls-files skills/` path MUST appear or [55] fails. *Files: 00-helpers.sh. Test: DoD [24][55].*
- [x] **T16** Version → `0.6.0`: `.claude-plugin/plugin.json` `.version`; `.claude-plugin/marketplace.json` `.plugins[0].version` + `.plugins[0].source.ref=v0.6.0` + `.plugins[1].version`; `README.md` badge + ≤15-line "What's new in 0.6.0" blurb (stay ≤450 LOC). *Files: those 3. Test: DoD [7][16][16b].*
- [x] **T17** `CHANGELOG.md` — `## [0.6.0] - 2026-07-01` entry (Keep-a-Changelog: summary blockquote + Added/Changed) covering all four enhancements. *Files: CHANGELOG.md. Test: manual read.*

### Wave 4 — Verify
- [x] **T18** Run `validate-dod.sh` + `check-collisions.sh` + `sync-runtimes.sh --dry-run`; render `report-template.html` with sample data + screenshot; fix every red. *Files: as needed. Test: full harness green.*

## 6. Daily Updates

**2026-07-01 — Phase 2.5 Spec self-review (3 parallel reviewers).** No Critical. Applied: (A-2) §3 note resolving bracketed DoD `[n]` to `validate-dod.d/*.sh`; (C-1) split Wave 2 → 2a/2b; (B-1) T15 verbatim 3-path enumeration; (B-2) T14 anchor-safety (byte-identical Multi-reviewer headings, drift text inside METHOD/SEVERITY, no stray bold); mirror-pair atomicity noted on T13/T14. Confirmed non-issue: `plugins[1].source.ref` stays `main`. Wave plan confirmed collision-free.

**2026-07-01 — Wave 1 (Foundations) done.** Authored inline (dispatch classifier was transiently down; foundation files are consistency-critical so parent-authored for an exact Design-Spec match). T1 `goal-anchor.md` (55L), T2 `html-report.md` (64L), T3 `assets/report-template.html` (156L, self-contained, 0 external refs), T4 `work-doc-template.md` +`## Primary Goal & Guardrails` (188L, numbered headings intact), T5 `universal-preamble.md` +Q5 Goal (65L, 4 wizard headers intact). Targeted checks green: all ≤500 LOC; token scrub clean; contract headers preserved.

**2026-07-01 — Wave 2a (Core hackify surface) done.** Authored inline (classifier still flaky; these are the tightest DoD-guarded core files). T6 `SKILL.md` (372L) — Phase 1 grooming+anchor, Phase 2.5 Reviewer A drift-check, Phase 5 Reviewer C drift-check + address-all loop + Minor-no-longer-deferred, Step C.5 class (g) offer-to-fix, Step F HTML report. T7 `finish.md` (400L) — class (g) baseline+offer-to-fix rewrite, Step F HTML pointer. T8 `review-and-verify.md` (375L) — address-all loop + decision table + Minor change; escalation template contract untouched. T9 `commands/summary.md` (61L) — HTML-report step 7b + Retrospective append fix. Verified: [17][18][19][20] tokens intact; [10][11][15] escalation anchors + canonical severity + word cap intact; token scrub 0.

**2026-07-01 — Wave 2b (Companions + reviewers) done.** T10 `quick/SKILL.md` (94L) — #5C parity: gains trimmed clarify+goal, single-lens address-all review, offer-to-fix cleanup, HTML report; KEEPS "Skipped phases" identity (skips Plan+Gate, Spec-review, 3-lens Phase 5, four-options). T11 `yolo/SKILL.md` (83L) — in-chat anchor, address-all auto-fix EVERY severity + re-scan, auto-fix pre-existing cleanup, HTML report. T12 `groom/SKILL.md` (95L) — graduation seeds `## Primary Goal & Guardrails`. T13 Phase-2.5 Reviewer-A pair + T14 Phase-5 Reviewer-C pair — drift-check as METHOD step (+VERIFICATION item +skeleton line); mirror pairs land together. Verified: quick [22][23][35], yolo [34], reviewer [9-15] 3 byte-identical headings + anchors + canonical severity + word cap; phase-5-multi-review 463/500; token scrub 0.

## 7. Sprint Review

### Phase 4 — Verify (2026-07-01, fresh evidence)

- **`bash scripts/validate-dod.sh` → `ALL CHECKS PASSED` (exit 0).** Every check [1]–[90] green, incl. [80] file-size cap "102 files scanned; all ≤ 500 LOC", [16]/[16b] version 0.6.0 consistent, [34] yolo tokens, [22]/[23]/[35] quick tokens, [26] template headings, [55] mirror-completeness.
- **`bash scripts/check-collisions.sh` → 7 OK | 0 collisions.**
- **`bash scripts/sync-runtimes.sh --dry-run` → 7 runtimes, 465 files.** The 3 new files (`goal-anchor.md`, `html-report.md`, `assets/report-template.html`) mirror to the same 6 runtimes as existing `finish.md` / `codewalk/assets/viewer.html` (copilot-cli takes a MANIFEST only, by design).
- **HTML report render** — filled `report-template.html` with real task data (22 files, +564/−45, 4 commits, 18/18 tasks) via `.replace()` on the real template: 0 leftover tokens, 0 external network refs; screenshot confirms stat cards, severity SVG chart, phase-timeline pills, findings table, action items, Area/Change table, and next-steps all render cleanly (light/dark responsive).
- **Line-cap headroom after edits:** SKILL.md 372, finish.md 400, review-and-verify.md 375, phase-5-multi-review.md 463 — all ≤500.

### Phase 5 — Multi-reviewer + address-all loop (2026-07-01)

Three parallel reviewers (security / quality / plan-consistency+drift) over `5c7c604..2ad58ee`. **Zero Critical, zero Important across all three.**

- **A (security):** no exploitable findings; HTML asset confirmed self-contained (0 external refs, 0 inline JS), token scrub clean, version 0.6.0 correct.
- **B (quality):** DRY/terminology consistent across all 11 touched surfaces; mirror-pairs byte-identical; all caps ≤500; 7-section contract + canonical severity + word caps intact; all 12 new cross-ref links resolve.
- **C (plan-consistency+drift):** all 22 files map to tasks (0 scope creep); all 9 AC bullets + all 4 Original-Ask bullets delivered; goal-drift clean (guardrails honored); Q&A fidelity confirmed (#5C quick keeps "Skipped phases" identity; #2A augments not replaces); CHANGELOG matches.

**Address-all loop (decision table → empty):** A1 `html-report.md` entity-encode step — accept, fixed. B2 quick 5-lite pointer single-reviewer clarity — accept, fixed. B1 goal-anchor casing — push-back (reviewer confirmed non-defect). C1 T18 checkbox — already fixed. C2 CHANGELOG shorthand — push-back (deliberate, reviewer said no fix required). **Re-scan after fixes: `validate-dod.sh` EXIT 0 / ALL CHECKS PASSED.**

### Self-review (parent, against the 14-item checklist)

DRY ✓ · named-types n/a (no code) · layering n/a · no lint suppressions ✓ · file caps ≤500 ✓ · function caps n/a · dead code none ✓ · edge cases (empty-state HTML rows, entity-encode) ✓ · naming-for-intent ✓ · error handling n/a · no security regressions ✓ · no new `!` ✓ · no empty catches ✓ · no bare Error ✓.

## 8. Retrospective

_(filled at Phase 6; record the deliberate demo-GIF deferral rationale here)_
