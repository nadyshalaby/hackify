---
name: quick
description: Compressed-flow companion to the hackify workflow for genuinely small tasks where full ceremony (Plan+Gate, Spec review, the 5-to-6-reviewer parallel Multi-reviewer, 4-options finish) would burn more wall-clock and tokens than the change is worth. Auto-discovery triggers, invoke this skill when the user says any of "quick fix", "small change", "just fix the", "one-line fix", "tiny edit", "small fix", "small bug", "quick patch", "minor tweak", "just rename", "fix typo", or the explicit slash form /hackify:quick. Workflow shape. Phase 1 (clarify ONLY if ambiguous + restate the north-star goal; zero questions otherwise) → Phase 3 (implement; single foreground agent OR inline edit; file allowlist still applies) → Phase 4 (verify; full test + lint + typecheck triad still mandatory) → Phase 5-lite (single-lens address-all review) → Phase 6 (Step C.5 touched-scope cleanup + Step F plain-language update log + styled HTML report). Do NOT auto-fire on cross-file refactors, redesigns, debug investigations of unknown root causes, or anything touching auth/crypto/migration/secret/token/password, those route to full hackify via its own description. User-locked mode, once invoked, quick mode stays in quick mode for the entire task. It only promotes to full hackify when the user explicitly says so (e.g., "switch to full", "promote to full", "/hackify:hackify"). No work-doc is created, so progress cannot be paused or resumed across sessions, invoke full hackify if you need pause/resume.
---

# Hackify Quick (Compressed Flow For Small Tasks)

Sibling to the main hackify skill. Same end-to-end discipline (clarify → implement → verify → summary), ceremony stripped. Self-contained under the same **three-tier skill-call rule** as full hackify (`../hackify/SKILL.md`): runtime-native skills mapped in `runtime-adapters.md` are allowed, plugin-bundled siblings are allowed, third-party plugin skills are never invoked. Running a bundled plugin script by path (the law-scout) is not a skill call at all. Explicit user-initiated promotion re-enters full hackify by name. Target: ~one-third the tokens/wall-clock of full hackify.

All three orchestration defaults apply ([`../hackify/references/orchestration.md`](../hackify/references/orchestration.md)). Quick mode's fan-outs are small by design (one implementer, one reviewer, one batched refuter), so maximum tier mostly means the runtime's plain parallel dispatch; announce the tier in the Phase 1 goal-anchor line and honor `light mode` / `no ultracode` / `cheap mode` / `single agent`. The iteration driver still carries the task across turns until the ledger is ticked, quick has no work-doc, so its exit condition is the session-local ledger, not an archived doc. The completion sentinel applies here too: print the paste-ready `/goal <condition>` line beside the Phase 1 goal-anchor line, naming the commit plus the green triad and a closed review round. Quick tasks usually finish in one turn and the line still earns its place, the moment a "quick" fix turns out not to be quick, the condition is already written. You print it, only the user sets it, and never from a subagent.

The always-on ship bar applies here in full, and it stays cheap on small diffs by design: the ship gate legs are blocking only when the diff touched something the build or startup path consumes, so a typo fix records three `⏭ skipped` rows instead of booting the app (`../hackify/references/ship-gate.md`).

## Workflow shape

```
Phase 1 (clarify + goal anchor) → Phase 3 (implement) → Phase 4 (verify) → Phase 5-lite (single-lens review) → Phase 6 (Step C.5 cleanup + Step F update log + HTML report)
```

No Plan+Gate. No Spec self-review. No parallel reviewer panel (ONE reviewer carrying every lens, plus a batched refuter, runs the address-all review instead). No four-options finish menu. The update log + styled HTML report are the mandatory artifacts.

## Phase ledger, trackable, ordered (always-on)

Open a **phase ledger** at task start: a trackable to-do list (the runtime's **todo tracker**) with one item per kept phase. Clarify → Implement → Verify → Review-lite → Cleanup → Summary. Rules (full contract: `../hackify/references/phase-ledger.md`):

- One item `in_progress` at a time. No later phase starts until the current phase's exit artifact exists and its item is `completed`. No phase skipped, mark a carve-out `completed` with a one-line reason.
- **Reflect after each item**, one line: what changed, did it pass, what is next, then advance.
- Quick keeps no work-doc and no archive item, so the ledger is session-local. It exists to force order and reflection, not to survive a restart.

## Expert mindset (always-on)

Even in quick mode, think as a **senior, multi-disciplinary engineer**, problem-solver, security, performance, architect, advisor, verifier. Small tasks are where broken work hides. Prove instead of claim; when unsure, ask. Doctrine: `../hackify/references/expert-mindset.md` (a tight version is injected every prompt from `rules/expert-mindset.md`, beside the always-on `rules/hard-caps.md` and `rules/perf-guardrails.md`, the caps and performance laws bind in quick mode too).

## Kept phases

| Phase | Action | Rationale |
|---|---|---|
| **1. Clarify + goal** | Run the wizard at `../hackify/references/clarify-questions/README.md` if the ask has any ambiguity. **If the ask names a file or symbol but not a fix, read it end-to-end before judging ambiguity.** Zero ambiguity ("fix typo on line 42 of README.md") → zero questions, go to Phase 3. Either way, restate the north-star goal in one line, the in-chat Primary Goal & Guardrails anchor (no work-doc). | A misread ask costs more than a one-question wizard; the anchor keeps the fix on target. |
| **3. Implement** | **Dispatch. Never write the change yourself**, the no-parent-authored-diff law in `../hackify/SKILL.md` binds here too, down to a one-character typo. Split the ask into file-disjoint units and dispatch one agent per unit in a SINGLE message; a genuinely atomic change dispatches alone and you say in chat why it could not be split. File allowlist applies, each agent touches only its declared files. | Every code change goes through the dispatch path, no exceptions for size. Splitting is the first move, not the fallback; promote to full hackify if the task outgrows the carve-out. |
| **4. Verify** | Full triad (test + lint + typecheck) fresh, plus a **lite Evidence Ledger** (one proof row per task) and re-verify Layers 1-2 (fresh triad + goal-drift re-check). Skips the heavy Layer 3 independent re-prove. Then run BOTH deterministic scouts over the diff, perf-scout (`skills/hackify/references/perf-scout.md`) and law-scout (`skills/hackify/references/law-scout.md`), and disposition every candidate, fixed, or false-positive with a one-line reason, before the review starts, EXCEPT dismissals of Critical-default candidates: those carry over to the 5-lite reviewer for co-sign during its review. **Then run the ship gate** (`skills/hackify/references/ship-gate.md`): `ship.build`, `ship.boot`, `ship.smoke`, blocking whenever the diff touched something that leg's target consumes, `⏭ skipped` with a written reason otherwise, so a typo fix records three skips instead of booting the app. Spec: `skills/hackify/references/review-and-verify.md`. | Skipping verify is how typo fixes ship broken. A green triad still is not a booted app. |
| **5-lite. Single-lens review** | Dispatch ONE foreground reviewer over the diff carrying every lens at once: quality + engineering law + correctness + goal drift + performance + cross-module coherence. Then **refute before you fix** with ONE batched refuter (`skills/hackify/references/parallel-agents/phase-5-refute.md`, default is to keep the finding), then the address-all loop: tabulate findings, fix EVERY severity incl. Minor, re-scan to zero **on a settled diff** (a round that changed code mandates another round). Performance findings cite `perf.<domain>.<slug>` IDs from `rules/performance.md`; law findings cite lawkeeper `rule_id`s. Coherence lens per `skills/hackify/references/parallel-agents/phase-5-multi-review-f-coherence.md`, one implementation agent still leaves seams against existing code. **When the diff is UI-bearing, the same reviewer also carries the design-conformance lens**, audit against `<project>/docs/design/DESIGN.md` if one exists, else the `skills/hackify/references/frontend-design.md` bans. Method: `skills/hackify/references/parallel-agents/phase-5-multi-review-e-design.md`. See `skills/hackify/references/review-and-verify.md` (re-scan with the single reviewer, not the 6-lens panel). | Small diffs still ship bugs; one reviewer carrying every lens + refute + address-all is the light-but-real safety net. A one-line CSS tweak is exactly where token drift starts. |
| **6 C.5. Cleanup** | Offer-to-fix pre-existing lint/type/test/dead-code in the touched files so they end clean (per `finish.md` class (g)). | The best version is what lands, no leftover issues in files you touched. |
| **6F. Update log + HTML report** | Print the plain-language update log per `skills/hackify/references/finish.md` Step F, one block per change with the five fields, then emit the self-contained HTML report per `skills/hackify/references/html-report.md`. | The user opted into speed, not opacity. |

## Skipped phases (exactly these four, no others)

| Phase | Rationale |
|---|---|
| **Phase 2. Plan+Gate** | The ask itself is the plan. Tasks needing a written plan are too large for quick mode. |
| **Phase 2.5. Spec self-review** | No spec was written in Phase 2, nothing to scrutinize. |
| **Phase 5, parallel Multi-reviewer panel** | The five-to-six-parallel-reviewer panel is overkill for quick's small diffs. One reviewer carries every lens instead, and the refuter runs as a single batched agent (see Kept phases). The lenses are not dropped, only the parallelism. Promote to full hackify for the full panel. |
| **Phase 6, four-options finish menu** | Quick mode does in-place edits. The user lands via their normal git workflow. Steps C.5 (cleanup) + F (summary + HTML report) are the Phase 6 pieces kept. |

## Note (Debug-when-stuck is not skipped)

**Phase 3b is NOT skipped, if a debug investigation is needed, promote to full hackify (say "promote to full") and the 4-phase root-cause hunt runs there under its own discipline.** Quick mode itself does not run Phase 3b; the promotion path preserves the in-progress diff in the new work-doc's Daily Updates.

## Promotion to full hackify (user-initiated only)

Quick mode never auto-promotes. The user explicitly triggers promotion by saying any of these phrases (case-insensitive, scanned in the most recent user message only):

- `switch to full` / `switch to full mode`
- `go to full mode` / `go to full hackify`
- `promote to full` / `promote this to full`
- `/hackify:hackify` (slash command)
- `do full review` / `run Phase 5` / `run multi-reviewer` (explicit review request, promotes so Phase 5 can run)

No diff-size, file-count, attempt-counter, or path-pattern check ever auto-promotes. If the user is silent, quick mode stays in quick mode for the whole task, even if the diff grows large or touches sensitive paths. That is the user's stated preference.

## Promotion procedure

On user-initiated promotion: (1) STOP implementation; (2) write a work-doc from accumulated context at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` (template at `skills/hackify/references/work-doc-template.md`); (3) re-enter full hackify Phase 2 (Plan+Gate); (4) preserve intent + clarify-answers + any partial diff in the Daily Updates section. Set frontmatter `current_task: (promoted from quick mode, awaiting gate)`. Do not silently re-dispatch implementation agents.

## When NOT to use quick mode

Route these to full hackify (`/hackify:hackify`) from the start.

| Shape | Why |
|---|---|
| Cross-file refactors | Quick mode targets ≤3 files; larger spread wants Plan+Gate. |
| Redesigns | Plan+Gate is required for sign-off on the new shape. |
| Debug investigations of unknown root causes | Phase 3b's 4-phase root-cause hunt is needed from the jump. |
| Touches auth/crypto/migrations/secrets/tokens/passwords | Security-sensitive surface deserves Phase 5 multi-reviewer. |
| Cross-team review needs | Phase 5 multi-reviewer anchors the review conversation. |
| Cannot list touched files up-front | Task is too underspecified for a file allowlist. |

## Update log (mandatory)

End every task with a plain-language **update log**: one block per change, five fields each, in this order.

```
**Problem**
**Root cause**
**Solution**
**Verification evidence**
**Deployment status**
```

Separate blocks with a line containing exactly `----`. Quick mode typically produces one block; up to three if the fix touched separate things.

Write it the way you would explain the work out loud: everyday words, no jargon the user did not use, and never a phase number, task ID, reviewer letter or scout name. Field-by-field guidance, voice rules, and a worked example: `skills/hackify/references/finish.md` Step F.

Print to chat. If the user promoted to full hackify mid-task, append the log to the new work-doc's Retrospective under `## Update log`. For on-demand invocation, see `commands/summary.md` (`/hackify:summary`).

**Then emit the styled HTML report**, a self-contained `<slug>.report.html` at `docs/work/reports/<YYYY-MM-DD>-<slug>.report.html` (quick has no archived work-doc). Authoring + token map: `skills/hackify/references/html-report.md`.

## Anti-rationalizations (STOP and apply the listed reality)

| Thought | Reality |
|---|---|
| "I can skip Phase 4 verify, it is just a typo" | Phase 4 stays. Typo fixes still need lint + typecheck to pass. The verification triad is the cheapest insurance in the workflow. |
| "User said 'quick' so we skip Phase 1 clarify" | Only skip clarify if there is zero ambiguity in the ask. If even one detail is unclear, run the wizard, one batched question is cheaper than a wrong implementation. |
| "An update log is overkill for a one-line fix" | It's mandatory. One block is fine. The user always knows what landed and why. |
| "I'll fold verify and review into one step" | The ledger keeps them separate and ordered. Tick Verify `completed` before Review-lite starts. |
| "Quick mode, so skip the ship gate" | The ship gate is always-on in every mode. If there is nothing to run, write the `⏭ skipped` row with the reason. That costs one line. |
| "One reviewer means fewer lenses" | No. One reviewer, all lenses. Quick mode drops the review parallelism, never the coverage. |
| "It's a typo, I'll just edit the file myself" | The no-parent-authored-diff law binds in quick mode too, with no size threshold. Dispatch it. |
| "Quick mode means one agent, so no splitting" | Splitting is the first move. One agent is what you land on when the change is genuinely atomic, not where you start. |
| "The re-scan was clean, done" | Only if the diff has not changed since that scan. Fixes applied after a scan were never reviewed. |
| "This task is getting bigger than I thought, let me silently switch to full mode for the user" | Quick mode never auto-promotes. The user explicitly opted into quick mode. Stay in quick mode until the user says "switch to full" or one of the documented promotion phrases. |

## One-line summary

Clarify-if-ambiguous + goal anchor → implement (one agent, file allowlist) → verify fresh (triad + both scouts + ship gate) → single reviewer carrying every lens, refute, then address-all to a settled diff → touched-scope cleanup + plain-language update log + styled HTML report. Stays in quick mode until the user explicitly promotes to full hackify.
